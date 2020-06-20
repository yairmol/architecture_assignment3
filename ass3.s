; parse_arg(arg, format, index)
%macro parse_arg 3
	push ebx				; save ebx in case sscanf overrides some registers
	; push dword [ebx + 4*%3]
	; push string_format
	; call printf				; printf("%s\n", argv[index])
	;add esp, 8
	pop ebx
	push ebx
	push %1
	push %2
	push dword [ebx + 4*%3]
	call sscanf				; sscanf(argv[index], format, arg)
	add esp, 12
	pop ebx					; restore ebx
%endmacro

; print_arg(arg, string_format)
%macro print_arg 2
	push ebx				; save ebx in case sscanf overrides some registers
	push %1
	push %2
	call printf				; printf(format, arg)
	add esp, 8
	pop ebx					; restore ebx
%endmacro

; define constants
STKSZ 	equ 16*1024
CODEP 	equ 0
FLAGSP 	equ 4
SPP 	equ 8

section .rodata
	argument_error_string: db "error: not enough arguments", 10, 0
	decimal_string_format: db "%d", 0
	float_string_format: db "%f", 0
	string_format: db "%s", 10, 0
	hexa_string_format: db "%X", 10, 0
	right_string: db "rightmost", 10, 0
	done_string: db "DONE!", 10, 0
	pointer_string_format: db "main esp: %p",10,0

section .data
	global drones_array
	global main_cr
	global SPT
	global CURR
	global scheduler_cr
	
	global N
	global K
	global R
	global d

	; game configuration variables
	N: dd 0		; number of drones
	R: dd 0		; number of rounds after which a drone is eliminated
	K: dd 0		; number of drone steps after which the game board is printed
	d: dq 0.0	; maximum distnace to destroy target
	seed: dw 0	; seed for the LFSR random generator

	SPT: dd 0	; holds the stack pointer while init
	CURR: dd 0	; pointer to the currently running co-routine
	; a memory location holding a pointer to the beggining of the drones co-routine array
	drones_array: dd 0
	drone_cr_array: dd 0

	; define the main co-routine
	main_cr: dd main
	flags_main: dd 1
	sp_main: dd esp

	; Structure for the scheduler co-routine
	scheduler_cr: dd scheduler_co_routine
	Flags_scheculer: dd 0
	sp_scheduler: dd stk_scheduler+STKSZ

	; Structure for the Printer co-routine
	printer_cr: dd printer_co_routine
	Flags_printer: dd 0
	sp_printer: dd stk_printer+STKSZ

section .bss
	stk_scheduler: resb STKSZ
	stk_printer: resb STKSZ

section .text
	global main
	global random_generator
	global resume
	global co_init
	extern stderr
	extern fprintf
	extern sscanf
	extern printf
	extern calloc
	extern free
	extern target_co_routine
	extern scheduler_co_routine
	extern printer_co_routine
	extern drone_init
	extern init_target
	
main:
	push ebp
	mov ebp, esp
	pushad
	mov ebx, [ebp + 8]		; ebx = argc
	cmp ebx, 5				; check that there are 5 arguments (exculding the name of the program)
	ja read_arguments
	push argument_error_string
	push dword [stderr]
	call fprintf			; fprintf(stderr, error_string)
	add esp, 8
	jmp end_main
	read_arguments:			; template: ass3 <N> <R> <K> <d> <seed>
	mov ebx, [ebp + 12]		; ebx = argv
	parse_arg N, decimal_string_format, 1
	parse_arg R, decimal_string_format, 2
	parse_arg K, decimal_string_format, 3
	parse_arg d, float_string_format, 4
	parse_arg seed, decimal_string_format, 5

	; mov dword [seed], 0xACE1
	; mov eax, 0
	; call random_generator
	; push eax
	; push hexa_string_format
	; call printf
	; add esp, 8
	; finit
	; fld qword[d]
	; sub esp,8
	; fstp qword[esp]
	; push float_string_format
	; call printf
	; add esp, 12
	; print_arg dword[N], decimal_string_format
	; print_arg dword[R], decimal_string_format
	; print_arg dword[K], decimal_string_format
	; print_arg dword[seed], decimal_string_format
	; initiate the scheduler, printer and target co-routines
	debug: mov ebx, scheduler_cr
	call co_init
	mov ebx, printer_cr
	call co_init
	call init_target

	; create an array of pointers for drones co-routines
	push dword 4			; ponter size
	push dword [N]
	call calloc				; calloc(N, 4) allocate an array of size N, where each element of the array is a pointer to a drone struct
	add esp, 8
	mov [drones_array], eax	; set the drone_array to point to the begining of the drones co-routine array
	mov ebx, 0
	; initialize all drones co-routine
	drone_init_for_start:
		cmp ebx, [N]
		je drone_init_for_end
		; init drone with id ebx
		call drone_init
		inc ebx
		jmp drone_init_for_start
	drone_init_for_end:
	mov dword [CURR], main_cr
	; begin the simulation by starting the scheduler co-routine 
	mov ebx, scheduler_cr
	call resume
	push done_string
	call printf
	add esp, 4
	call free_memory
	end_main:
	popad
	mov esp, ebp
	pop ebp
	ret

; initialization method for the printer and scheduler co-routine
; ebx is pointing to the relevent co-routine
co_init:
	pushad
	bts dword [ebx + FLAGSP],0	; initialized?
	jc init_done
	mov eax, [ebx + CODEP] 		; Get initial IP
	mov [SPT], esp				; save the stack pointer
	mov esp, [ebx + SPP] 		; Get initial SP
	mov ebp, esp 				; Also use as EBP
	push eax 					; Push initial "return" address
	pushfd 						; and flags
	pushad 						; and all other regs
	mov [ebx + SPP], esp		; Save new SP
	mov esp, [SPT] 				; Restore old SP
init_done:
	popad
	ret

; resume method for the printer and scheduler co-routines
; assume that ebx hold the pointer to the resumed co-routine and CURR is apointer to the current running co-routine
; when this method is called the return address is pushed, then we push the state of computation and retrun to the resumed co-routine
resume:
	pushfd 						; Save state of caller
	pushad
	mov edx, [CURR]
	mov [edx + SPP], esp 		; Save current SP
do_resume:
	mov esp, [ebx + SPP] 		; Load SP (resumed co)
	mov [CURR], ebx				; set the new current co-routine
	popad 						; Restore resumed co-routine state
	popfd
	ret 						; "return" to resumed co-routine!

random_generator:
	push ebp
	mov ebp, esp
	sub esp, 2
	pushad
	mov bx, [seed]		; bx will be our shift register
	mov esi, 0			; set for variable to 0
	for_random_start:
		; calculate the input bit as [16] XOR [14] XOR [13] XOR [11]
		cmp esi, 16
		je for_random_end
		mov cx, bx
		and cx, 1		; cx now hold the 16th bit
		mov dx, bx
		and dx, 4		; dx now hold the 14th bit
		shr dx, 2		; set the location of the 14th bit to the 16th bit so we could xor the two bits
		xor cx, dx		; xor the two bits and store it in cx
		mov dx, bx
		and dx, 8		; dx now holds the 13th bit
		shr dx, 3		; set the location of the 13th bit to the 16th bit so we could xor the two bits
		xor cx, dx		; xor the two bits and store it in cx
		mov dx, bx
		and dx, 32		; dx now holds the 11th bit
		shr dx, 5		; set the location of the 13th bit to the 16th bit so we could xor the two bits
		xor cx, dx		; xor the two bits and store in cx
		shr bx, 1		; shift the shift register one time
		shl cx, 15		; set the first bit of cx to be the calculated bit
		add bx, cx		; set the first bit of bx to be the calculated bit
		inc esi
		jmp for_random_start
	for_random_end:
	mov [ebp - 2], bx
	mov [seed], bx		; store the new value in seed for next time 
	popad
	mov eax, 0
	mov ax, [ebp - 2]
	add esp, 2
	mov esp, ebp
	pop ebp
	ret

free_memory:
	push ebp
	mov ebp, esp
	pushad
	mov ecx, 0
	free_memory_for_start:
		; TODO; fix this to free the real stack
		mov ebx, [drones_array + ecx*4]
		push ebx			; save ebx in case free overrides it
		push dword [ebx + SPP]
		call free
		add esp, 4
		pop ebx				; restore ebx
		push ebx
		call free			; free the allocated drone co-routine struct
		add esp, 4
	free_memory_for_end:
	; free the drone pointers array
	push dword [drones_array]
	call free				; free the allocated memory for the drones array
	add esp, 4
	popad
	mov esp, ebp
	pop ebp
	ret
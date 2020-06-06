; parse_arg(arg, format, index)
%macro parse_arg 3
	push ebx				; save ebx in case sscanf overrides some registers
	push dword [ebx + 4*%3]
	push string_format
	call printf				; printf("%s\n", argv[index])
	add esp, 8
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

; struct drone-co-routine {
;	void* codep;	the pointer to the next line of code to execute
;	void* sp;		stack pointer for the drone co-routine
;	tword x;		drone's x coordinate
;	tword y;		drone's y coordinate
;	tword angle;	drone's angle from the x axix in degrees [0, 360] (heading)
;	tword speed; 	drone's speed
; }
; struct size: 48

; define constants
STKSZ 	equ 16*1024
CODEP 	equ 0
FLAGSP 	equ 4
SPP 	equ 8
DRSZ	equ 48 				; TODO: define the Drone co-routine structue and set it's size here

section .rodata
	argument_error_string: db "error: not enough arguments", 10, 0
	decimal_string_format: db "%d", 0
	float_string_format: db "%lf", 0
	string_format: db "%s", 10, 0
	hexa_string_format: db "%X", 10, 0
	right_string: db "rightmost", 10, 0

section .text
	global drones_array

section .data
	; game configuration variables
	N: dd 0		; number of drones
	R: dd 0		; number of rounds after which a drone is eliminated
	K: dd 0		; number of drone steps after which the game board is printed
	d: dq 0.0	; maximum distnace to destroy target
	seed: dw 0	; seed for the LFSR random generator

	; a memory location holding a pointer to the beggining of the drones co-routine array
	drones_array: dd 0

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
	extern stderr
	extern fprintf
	extern sscanf
	extern printf
	extern calloc
	extern free

	extern scheduler_co_routine
	extern printer_co_routine
	extern drone_init
	
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
	mov dword [seed], 0xACE1
	mov eax, 0
	call random_generator
	push eax
	push hexa_string_format
	call printf
	add esp, 8
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

	; create an array of drones co-routines
	push DRSZ
	push dword [N]
	call calloc				; calloc(N, DRSZ) allocate an array of size N, where each element of the array is of size DRSZ
	add esp, 8
	mov [drones_array], eax	; set the drone_array to point to the begining of the drones co-routine array
	; TODO: initiate each co-routine
	end_main:
	push dword [drones_array]
	call free				; free the allocated memory for the drones array
	add esp, 4
	popad
	mov esp, ebp
	pop ebp
	ret

; TODO: fix this to match our co-routine structure
; co_init:
; 	pushad
; 	bts dword [EBX+FLAGSP],0 ; initialized?
; 	jc init_done
; 	mov EAX,[EBX+CODEP] ; Get initial IP
; 	mov [SPT], ESP
; 	mov ESP,[EBX+SPP] ; Get initial SP
; 	mov EBP, ESP ; Also use as EBP
; 	push EAX ; Push initial "return" address
; 	pushfd ; and flags
; 	pushad ; and all other regs
; 	mov [EBX+SPP],ESP ; Save new SP
; 	mov ESP, [SPT] ; Restore old SP
; init_done:
; 	popad
; 	ret

; ; TODO: fix this to match our co-routine structure
; resume:
; 	pushf ; Save state of caller
; 	pusha
; 	mov EDX, [CURR]
; 	mov [EDX+SPP],ESP ; Save current SP
; do_resume:
; 	mov ESP, [EBX+SPP] ; Load SP (resumed co)
; 	mov [CURR], EBX
; 	popa ; Restore resumed co-routine state
; 	popf
;	ret ; "return" to resumed co-routine!

random_generator:
; TODO: implement the LFSR psuedo-random generator as specified in the instructions
	push ebp
	mov ebp, esp
	sub esp, 2
	pushad
	mov bx, [seed]		; bx will be our shift register
	; calculate the input bit as [16] XOR [14] XOR [13] XOR [11]
	mov cx, bx
	and cx, 1			; cx now hold the 16th bit
	mov dx, bx
	and dx, 4			; dx now hold the 14th bit
	shr dx, 2			; set the location of the 14th bit to the 16th bit so we could xor the two bits
	xor cx, dx			; xor the two bits and store it in cx
	mov dx, bx
	and dx, 8			; dx now holds the 13th bit
	shr dx, 3			; set the location of the 13th bit to the 16th bit so we could xor the two bits
	xor cx, dx			; xor the two bits and store it in cx
	mov dx, bx
	and dx, 32			; dx now holds the 11th bit
	shr dx, 5			; set the location of the 13th bit to the 16th bit so we could xor the two bits
	xor cx, dx			; xor the two bits and store in cx
	shr bx, 1			; shift the shift register one time
	shl cx, 15			; set the first bit of cx to be the calculated bit
	add bx, cx			; set the first bit of bx to be the calculated bit
	mov [ebp - 2], bx 
	popad
	mov ax, [ebp - 2]
	add esp, 2
	mov esp, ebp
	pop ebp
	ret
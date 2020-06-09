; struct co-routine {
;   void* codep
;   int flags
;   void* stp
; }
CRSZ    equ 12     ; co routine struct size is 12 
STKSZ 	equ 16*1024
CODEP 	equ 0
FLAGSP 	equ 4
SPP 	equ 8
section .rodata
    float_string_format: db "%lf", 10, 0
    decimal_string_format: db "%d", 10, 0
section .data
    ; variables to hold the co-routine state
    x:      dq 0
    y:      dq 0
    angle:  dq 0
    speed:  dq 0

section .text
    global drone_init
    global drone_resume
    extern random_generator
    extern drones_array
    extern malloc
    extern CURR
    extern SPT
    extern printf

drone_co_routine:

; TODO: implement the drone co-routine
; (*) calculate random heading change angle  ∆α       ; generate a random number in range [-60,60] degrees, with 16 bit resolution
; (*) calculate random speed change ∆a         ; generate random number in range [-10,10], with 16 bit resolution        
; (*) calculate a new drone position as follows:
;     (*) first move speed units at the direction defined by the current angle, wrapping around the torus if needed.
;         For example, if speed=60 then move 60 units in the current direction.
;     (*) then change the current angle to be α + ∆α, keeping the angle between [0, 360] by wraparound if needed
;     (*) then change the current speed to be speed + ∆a, keeping the speed between [0, 100] by cutoff if needed
; (*) while mayDestroy(…) to check if a drone may destroy the target
;     (*) destroy the target	
;     (*) resume target co-routine
;     (*) calculate random angle ∆α       ; generate a random number in range [-60,60] degrees, with 16 bit resolution
;     (*) calculate random speed change ∆a    ; generate random number in range [-10,10], with 16 bit resolution        
;     (*) calculate a new drone position as follows:
;         (*) first move speed units at the direction defined by the current angle, wrapping around the torus if needed. 
;         (*) then change the current angle to be α + ∆α, keeping the angle between [0, 360] by wraparound if needed
;         (*) then change the current speed to be speed + ∆a, keeping the speed between [0, 100] by cutoff if needed
; (*) end while 	
;     (*) switch back to a scheduler co-routine by calling resume(scheduler)

; assume ebx holds the id of the drone
drone_init:
	pushad
    push ebx
    push dword CRSZ
    call malloc                 ; malloc(CRSZ) allocate a co-routine struct 
    add esp, 4
    pop ebx
    mov [drones_array + ebx*4], eax ; store the pointer to the co-routine in the drones co-routine array
    mov ebx, eax                ; ebx now points to the co-routine struct
    mov dword [ebx + CODEP], drone_co_routine
    mov dword [ebx + FLAGSP], 1
    push STKSZ
    call malloc                 ; malloc(STKSZ) allocate a stack for this co-routine
    add esp, 4
    mov [ebx + SPP], eax        ; set co-routine stack pointer
    add dword [ebx + SPP], STKSZ; set stack pointer to top of the stack
	mov eax, [ebx + CODEP] 		; Get initial IP
	mov [SPT], esp				; save the stack pointer
	mov esp, [ebx + SPP] 		; Get initial SP
	mov ebp, esp 				; Also use as EBP
	push eax 					; Push initial "return" address
	pushfd 						; and flags
	pushad 						; and all other regs
    call random_generator       ; generate initial x coordinate
    mov [x], ax                 ; store it in x
    push eax
    push decimal_string_format
    call printf
    add esp, 8
    call random_generator       ; generate initial y coordinate
    mov [y], ax                 ; store it in y
    push eax
    push decimal_string_format
    call printf
    add esp, 8
    call random_generator       ; generate initial angle
    mov [angle], ax             ; store it in angle
    push eax
    push decimal_string_format
    call printf
    add esp, 8
    call random_generator       ; generate initial speed
    mov [speed], ax             ; store it in speed
    push eax
    push decimal_string_format
    call printf
    add esp, 8
    fild qword [x]               ; push x,y,angle and speed to stack
	sub esp,8
	fstp qword [esp]
    fild qword [y]
	sub esp,8
	fstp qword [esp]
    fild qword [angle]
	sub esp,8
	fstp qword [esp]
    fild qword [speed]
	sub esp,8
	fstp qword [esp]

    fild qword[x]
	sub esp,8
	fstp qword[esp]
	push float_string_format
	call printf
	add esp, 12
    fild qword[y]
	sub esp,8
	fstp qword[esp]
	push float_string_format
	call printf
	add esp, 12
    fild qword[angle]
	sub esp,8
	fstp qword[esp]
	push float_string_format
	call printf
	add esp, 12
    fild qword[speed]
	sub esp,8
	fstp qword[esp]
	push float_string_format
	call printf
	add esp, 12
	mov [ebx + SPP], esp		; Save new SP
	mov esp, [SPT] 				; Restore old SP
init_done:
	popad
	ret
; TODO: implement drone-co-routine initialization

; assume that ebx contains the index of the drone to be resumed
drone_resume:
; TODO: implement drone-co-routine resume
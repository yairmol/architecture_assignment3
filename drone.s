; scale(loc,a,b) scales ax to range [a,b] and stores it in loc
%macro scale 3
    push eax
	fild dword [esp]    ;load ax
    pop eax
    fld qword [%3]
    fld qword [%2]
    fsubp
    fmulp       ; ax * (b-a)
    fild dword [max_int]
    fdivp       ;(ax * (b-a))/(2^16 -1)
    fld qword [%2]
    faddp        ;(ax * (b-a))/(2^16 -1) +a
    fstp qword [%1]
    ffree
%endmacro

%macro print_float 0
    pushad
    sub esp, 8
    fst qword [esp]
    push float_string_format
    call printf
    add esp, 12
    popad
%endmacro

%macro print 2
    pushad
    push dword %2
    push %1
    call printf
    add esp, 8
    popad
%endmacro

; struct drone-co-routine {
;	void* codep;	the pointer to the next line of code to execute
;	int flags;		flags
;	void* sp;		stack pointer for the drone co-routine
;	double x;		drone's x coordinate
;	double y;		drone's y coordinate
;	double angle;	drone's angle from the x axix in degrees [0, 360] (heading)
;	double speed; 	drone's speed
;   int score;
;   void* initial_sp; the pointer the stack begining
; }
; struct size: 52

CRSZ    equ 52     ; co routine struct size is 48
STKSZ 	equ 16*64
CODEP 	equ 0
FLAGSP 	equ 4
SPP 	equ 8
XP      equ 12
YP      equ 20
ANGLEP  equ 28
SPEEDP  equ 36
SCOREP  equ 44
ISPP    equ 48

section .rodata
    float_string_format: db "%f", 10, 0
    decimal_string_format: db "score: %d", 10, 0
    pointer_string_format: db "pointer: %p", 10, 0

section .data
    extern drones_array
    extern scheduler_cr
    extern d
    extern target_cr
    extern curr_drone
    ; variables to hold the co-routine state
    x:              dq 0
    y:              dq 0
    angle:          dq 0
    delta_angle:    dq 0
    speed:          dq 0
    delta_speed:    dq 0
    score:          dd 0
    max_delta_angle: dq 60.0
    min_delta_angle: dq -60.0
    max_delta_speed: dq 10.0
    min_delta_speed: dq -10.0
    max_angle: dq 360.0
    zero: dq 0.0
    hundred: dq 100.0
    max_int: dd 65535
    temp: dq 0.0

section .text
    global drone_init
    global drone_resume
    extern random_generator
    extern malloc
    extern printf
    extern co_init
    extern resume
    
drone_co_routine:
    finit
    call change_drone_position

    drone_while_start:
    call mayDestroy
    ;print decimal_string_format, eax
    cmp eax, 0          ; if mayDestroy returned false
    je cant_destroy     ; don't increment the score
    mov ebx, [curr_drone]
    inc dword [ebx + SCOREP]
    mov ebx, target_cr
    call resume
    cant_destroy:
    call change_drone_position
    mov ebx, scheduler_cr
    call resume
    jmp drone_while_start
    drone_while_end:

change_drone_position: 
    push ebp
	mov ebp, esp
	pushad
    finit
    ; generate random delta angle
    call random_generator
    scale delta_angle, min_delta_angle, max_delta_angle
    ; generate random delta speed
    call random_generator
    scale delta_speed, min_delta_speed, max_delta_speed
    
    ; calculate new x
    mov ebx, [curr_drone]
    fld qword [ebx + ANGLEP]   ;load angle
    push dword 180
    fild dword [esp]
    pop eax
    fdivp               ; angle / 180
    fldpi
    fmulp               ; angle * pi / 180
    fcos                ; cosα
    fmul qword [ebx + SPEEDP]  ; speed * cosα
    fstp qword [temp]
    push dword 100
    fild dword [esp]
    pop eax
    fld qword [temp]
    fadd qword [ebx + XP]
    fprem

    ftst    ;compare ST(0) with 0.0
    fstsw ax          ;copy the Status Word containing the result to AX
    fwait             ;insure the previous instruction is completed
    sahf              ;transfer the condition codes to the CPU's flag register
    ja not_negative_x
    jz not_negative_x
    push dword 100
    fild dword [esp]
    pop eax
    faddp
    not_negative_x:
    fstp qword [ebx + XP]
    ffree

    ; calculate new y
    fld qword [ebx + ANGLEP]
    push dword 180
    fild dword [esp]
    pop eax
    fdivp               ; angle / 180
    fldpi
    fmulp               ; angle * pi / 180
    fsin                ; sinα
    fmul qword [ebx + SPEEDP]
    fstp qword [temp]
    push dword 100
    fild dword [esp]
    pop eax
    fld qword [temp]
    fadd qword [ebx + YP]
    fprem
    ftst    ;compare ST(0) with 0.0
    fstsw ax          ;copy the Status Word containing the result to AX
    fwait             ;insure the previous instruction is completed
    sahf              ;transfer the condition codes to the CPU's flag register
    ja not_negative_y
    jz not_negative_y
    push dword 100
    fild dword [esp]
    pop eax
    faddp
    not_negative_y:
    fstp qword [ebx + YP]
    ffree

    ; calculate new angle
    fld qword [ebx + ANGLEP]   
    fadd qword [delta_angle]   ;angle += ∆α
    ; wraparound:       
    fstp qword [temp]
    push dword 360
    fild dword [esp]
    pop eax
    fld qword [temp]
    fprem
    ftst    ;compare with 0.0
    fstsw ax          ;copy the Status Word containing the result to AX
    fwait             ;insure the previous instruction is completed
    sahf              ;transfer the condition codes to the CPU's flag register
    ja not_negative_angle
    jz not_negative_angle
    push dword 360
    fild dword [esp]
    pop eax
    faddp
    not_negative_angle:
    fstp qword [ebx + ANGLEP]
    ffree

    ; calculate new speed
    fld qword [ebx + SPEEDP]
    fadd qword [delta_speed]    ;speed += delta_speed
    fst qword [ebx + SPEEDP]  
    push dword 100
    ficom dword [esp]   ;compare ST(0) with the value of the real8_var variable
    pop eax
    fstsw ax          ;copy the Status Word containing the result to AX
    fwait             ;insure the previous instruction is completed
    sahf              ;transfer the condition codes to the CPU's flag register
    jb check_negative_speed   ;only the C0 bit (CF flag) would be set if no error   => speed < 100
    push dword 100
    fild dword [esp]
    pop eax
    fstp qword [ebx + SPEEDP]
    jmp change_drone_position_end
    check_negative_speed:
    ftst    ;compare ST(0) with 0.0
    fstsw ax          ;copy the Status Word containing the result to AX
    fwait             ;insure the previous instruction is completed
    sahf              ;transfer the condition codes to the CPU's flag register
    ja change_drone_position_end
    fldz    ; fld 0
    fstp qword [ebx + SPEEDP]

    change_drone_position_end:
    popad
    mov esp, ebp
	pop ebp
	ret

mayDestroy:
    push ebp
    mov ebp, esp
    sub esp, 4
    pushad
    mov dword [ebp - 4], 0    ;can't destroy
    finit
    mov ebx, target_cr
    fld qword [ebx + XP]
    mov ecx, [curr_drone]    
    fld qword [ecx + XP]
    fsubp               ; (target.x - drone.x)
    fld st0             ; duplicate st0
    fmulp               ; st0 = (target.x - drone.x)^2
    fld qword [ebx + YP]
    fld qword [ecx + YP]
    fsubp               ; (target.y - drone.y)
    fld st0             ; duplicate st0
    fmulp               ; st0 = (target.y - drone.y)^2
    faddp               ; st0 = (dx^2 + dy^2)
    fsqrt               ; st0 = sqrt(st0)
    fld qword [d]       
    fcomi st0, st1        ; d < distance ?
    jb no_destroy       ; if yes, don't destroy the target
    mov dword [ebp - 4], 1    

    no_destroy:
    popad
    mov eax, [ebp - 4]
    add esp, 4
    mov esp, ebp
    pop ebp
    ret


; assume ebx holds the id of the drone
drone_init:
    ; init the drone co-routne struct
	pushad
    finit
    ;print pointer_string_format, drone_co_routine
    push ebx
    push dword CRSZ
    call malloc                 ; malloc(CRSZ) allocate a co-routine struct 
    add esp, 4
    ;print pointer_string_format, eax
    pop ebx
    mov ecx, [drones_array]
    mov [ecx + ebx*4], eax ; store the pointer to the co-routine in the drones co-routine array
    mov ebx, eax                ; ebx now points to the co-routine struct
    mov dword [ebx + CODEP], drone_co_routine
    mov dword [ebx + FLAGSP], 0
    push ebx
    push STKSZ
    call malloc                 ; malloc(STKSZ) allocate a stack for this co-routine
    add esp, 4
    ;print pointer_string_format, eax
    pop ebx
    mov [ebx + SPP], eax        ; set co-routine stack pointer
    mov [ebx + ISPP], eax
    add dword [ebx + SPP], STKSZ; set stack pointer to top of the stack
    ; generate random initial properties
    call random_generator       ; generate initial x coordinate
    scale ebx + XP, zero, hundred
    call random_generator       ; generate initial y coordinate
    scale ebx + YP, zero, hundred
    call random_generator       ; generate initial angle
    scale ebx + SPEEDP, zero, hundred
    call random_generator       ; generate initial speed
    scale ebx + ANGLEP, zero, max_angle

    ; print the generated values just to see that ecerything is ok
    ; push ebx
    ; fld qword[ebx + XP]
	; sub esp,8
	; fstp qword[esp]
	; push float_string_format
	; call printf
	; add esp, 12
    ; fld qword[ebx + YP]
	; sub esp,8
	; fstp qword[esp]
	; push float_string_format
	; call printf
	; add esp, 12
    ; fld qword[ebx + ANGLEP]
	; sub esp,8
	; fstp qword[esp]
	; push float_string_format
	; call printf
	; add esp, 12
    ; fld qword[ebx + SPEEDP]
	; sub esp,8
	; fstp qword[esp]
	; push float_string_format
	; call printf
	; add esp, 12
    ; pop ebx

    ; init the co-routine
    call co_init
	popad
	ret

; scale(loc,a,b) scales ax to range [a,b] and stores it in loc
%macro scale 3
    push eax
	fild dword [esp]    ;load ax
    ;print_float
    pop eax
    fld qword [%3]
    fld qword [%2]
    fsubp
    ;print_float
    fmulp       ; ax * (b-a)
    ;print_float
    fild dword [max_int]
    ;print_float
    fdivp       ;(ax * (b-a))/(2^16 -1)
    ;print_float
    fld qword [%2]
    ;print_float
    faddp        ;(ax * (b-a))/(2^16 -1) +a
    ;print_float
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

section .rodata
    float_string_format: db "%f",10,0

section .data
    global x
    global y
    global angle
    global speed
    global target_x
    global target_y 
    global d
    seed_1: dw 0xACE1
    seed: dw 0xACE1
    max_delta_angle: dq 60.0
    min_delta_angle: dq -60.0
    max_delta_speed: dq 10.0
    min_delta_speed: dq -10.0
    max_int: dd 65535
    delta_angle: dq 0
    delta_speed: dq 0
    temp: dq 0.0
    x: dq 0
    y: dq 0
    speed: dq 0
    angle: dq 0
    target_x: dq 0.0
    target_y: dq 0.0
    d: dq 0.0

section .text
    global random_generator_1
    global mayDestroy
    global change_drone_position
    extern printf
    extern random_generator2

random_generator_1:
    push ebp
	mov ebp, esp
	sub esp, 2
	pushad
	mov bx, [seed_1]		; bx will be our shift register
    ; calculate the input bit as [16] XOR [14] XOR [13] XOR [11]
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
	mov [ebp - 2], bx
	mov [seed_1], bx		; store the new value in seed for next time 
	popad
	mov eax, 0
	mov ax, [ebp - 2]
	add esp, 2
	mov esp, ebp
	pop ebp
	ret

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


mayDestroy:
    push ebp
    mov ebp, esp
    sub esp, 4
    pushad
    mov dword [ebp - 4], 0    ;can't destroy
    finit
    fld qword [target_x]    
    fld qword [x]
    fsubp               ; (target.x - drone.x)
    ;print_float
    fld st0             ; duplicate st0
    fmulp               ; st0 = (target.x - drone.x)^2
    ;print_float
    fld qword [target_y]
    fld qword [y]
    fsubp               ; (target.y - drone.y)
    ;print_float
    fld st0             ; duplicate st0
    fmulp               ; st0 = (target.y - drone.y)^2
    ;print_float
    faddp               ; st0 = (dx^2 + dy^2)
    ;print_float
    fsqrt               ; st0 = sqrt(st0)
    ;print_float
    fld qword [d]       
    ;print_float
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

change_drone_position: 
    push ebp
	mov ebp, esp
	pushad
    finit
    ; generate random delta angle
    call random_generator2
    scale delta_angle, min_delta_angle, max_delta_angle
    ; generate random delta speed
    call random_generator2
    scale delta_speed, min_delta_speed, max_delta_speed
    
    ; calculate new x
    fld qword [angle]   ;load angle
    ;print_float
    push dword 180
    fild dword [esp]
    pop eax
    fdivp               ; angle / 180
    fldpi
    fmulp               ; angle * pi / 180
    fcos                ; cosα
    ;print_float
    fmul qword [speed]  ; speed * cosα
    ;print_float
    fstp qword [temp]
    push dword 100
    fild dword [esp]
    pop eax
    fld qword [temp]
    fadd qword [x]
    fprem
    ;print_float
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
    fstp qword [x]
    ffree

    ; calculate new y
    fld qword [angle]
    push dword 180
    fild dword [esp]
    pop eax
    fdivp               ; angle / 180
    fldpi
    fmulp               ; angle * pi / 180
    fsin                ; sinα
    fmul qword [speed]
    fstp qword [temp]
    push dword 100
    fild dword [esp]
    pop eax
    fld qword [temp]
    fadd qword [y]
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
    fstp qword [y]
    ffree

    ; calculate new angle
    fld qword [angle]   
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
    fstp qword [angle]
    ffree

    ; calculate new speed
    fld qword [speed]
    fadd qword [delta_speed]    ;speed += delta_speed
    fst qword [speed]  
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
    fstp qword [speed]
    jmp change_drone_position_end
    check_negative_speed:
    ftst    ;compare ST(0) with 0.0
    fstsw ax          ;copy the Status Word containing the result to AX
    fwait             ;insure the previous instruction is completed
    sahf              ;transfer the condition codes to the CPU's flag register
    ja change_drone_position_end
    fldz    ; fld 0
    fstp qword [speed]

    change_drone_position_end:
    popad
    mov esp, ebp
	pop ebp
	ret
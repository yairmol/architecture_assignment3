; scale(loc,a,b) scales ax to range [a,b] and stores it in loc
%macro scale 3
    push eax
	fild dword [esp]    ;load ax
    pop eax
    fld qword %3
    fld qword %2
    fsubp
    fmulp       ; ax * (b-a)
    fild dword [max_int]
    fdivp       ;(ax * (b-a))/(2^16 -1)
    fld qword %2
    faddp        ;(ax * (b-a))/(2^16 -1) +a
    fstp qword [%1]
    ffree
%endmacro

section .data
    seed_1: dw 0xACE1
    seed: dw 0xACE1
    angle_max: dq 60.0
    angle_min: dq -60.0
    speed_max: dq 10.0
    speed_min: dq -10.0
    max_int: dw 65535
    delta_angle: dq 0
    delta_speed: dq 0
    x: dq 0
    y: dq 0
    speed: dq 0
    angle: dq 0

section .text
    global random_generator_1

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

move_drone:     
    push ebp
	mov ebp, esp
	;//sub esp, 4
    pushfd
	pushad
    finit

    call random_generator
    ; push ax
    ; call angle_scale
    scale delta_angle, [angle_min], [angle_max]
    ;add esp, 4
    ;mov [delta_angle], eax               ;putting the random number in delta_angle
    call random_generator
    ; push ax
    ; call speed_scale
    scale delta_speed, [speed_min], [speed_max]
    ;//add esp, 4
    ;//mov [delta_speed], eax     ;putting the random number in speed
    fld qword [angle]   ;load angle
    push dword 180
    fild dword [esp]
    pop eax
    fdivp               ; angle / 180
    fldpi
    fmulp               ; angle * pi / 180
    fcos                ; cosα
    fmul qword [speed]  ; speed * cosα
    fst qword [x]       ; x = speed * cosα
    ;cmp qword [x], 99   ; TODO: change comparison
    jle no_x_wrap
    push dword 100
    fild dword [esp]
    fsubp 
    pop eax
    fst qword [x]
    no_x_wrap:
    ffree
    fld qword [angle]
    push dword 180
    fild dword [esp]
    pop eax
    fdivp               ; angle / 180
    fldpi
    fmulp               ; angle * pi / 180
    fsin                ; sinα
    fmul qword [speed]
    fst qword [y]       ; y = speed * sinα
    ;cmp qword [y], 99   ; TODO: change comparison
    jle no_y_wrap
    push dword 100
    fild dword [esp]
    pop eax
    fsubp
    fst qword [y]
    no_y_wrap:
    ffree
    fld qword [angle]
    fadd qword [delta_angle]    ; angle += ∆α
    fst qword [angle]
    wraparound:       
    ;cmp qword [angle], 360  ; TODO: change comparison
    jle wraparound_end
    push dword 360
    fild dword [esp]
    pop eax
    fsubp
    fst qword [angle]
    jmp wraparound
    wraparound_end:
    ffree
    fld qword [speed]
    fadd qword [delta_speed]    ; speed += delta_speed 
    fst qword [speed]
    ;cmp qword [speed], 100      ; if speed > 100 -> speed = 100 ; TODO: change comparison
    jle change_drone_position_end
    push dword 100
    fild dword [esp]
    pop eax
    fstp qword [speed]

    change_drone_position_end:
    popad
    popfd
    mov esp, ebp
	pop ebp
	ret
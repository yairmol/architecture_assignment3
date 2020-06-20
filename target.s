STKSZ equ 64*4
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

section .data
	global target_cr
	extern curr_drone

	target_cr: dd target_co_routine
	flags_target: dd 0
	sp_target: dd stk_target + STKSZ
	target_x: dq 0.0
	target_y: dq 0.0

	zero: dq 0.0
	hundred: dq 100.0
	max_int: dd 65535

section .bss
	stk_target: resb STKSZ

section .text
    global target_co_routine
    global init_target
    extern random_generator
	extern co_init
	extern resume

target_co_routine:
	; (*) call createTarget() function to create a new target with randon coordinates on the game board
	call createTarget
	; (*) switch to the co-routine of the "current" drone by calling resume(drone id) function
	mov ebx, [curr_drone]
	call resume
	jmp target_co_routine

createTarget:
	pushad
	call random_generator
	scale target_x, zero, hundred
	call random_generator
	scale target_y, hundred, zero
	popad
	ret

init_target:
	pushad
	call createTarget
	mov ebx, target_cr
	call co_init
	popad
	ret



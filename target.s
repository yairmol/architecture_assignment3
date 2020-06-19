STKSZ equ 64*4
; scale(a,b) scales ax to [a,b] range
%macro scale 3
    mov qword [randNum], ax
	fld qword [randNum]    ;load ax
    fmul %2   ; ax * a
    fmul 2     ;ax * (b - a)
    fdiv 65535     ;(ax * (b-a))/(2^16 -1)
    fsub %2     ;(ax * (b-a))/(2^16 -1) +a
    fst qword [%1]
    ffree
%endmacro

section .data
	target_cr: dd target_co_routine
	flags_target: dd 0
	sp_target: dd stk_target + STKSZ
	target_x: dq 0.0
	target_y: dq 0.0

section .bss
	stk_target: resb STKSZ

section .text
    global target_co_routine
    global createTarget
    extern random_generator
	extern co_init

target_co_routine:
; TODO: implement the target co-routine as follows:
; (*) call createTarget() function to create a new target with randon coordinates on the game board
; (*) switch to the co-routine of the "current" drone by calling resume(drone id) function

createTarget:
	pushad
	call random_generator
	scale dword 0, dword 100, target_x
	call random_generator
	scale dword 0, dword 100, target_y
	popad
	ret

init_target:
	pushad
	call createTarget
	mov ebx, target_cr
	call co_init
	popad
	ret



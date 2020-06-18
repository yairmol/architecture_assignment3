section .data
	target_cr: dd target_co_routine
	flags_target: dd 0
	sp_target: dd stk_target + STKSZ
	target_x: dq 0.0
	target_y: dq 0.0

section .text
    extern random_generator
    global target_co_routine
    global init_target

target_co_routine:
; TODO: implement the target co-routine as follows:
; (*) call createTarget() function to create a new target with randon coordinates on the game board
; (*) switch to the co-routine of the "current" drone by calling resume(drone id) function

createTarget:
; (*) calculate a random x coordinate
; (*) calculate a random y coordinate

init_target:


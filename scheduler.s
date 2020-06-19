section .rodata
    decimal_string_format: db "stack pointer: %p", 10, 0
section .text
    global scheduler_co_routine
    extern printf
    extern main_cr
    extern resume

scheduler_co_routine:
push esp
push decimal_string_format
call printf
add esp, 8
mov ebx, main_cr
call resume
; TODO: implement the scheduler co-routine as follows:
; (*) start from i=1
; (*)if drone i%N is active
;     (*) switch to the i’s drone co-routine
; (*) i++
; (*) if i%K == 0 //time to print the game board
;     (*) switch to the printer co-routine
; (*) if (i/N)%R == 0 && i>0 //R rounds have passed
;     (*) find M - the lowest number of targets destroyed, between all of the active drones
;     (*) "turn off" one of the drones that destroyed only M targets.
; (*) if only one active drone is left
;     (*)print The Winner is drone: <id of the drone>
;     (*) stop the game (return to main() function or exit)
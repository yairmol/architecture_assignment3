section .text
    extern random_generator
target_co_routine:
; TODO: implement the target co-routine as follows:
; (*) call createTarget() function to create a new target with randon coordinates on the game board
; (*) switch to the co-routine of the "current" drone by calling resume(drone id) function

createTarget:
; (*) calculate a random x coordinate
; (*) calculate a random y coordinate
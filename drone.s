section .text
    global drone_init
    global drone_resume
    extern random_generator

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

drone_init:
; TODO: implement drone-co-routine initialization

drone_resume:
; TODO: implement drone-co-routine resume
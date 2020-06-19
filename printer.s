section .data
    extern drones_array

section .text
    global printer_co_routine
printer_co_routine:
; TODO: implement the printer co-routine
; format:
; x,y	                               ; this is the current target coordinates
; 1,x_1,y_1,α_1,speed_1,numOfDestroyedTargets_1    ; the first field is the drone id
; 2,x_2,y_2,α_2,speed_2,numOfDestroyedTargets_2    ; the fifth field is the number of targets destroyed by the drone
; …
; N,x_N,y_N,α_N,speed_N,numOfDestroyedTargets_N
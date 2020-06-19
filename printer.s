XP      equ 12
YP      equ 20
ANGLEP  equ 28
SPEEDP  equ 36
SCOREP  equ 44

%macro push_double 1
    fld %1
    sub esp, 8
    fstp qword [esp]
%endmacro
section .rodata
    target_format: db "%.2f,%.2f",10,0
    drone_format: db "%d,%.2f,%.2f,%.2f,%.2f,%d",10,0
section .data
    extern target_cr
    extern drones_array
    extern N
    extern scheduler_cr

section .text
    global printer_co_routine
    extern printf

printer_co_routine:
; TODO: implement the printer co-routine
; format:
; x,y	                               ; this is the current target coordinates
; 1,x_1,y_1,α_1,speed_1,numOfDestroyedTargets_1    ; the first field is the drone id
; 2,x_2,y_2,α_2,speed_2,numOfDestroyedTargets_2    ; the fifth field is the number of targets destroyed by the drone
; …
; N,x_N,y_N,α_N,speed_N,numOfDestroyedTargets_N

    push_double [target_cr + YP]
    push_double [target_cr + XP]
    push target_format
    call printf
    add esp, 20
    mov ecx, 0
    print_board_for_start:
    cmp ecx, [N]
    je print_board_for_end
    mov ebx, [drones_array + ecx*4]
    push ecx                    ; save ecx in case printf overrides it
    push dword [ebx + SCOREP]   ; push arguments
    push_double [ebx + SPEEDP]
    push_double [ebx + ANGLEP]
    push_double [ebx + YP]
    push_double [ebx + XP]
    push ecx + 1                ; TODO: check if this is valid command
    push drone_format
    call printf                 ; printf(drone_format, drone.x, drone.y, drone.angle, drone.speed, drone.scorep)
    add esp, 40
    pop ecx                     ; restore ecx
    inc ecx
    jmp print_board_for_start
    print_board_for_end:
    mov ebx, scheduler_cr
    call resume                 ; switch back to the scheduler co-routine
    jmp printer_co_routine
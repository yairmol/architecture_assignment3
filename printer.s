XP      equ 12
YP      equ 20
ANGLEP  equ 28
SPEEDP  equ 36
SCOREP  equ 44

%macro push_double 1
    fld qword %1
    sub esp, 8
    fstp qword [esp]
%endmacro

%macro print_int 1
    pushad
    push dword %1
    push decimal_format
    call printf
    add esp, 8
    popad
%endmacro
section .rodata
    target_format: db "%.2f, %.2f",10,0
    drone_format: db "%d, %.2f, %.2f, %.2f, %.2f, %d",10,0
    decimal_format: db "printer dec: %d",10,0
section .data
    extern target_cr
    extern drones_array
    extern N
    extern scheduler_cr
    extern resume

section .text
    global printer_co_routine
    extern printf

printer_co_routine:
    push_double [target_cr + YP]
    push_double [target_cr + XP]
    push target_format
    call printf
    add esp, 20
    mov ecx, 0
    print_board_for_start:
    cmp ecx, [N]
    jge print_board_for_end
    mov ebx, [drones_array + ecx*4]
    push ecx
    push dword [ebx + SCOREP]   ; push arguments
    push_double [ebx + SPEEDP]
    push_double [ebx + ANGLEP]
    push_double [ebx + YP]
    push_double [ebx + XP]
    inc ecx
    push ecx                    ; TODO: check if this is valid command
    dec ecx
    push drone_format
    call printf                 ; printf(drone_format, drone.x, drone.y, drone.angle, drone.speed, drone.scorep)
    add esp, 44
    pop ecx
    inc ecx
    jmp print_board_for_start
    print_board_for_end:
    mov ebx, scheduler_cr
    call resume                 ; switch back to the scheduler co-routine
    jmp printer_co_routine
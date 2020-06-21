;define
CRSZ    equ 48     ; co routine struct size is 12 
STKSZ 	equ 16*1024
CODEP 	equ 0
FLAGSP 	equ 4
SPP 	equ 8
XP      equ 12
YP      equ 20
ANGLEP  equ 28
SPEEDP  equ 36
SCOREP  equ 44

%macro print 2
    pushad
    push dword %2
    push dword %1
    call printf
    add esp, 8
    popad
%endmacro

section .rodata
    decimal_string_format2: db "drone destroyed: %d", 10, 0
    decimal_string_format: db "debug: %d", 10, 0
    winner_string_format: db "The Winner is drone: %d", 10, 0
    decimal_k_format: db "K: %d",10,0
    current_drone_string_format: db "current drone: %d",10,0
section .text
    global scheduler_co_routine
    extern printf
    extern main_cr
    extern resume

section .data
    global curr_drone
    extern N
    extern K
    extern R
    extern drones_array
    extern printer_cr

    curr_drone: dd 0

scheduler_co_routine:
    sub esp, 8
    mov edi, 0  ;edi = i
    mov ecx, [N]
    mov [ebp - 4], ecx  ;   [ebp - 4] -> active drones
    scheduler_start:
    mov eax, edi
    mov edx, 0
    mov ecx, [N]
    div ecx
    mov ecx, edx    ;ecx = i % N
    ;check if a drone is active
    ;inc ecx ;ecx = (i % N) + 1
    ;print current_drone_string_format, ecx
    mov edx, [drones_array]
    mov ebx, [edx + 4 * ecx]  ;i's drone co-routine
    mov [curr_drone], ebx
    bt dword [ebx + FLAGSP], 2    ;if a drone is active
    jc no_active
    call resume
    no_active:
    mov eax, edi
    mov edx, 0
    mov ecx, [K]
    div ecx
    mov ecx, edx    ;ecx = i % K
    cmp ecx, 0
    jne no_print
    mov ebx, printer_cr  ;printer's co-routine
    call resume
    no_print:
    ;check if (i/N)%R == 0
    mov eax, edi    ;eax = i 
    mov ecx, [N]
    mov edx, 0
    div ecx     ;eax = i/N
    mov edx, 0  ;check if its correct
    mov ecx, [R]
    div ecx
    mov ecx, edx    ;ecx = (i/N)%R
    cmp ecx, 0
    jne no_destroy
    ;check if i%N ==0
    mov eax, edi    ;eax = i
    mov ecx, [N]
    mov edx, 0
    div ecx
    mov ecx, edx    ; ecx = i % N
    cmp ecx, 0
    jne no_destroy
    cmp edi, 0
    je no_destroy
    ;destroy
    mov esi, 0  ; esi = 0
    mov eax, 0  ; eax = drone with the lowest score
    mov ecx, 0xFFFFFF  ;ecx = score
    check_scores:
    cmp esi, dword [N]  
    je check_scores_end
    mov edx, [drones_array]
    mov ebx, [edx + 4 * esi]
    bt dword [ebx + FLAGSP], 2    ;is the drone active?
    jc next_drone_score     ;if the drone is not active
    cmp ecx, dword [ebx + SCOREP]    ;if(drone_i->score < ecx)
    jle next_drone_score
    mov ecx, dword [ebx + SCOREP]  ;ecx = drone i score
    mov eax, esi
    next_drone_score:
    inc esi
    jmp check_scores
    check_scores_end:   ;eax has the index of the drone with the lowest score
    mov edx, [drones_array]
    mov ebx, [edx + 4 * eax]   ;go to the drone with the lowest score
    bts dword [ebx + FLAGSP], 2   ;destroy the drone
    ; mov ecx, [ebp - 4]
    ; dec ecx
    ; mov [ebp - 4], ecx  ; active_drones-- 
    dec dword [ebp - 4] ;active--
    no_destroy:
    inc edi     ;i++
    mov ecx, [ebp -4]   ;check how many drones are left
    cmp ecx, 1  ;if there are more than 1 active drone
    jg scheduler_start
    ;TODO: loop all drones check which one is active and put his index in ecx
    mov esi, 0  ; esi = 0
    check_active_drone:
    mov edx, [drones_array]
    mov ebx, [edx + 4 * esi]  
    bt dword [ebx + FLAGSP], 2    ;is the drone active?
    jnc check_active_drone_end  ;if the drone is active
    print decimal_string_format, esi
    inc esi
    jmp check_active_drone
    check_active_drone_end:
    inc esi
    push esi
    push winner_string_format
    call printf
    add esp, 8
    mov ebx, main_cr  ;resume main
    call resume
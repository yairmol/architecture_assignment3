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

section .rodata
    decimal_string_format: db "stack pointer: %p", 10, 0
    winner_string_format: db "The Winner is drone: %d", 10, 0
section .text
    global scheduler_co_routine
    extern printf
    extern main_cr
    extern resume

section .data
    extern N
    extern K
    extern R
    extern drones_array

scheduler_co_routine:

    finit
    sub esp, 8

    ; push esp
    ; push decimal_string_format
    ; call printf
    ; add esp, 8
    ; mov ebx, main_cr
    ; call resume

    scheduler_start:
    mov ecx, [N]
    mov [ebp - 4], ecx  ;   [ebp - 4] -> active drones

    mov edi, 0
    mov edi, 1  ;edi = i
    mov eax, 0
    mov eax, [N]
    div edi
    mov ecx, edx    ;ecx = i % N
    ;TODO check if a drone is active
    dec ecx
    mov ebx, [drones_array + 4 * ecx]  ;i's drone co-routine
    bt dword [ebx + FLAGSP], 2    ;if a drone is active
    jc no_active
    call resume
    no_active:
    inc edi     ;i++
    mov eax, [K]
    div edi
    mov ecx, edx    ;ecx = i % K
    cmp ecx, 0
    jne no_print
    mov ebx, 0  ;printer's co-routine
    call resume
    no_print:
    mov eax, edi    ;eax = i
    mov ecx, 0 
    mov ecx, [N]
    div ecx     ;eax = i/N
    mov ecx, 0 
    mov ecx, [R]
    div ecx
    mov ecx, edx    ;ecx = (i/N)%R
    cmp ecx, 0
    jne no_destroy
    ;//TODO: destroy
    mov esi, 0  ; esi = 0
    mov eax, 0  ; eax = drone with the lowest score
    mov ecx, 0xFFFFFFFF  ;ecx = score
    check_scores:
    cmp esi, dword [N]  
    je check_scores_end
    mov ebx, [drones_array + 4 * esi]
    bt dword [ebx + FLAGSP], 2    ;is the drone active?
    jc next_drone_score     ;if the drone is not active
    cmp ecx, dword [ebx + SCOREP]    ;if(drone_i->score < ecx)
    jle next_drone_score
    mov ecx, [ebx + SCOREP]  ;ecx = drone i score
    mov eax, esi
    next_drone_score:
    inc esi
    jmp check_scores
    check_scores_end:   ;eax has the index of the drone with the lowest score
    mov ebx, [drones_array + 4 * eax]
    bts dword [ebx + FLAGSP], 2   ;destroy the drone
    mov ecx, [ebp - 4]
    dec ecx
    mov [ebp - 4], ecx  ; active_drones-- 
    no_destroy:
    mov ecx, [ebp -4]
    cmp ecx, 1
    jg scheduler_start
    ;TODO: loop all drones check which one is active and put his index in ecx
    mov esi, 0  ; esi = 0
    check_active_drone:
    mov ebx, [drones_array + 4 * esi]  
    bt dword [ebx + FLAGSP], 2    ;is the drone active?
    jnc check_active_drone_end  ;if the drone is active
    inc esi
    jmp check_active_drone
    check_active_drone_end:
    inc esi
    push esi
    push winner_string_format
    call printf
    add esp, 8
    mov ebx, 0  ;resume main
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
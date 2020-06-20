;define
FLAGSP 	equ 4

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
    extern drones_array

scheduler_co_routine:

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
    bt [ebx + FLAGSP], 2
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
    mov ecx, [ebp - 4]
    dec ecx
    mov [ebp - 4], ecx  ; active_drones-- 
    no_destroy:
    mov ecx, [ebp -4]
    cmp ecx, 1
    jg scheduler_start
    ;TODO: loop all drones check which one is active and put his index in ecx
    push ecx
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
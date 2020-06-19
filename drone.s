; scale(a,b) scales ax to [a,b] range
%macro scale 2
    mov qword [randNum], ax
	fld qword [randNum]    ;load ax
    fmul %2   ; ax * a
    fmul 2     ;ax * (b - a)
    fdiv 65535     ;(ax * (b-a))/(2^16 -1)
    fsub %2     ;(ax * (b-a))/(2^16 -1) +a
    fst qword [%1]
    ffree
%endmacro

; struct co-routine {
;   void* codep
;   int flags
;   void* stp
; }

; struct drone-co-routine {
;	void* codep;	the pointer to the next line of code to execute
;	int flags;		flags
;	void* sp;		stack pointer for the drone co-routine
;	double x;		drone's x coordinate
;	double y;		drone's y coordinate
;	double angle;	drone's angle from the x axix in degrees [0, 360] (heading)
;	double speed; 	drone's speed
;   int score;
; }
; struct size: 48

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
    float_string_format: db "%lf", 10, 0
    decimal_string_format: db "%d", 10, 0

section .data
    extern drones_array
    extern scheduler_cr
    ; variables to hold the co-routine state
    x:              dq 0
    y:              dq 0
    angle:          dq 0
    delta_angle:    dq 0
    speed:          dq 0
    delta_speed:    dq 0
    score:          dd 0
    randNum:        dq 0

section .text
    global drone_init
    global drone_resume
    global change_drone_position
    extern random_generator
    extern malloc
    extern printf
    extern co_init

change_drone_position:      
    push ebp
	mov ebp, esp
	;//sub esp, 4
    pushfd
	pushad
    finit

    call random_generator
    ; push ax
    ; call angle_scale
    scale delta_angle, 60
    ;add esp, 4
    ;mov [delta_angle], eax               ;putting the random number in delta_angle
    call random_generator
    ; push ax
    ; call speed_scale
    scale delta_speed, 10
    ;//add esp, 4
    ;//mov [delta_speed], eax     ;putting the random number in speed
    fld qword [angle]   ;load angle
    fldpi
    fdiv 180
    fmulp           ;angle * pi / 180
    fcos                ;cosα
    fmul qword [speed] ;speed * cosα
    fst qword [x]   ;x = speed * cosα
    cmp qword [x], 99
    jle no_x_wrap
    fsub 100
    fst qword [x]
    no_x_wrap:
    ffree
    fld qword [angle]
    fldpi
    fdiv 180
    fmulp           ;angle * pi / 180
    fsin
    fmul qword [speed]
    fst qword [y]   ;y = speed * sinα
    cmp qword [y], 99
    jle no_y_wrap
    fsub 100
    fst qword [y]
    no_y_wrap:
    ffree
    fld qword [angle]
    fadd qword [delta_angle]   ;angle += ∆α
    fst qword [angle]
    wraparound:       ;
    cmp qword [angle], 360
    jle wraparound_end
    fsub 360
    fst qword [angle]
    jmp wraparound
    wraparound_end:
    ffree
    fld qword [speed]
    fadd qword [delta_speed]    ;speed += delta_speed 
    fst qword [speed]
    cmp qword [speed], 100      ;if speed > 100 -> speed = 100
    jle change_drone_position_end
    mov qword [speed], 100

    change_drone_position_end:
    popad
    popfd
    mov esp, ebp
	pop ebp
	ret



drone_co_routine:
    push ebp
	mov ebp, esp
	;//sub esp, 4
    pushfd
	pushad
    finit
    call change_drone_position

    ; call random_generator
    ; ; push ax
    ; ; call angle_scale
    ; scale delta_angle, 60
    ; add esp, 4
    ; //mov [delta_angle], eax               ;putting the random number in angle
    ; call random_generator
    ; ; push ax
    ; ; call speed_scale
    ; scale delta_speed, 10
    ; add esp, 4
    ; //mov [delta_speed], eax     ;putting the random number in speed
    ; fld qword [angle]   ;load angle
    ; fldpi
    ; fdiv 180
    ; fmulp           ;angle * pi / 180
    ; fcos                ;cosα
    ; fmul qword [speed] ;speed * cosα
    ; fst qword [x]   ;x = speed * cosα
    ; cmp qword [x], 99
    ; jle no_x_wrap
    ; fsub 100
    ; fst qword [x]
    ; no_x_wrap:
    ; ffree
    ; fld qword [angle]
    ; fldpi
    ; fdiv 180
    ; fmulp           ;angle * pi / 180
    ; fsin
    ; fmul qword [speed]
    ; fst qword [y]   ;y = speed * sinα
    ; cmp qword [y], 99
    ; jle no_y_wrap
    ; fsub 100
    ; fst qword [y]
    ; no_y_wrap:
    ; ffree
    ; fld qword [angle]
    ; fadd qword [delta_angle]   ;angle += ∆α
    ; fst qword [angle]
    ; wraparound:       ;
    ; cmp qword [angle], 360
    ; jle wraparound_end
    ; fsub 360
    ; fst qword [angle]
    ; jmp wraparound
    ; wraparound_end:
    ; ffree
    ; fld qword [speed]
    ; fadd qword [delta_speed]    ;speed += delta_speed 
    ; fst qword [speed]
    ; cmp qword [speed], 100      ;if speed > 100 -> speed = 100
    ; jle drone_while_start
    ; mov qword [speed], 100

    drone_while_start:
    push qword [x]
    push qword [y]
    call mayDestroy     ;call mayDestroy with x and y
    add esp, 16
    cmp eax, 0
    je drone_while_end:
    inc dword [score]
    mov ebx, scheduler_cr
    call resume
    call change_drone_position

    jmp drone_while_start
    drone_while_end:
    mov ebx, sche ;TODO: go to scheduler co routine
    call resume

    popad
    popfd
    mov esp, ebp
	pop ebp
	ret

    


    
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

; angle_scale:
;     push ebp
; 	mov ebp, esp
;     pushfd
; 	pushad
;     finit
;     fld qword [ebp + 8]     ;load ax
;     fmul 120   ; ax * 120
;     fdiv 65535     ;(ax * 120)/(2^16 -1)
;     fsub 60     ;(ax * 120)/(2^16 -1) -60
;     fst qword [delta_angle]
;     ffree
;     popad
;     popfd
;     mov esp, ebp
; 	pop ebp
; 	ret

; speed_scale:
;     push ebp
; 	mov ebp, esp
; 	pushfd
;     pushad

;     finit
;     fld qword [ebp + 8]     ;load ax
;     fmul 20   ; ax * 20
;     fdiv 65535     ;(ax * 20)/(2^16 -1)
;     fsub 10     ;(ax * 120)/(2^16 -1) -10
;     fst qword [delta_speed]
;     ffree

;     popad
;     popfd
;     mov esp, ebp
; 	pop ebp
; 	ret



; assume ebx holds the id of the drone
drone_init:
    ; init the drone co-routne struct
	pushad
    push ebx
    push dword CRSZ
    call malloc                 ; malloc(CRSZ) allocate a co-routine struct 
    add esp, 4
    pop ebx
    mov [drones_array + ebx*4], eax ; store the pointer to the co-routine in the drones co-routine array
    mov ebx, eax                ; ebx now points to the co-routine struct
    mov dword [ebx + CODEP], drone_co_routine
    mov dword [ebx + FLAGSP], 0
    push ebx
    push STKSZ
    call malloc                 ; malloc(STKSZ) allocate a stack for this co-routine
    add esp, 4
    pop ebx
    mov [ebx + SPP], eax        ; set co-routine stack pointer
    add dword [ebx + SPP], STKSZ; set stack pointer to top of the stack

    ; generate random initial properties
    call random_generator       ; generate initial x coordinate
    scale dword 0, dword 100, ebx + XP
    call random_generator       ; generate initial y coordinate
    scale dword 0, dword 100, ebx + YP
    call random_generator       ; generate initial angle
    scale dword 0, dword 100, ebx + SPEEDP
    call random_generator       ; generate initial speed
    scale dword 0, dword 360, ebx + ANGLEP
    ; push eax
    ; push decimal_string_format
    ; call printf
    ; add esp, 8

    ; print the generated values just to see that ecerything is ok
    push ebx
    fld qword[ebx + XP]
	sub esp,8
	fstp qword[esp]
	push float_string_format
	call printf
	add esp, 12
    fld qword[ebx + YP]
	sub esp,8
	fstp qword[esp]
	push float_string_format
	call printf
	add esp, 12
    fld qword[ebx + ANGLEP]
	sub esp,8
	fstp qword[esp]
	push float_string_format
	call printf
	add esp, 12
    fld qword[ebx + SPEEDP]
	sub esp,8
	fstp qword[esp]
	push float_string_format
	call printf
	add esp, 12
    pop ebx

    ; init the co-routine
    call co_init
	popad
	ret

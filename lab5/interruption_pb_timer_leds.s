.equ   RED_LEDS, 0x10000000
.equ GREEN_LEDS, 0x10000010
.equ   SWITCHES, 0x10000040
.equ         PB, 0x10000050
.equ      TIMER, 0x10002000

.equ ITR_PB,    0b10    # interuption pushbutton
.equ ITR_TIMER, 0b1     # interuption timmer

.equ PB_FIRST, 0b1
.equ RED_SWITCHES_07, 0xFF
.equ GREEN_SWITCHES_01, 0x1

.org 0x20
RTI:
   addi sp, sp, -12
   stw  ra, 8(sp)
   stw  r9, 4(sp)
   stw  r11, 0(sp)

   # descobrir quem gerou a exceção
   rdctl et, ipending
   beq   et, r0, SW_EXCEPTION

    HW_EXCEPTION:
        # sei que foi um HW que gerou a interrupção
        addi  ea, ea, -4         # qdo é interrupção (HW), preciso subtrair 4

        # preciso saber qual IRQ foi acionada
        TESTA_PB:
            movi  r9, ITR_PB           # máscara do IRQ1 (pushbutton)
            bne   et, r9, TESTA_TIMER  # caso não seja PB, saio da RTI
            call  TRATA_PB
            br  FIM_RTI

        TESTA_TIMER:   
            movi  r9, ITR_TIMER    # máscara do IRQ0 (timer)
            bne   et, r9, FIM_RTI  # caso não seja PB, saio da RTI
            call TRATA_TIMER
            br  FIM_RTI

    SW_EXCEPTION:

FIM_RTI:

   ldw  ra, 8(sp)
   ldw  r9, 4(sp)
   ldw  r11, 0(sp)
   addi sp, sp, 12

  eret
#

TRATA_PB:
    addi sp, sp, -16
    stw  ra, 12(sp)
    stw r12, 8(sp)
    stw r11, 4(sp)
    stw  r9, 0(sp)
    # TRATA O PB

    call LOAD_LEDS_FROM_SWITCH

    movia  r9, PB
    movi  r11, 0b1000
    stwio r11, 0xC(r9)		# resetando o botão 3

    ldw  ra, 12(sp)
    ldw r12, 8(sp)
    ldw r11, 4(sp)
    ldw  r9, 0(sp)
    addi sp, sp, 16
    ret
#

TRATA_TIMER:
    addi    sp, sp, -12
    stw     ra,  0(sp)
    stw     r9,  4(sp)
    stw     r11, 8(sp)

    movia   r9, TIMER
    movi    r11, ITR_TIMER
    stwio   r11, 0(r9)		# resetando o timer

    call UPDATE_GREEN_LED


    ldw     ra,  0(sp)
    ldw     r9,  4(sp)
    ldw     r11, 8(sp)
    addi    sp, sp, 12
    
    ret
#

.equ STACK, 0x1000

.global _start
_start:   
    movia  sp, STACK     # inicializo a pilha

    movi r4, 0b1000
    call LOAD_PB_INTERRUPTION

    movi r4, 1
    call LOAD_TIMER_INTERRUPTION

    call INITIALIZE_LOADED_INTERRUPTIONS

    call START_LISTENING_INTERRUPTIONS 

END:
  br END

START_LISTENING_INTERRUPTIONS:
    movi  r10, 1
    wrctl status, r10	# habilita interrupção no processador (PIE)
    
ret

# r4 -> the seconds to await ("integer")
LOAD_TIMER_INTERRUPTION:
    addi  sp, sp, -12
    stw   r9, 0(sp)
    stw  r10, 4(sp)
    stw  r11, 8(sp)

    # configura TIMER para gerar interrupções de r4 em r4 segundos
    movia r9, 50000000
    mul  r10, r9, r4    # r4 segundos

    movia  r9, TIMER
    andi   r11, r10, 0xFFFF
    stwio  r11, 8(r9)		# parte baixa do contador

    srli   r11, r10, 16      # parte alta do contador
    stwio  r11, 12(r9)

    # habilitar temporizador
    movi   r10, 0b111      # START | CONT | ITO
    stwio  r10, 4(r9)

    movia  r9, ENABLED_INTERRUPTIONS
    ldw    r9, (r9)
    movi  r10, 0b1
    or    r10, r10, r9

    movia  r9, ENABLED_INTERRUPTIONS
    stw    r10, (r9)  # CARREGA interrupção da IRQ 0 (timer)

    ldw   r9, 0(sp)
    ldw  r10, 4(sp)
    ldw  r11, 8(sp)
    addi sp, sp, 12

ret

# r4 -> the button to initialize
LOAD_PB_INTERRUPTION:
    addi sp, sp, -8
    stw   r9, 4(sp)
    stw  r10, 0(sp)

    movia  r9, PB		# endereço do pushbutton   

    mov  r10, r4 
    stwio r10, 8(r9)		# habilita interrupção do botão

    movia  r9, ENABLED_INTERRUPTIONS
    ldw    r9, (r9)
    movi  r10, ITR_PB
    or    r10, r10, r9

    movia  r9, ENABLED_INTERRUPTIONS
    stw    r10, (r9)

    # wrctl ienable, r10   # CARREGA interrupção da IRQ 1 - Push button 0b10

    ldw  r9,  4(sp)
    ldw  r10, 0(sp)
    addi sp, sp, 8

ret

INITIALIZE_LOADED_INTERRUPTIONS:
    addi sp, sp, -4
    stw  r9, 0(sp)

    movia  r9, ENABLED_INTERRUPTIONS
    ldw    r9, (r9)

    wrctl ienable, r9

    ldw  r9, 0(sp)
    addi sp, sp, 4
ret

LOAD_LEDS_FROM_SWITCH:
	addi sp, sp, -24
	stw   r2, 20(sp)
	stw   ra, 16(sp)
	stw  r18, 12(sp)
	stw  r17, 8(sp)
	stw  r16, 4(sp)
	stw   r4, 0(sp)

	movia r16, SWITCHES

	ldwio r4, 0(r16)
	andi  r4, r4, RED_SWITCHES_07

	call CALCULATE_SWITCH_SUM

	movia r16, SUM
	ldw   r18, (r16)

	add r18, r18, r2
	stw r18, (r16)		# update the sum

	movia r17, RED_LEDS
	stwio r18, 0(r17)

	ldw   r2, 20(sp)
	ldw   ra, 16(sp)
	ldw  r18, 12(sp)
	ldw  r17, 8(sp)
	ldw  r16, 4(sp)
	ldw   r4, 0(sp)
	addi sp, sp, 24

ret

CALCULATE_SWITCH_SUM:
	/* 
		r4  - switch value (after mask)
		
		r16 - value
		r17 - counter
		r18  - sum
		
		r19 - less significative bit
	*/

	addi sp, sp, -20
	stw   ra, 16(sp)
	stw  r19, 12(sp)
	stw  r18,  8(sp)
	stw  r17,  4(sp)
	stw  r16,  0(sp)
	
	mov r16, r4 # initialize the value
	mov r17, r0 # initialize the counter
	mov r18, r0 # initialize the sum
	
	br VALIDATE_IF_ALL_ZEROS
	
	BODY:
		andi r19, r16, 0x1
		beq  r19, r0, PREPARE_NEXT_ITERATION
		
		add r18, r18, r17	
		# if not zero, the switch is clicked in the position (counter)
		
		PREPARE_NEXT_ITERATION:
			addi r17, r17, 1
			srli r16, r16, 1

	VALIDATE_IF_ALL_ZEROS:
		bne r16, r0, BODY

	mov r2, r18
	
	ldw   ra, 16(sp)
	ldw  r19, 12(sp)
	ldw  r18,  8(sp)
	ldw  r17,  4(sp)
	ldw  r16,  0(sp)
	addi sp, sp, 20

ret

UPDATE_GREEN_LED:
    addi    sp, sp, -12
	stw     ra, 0(sp)
	stw     r2, 4(sp)
	stw     r9, 8(sp)

    call    TOGGLE_GREEN_LED_STATE
    
    movia   r9, GREEN_LEDS
	stwio   r2, (r9)

    ldw     ra, 0(sp)
	ldw     r2, 4(sp)
	ldw     r9, 8(sp)
	addi    sp, sp, 12

ret 

# returns the new state
TOGGLE_GREEN_LED_STATE:
    addi  sp, sp, -12
	stw   ra, 0(sp)
	stw   r9, 4(sp)
	stw  r10, 8(sp)

    movia   r9, GREEN_LED_STATE
    ldw     r10, (r9) 

    xori    r10, r10, 1 # toggle r9
    stw     r10, (r9)

    mov     r2, r10

	ldw   ra, 0(sp)
	ldw   r9, 4(sp)
	ldw  r10, 8(sp)
	addi sp, sp, 12

ret 

GREEN_LED_STATE:
.word 0

SUM:
.word 0

ENABLED_INTERRUPTIONS:
.word 0
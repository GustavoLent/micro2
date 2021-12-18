.equ PB, 0x10000050
.equ HEX0_3, 0x10000020
.equ TIMER, 0x10002000

.equ ITR_PB,    0b10
.equ ITR_TIMER, 0b1

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
   addi sp, sp, -12
   stw  r12, 8(sp)
   stw  r9, 4(sp)
   stw  r11, 0(sp)
  # TRATA O PB
  
  
   movia r9, PB
   movi r11, 0b1000
   stwio r11, 0xC(r9)		# resetando o botão 3
   
  # Logica para deslocar segmentos display 7seg      
   movia r12, HEX0_3

   movia r9, STATUS
   ldw   r11, (r9)

   stwio r11, (r12)
 
   roli  r11, r11, 1 
   stw   r11, (r9)
   
   ldw  r12, 8(sp)
   ldw  r9, 4(sp)
   ldw  r11, 0(sp)
   addi sp, sp, 12
   ret
#

TRATA_TIMER:
    addi sp, sp, -12
    stw  r12, 8(sp)
    stw  r9, 4(sp)
    stw  r11, 0(sp)

    movia r9, TIMER
    movi r11, ITR_TIMER
    stwio r11, 0(r9)		# resetando o timer

    # Logica para deslocar segmentos display 7seg      
    movia r12, HEX0_3

    movia r9, STATUS
    ldw   r11, (r9)

    stwio r11, (r12)

    roli  r11, r11, 1 
    stw   r11, (r9)   


    ldw  r12, 8(sp)
    ldw  r9, 4(sp)
    ldw  r11, 0(sp)
    addi sp, sp, 12
    
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
#

# r4 -> the seconds to await ("integer")
LOAD_TIMER_INTERRUPTION:
    addi sp, sp, -12
    stw  r9,  0(sp)
    stw  r10, 4(sp)
    stw  r11, 8(sp)

    # configura TIMER para gerar interrupções de 2 em 2 segundos
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

    ldw  r9,  0(sp)
    ldw  r10, 4(sp)
    ldw  r11, 8(sp)
    addi sp, sp, 12

    ret
#

# r4 -> the button to initialize
LOAD_PB_INTERRUPTION:
    addi sp, sp, -8
    stw  r9, 4(sp)
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

    ldw  r9, 4(sp)
    ldw  r10, 0(sp)
    addi sp, sp, 8

    ret
#

INITIALIZE_LOADED_INTERRUPTIONS:
    addi sp, sp, -4
    stw  r9, 0(sp)

    movia  r9, ENABLED_INTERRUPTIONS
    ldw    r9, (r9)

    wrctl ienable, r9

    ldw  r9, 0(sp)
    addi sp, sp, 4

    ret
#

STATUS:  
.word 1  

ENABLED_INTERRUPTIONS:  
.word 0  


	

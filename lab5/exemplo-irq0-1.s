/*

 Aula passada: polling - desvantagem: sub-utiliza o processador
     
   
   Técnica nova (em substituição ao polling): Interrupção
   
   
   Interrupção - implementada em HW
   
     - quando o dispositivo está pronto, é gerada a interrupção
     - ações realizadas pelo processador:
	 1) ele para o que está fazendo e salta para um endereço pré-definido
	     No Nios2, este endereço é o 0x20 - PC é salvo (contexto)
     2) a RTI (Rotina de Tratamento de Interrupção), escrita pelo programador,
	    é executada - (sempre termina com uma instrução eret)
	 3) o fluxo de execução retorna para a instrução que foi interrompida

   
   Do ponto de vista de programação:
   
    1) código principal "_start"
	  -> basicamente o que vimos até hoje na disciplina
	  
	2) RTI - no endereço 0x20
	  -> código que vai tratar as interrupções

*/


.equ PB, 0x10000050
.equ HEX0_3, 0x10000020
.equ TIMER, 0x10002000


#
# RTI - é chamada não só em interrupção de HW, mas também em exceções de SW
#
.org 0x20
# Código da RTI

   addi sp, sp, -12
   stw  ra, 8(sp)
   stw  r9, 4(sp)
   stw  r11, 0(sp)

   # descobrir quem gerou a exceção
   rdctl et, ipending
   beq   et, r0, SW_EXCEPTION
   
   addi  ea, ea, -4         # qdo é interrupção (HW), preciso subtrair 4
   
   # sei que foi um HW que gerou a interrupção
   # preciso saber qual IRQ foi acionada
   movi  r9, 0b10    # máscara do IRQ1 (pushbutton)
   bne   et, r9, TESTA_TIMER  # caso não seja PB, saio da RTI

   call  TRATA_PB
   
   br  FIM_RTI
   
TESTA_TIMER:   
   movi  r9, 0b1    # máscara do IRQ0 (timer)
   bne   et, r9, FIM_RTI  # caso não seja PB, saio da RTI

   call TRATA_TIMER

SW_EXCEPTION:

FIM_RTI:

   ldw  ra, 8(sp)
   ldw  r9, 4(sp)
   ldw  r11, 0(sp)
   addi sp, sp, 12

  eret



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


TRATA_TIMER:
   addi sp, sp, -12
   stw  r12, 8(sp)
   stw  r9, 4(sp)
   stw  r11, 0(sp)
   
   
   movia r9, TIMER
   movi r11, 0b1
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



.equ STACK, 0x1000


# Código principal
.global _start
_start:
   ###movi r13, 1
   
   movia  sp, STACK     # inicializo a pilha
   movia  r9, PB		# endereço do pushbutton   

   # Habilitar interrupções

   # status
   #  bit 0 -> bit PIE - Processor Interrupt Enable

   # todos os dispositivos que geram interrupção tem atribuído um IRQ
   # (Interrupt Request) pelo projetista
   # ienable
   #   registrador de 31 bits, onde cada bit diz se a interrupção da
   #   respectiva IRQ está habilitada ou não

   # ipending
       # registra qual a IRQ do dispositivo que gerou a interrupção
   
   movi  r10, 0b1000 
   stwio r10, 8(r9)		# habilita interrupção do botão 3
   
   # configura TIMER para gerar interrupções de 2 em 2 segundos
   movia  r10, 50000000*2    #2 segundos
   
   movia  r9, TIMER
   andi   r11, r10, 0xFFFF
   stwio  r11, 8(r9)		# parte baixa do contador
   
   srli   r11, r10, 16      # parte alta do contador
   stwio  r11, 12(r9)
   
   # habilitar temporizador
   movi   r10, 0b111      # START | CONT | ITO
   stwio  r10, 4(r9)
   
   
   movi  r10, 0b11
   wrctl ienable, r10   # habilita interrupção da IRQ 1 (Push button) e IRQ 0 (timer)
   
   movi  r10, 0b1
   wrctl status, r10	# habilita interrupção no processador (PIE)
   
   

   
   
   
   
   
   
# polling -> perguntar se o botão 3 foi pressionado

/*
POLLING:
   ldwio r8, 0xC(r9)        # acessa EDGECAPTURE REGISTER do PB
   andi  r10, r8, 0b1000   # separa o botão 3
   beq   r10, r0, POLLING
   
   movi r11, 0b1000
   stwio r11, 0xC(r9)		# resetando o botão 3


   # desloca segmentos
   movia r12, HEX0_3

   stwio r13, (r12)
 
   roli  r13, r13, 1

   br POLLING
*/

END:
  br END	
  
STATUS:  
.word 1  


	

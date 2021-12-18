
#
#  Entrada/Saida (I/O - E/S)
#    
#   I/O mapeada em memória
#     os dispositivos de I/O são acessados através de operações LD/SW
#
#  1o - endereço do dispositivo 
#  2o - forma de comunicação - paralela
#       -> usa interface PIO
#
#

.equ RED_LEDS, 0x10000000
.equ PB, 0x10000050
.equ HEX0_3, 0x10000020

.global _start
_start:

/* Exemplo de como acessar o LED vermelho
   movi  r8, 0b100010101111
   movia r9, RED_LEDS
   stwio   r8, (r9)
   
   # quero resetar apenas o primeiro bit (bit 0)   
   movia r10, 0xFFFFFFFE   
   and   r8, r8, r10   
   stwio r8, (r9)
*/   
   
   # Uso do push buttons
   # -> interface PIO, tem 3 registradores efetivos
   
# polling -> perguntar se o botão 3 foi pressionado

movia r9, PB		# endereço do pushbutton
POLLING:
   #ldwio r8, 0(r9)        # acessa DATA REGISTER do PB
   ldwio r8, 0xC(r9)        # acessa EDGECAPTURE REGISTER do PB
   andi  r10, r8, 0b1000   # separa o botão 3
   beq   r10, r0, POLLING
   
   
   # o bit no registrador EDGECAPTURE sempre fica ligado depois que alguém
   # apertou e soltou o botão
   # para resetar o bit 3, é necessário escrever no registrador EDGECAPTURE um
   # valor com os bits setados (para 3, escrever 0b1000)
   movi r11, 0b1000
   stwio r11, 0xC(r9)		# resetando o botão 3

   # r15 - acumulador 
   #  1110 1010 1100 0000    -> 16 bits
   
   ####################################
   ##### MANIPULA O DISPLAY 7segs
   ####################################
   movia r12, HEX0_3
   
   movia r15, TABLE_7segs   
   ldw   r13, 0(r15)    # código 7seg do número 0
   ldw   r16, 4(r15)    # código 7seg do número 1
   
#   movi  r13, 0b111111     # quero acender o valor 0 -> HEX0

   slli  r14, r16, 8	   # deslocando 8 bits para esqueda -> HEX1
   
#       00111111    r13
#111111 00000000	r14   
   
   or   r13, r14, r13       #junto os valores dos HEX0 e HEX1

   stwio r13, (r12)
 


   br POLLING
   
END:
  br END
  
TABLE_7segs:
 .word 0x3F		# 0
 .word 0x06     # 1
#.
#.
#.
# .word         # F
 
.end

Tabela de mapeamento 7seg

 Numero hexa (4 bits)    | codigo 7 seg  (8 bits)
      0                       0b00111111  / 0x3F  / 63
      1                       0b110 / 6 / 0x6
      2
	  3
	  4
	  .
	  .
	  C                         ????
	  .
	  .
	  F
 




   
   

	
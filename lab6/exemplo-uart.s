# Quero acender/apagar o primeiro led vermelho, quando a tecla x for apertada,
# usando a interface UART

.equ UART, 0x10001000
.equ LEDV, 0x10000000

.global _start
_start:
	
	movia r8, UART
	movia r14, LEDV
	movi  r13, 0       # status do LED
	
POLLING_UART:	# fica esperando alguém digitar algo

	ldwio r9, (r8)      # lendo registrador de dados da UART
	
	andi  r10, r9, 0x8000 # 0b1000000000000000  # isolando o RVALID
	
	beq   r10, r0, POLLING_UART
	
	# caractere foi lido da UART > r9
	
	# isolar o caracter
	andi  r11, r9, 0xFF

	# checar se caractere é o 'x'
	movi  r12, 'x'
	bne   r11, r12, POLLING_UART # se igual, le proximo caractere
	
	# é o x!
	
	xori   r13, r13, 0x1
	
	stwio r13, (r14)    # acende/apaga LED
	
	br POLLING_UART
 
STRING: 
.asciz "Minha String" 
 

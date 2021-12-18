.equ	STACK, 0x10000
.equ	    N, 30
# FIBO(0) = 0
# FIBO(1) = 1
# FIBO(2) = FIBO(1) + FIBO(0) = 1 + 0 = 1
# FIBO(3) = FIBO(2) + FIBO(1) = 1 + 1 = 2
# FIBO(4) = FIBO(3) + FIBO(2) = 2 + 1 = 3
# FIBO(5) = FIBO(4) + FIBO(3) = 3 + 2 = 5
# FIBO(6) = FIBO(5) + FIBO(4) = 5 + 3 = 8

.global _start
_start:

    movia	sp, STACK       # Inicializa a pilha

	addi sp, sp, -4
	movi r8, N
	stw  r8, (sp)           # Parâmetro N está na pilha, antes da que será criada pelo callee

	call FIBO

END:
    br		END             # Espera aqui quando o programa terminar

/*
	Stack Frame do Fibonacci
				Args de entrada (N)
	sp' -->		-------------------
					   ra
					   r8  (Other saved registers)
	sp  -->			   N-x ("Space for outgoing stack arguments" - Argumento para quem é chamado)
				-------------------
*/

FIBO:
	# PRÓLOGO
	addi sp, sp, -12 	# inicializa stack-frame com 3 posições
	stw  ra, 8(sp)
	stw  r8, 4(sp)
						# 12(sp) é o parâmetro (N)
	ldw  r8, 12(sp) 	# r8 = N
	mov  r2, r8     	# Move N para o retorno (útil quando for 0 ou 1)

	beq   r8,  r0, SAI_FIBO # sai se N == 0
	movi r16,   1
	beq   r8, r16, SAI_FIBO # sai se N == 1

	addi r9, r8, -1 	# r9 = N - 1
	stw  r9, (sp)
	call FIBO       	#r2 = FIBO(N-1)

	addi r9, r8, -2 	# r9 = N - 2
	mov  r8, r2     	# r8 = FIBO(N-1)

	stw  r9, (sp)
	call FIBO			#r2 = FIBO(N-12)

	add r2, r8, r2 # r2 = N + FIBO(N-1)

	SAI_FIBO:
		# EPÍLOGO
		ldw  ra, 8(sp)
		ldw  r8, 4(sp)
		addi sp, sp, 12 # desmonta o stack-frame

		ret

# fim FIBO
.end

.global _start
_start:

# em js
# let fibo = (n)=>{
#     let numbers = []
#     numbers[0] = 0
#     numbers[1]=1    

#     for(let i = 2; i<n; i++){
#         let sum = numbers[i-1]
#         sum = sum + numbers[i-2]
#         numbers[i] = sum
#     }
#     return numbers
# }
# fibo(8)

 # carregar parâmetros
 
  movia r2, N
  ldw r8, (r2)      # r8 = N

  addi r9, r2, 4    # r9 aponta agora para VT[0]
  stw  r0, (r9)     # VT[0] = 0

  addi r9, r9, 4    # r9 aponta agora para VT[1]
  addi r2, r0, 1
  stw  r2, (r9)     # VT[0] = 1

  movi r10, 2       # inicia laço com i=2
LACO:
# r9 está apontando para VT[1]
  bge  r10, r8, FIM   # condição de saída (i >= N)

#   VT[i] = VT[i-1] + VT[i-2]

  	ldw  r2, (r9)     # r2 =  VT[i-1]
	add  r3, r0, r2   # r3 =  VT[i-1]
	# r3 == sum

	subi r9, r9, 4    # r9 aponta para VT[i-2]
  	ldw  r2, (r9)     # r2 = VT[i-2]
	add  r3, r3, r2   # r3 = VT[i-1] + VT[i-2]

	addi  r9, r9, 8   # Avança ponteiro para próximo elemento 
					  # Compensa o -4 e adiciona mais 4, por isso soma 8
  	stw   r3, (r9)    # VT[i] = VT[i-1] + VT[i-2]

  	addi r10, r10, 1  # i = i+1
	br   LACO

FIM:
 br FIM

.org 0x1000
.equ TAMANHO, 47      # define número para calcular fibonacci. 47 = Maior número antes de dar erro
DADOS:
N:
.word TAMANHO
VT:
.skip TAMANHO*4


# registradores NiosII (MIPS) - r0 - r31

# código escrito em linguagem alto nivel (C#) -> *compilador* -> arquivo em linguagem de montagem
# arq. linguagem de montagem -> *montador* -> arquivo objeto (linguagem de máquina)

# instruções aritméticas e lógicas 
# instruções de salto
# instruções que afetam memória (load/store)
#  - ÚNICA FORMA DE ACESSAR A MEMÓRIA
# instruções com imediatos, assumem 16 bits
 	# 16 bits -> 64k (0 -> 65535) - sem sinal
 	# 16 bits com sinal -> -32768 <-> 32767 

# em linguagem de montagem, há três classes comandos
  # instruções nativas 
  # pseudo-instruções
  # diretivas de montagem



#############################################
# - METODO PARA ESCRITA DE LM NIOS2
#
# 1 - ENTENDER O PROBLEMA A SER RESOLVIDO
#  PROPOSTA: Calcular a sequencia de números triangulares  
#     T(0) = 0,           se N=0
#     T(N) = N + T(N-1),  se N>0
#
#   ENTRADA:  N - número de elementos, na posição de memória 0x400
#   SAIDA: VT - vetor com os N primeiros números da sequência
#
#  EXEMPLO:  se N=5, VT = {0, 1, 3, 6, 10}
#       
#
# 2 - ESCREVER ALGORITMO
#
#   VT[0] = 0;
#
#   for (i=1; i<=N; i++)
#     VT[i] = i + VT[i-1]
#
#
# 3 - MAPEAMENTO DE REGISTRADOR
#
#    N  => r8
#    VT => r9 - endereço base do vetor de saída
#    i  => r10 
#
# 4 - SEMPRE FAZER O CODIGO LM EM ETAPAS
#
#############################################


 

.global _start         # main()
_start:

 # carregar parâmetros
 
  movia r2, N
  ldw r8, (r2)      # r8 = N

#   VT[0] = 0;
  addi r9, r2, 4    # r2 aponta agora para VT
  stw  r0, (r9)     # VT[0] = 0

#   for (i=1; i<=N; i++)
 # antes de entrar no laço: i=1
 # testa (i<=N) para entrar no laço
 #  --- corpo do laço
 # no final do laço, incrementa 1
  movi r10, 1   # i=1
LACO:
# r9 está apontando para VT[0]
  bgt  r10, r8, FIM   # condição de saída (i>N)

#     VT[i] = i + VT[i-1]
    ldw  r2, (r9)     # r2 = VT[i-1]
	add r3, r10, r2  # r3 = i + VT[i-1]
    
	addi  r9, r9, 4   # avança ponteiro para próximo elemento
    stw   r3, (r9)    # VT[i] = i + VT[i-1]


    addi r10, r10, 1   # i = i+1
	br   LACO


FIM:
 br FIM


.equ TAMANHO, 15      # #define TAMANHO 7
DADOS:
N:
.word TAMANHO
VT:
.skip TAMANHO*4
  


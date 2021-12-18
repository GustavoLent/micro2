/* Arquivo principal - parte 1 do laboratorio 2 */

.equ	STACK, 0x10000

/*****************************************************************************/
/* Program principal                                                         */
/*   Invoca sub-rotina para ordenar lista de valores em ordem decrescente.   */
/*                                                                           */
/* r8  - Endereco do tamanho da lista de numeros                             */
/* r9  - Endereco do primeiro numero na lista                                */
/*****************************************************************************/

.global _start
_start:
    movia	sp, STACK          /* Configura registradores da pilha e    */
    mov		fp,  sp            /* e frame pointer.                      */

    movia	r4,  SIZE          /* Endereço do tamanho                   */
    ldw   	r4, 0(r4)          /* Carrega o tamanho da lista 			*/
    movia	r5,  LIST          /* Endereço do primeiro elemento         */
    # r4 e r5 são os dois parâmetros para a função

    call	SORT

END:
    br		END              /* Espera aqui quando o programa terminar  */

/*****************/    

.org	0x200

LIST_FILE:
SIZE:
.word 5
LIST:
.word 13, 14, 15, 16, 17

.global SORT
SORT:
	# r16 ~ r23 registradores do callee
	# r4 = size
	# r5 = endereço primeiro elemento da lista

/*
	r16 = i
	r17 = indice_max
	r18 = j

	r19 = temp offset to build the addres ( j * 4 )		<-- temp usage for this reg
	r19 = temp addres									<-- temp usage for this reg
	r19 = vector[j] 									<-- final usage for this reg
	<!>   r19 will be used to load the "vector[indice_max]"

	r20 = temp offset to build the addres ( indice_max * 4 )		
	r20 = temp addres									
	r20 = vector[indice_max]
	
	r21 = temp address
	r22 = temp address
	
	r23 = temp
*/

	movi r16, 0 # i (r16) = 0

	FOR_SCANNING:
		bge r16, r4, RETURN 	# i >= SIZE, return
			mov r17, r16		# indice_max (r17) = i (r16)

			mov  r18, r16 		# j = i
			addi r18, r18, 1   	# j = i + 1
			FOR_SEARCH_HIGHER:
				bge r18, r4, SWAP

					slli r19, r18, 2
					add  r19, r19, r5 	# r19 = offset to vector[j]
					ldw  r19, (r19)		# r19 = vector[j]

					slli r20, r17, 2
					add  r20, r20, r5 	# r20 = offset to vector[indice_max]
					ldw  r20, (r20)		# r20 = vector[indice_max]

					ble r19, r20, BACK_TO_FOR_SEARCH_HIGHER 	# if (vector[j] <= vector[indice_max]); go BACK_TO_FOR_SEARCH_HIGHER

					mov r17, r18								# else, indice_max (r17) = j (r18);
																#       and come back to FOR_SEARCH_HIGHER
				BACK_TO_FOR_SEARCH_HIGHER:
					addi r18, r18, 1
					br FOR_SEARCH_HIGHER

			SWAP:
				beq r16, r17, BACK_TO_FOR_SCANNING 	# if (i == indice_max), skip SWAP

				slli r21, r17, 2
				add  r21, r21, r5 	# r21 = "temp address" to vector[indice_max]
				
				slli r22, r16, 2	
				add  r22, r22, r5 	# r22 = "temp address" to vector[i]
				
				ldw  r19, (r22)		# r19 = vector[i]
				ldw  r20, (r21)		# r20 = vector[indice_max]

				mov  r23, r20 		# temp = vector[indice_max]				

				stw  r19, (r21)		# vector[indice_max] = vector[i];
				stw  r23, (r22)		# vector[i] = temp;

		BACK_TO_FOR_SCANNING:
			addi r16, r16, 1
			br   FOR_SCANNING	

	RETURN:
		ret
.end



































.equ	N, 0x3EFD6
.equ 	MASK, 0x1
.equ 	STEP, 0x1


.global start
start:
	
	mov  r4, r0	# let counter = 0
	mov  r5, r0	# let greater = 0
	# THE RESULT WILL BE IN r5	
	
	movia r8, N	# r8 = N
	
	br COND
	
	BODY:

		movia r15, MASK   # temp
		and   r9, r8, r15 # r9 = curr (less significative bit)

		beq	  r9, r0, SWAP_COUNTER_GREATER

		INC_COUNTER:
			addi r4, r4, 1
			br CONTINUE

		SWAP_COUNTER_GREATER:
			call MAX		# get max from counter (r4) and greater (r5)
			mov r5, r2		# assign the max into greater
			mov r4, r0		# reset the counter

		CONTINUE:
			srli  r8, r8, STEP

	COND:
		bne r8, r0, BODY

	#if ended with 1, will not fire "SWAP_COUNTER_GREATER"
	call MAX		# get max from counter (r4) and greater (r5)
	mov r5, r2		# assign the max into greater

	mov  r2, r0
	mov  r4, r0
	mov  r9, r0
	mov r15, r0		# clean all to simplify the result visualization

	END:
		br END 

MAX: 
	# r4 = value1; r5 = value2
	blt r4, r5, ELSE 

	IF:
		mov r2, r4
		br  RETURN

	ELSE:
		mov r2, r5

	RETURN:
		ret
##############################

.end

.equ	   STACK, 0x10000
.equ    RED_LEDS, 0x10000000
.equ    SWITCHES, 0x10000040
.equ          PB, 0x10000050

.equ SWITCHES_07, 0xFF
.equ    PB_FIRST, 0b10


.global _start

_start:
	movia  sp, STACK
	movia  r9, PB
	movia r10, SWITCHES
	movia r11, RED_LEDS

	POLLING:

		ldwio r12, 0xC(r9)			# acessa EDGECAPTURE REGISTER do PB
		andi  r13, r12, PB_FIRST		# separa o botão 3
		beq   r13, r0, POLLING

		call LOAD_LEDS_FROM_SWITCH

		# ldwio r4, (r10)
		# andi  r4, r4, SWITCHES_07

		# call CALCULATE_SWITCH_SUM
		# stwio r2, (r11)

		movi  r13, PB_FIRST
		stwio r13, 0xC(r9)			# resetando o botão 3
		br POLLING

END:
	br END

LOAD_LEDS_FROM_SWITCH:
	addi sp, sp, -16
	stw  ra, 12(sp)
	stw  r18, 8(sp)
	stw  r17, 4(sp)
	stw  r16, 0(sp)

	movia r16, SWITCHES

	ldwio r4, 0(r16)
	andi  r4, r4, SWITCHES_07

	call CALCULATE_SWITCH_SUM

	movia r16, SUM
	ldw   r18, (r16)

	add r18, r18, r2
	stw r18, (r16)		# update the sum

	movia r17, RED_LEDS
	stwio r18, 0(r17)

	ldw  ra, 12(sp)
	ldw  r18, 8(sp)
	ldw  r17, 4(sp)
	ldw  r16, 0(sp)
	addi sp, sp, 16

ret
#

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
####

SUM:
.word 0
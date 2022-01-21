/********************************************************************************
* This program demonstrates use of the JTAG UART port in the DE2 Media Computer
*
* It performs the following:
* 1. sends a text string to the JTAG UART
* 2. reads character data from the JTAG UART
* 3. echos the character data back to the JTAG UART
********************************************************************************/
.text /* executable code follows */
.global _start
_start:
    /* set up stack pointer */
    movia   sp, 0x007FFFFC /* stack starts from highest memory address in SDRAM */
    movia   r6, 0x10001000 /* JTAG UART base address */
    
    movia   r5, TEXT_STRING
    call    PRINT_JTAG_WITHOUT_FILTER
    
    movia   r5, NEW_LINE
    call    PRINT_JTAG_WITHOUT_FILTER

    /* read and echo characters */
    GET_JTAG:
        ldwio r4, 0(r6) /* read the JTAG UART Data register */
        andi r8, r4, 0x8000 /* check if there is new data */
        
        beq r8, r0, GET_JTAG /* if no data, wait */
        
        andi r5, r4, 0x00ff /* the data is in the least significant byte */
        call READ_PRINT_JTAG_WITH_FILTER /* echo character */
    br GET_JTAG

/* r5 is the string */
PRINT_JTAG_WITHOUT_FILTER:
    /* save any modified registers */
    subi    sp, sp, 16
    stw     r10, 12(sp)
    stw     r9, 8(sp)
    stw     r8, 4(sp)
    stw     r5, 0(sp)

    movia   r9, 0x10001000                              /* JTAG UART base address */

    WITHOUT_FILTER_LOOP:
        ldb     r8, 0(r5)
        beq     r8, zero, END_WITHOUT_FILTER_LOOP       /* string is null-terminated */

            ldwio   r10, 4(r9)                          /* read the JTAG UART Control register */
            andhi   r10, r10, 0xffff                    /* check for write space */
            beq     r10, r0, END_WITHOUT_FILTER_LOOP    /* if no space, ignore the character */

            stwio   r8, 0(r9)

        addi    r5, r5, 1
    br WITHOUT_FILTER_LOOP

    END_WITHOUT_FILTER_LOOP:
        /* restore registers */
        ldw     r10, 12(sp)
        ldw     r9, 8(sp)
        ldw     r8, 4(sp)
        ldw     r5, 0(sp)
        addi    sp, sp, 16
ret

/********************************************************************************
* Subroutine to send a character to the JTAG UART
* r5 = character to send
********************************************************************************/
.global READ_PRINT_JTAG_WITH_FILTER
READ_PRINT_JTAG_WITH_FILTER:
    /* save any modified registers */
    subi    sp, sp, 12          /* reserve space on the stack */
    stw     ra, 8(sp)           /* save register */
    stw     r8, 4(sp)           /* save register */
    stw     r9, 0(sp)           /* save register */

    movia   r9, 0x10001000      /* JTAG UART base address */

    ldwio   r8, 4(r9)           /* read the JTAG UART Control register */
    andhi   r8, r8, 0xffff      /* check for write space */
    beq     r8, r0, END_PUT     /* if no space, ignore the character */

    /* words to ignore */
    movi    r8, 8               /* backspace */
    beq     r5, r8, END_PUT

    movi    r8, 127             /* dell */
    beq     r5, r8, END_PUT

    stwio   r5, 0(r9)           /* print the word */

    movi    r8, '\n'
    bne     r5, r8, END_PUT
    movia   r5, NEW_LINE
    call    PRINT_JTAG_WITHOUT_FILTER /* r5 already is '\n' */

END_PUT:
    /* restore registers */
    ldw     ra, 8(sp)
    ldw     r8, 4(sp)
    ldw     r9, 0(sp)
    addi    sp, sp, 12
ret

.data /* data follows */
TEXT_STRING:
.asciz "JTAG UART example code\n"

NEW_LINE:
.asciz "> "
.end
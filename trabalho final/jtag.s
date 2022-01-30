.text
.global _start

/* main function */
_start:
    movia   sp, 0x007FFFFC      /* stack starts from highest memory address in SDRAM */
    movia   r7, JTAG            /* JTAG UART base address */

    /* Initial prints */
    movia   r5, TEXT_STRING
    call    PRINT_JTAG_WITHOUT_FILTER
    
    movia   r5, INSTRUCTIONS
    call    PRINT_JTAG_WITHOUT_FILTER
    
    movia   r5, NEW_LINE
    call    PRINT_JTAG_WITHOUT_FILTER
    /* Ended initial prints */

    JTAG_POOLING:
        ldwio r4, 0(r7)                     /* read the JTAG UART Data register */
        andi r8, r4, 0x8000                 /* check if there is new data */
        
        beq r8, r0, JTAG_POOLING            /* if no data, wait */
        
        andi r5, r4, 0x00ff                 /* the data is in the least significant byte */
        call PRINT_JTAG_WITH_FILTER    /* echo character */
    br JTAG_POOLING
/* end main function */

/* r5 is the string */
PRINT_JTAG_WITHOUT_FILTER:
    subi    sp, sp, 16
    stw     r10, 12(sp)
    stw     r9, 8(sp)
    stw     r8, 4(sp)
    stw     r5, 0(sp)

    movia   r9, JTAG                    /* JTAG UART base address */

    movi r8, 127                        /* 127 is the last ascii code */
    bgt  r5, r8, WITHOUT_FILTER_LOOP

    stwio   r5, (r9)                    /* if is ascii, just print */
    br END_WITHOUT_FILTER_LOOP

    WITHOUT_FILTER_LOOP:
        ldb     r8, 0(r5)
        
        COMPARE_WRITE_VALUE:
            beq     r8, zero, END_WITHOUT_FILTER_LOOP       /* string is null-terminated */

                ldwio   r10, 4(r9)                          /* read the JTAG UART Control register */
                andhi   r10, r10, 0xffff                    /* check for write space */
                beq     r10, r0, COMPARE_WRITE_VALUE        /* if no space, wait */

                stwio   r8, 0(r9)

            addi    r5, r5, 1
    br WITHOUT_FILTER_LOOP


    END_WITHOUT_FILTER_LOOP:
        ldw     r10, 12(sp)
        ldw     r9, 8(sp)
        ldw     r8, 4(sp)
        ldw     r5, 0(sp)
        addi    sp, sp, 16
ret

/* r5 is the incomming data */
EVALUATE_LED_STATE_BY_INCOMMING_DATA:
    subi    sp, sp, 20
    stw     r8, 16(sp)
    stw     r7, 12(sp)
    stw     r6, 8(sp)
    stw     r5, 4(sp)
    stw     ra, 0(sp)
    /* 
        r8: The value used to compare the state
        r7: The current state from LEDS_STATE
        r6: The address of the LEDS_STATE
    */

    LEDS_STATE_VALIDATION: 
        movia r6, LEDS_STATE
        ldw   r7, (r6)

        movi r8, 0
        beq r7, r8, LEDS_STATE_00

        movi r8, 1
        beq r7, r8, LEDS_STATE_01

        movi r8, 2
        beq r7, r8, LEDS_STATE_02

        movi r8, 3
        beq r7, r8, LEDS_STATE_03

        movi r8, 4
        beq r7, r8, LEDS_STATE_04

        movi r8, 5
        beq r7, r8, LEDS_STATE_05

        movi r8, 6
        beq r7, r8, LEDS_STATE_06

        movi r8, 7
        beq r7, r8, LEDS_STATE_07

        movi r8, 8
        beq r7, r8, LEDS_STATE_08

        movi r8, 9
        beq r7, r8, LEDS_STATE_09

        movi r8, 10
        beq r7, r8, LEDS_STATE_10

        movi r8, 11
        beq r7, r8, LEDS_STATE_11

    br LEDS_END         /* validate "state not found" error? */
 
    LEDS_STATE_00:
        movi r8, 'L'
        bne r5, r8, LEDS_END
        
        movi r8, 1 /* the next LEDs state is 1, cause L commes */
        stw  r8, (r6)
    br LEDS_END

    LEDS_STATE_01:      /* the error is validated in LEDS_STATE_01_5; when validate if comes "L5" */
        movi r8, '0'
        bne r5, r8, LEDS_STATE_01_1
        
        movi r8, 2      /* the next LEDs state is 2, cause "L0" commes */
        stw  r8, (r6)
        br LEDS_END
        
        LEDS_STATE_01_1:
            movi r8, '1'
            bne r5, r8, LEDS_STATE_01_2
        
            movi r8, 5      /* the next LEDs state is 5, cause "L1" commes */
            stw  r8, (r6)
            br LEDS_END

        LEDS_STATE_01_2:
            movi r8, '2'
            bne r5, r8, LEDS_STATE_01_3
        
            movi r8, 8      /* the next LEDs state is 8, cause "L2" commes */
            stw  r8, (r6)
            br LEDS_END

        LEDS_STATE_01_3:
            movi r8, '3'
            bne r5, r8, LEDS_STATE_01_4
        
            movi r8, 9      /* the next LEDs state is 9, cause "L3" commes */
            stw  r8, (r6)
            br LEDS_END
    
        LEDS_STATE_01_4:
            movi r8, '4'
            bne r5, r8, LEDS_STATE_01_5
                
            movi r8, 10      /* the next LEDs state is 10, cause "L4" commes */
            stw  r8, (r6)
            br LEDS_END
    
        LEDS_STATE_01_5:
            movi r8, '5'
            movia r3, DIGIT_TEXT    /* a Digit is expected */
            bne r5, r8, LEDS_ERROR_STATE
                
            movi r8, 11      /* the next LEDs state is 11, cause "L5" commes */
            stw  r8, (r6)
            br LEDS_END

    br LEDS_END

    LEDS_STATE_02:
        movi r8, ' '
        movi r3, ' '    /* 'space' is expected */
        bne r5, r8, LEDS_ERROR_STATE
        
        movi r8, 3 /* the next LEDs state is 3, cause "L0 " commes */
        stw  r8, (r6)
    br LEDS_END

    LEDS_STATE_03:
        movi r8, '0'
        movia r3, DIGIT_TEXT    /* a Digit is expected */
        blt  r5, r8, LEDS_ERROR_STATE   /* if lower than char 0, error */

        movi r8, '9'
        bgt  r5, r8, LEDS_ERROR_STATE   /* if greather than char '9', error */

        movi r8, 4                      /* the next LEDs state is 4, cause "L0 X" commes */
        stw  r8, (r6)

        movia r7, LEDS_TARGET           /* get the LEDS_TARGET offset */
        subi  r8, r5, '0'               /* fix the LED offset */
        stw   r8, (r7)                  /* set the LEDS_TARGET, that will be used in the next state, 4 */
    br LEDS_END

    LEDS_STATE_04:
        movi r8, '\n'
        movia r3, ENTER_TEXT    /* a "enter" is expected */
        bne r5, r8, LEDS_ERROR_STATE

        movi r8, 0                      /* the next LEDs state is 0, cause "L0 X\n" commes */
        stw  r8, (r6)

        movia r8, LEDS_ON_OFF_STATE     /* load what LEDs are on, already in the binary format */
        ldw   r8, (r8)

        movia r7, LEDS_TARGET           /* load the LED that will be turned on, not in the correct format yet */
        ldw   r7, (r7)

        mov  r5, r7
        call GET_LED_CODE_FROM_DEC
        mov  r7, r2

        or   r8, r8, r7
        movia r7, LEDS                  /* LEDs address */
        stwio   r8, (r7)                /* update what LEDs should be on */

        movia r7, LEDS_ON_OFF_STATE     
        stw   r8, (r7)                  /* update the LEDS_ON_OFF_STATE */

    br LEDS_END

    LEDS_STATE_05:
        movi r8, ' '
        movi r3, ' '    /* a "space" is expected */
        bne r5, r8, LEDS_ERROR_STATE
        
        movi r8, 6 /* the next LEDs state is 6, cause "L1 " commes */
        stw  r8, (r6)
    br LEDS_END

    LEDS_STATE_06:
        movi r8, '0'
        movia r3, DIGIT_TEXT    /* a Digit is expected */
        blt  r5, r8, LEDS_ERROR_STATE   /* if lower than char 0, error */

        movi r8, '9'
        bgt  r5, r8, LEDS_ERROR_STATE   /* if greather than char '9', error */

        movi r8, 7                      /* the next LEDs state is 7, cause "L1 X" commes */
        stw  r8, (r6)

        movia r7, LEDS_TARGET           /* get the LEDS_TARGET offset */
        subi  r8, r5, '0'               /* fix the LED offset */
        stw   r8, (r7)                  /* set the LEDS_TARGET, that will be used in the next state, 7 */
    br LEDS_END

    LEDS_STATE_07:
        movi r8, '\n'
        movia r3, ENTER_TEXT    /* a "enter" is expected */
        bne r5, r8, LEDS_ERROR_STATE    /* the expected is "\n", to complete "L1 X\n". If r5 not equals to "\n", there is an error */

        movi r8, 0                      /* the next LEDs state is 0, cause "L1 X\n" commes */
        stw  r8, (r6)

        movia r8, LEDS_ON_OFF_STATE     /* load what LEDs are on, already in the binary format */
        ldw   r8, (r8)

        movia r7, LEDS_TARGET           /* load the LED that will be turned on, not in the correct format yet */
        ldw   r7, (r7)

        mov  r5, r7
        call GET_LED_CODE_FROM_DEC      /* call the function that will map the LEDS_TARGET offset to the correct LED mask */
        mov  r7, r2

        nor  r7, r7, r7                 /* NOT bitwise operation in the mask that contains the LED tha must be turned off */
        and  r8, r8, r7                 
        
        /* 
            And between masks. 
            Because if we want to turn off the led 3, the offset will create the mask [00100] (suposing 6 LEDs)
            Performing a NOT (nor with himself), will result in the mask [11011]

            With that, and considering that the on LEDs is [10101], it's possible to execute an AND between the masks to obtain [10001].

            Obs:
            The not will create an 32 bits result, like [111...1111011]. As the LEDs uses only 9 bits, those other ones from the "off-mask" doesnt causes any error.
        */

        movia r7, LEDS                  /* LEDs address */
        stwio r8, (r7)                  /* update what LEDs should be on */

        movia r7, LEDS_ON_OFF_STATE     
        stw   r8, (r7)                  /* update the LEDS_ON_OFF_STATE */

    br LEDS_END

    LEDS_STATE_08:
        movi r8, '\n'
        movia r3, ENTER_TEXT    /* a "enter" is expected */
        bne  r5, r8, LEDS_ERROR_STATE

        stw r0, (r6)                    /* the next LEDs state is 0, cause "L2\n" commes */

        movia r7, LEDS_ON_OFF_STATE
        ldw   r7, (r7)                  /* get the LEDS_ON_OFF_STATE */

        movi r8, EVEN_LEDS              /* get the even LEDs mask */
        or   r8, r8, r7                 /* update the LEDs mask with those that was already on, and the even LEDs */

        movia r7, LEDS                  /* LEDs address */
        stwio r8, (r7)                  /* update the LEDs with the new mask */

        movia r7, LEDS_ON_OFF_STATE
        stw r8, (r7)                    /* update the LEDS_ON_OFF_STATE with the new mask */

    br LEDS_END

    LEDS_STATE_09:
        movi r8, '\n'
        movia r3, ENTER_TEXT    /* a "enter" is expected */
        bne  r5, r8, LEDS_ERROR_STATE

        stw r0, (r6)                    /* the next LEDs state is 0, cause "L3\n" commes */

        movia r7, LEDS_ON_OFF_STATE
        ldw   r7, (r7)                  /* get the LEDS_ON_OFF_STATE */

        movi r8, ODD_LEDS               /* get the even LEDs mask */
        or   r8, r8, r7                 /* update the LEDs mask with those that was already on, and the odd LEDs */

        movia r7, LEDS                  /* LEDs address */
        stwio r8, (r7)                  /* update the LEDs with the new mask */

        movia r7, LEDS_ON_OFF_STATE
        stw r8, (r7)                    /* update the LEDS_ON_OFF_STATE with the new mask */

    br LEDS_END

    LEDS_STATE_10:
        movi r8, '\n'
        movia r3, ENTER_TEXT    /* a "enter" is expected */
        bne  r5, r8, LEDS_ERROR_STATE

        stw r0, (r6)                    /* the next LEDs state is 0, cause "L4\n" commes */

        movia r7, LEDS_ON_OFF_STATE
        ldw   r7, (r7)                  /* get the LEDS_ON_OFF_STATE */

        movia r8, SWITCHES
        ldwio r8, (r8)                 
	    andi  r8, r8, SWITCHES_LEDS_MASK

        or   r8, r8, r7                 /* update the LEDs mask with those that was already on, and the odd LEDs */

        movia r7, LEDS                  /* LEDS address */
        stwio r8, (r7)                  /* update the LEDs with the new mask */

        movia r7, LEDS_ON_OFF_STATE
        stw r8, (r7)                    /* update the LEDS_ON_OFF_STATE with the new mask */

    br LEDS_END

    LEDS_STATE_11:
        movi r8, '\n'
        movia r3, ENTER_TEXT    /* a "enter" is expected */
        bne r5, r8, LEDS_ERROR_STATE

        stw  r0, (r6)                   /* the next LEDs state is 0, cause "L5\n" commes */

        movia r7, LEDS                  /* LEDs address */
        stwio r0, (r7)                  /* turn off all the LEDs */

        movia r8, LEDS_ON_OFF_STATE     /* get the LEDS_ON_OFF_STATE address */
        stw   r0, (r8)                  /* update LEDS_ON_OFF_STATE with all disabled */

    br LEDS_END

    LEDS_ERROR_STATE:
        mov r7, r5  /* Save the typed char, it will be replaced when calling other functions!!! */

        movi r8, '\n'
        beq  r7, r8, LEDS_ERROR_STATE_PRINT_ERROR

        mov r5, r8
        call PRINT_JTAG_WITHOUT_FILTER      
        /* The entered text was not an '\n', so the pointer is in the same line. Print '\n' */
        /* Remember: the console prints the char typed, so the '\n' would have been written*/

        LEDS_ERROR_STATE_PRINT_ERROR:
            mov r4, r7          /* The "print error" r4 is the "obtained data", saved in r7 */
            call PRINT_ERROR

            movi r5, '\n'
            call PRINT_JTAG_WITHOUT_FILTER  /* Print '\n' after the error message */

            movia r8, LEDS_STATE
            stw   r0, (r8)                  /* restore the LEDs state */

        LEDS_ERROR_STATE_NEW_LINE_INDICATOR_VALIDATION:
            movi r8, '\n'
            beq  r7, r8, LEDS_END

            movia r5, NEW_LINE
            call PRINT_JTAG_WITHOUT_FILTER      /* print '> ' */

    br LEDS_END

    LEDS_END:
        ldw     r8, 16(sp)
        ldw     r7, 12(sp)
        ldw     r6, 8(sp) 
        ldw     r5, 4(sp)
        ldw     ra, 0(sp)
        addi    sp, sp, 20
ret

/* r5 = character to send */
PRINT_JTAG_WITH_FILTER:
    subi    sp, sp, 12
    stw     ra, 8(sp)
    stw     r8, 4(sp)
    stw     r9, 0(sp)

    movia   r9, JTAG                                /* JTAG UART base address */

    ldwio   r8, 4(r9)                               /* read the JTAG UART Control register */
    andhi   r8, r8, 0xffff                          /* check for write space */
    beq     r8, r0, END_PRINT_JTAG_WITH_FILTER      /* if no space, ignore the character */

    /* ignoring words */
        movi    r8, 8               /* backspace */
        beq     r5, r8, END_PRINT_JTAG_WITH_FILTER

        movi    r8, 127             /* dell */
        beq     r5, r8, END_PRINT_JTAG_WITH_FILTER
    /* end ignoring */

    stwio   r5, 0(r9)               /* print the word */
    call EVALUATE_LED_STATE_BY_INCOMMING_DATA

    movi    r8, '\n'
    bne     r5, r8, END_PRINT_JTAG_WITH_FILTER
    movia   r5, NEW_LINE             /* r5 was an '\n', so a new line was printed and this needs a line indicator */
    call    PRINT_JTAG_WITHOUT_FILTER 

    END_PRINT_JTAG_WITH_FILTER:
        ldw     ra, 8(sp)
        ldw     r8, 4(sp)
        ldw     r9, 0(sp)
        addi    sp, sp, 12
ret

/* r3 is the expected, r4 is the obtained */
PRINT_ERROR:
    PRINT_ERROR_CREATE_STACK:
        subi    sp, sp, 12
        stw     ra, 8(sp)
        stw     r5, 4(sp)
        stw     r4, 0(sp)
        
    /* if the obtained is '\n', change to 'enter' */
    movi r8, '\n'
    bne r4, r8, CONTINUE_PRINT_ERROR
    movia r4, ENTER_TEXT

    CONTINUE_PRINT_ERROR:
    movia   r5, EXPECTED
    call    PRINT_JTAG_WITHOUT_FILTER

    mov     r5, r3
    call    PRINT_JTAG_WITHOUT_FILTER

    movia   r5, OBTAINED
    call    PRINT_JTAG_WITHOUT_FILTER

    mov     r5, r4
    call    PRINT_JTAG_WITHOUT_FILTER

    movia   r5, OBTAINED_END
    call    PRINT_JTAG_WITHOUT_FILTER

    PRINT_ERROR_RESTORE_STACK:
        ldw     ra, 8(sp)
        ldw     r5, 4(sp)
        ldw     r4, 0(sp)
        addi    sp, sp, 12
ret

/* r5 is the dec */
GET_LED_CODE_FROM_DEC:
    subi    sp, sp, 12
    stw     r8, 8(sp)
    stw     r5, 4(sp)
    stw     ra, 0(sp)

    movia r8, 1      
    bne   r5, r8, GET_LED_CODE_FROM_DEC_2                 /* the code for 1 is 1 */
    movi  r2, 1
    br    END_GET_LED_CODE_FROM_DEC

    GET_LED_CODE_FROM_DEC_2:
        movia r8, 2      
        bne   r5, r8, GET_LED_CODE_FROM_DEC_3             /* the code for 2 is 2 */
        movi  r2, 2
        br    END_GET_LED_CODE_FROM_DEC

    GET_LED_CODE_FROM_DEC_3:
        movia r8, 3      
        bne   r5, r8, GET_LED_CODE_FROM_DEC_4             /* the code for 3 is 4 */
        movi  r2, 4
        br    END_GET_LED_CODE_FROM_DEC

    GET_LED_CODE_FROM_DEC_4:
        movia r8, 4      
        bne   r5, r8, GET_LED_CODE_FROM_DEC_5             /* the code for 4 is 8 */
        movi  r2, 8
        br    END_GET_LED_CODE_FROM_DEC

    GET_LED_CODE_FROM_DEC_5:
        movia r8, 5      
        bne   r5, r8, GET_LED_CODE_FROM_DEC_6             /* the code for 5 is 16 */
        movi  r2, 16
        br    END_GET_LED_CODE_FROM_DEC

    GET_LED_CODE_FROM_DEC_6:
        movia r8, 6      
        bne   r5, r8, GET_LED_CODE_FROM_DEC_7             /* the code for 6 is 32 */
        movi  r2, 32
        br    END_GET_LED_CODE_FROM_DEC

    GET_LED_CODE_FROM_DEC_7:
        movia r8, 7      
        bne   r5, r8, GET_LED_CODE_FROM_DEC_8             /* the code for 7 is 64 */
        movi  r2, 64
        br    END_GET_LED_CODE_FROM_DEC

    GET_LED_CODE_FROM_DEC_8:
        movia r8, 8      
        bne   r5, r8, GET_LED_CODE_FROM_DEC_9             /* the code for 8 is 128 */
        movi  r2, 128
        br    END_GET_LED_CODE_FROM_DEC

    GET_LED_CODE_FROM_DEC_9:
        movia r8, 9      
        bne   r5, r8, GET_LED_CODE_FROM_DEC_DEFAULT       /* the code for 9 is 256 */
        movi  r2, 256
        br    END_GET_LED_CODE_FROM_DEC

    GET_LED_CODE_FROM_DEC_DEFAULT:
        movi  r2, 0

    END_GET_LED_CODE_FROM_DEC:
        ldw     r8, 8(sp)
        ldw     r5, 4(sp)
        ldw     ra, 0(sp)
        addi    sp, sp, 12
ret

.org 0x1000

LEDS_STATE:
.word 0

LEDS_TARGET:
.word 0

LEDS_ON_OFF_STATE:
.word 0

.equ SWITCHES, 0x10000040
.equ LEDS, 0x10000010
.equ JTAG, 0x10001000

.equ EVEN_LEDS, 0b010101010
.equ ODD_LEDS, 0b101010101

.equ SWITCHES_LEDS_MASK, 0b111111111

TEXT_STRING:
.asciz ">  Interpretador de comandos via console  <\n"

INSTRUCTIONS:
.asciz "  Entre com comandos finalizados por enter\n\n"

NEW_LINE:
.asciz "> "

ENTER_TEXT:
.asciz "enter"

DIGIT_TEXT:
.asciz "0~9"

EXPECTED:
.asciz "Era esperado ["

OBTAINED:
.asciz "] mas foi obtido ["

OBTAINED_END:
.asciz "]."

.end
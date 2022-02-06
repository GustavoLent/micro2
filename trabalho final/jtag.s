.org 0x20

RTI:
   addi sp, sp, -8
   stw  ra, 0(sp)
   stw  r9, 4(sp)

   # descobrir quem gerou a exceção
   rdctl et, ipending
   beq   et, r0, SW_EXCEPTION

    HW_EXCEPTION:
        # sei que foi um HW que gerou a interrupção
        addi  ea, ea, -4         # qdo é interrupção (HW), preciso subtrair 4

        # preciso saber qual IRQ foi acionada
        TESTA_TIMER:   
            movi  r9, ITR_TIMER    # máscara do IRQ0 (timer)
            bne   et, r9, FIM_RTI  # caso não seja timer, saio da RTI
            call ON_TIMER_INTERRUPTION
            br  FIM_RTI

    SW_EXCEPTION:

    FIM_RTI:
        ldw  ra, 0(sp)
        ldw  r9, 4(sp)
        addi sp, sp, 8
eret

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

    movi r4, TIMER_PERIOD_MULTIPLIER
    call LOAD_TIMER_INTERRUPTION

    call INITIALIZE_LOADED_INTERRUPTIONS
    call START_LISTENING_INTERRUPTIONS 

    movia r4, HEX0_0
    movia r5, SECONDS_COUNTER
    ldw   r5, (r5)
    call UPDATE_TIMER_DISPLAY

    JTAG_POOLING:
        ldwio r4, 0(r7)                     /* read the JTAG UART Data register */
        andi r8, r4, 0x8000                 /* check if there is new data */
        
        beq r8, r0, JTAG_POOLING            /* if no data, wait */
        
        andi r5, r4, 0x00ff                 /* the data is in the least significant byte */
        call PRINT_JTAG_WITH_FILTER    /* echo character */
    br JTAG_POOLING
/* end main function */

/*** Timer functions ***/
    # r4 -> the seconds to await ("integer")
    LOAD_TIMER_INTERRUPTION:
        addi  sp, sp, -12
        stw   r9, 0(sp)
        stw  r10, 4(sp)
        stw  r11, 8(sp)

        # configure TIMER to generate interrupts from r4 in r4 seconds    
        movia r9, TIMER_BASE_PERIOD
        mul  r10, r9, r4                    # TIMER_BASE_PERIOD * r4

        movia  r9, TIMER
        andi   r11, r10, 0xFFFF
        stwio  r11, 8(r9)           # counter lowest bits

        srli   r11, r10, 16         # counter highest bits
        stwio  r11, 12(r9)

        # habilitar temporizador
        movi   r10, 0b111      # START | CONT | ITO
        stwio  r10, 4(r9)

        movia  r9, ENABLED_INTERRUPTIONS
        ldw    r9, (r9)
        movi  r10, 0b1
        or    r10, r10, r9          # Add the created timer interruption in the loaded interruptions

        movia  r9, ENABLED_INTERRUPTIONS
        stw    r10, (r9)  # CARREGA interrupção da IRQ 0 (timer)

        ldw   r9, 0(sp)
        ldw  r10, 4(sp)
        ldw  r11, 8(sp)
        addi sp, sp, 12

    ret

    /* Will validate the seconds count, and will validate if the seconds update triggers the alarm */
    VALIDATE_SECONDS_COUNT:
        subi    sp, sp, 20
        stw     ra,  0(sp)
        stw     r9,  4(sp)
        stw     r11, 8(sp)
        stw     r5, 12(sp)
        stw     r3, 16(sp)

        VALIDATING_IF_IS_COUNTING_SECONDS:
            movia r9, IS_COUNTING_SECONDS
            ldw   r9, (r9)

            beq r9, r0, ON_TIMER_INTERRUPTION_END

            /* Is counting seconds*/
            movia r9, SECONDS_COUNTER_STATE
            ldw   r9, (r9)

            beq r9, r0, TURN_SECONDS_COUNTER_STATE_EQUALS_1

            /* The seconds counting state is 1*/
            movia r9, SECONDS_COUNTER_STATE
            stw   r0, (r9)                  /* Back seconds counting state to 0*/

            movia  r9, SECONDS_COUNTER
            ldw   r11, (r9)                 /* Get the counted value */
            addi  r11, r11, 1               /* Add 1 */
            stw   r11, (r9)                 /* Store the counted value. Now the SECONDS_COUNTER is updated */

            movia r4, HEX0_0
            mov  r5, r11
            call UPDATE_TIMER_DISPLAY       /* Update the timer display */

            movia  r9, ALARM_TRIGGER_VALUE
            ldw   r9, (r9)                 /* Get the alert trigger value */
            
            bne r9, r11, VALIDATE_SECONDS_COUNT_END  /* If the alert trigger value is NOT equal to counted seconds, jump to end  */   

            movia  r9, ALARM_TRIGGERED
            movi  r11, 1
            stw   r11, (r9)                 /* As they're equals, update the state of the alarm */

            movia r9, ALARM_STATE
            stw   r0, (r9)                  /* Initialize the alarm state */

            movia r5, RED_LEDS_ON_MASK
            call UPDATE_RED_LEDS            /* Turn the red LEDs on */

            br VALIDATE_SECONDS_COUNT_END

            TURN_SECONDS_COUNTER_STATE_EQUALS_1:    /* Here, the seconds counter state will be set as 1, this means that in the next timer interruption the second will be updated. */
                movia r9, SECONDS_COUNTER_STATE
                movi  r11, 1
                stw   r11, (r9)

        VALIDATE_SECONDS_COUNT_END:
            ldw     ra,  0(sp)
            ldw     r9,  4(sp)
            ldw     r11, 8(sp)
            ldw     r5, 12(sp)
            ldw     r3, 16(sp)
            addi    sp, sp, 20
    ret

    ON_TIMER_INTERRUPTION:
        subi    sp, sp, 24
        stw     ra,  0(sp)
        stw     r9,  4(sp)
        stw     r11, 8(sp)
        stw     r5, 12(sp)
        stw     r2, 16(sp)
        stw     r4, 20(sp)

        movia r9, TIMER
        movi r11, ITR_TIMER
        stwio r11, 0(r9)		# resetando o timer

        call VALIDATE_SECONDS_COUNT

        VALIDATING_IF_ALARM_TRIGGERED:
            movia r9, ALARM_TRIGGERED
            ldw   r9, (r9)

            beq r9, r0, ON_TIMER_INTERRUPTION_END /* If the alarm has not been triggered, exit */ 

            movia r9, ALARM_STATE
            ldw   r9, (r9)

            mov  r4, r9
            movi r5, 2
            call DIV_REMAINDER

            bne r2, r0, ALARM_STATE_IS_ODD
            
            ALARM_STATE_IS_EVEN:
                movia r5, RED_LEDS_ON_MASK
                call UPDATE_RED_LEDS
                br VALIDATE_ALARM_STATE

            ALARM_STATE_IS_ODD:
                mov r5, r0
                call UPDATE_RED_LEDS

            VALIDATE_ALARM_STATE:
                # VALIDAR SE R9 NÃO FOI MODIFICADO
                movi r11, 21
                beq  r9, r11, RESET_ALARM_STATE

                movia r11, ALARM_STATE
                addi   r9, r9, 1
                stw    r9, (r11)        /* If the alarm state is not 21, u */
                br     ON_TIMER_INTERRUPTION_END

            RESET_ALARM_STATE:
                movia r11, ALARM_STATE
                stw    r0, (r11)

                movia r11, ALARM_TRIGGERED
                stw    r0, (r11)

        br ON_TIMER_INTERRUPTION_END

        ON_TIMER_INTERRUPTION_END:
            ldw     ra,  0(sp)
            ldw     r9,  4(sp)
            ldw     r11, 8(sp)
            ldw     r5, 12(sp)
            ldw     r2, 16(sp)
            ldw     r4, 20(sp)
            addi    sp, sp, 24
    ret

    /* r5 is the incomming data */
    TIMER_COMMANDS_FINITE_STATE_MACHINE:
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

        movia r8, IS_VALIDATING_LEDS_COMMAND
        ldw   r8, (r8)
        bne   r8, r0, TIMER_COMMANDS_FINITE_STATE_MACHINE_END /* If the LEDs state is being validated, dont validate any state from Timer Command*/

        TIMMER_COMMANDS_STATE_VALIDATION: 
            movia r6, TIMMER_COMMANDS_STATE
            ldw   r7, (r6)

            movi r8, 0
            beq r7, r8, TIMMER_COMMANDS_STATE_00

            movi r8, 1
            beq r7, r8, TIMMER_COMMANDS_STATE_01

            movi r8, 2
            beq r7, r8, TIMMER_COMMANDS_STATE_02

            movi r8, 3
            beq r7, r8, TIMMER_COMMANDS_STATE_03

            movi r8, 4
            beq r7, r8, TIMMER_COMMANDS_STATE_04

            movi r8, 5
            beq r7, r8, TIMMER_COMMANDS_STATE_05

            movi r8, 6
            beq r7, r8, TIMMER_COMMANDS_STATE_06

            movi r8, 7
            beq r7, r8, TIMMER_COMMANDS_STATE_07

            movi r8, 8
            beq r7, r8, TIMMER_COMMANDS_STATE_08

        br TIMER_COMMANDS_FINITE_STATE_MACHINE_END

        TIMMER_COMMANDS_STATE_00:
            movi r8, 'C'
            bne  r5, r8, TIMER_COMMANDS_FINITE_STATE_MACHINE_END

            movi r8, 1      /* the next LEDs state is 1, cause C commes */
            stw  r8, (r6)

            movia r8, IS_VALIDATING_TIMER_COMMAND
            movi  r7, 1
            stw   r7, (r8)  /* Store that now the LEDs command is being validated */

        br TIMER_COMMANDS_FINITE_STATE_MACHINE_END

        TIMMER_COMMANDS_STATE_01:      /* the error is validated in TIMMER_COMMANDS_STATE_01_2; when validate if comes "C2" */
            movi r8, '0'
            bne r5, r8, TIMMER_COMMANDS_STATE_01_1

            movi r8, 2      /* the next Timmer Commands state is 2, cause "C0" commes */
            stw  r8, (r6)
            br TIMER_COMMANDS_FINITE_STATE_MACHINE_END

            TIMMER_COMMANDS_STATE_01_1:
                movi r8, '1'
                bne r5, r8, TIMMER_COMMANDS_STATE_01_2

                movi r8, 8      /* the next Timmer Commands state is 5, cause "C1" commes */
                stw  r8, (r6)
                br TIMER_COMMANDS_FINITE_STATE_MACHINE_END

            TIMMER_COMMANDS_STATE_01_2:
                movi r8, '2'
                movia r3, DIGITS_0_TO_2_TEXT    /* a Digit from 0 to 2 is expected */
                bne r5, r8, TIMMER_COMMANDS_ERROR_STATE

                movi r8, 14      /* the next Timmer Commands state is 8, cause "C2" commes */
                stw  r8, (r6)
                br TIMER_COMMANDS_FINITE_STATE_MACHINE_END

        br TIMER_COMMANDS_FINITE_STATE_MACHINE_END

        TIMMER_COMMANDS_STATE_02:
            movi r8, ' '
            movi r3, ' '    /* 'space' is expected */
            bne r5, r8, TIMMER_COMMANDS_ERROR_STATE
            
            movi r8, 3 /* the next LEDs state is 3, cause "C0 " commes */
            stw  r8, (r6)
        br TIMER_COMMANDS_FINITE_STATE_MACHINE_END

        TIMMER_COMMANDS_STATE_03:
            movi r8, '0'
            movia r3, DIGIT_TEXT                        /* a Digit is expected */
            blt  r5, r8, TIMMER_COMMANDS_ERROR_STATE    /* if lower than char 0, error */

            movi r8, '9'
            bgt  r5, r8, TIMMER_COMMANDS_ERROR_STATE    /* if greather than char '9', error */

            movi r8, 4                                  /* the next state is 4, cause "C0 X" commes */
            stw  r8, (r6)

            movia r7, TIMMER_COMMANDS_TEMPORARY_DECIMAL_MINUTES
            subi  r8, r5, '0'                                   /* fix the number value */
            stw   r8, (r7)                                      /* store the given value as the timer decimal minute value */
        br TIMER_COMMANDS_FINITE_STATE_MACHINE_END

        TIMMER_COMMANDS_STATE_04:
            movi r8, '0'
            movia r3, DIGIT_TEXT                        /* a Digit is expected */
            blt  r5, r8, TIMMER_COMMANDS_ERROR_STATE    /* if lower than char 0, error */

            movi r8, '9'
            bgt  r5, r8, TIMMER_COMMANDS_ERROR_STATE    /* if greather than char '9', error */

            movi r8, 5                                  /* the next state is 5, cause "C0 XX" commes */
            stw  r8, (r6)

            movia r7, TIMMER_COMMANDS_TEMPORARY_UNIT_MINUTES
            subi  r8, r5, '0'                                   /* fix the number value */
            stw   r8, (r7)                                      /* store the given value as the timer unit minute value */
        br TIMER_COMMANDS_FINITE_STATE_MACHINE_END

        TIMMER_COMMANDS_STATE_05:
            movi r8, '0'
            movia r3, DIGIT_TEXT                        /* a Digit is expected */
            blt  r5, r8, TIMMER_COMMANDS_ERROR_STATE    /* if lower than char 0, error */

            movi r8, '9'
            bgt  r5, r8, TIMMER_COMMANDS_ERROR_STATE    /* if greather than char '9', error */

            movi r8, 6                                  /* the next state is 6, cause "C0 XXY" commes */
            stw  r8, (r6)

            movia r7, TIMMER_COMMANDS_TEMPORARY_DECIMAL_SECONDS
            subi  r8, r5, '0'                                   /* fix the number value */
            stw   r8, (r7)                                      /* store the given value as the timer decimal seconds value */
        br TIMER_COMMANDS_FINITE_STATE_MACHINE_END

        TIMMER_COMMANDS_STATE_06:
            movi r8, '0'
            movia r3, DIGIT_TEXT                        /* a Digit is expected */
            blt  r5, r8, TIMMER_COMMANDS_ERROR_STATE    /* if lower than char 0, error */

            movi r8, '9'
            bgt  r5, r8, TIMMER_COMMANDS_ERROR_STATE    /* if greather than char '9', error */

            movi r8, 7                                  /* the next state is 7, cause "C0 XXYY" commes */
            stw  r8, (r6)

            movia r7, TIMMER_COMMANDS_TEMPORARY_UNIT_SECONDS
            subi  r8, r5, '0'                                   /* fix the number value */
            stw   r8, (r7)                                      /* store the given value as the timer unit seconds value */
        br TIMER_COMMANDS_FINITE_STATE_MACHINE_END

        TIMMER_COMMANDS_STATE_07:
            movi r8, '\n'
            movia r3, ENTER_TEXT            /* a "enter" is expected */
            bne r5, r8, TIMMER_COMMANDS_ERROR_STATE

            movi r8, 0                      /* the next state is 0, cause "C0 XXYY\n" commes */
            stw  r8, (r6)

            movia r7, TIMMER_COMMANDS_TEMPORARY_UNIT_SECONDS
            ldw r8, (r7)                                        /* Now, r8 will store the parsed seconds value */

            movia r7, TIMMER_COMMANDS_TEMPORARY_DECIMAL_SECONDS
            ldw   r7, (r7)
            muli  r7, r7, 10                                    /* decimal parsing */
            add r8, r8, r7                                      /* r8 contains the unit and the decimal value from seconds */

            movia r7, TIMMER_COMMANDS_TEMPORARY_UNIT_MINUTES
            ldw   r7, (r7)
            muli  r7, r7, 60                                    /* from minutes to seconds */
            add   r8, r8, r7

            movia r7, TIMMER_COMMANDS_TEMPORARY_DECIMAL_MINUTES
            ldw   r7, (r7)
            muli  r7, r7, 10
            muli  r7, r7, 60
            add   r8, r8, r7                                    /* r8 contains the unit and the decimal value from seconds and minutes */

            movia r7, SECONDS_COUNTER
            stw   r8, (r7)

            movia r4, HEX0_0
            mov  r5, r8
            call UPDATE_TIMER_DISPLAY       /* Update the timer display */

            movia r8, IS_VALIDATING_TIMER_COMMAND
            stw   r0, (r8)  /* Store that the timmer commands validation ended. */

        br TIMER_COMMANDS_FINITE_STATE_MACHINE_END

        TIMMER_COMMANDS_STATE_08:
            br TIMMER_COMMANDS_STATE_08

        br TIMER_COMMANDS_FINITE_STATE_MACHINE_END

        TIMMER_COMMANDS_STATE_14:
            movi r8, '\n'
            movia r3, ENTER_TEXT    /* a "enter" is expected */
            bne  r5, r8, TIMMER_COMMANDS_ERROR_STATE

            stw r0, (r6)                    /* the next state is 0, cause "C2\n" commes */
        br TIMER_COMMANDS_FINITE_STATE_MACHINE_END

        TIMMER_COMMANDS_ERROR_STATE:
            mov r7, r5  /* Save the typed char, it will be replaced when calling other functions!!! */

            movia r8, IS_VALIDATING_TIMER_COMMAND
            stw   r0, (r8)  /* Store that the timmer validation ended. */

            movi r8, '\n'
            beq  r7, r8, TIMMER_COMMANDS_ERROR_STATE_PRINT_ERROR

            mov r5, r8
            call PRINT_JTAG_WITHOUT_FILTER      
            /* The entered text was not an '\n', so the pointer is in the same line. Print '\n' */
            /* Remember: the console prints the char typed, so the '\n' would have been written*/

            TIMMER_COMMANDS_ERROR_STATE_PRINT_ERROR:
                mov r4, r7          /* The "print error" r4 is the "obtained data", saved in r7 */
                call PRINT_ERROR

                movi r5, '\n'
                call PRINT_JTAG_WITHOUT_FILTER  /* Print '\n' after the error message */

                movia r8, TIMMER_COMMANDS_STATE
                stw   r0, (r8)                  /* restore the timmer commands state */

            TIMMER_COMMANDS_ERROR_STATE_NEW_LINE_INDICATOR_VALIDATION:
                movi r8, '\n'
                beq  r7, r8, TIMER_COMMANDS_FINITE_STATE_MACHINE_END

                movia r5, NEW_LINE
                call PRINT_JTAG_WITHOUT_FILTER      /* print '> ' */

        br TIMER_COMMANDS_FINITE_STATE_MACHINE_END

        TIMER_COMMANDS_FINITE_STATE_MACHINE_END:
            ldw     r8, 16(sp)
            ldw     r7, 12(sp)
            ldw     r6, 8(sp) 
            ldw     r5, 4(sp)
            ldw     ra, 0(sp)
            addi    sp, sp, 20
    ret
/*** *************** ***/

/*** JTAG functions ***/
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
        call TIMER_COMMANDS_FINITE_STATE_MACHINE

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
/*** ************** ***/

/*** green LEDs functions ***/
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

        movia r8, IS_VALIDATING_TIMER_COMMAND
        ldw   r8, (r8)
        beq   r8, r0, LEDS_END /* If the timer command is being validated, dont validate any state from leds*/

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

        br LEDS_END
    
        LEDS_STATE_00:
            movi r8, 'L'
            bne r5, r8, LEDS_END
            
            movi r8, 1      /* the next LEDs state is 1, cause L commes */
            stw  r8, (r6)

            movia r8, IS_VALIDATING_LEDS_COMMAND
            movi  r7, 1
            stw   r7, (r8)  /* Store that now the LEDs command is being validated */

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
            movia r7, GREEN_LEDS            /* Green LEDs address */
            stwio   r8, (r7)                /* update what LEDs should be on */

            movia r7, LEDS_ON_OFF_STATE     
            stw   r8, (r7)                  /* update the LEDS_ON_OFF_STATE */

            movia r8, IS_VALIDATING_LEDS_COMMAND
            stw   r0, (r8)  /* Store that the leds validation ended. */

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

            movia r7, GREEN_LEDS            /* Green LEDs address */
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

            movia r7, GREEN_LEDS            /* Green LEDs address */
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

            movia r7, GREEN_LEDS            /* Green LEDs address */
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

            movia r7, GREEN_LEDS            /* Green LEDs address */
            stwio r8, (r7)                  /* update the LEDs with the new mask */

            movia r7, LEDS_ON_OFF_STATE
            stw r8, (r7)                    /* update the LEDS_ON_OFF_STATE with the new mask */

        br LEDS_END

        LEDS_STATE_11:
            movi r8, '\n'
            movia r3, ENTER_TEXT    /* a "enter" is expected */
            bne r5, r8, LEDS_ERROR_STATE

            stw  r0, (r6)                   /* the next LEDs state is 0, cause "L5\n" commes */

            movia r7, GREEN_LEDS                  /* Green LEDs address */
            stwio r0, (r7)                  /* turn off all the LEDs */

            movia r8, LEDS_ON_OFF_STATE     /* get the LEDS_ON_OFF_STATE address */
            stw   r0, (r8)                  /* update LEDS_ON_OFF_STATE with all disabled */

        br LEDS_END

        LEDS_ERROR_STATE:
            mov r7, r5  /* Save the typed char, it will be replaced when calling other functions!!! */

            movia r8, IS_VALIDATING_LEDS_COMMAND
            stw   r0, (r8)  /* Store that the leds validation ended. */

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
/*** ******************** ***/

/*** red LEDs functions ***/
    /*** r5 is the mask ***/
    UPDATE_RED_LEDS:
        addi sp, sp, -4
        stw  r9, 0(sp)

        movia  r9, RED_LEDS
        stwio    r5, (r9)

        ldw  r9, 0(sp)
        addi sp, sp, 4
    ret
/*** ****************** ***/

/*** 8bit display functions ***/
    /* r5 is the digit */
    GET_DISPLAY_MASK_FROM_DIGIT:
        subi    sp, sp, 4
        stw     r9,  0(sp)

        movi r9, 0
        bne  r5, r9, GET_DISPLAY_MASK_FROM_DIGIT_1
        movi r2, 0b0111111 # 0
        br GET_DISPLAY_MASK_FROM_DIGIT_END

        GET_DISPLAY_MASK_FROM_DIGIT_1:
            movi r9, 1
            bne  r5, r9, GET_DISPLAY_MASK_FROM_DIGIT_2
            movi r2, 0b0000110 # 1
            br GET_DISPLAY_MASK_FROM_DIGIT_END

        GET_DISPLAY_MASK_FROM_DIGIT_2:
            movi r9, 2
            bne  r5, r9, GET_DISPLAY_MASK_FROM_DIGIT_3
            movi r2, 0b1011011 # 2
            br GET_DISPLAY_MASK_FROM_DIGIT_END

        GET_DISPLAY_MASK_FROM_DIGIT_3:
            movi r9, 3
            bne  r5, r9, GET_DISPLAY_MASK_FROM_DIGIT_4
            movi r2, 0b1001111 # 3
            br GET_DISPLAY_MASK_FROM_DIGIT_END

        GET_DISPLAY_MASK_FROM_DIGIT_4:
            movi r9, 4
            bne  r5, r9, GET_DISPLAY_MASK_FROM_DIGIT_5
            movi r2, 0b1100110 # 4
            br GET_DISPLAY_MASK_FROM_DIGIT_END

        GET_DISPLAY_MASK_FROM_DIGIT_5:
            movi r9, 5
            bne  r5, r9, GET_DISPLAY_MASK_FROM_DIGIT_6
            movi r2, 0b1101101 # 5
            br GET_DISPLAY_MASK_FROM_DIGIT_END

        GET_DISPLAY_MASK_FROM_DIGIT_6:
            movi r9, 6
            bne  r5, r9, GET_DISPLAY_MASK_FROM_DIGIT_7
            movi r2, 0b1111101 # 6
            br GET_DISPLAY_MASK_FROM_DIGIT_END

        GET_DISPLAY_MASK_FROM_DIGIT_7:
            movi r9, 7
            bne  r5, r9, GET_DISPLAY_MASK_FROM_DIGIT_8
            movi r2, 0b0000111 # 7
            br GET_DISPLAY_MASK_FROM_DIGIT_END

        GET_DISPLAY_MASK_FROM_DIGIT_8:
            movi r9, 8
            bne  r5, r9, GET_DISPLAY_MASK_FROM_DIGIT_9
            movi r2, 0b1111111 # 8
            br GET_DISPLAY_MASK_FROM_DIGIT_END

        GET_DISPLAY_MASK_FROM_DIGIT_9:
            movi r9, 9
            bne  r5, r9, GET_DISPLAY_MASK_FROM_DIGIT_UNKWON_DIGIT
            movi r2, 0b1100111 # 9
            br GET_DISPLAY_MASK_FROM_DIGIT_END

        GET_DISPLAY_MASK_FROM_DIGIT_UNKWON_DIGIT:
            movi r9, 8
            movi r2, 0 # nothing

        GET_DISPLAY_MASK_FROM_DIGIT_END:
            ldw     r9,  0(sp)
            addi    sp, sp, 4
    ret

    /*  r4 is the display base address
        r5 is the seconds to display (that will be properly turned to minutes) */
    UPDATE_TIMER_DISPLAY:
        addi  sp, sp, -44
        stw   ra,  0(sp)
        stw   r2,  4(sp)
        stw   r4,  8(sp)
        stw   r5, 12(sp)
        stw   r7, 16(sp)
        stw   r8, 20(sp)
        stw   r9, 24(sp)
        stw  r10, 28(sp)
        stw  r11, 32(sp)
        stw  r12, 36(sp)
        stw  r13, 40(sp)

        mov r13, r4                 # store the display base address

        movi r7, 60                 # r7 = from seconds to minutes
        div  r8, r5, r7             # r8 = counted minutes (to show)

        mov  r4, r5
        mov  r5, r7
        call DIV_REMAINDER          # get the remainder from (TOTAL counted time in seconds / 60 seconds)
        mov  r9, r2                 # r9 = counted seconds (to show)

        movi r10, 0                 # r10 will contain the mask to show on the display
        movi r11, 10                # r11 will be used to divide values by 10

        UPDATE_TIMER_DISPLAY_PREPARE_SECONDS:
            div  r12, r9, r11                       # r12 = decimal value in the counted seconds
            mov r5, r12
            call GET_DISPLAY_MASK_FROM_DIGIT        # r2 = the mask to r12
            slli r2, r2, 8                          # as the second's decimal value must be show in the second display, rotate it by 8
            or   r10, r10, r2

            mov r4, r9
            mov r5, r11
            call DIV_REMAINDER

            mov r5, r2                          # r2 contains the unit value from counted seconds
            call GET_DISPLAY_MASK_FROM_DIGIT
            or   r10, r10, r2                   # as the second's unit value must be show in the first display, dont rotate
            # here, the seconds mask is ok
        
        UPDATE_TIMER_DISPLAY_PREPARE_MINUTES:
            div  r12, r8, r11                       # r12 = decimal value in the counted minutes
            mov r5, r12
            call GET_DISPLAY_MASK_FROM_DIGIT        # r2 = the mask to r12
            slli r2, r2, 24                         # as the minutes's decimal value must be show in the fourth display, rotate it by 24
            or   r10, r10, r2

            mov r4, r8
            mov r5, r11
            call DIV_REMAINDER

            mov r5, r2                              # r2 contains the unit value from counted seconds
            call GET_DISPLAY_MASK_FROM_DIGIT
            slli r2, r2, 16                         # as the minutes's decimal value must be show in the third display, rotate it by 16
            or   r10, r10, r2
        # here, the minutes mask is ok
        
        stwio r10, (r13)
        
        ldw   ra,  0(sp)
        ldw   r2,  4(sp)
        ldw   r4,  8(sp)
        ldw   r5, 12(sp)
        ldw   r7, 16(sp)
        ldw   r8, 20(sp)
        ldw   r9, 24(sp)
        ldw  r10, 28(sp)
        ldw  r11, 32(sp)
        ldw  r12, 36(sp)
        ldw  r13, 40(sp)
        addi  sp, sp, 44
    ret
/*** ********************** ***/

/*** Interruption functions ***/
    START_LISTENING_INTERRUPTIONS:
        addi  sp, sp, -4
        stw  r10, 0(sp)

        movi  r10, 1
        wrctl status, r10	# habilita interrupção no processador (PIE)
        
        ldw  r10, 0(sp)
        addi  sp, sp, 4
    ret

    INITIALIZE_LOADED_INTERRUPTIONS:
        addi sp, sp, -4
        stw  r9, 0(sp)

        movia  r9, ENABLED_INTERRUPTIONS
        ldw    r9, (r9)

        wrctl ienable, r9

        ldw  r9, 0(sp)
        addi sp, sp, 4
    ret
/*** ********************** ***/

/*** Math functions ***/
    /* r4 = a, r5 = b; r2 = remainder(a/b) */
    DIV_REMAINDER:
        addi sp, sp, -8
        stw  r7, 0(sp)
        stw  r8, 4(sp)

        div  r7, r4, r5     # r7 = integer result
        
        mul  r8, r5, r7
        sub  r8, r4, r8     # r8 = remainder
        mov r2, r8

        ldw  r7, 0(sp)
        ldw  r8, 4(sp)
        addi sp, sp, 8
    ret
/*** ************** ***/

/* addresses */
    .equ SWITCHES,  0x10000040
    .equ RED_LEDS,      0x10000000
    .equ GREEN_LEDS,      0x10000010
    .equ JTAG,      0x10001000
    .equ TIMER,     0x10002000
    .equ HEX0_0, 0x10000020
/*************/

/* masks */
    .equ EVEN_LEDS, 0b010101010
    .equ ODD_LEDS,  0b101010101
    .equ SWITCHES_LEDS_MASK, 0b111111111
    .equ RED_LEDS_ON_MASK, 0b111111111111111111
/*********/

.equ ITR_TIMER, 0b1     # interuption timmer
.equ TIMER_BASE_PERIOD, 25000000        # 500 ms
.equ TIMER_PERIOD_MULTIPLIER, 1

/* Strings */
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

    DIGITS_0_TO_2_TEXT:
    .asciz "0~2"

    EXPECTED:
    .asciz "Era esperado ["

    OBTAINED:
    .asciz "] mas foi obtido ["

    OBTAINED_END:
    .asciz "]."
/***********/

/* Timer variables */
    ALARM_TRIGGERED:                /* Indica se o alarme foi disparado */
    .word 0

    ALARM_STATE:                    /* Estado do alarme (de 0 até 21) */
    .word 0

    ALARM_TRIGGER_VALUE:
    .word 0

    IS_COUNTING_SECONDS:            /* Indica se deve contar os segundos */
    .word 1

    SECONDS_COUNTER:                /* Contador de segundos */
    .word 0

    SECONDS_COUNTER_STATE:          /* Estado do contador de segundos (0 ou 1) */
    .word 0

    TIMMER_COMMANDS_STATE:
    .word 0

    TIMMER_COMMANDS_TEMPORARY_DECIMAL_MINUTES:      /* Temporary value from variable SECONDS_COUNTER during the timmer command*/
    .word 0

    TIMMER_COMMANDS_TEMPORARY_UNIT_MINUTES:      /* Temporary value from variable SECONDS_COUNTER during the timmer command*/
    .word 0

    TIMMER_COMMANDS_TEMPORARY_DECIMAL_SECONDS:      /* Temporary value from variable SECONDS_COUNTER during the timmer command*/
    .word 0

    TIMMER_COMMANDS_TEMPORARY_UNIT_SECONDS:      /* Temporary value from variable SECONDS_COUNTER during the timmer command*/
    .word 0

    IS_VALIDATING_TIMER_COMMAND:
    .word 0

/*******************/

ENABLED_INTERRUPTIONS:          /* Variáveis relacionadas ao timer */
.word 0

IS_VALIDATING_LEDS_COMMAND:
.word 0

LEDS_STATE:
.word 0

LEDS_TARGET:
.word 0

LEDS_ON_OFF_STATE:
.word 0
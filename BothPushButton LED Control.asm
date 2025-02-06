;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
_main
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer
SetupP1     bic.b   #BIT0,&P1OUT            ; sets up the Red LED
            bis.b   #BIT0,&P1DIR
            bic.b   #BIT7,&P9OUT            ; sets up the Green LED
            bis.b   #BIT7,&P9DIR

            bic.b   #BIT1+BIT2,&P1DIR       ; sets up the buttons
            bis.b   #BIT1+BIT2,&P1REN
            bis.b   #BIT1+BIT2,&P1OUT

UnlockGPIO  bic.w   #LOCKLPM5,&PM5CTL0      ; disables GPIO

StartTimer
            bis.w   #TASSEL_1 + ID_1 + MC_1, &TA0CTL ; ACLK, Up mode
            mov.w   #49152, &TA0CCR0        ; Set CCR0 for ~3-second delay (adjust for clock settings)
            bis.w   #TACLR, &TA0CTL         ; Clear timer flag

MainLoop
			bit.b	#BIT1+BIT2, &P1IN
			jnz	  	MainLoop
			bis.w 	#TACLR, &TA0CTL
			bic.w 	#TAIFG, &TA0CTL
			jmp 	WaitLoop

WaitLoop
			bit.b	#BIT1+BIT2, &P1IN
			jnz		MainLoop
			bit.w	#TAIFG, &TA0CTL
			jz		WaitLoop

BlinkLoop
			bit.b 	#BIT1+BIT2, &P1IN
			jnz		MainLoop
            bis.b   #BIT0, &P1OUT           ; Turn on red LED (P1.0)
            bis.b   #BIT7, &P9OUT           ; Turn on green LED (P9.7)
            call    #Delay                  ; Call delay subroutine

            bic.b   #BIT0, &P1OUT           ; Turn off red LED
            bic.b   #BIT7, &P9OUT           ; Turn off green LED
			bit.b 	#BIT1+BIT2, &P1IN
			jnz		MainLoop
            call    #Delay                  ; Call delay subroutine
			jmp 	BlinkLoop

Delay
            mov.w   #50000, R5              ; Load delay value for short delay
DelayLoop
            dec.w   R5                      ; Decrement delay counter
            jnz     DelayLoop               ; Loop until counter reaches zero
            ret
;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            

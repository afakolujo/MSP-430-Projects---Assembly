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
            bic.b   #BIT1,&P1DIR       		; sets up the button
            bis.b   #BIT1,&P1REN
            bis.b   #BIT1,&P1OUT

UnlockGPIO  bic.w   #LOCKLPM5,&PM5CTL0      ; disables GPIO

StartTimer
            bis.w   #TASSEL__SMCLK+ MC_1 + ID_3 + TAIE, &TA0CTL ; ACLK, Up mode
            ;bis.w	#TAIDEX_1,&TA0EX0
            mov.w   #62499, &TA0CCR0        ; Set CCR0 for delay (adjust for clock settings)
            bis.w   #TACLR, &TA0CTL         ; Clear timer flag

btnwait		bit.b	#BIT1, &P1IN			; tests if the buttons are pressed
			jnz		btnwait
MainLoop
			mov		R15,R14					
			and		#0xF000,R14				; initializes the first
			swpb	R14						; swaps the high bytes with low to initialize the first value
			rram	#3,R14					; rolls the other three values to the right
			mov.w	MaskTable(R14),R13		; masks the value 
			call	#MorseCodeDriver		; finds the equivalent in the look up table
			call 	#Delay					; delays for 0.5 seconds
			call	#Delay					; delays for 0.5 seconds
			call	#Delay					; delays for 0.5 seconds
			rlam	#4,R15					; rolls the values to the left
			jnz		MainLoop
			jmp $							
			nop
;-------------------------------------------------------------------------------

MorseCodeDriver
			bit.w	#BITF,R13
			jz		OFF
			bis.b	#BIT0,P1OUT
			jmp		ON

OFF			bic.b	#BIT0,&P1OUT
ON
			call    #Delay
			rla		R13
			jnz		MorseCodeDriver
			bic.b 	#BIT0,&P1OUT

Delayend    bis		#TACLR,&TA0CTL
			bic		#TAIFG,&TA0CTL

			call    #Delay
			ret

Delay		bis		#TACLR,&TA0CTL
			bic		#TAIFG,&TA0CTL

Wait		bit		#TAIFG,&TA0CTL
			jz		Wait
			ret
; Main loop here
;-------------------------------------------------------------------------------
MaskTable	.word	0, 0xA000, 0xE800, 0xE000
			.word	0xA800, 0xBA00, 0xEE00, 0xEEE0
			.word	0x8000, 0xEA00, 0xAE00, 0xEBA0
			.word	0xBA80, 0xEA80, 0xBBA0, 0xAE80
                                            

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

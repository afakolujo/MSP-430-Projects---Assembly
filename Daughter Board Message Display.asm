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

;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global _main
            .global __STACK_END
            .sect   .stack                  ; Make stack linker segment ?known?

            .text                           ; Assemble to Flash memory
            .retain                         ; Ensure current section gets linked
            .retainrefs

SEGA        .set    BIT0 ; P2.0
SEGB        .set    BIT1 ; P2.1
SEGC        .set    BIT2 ; P2.2
SEGD        .set    BIT3 ; P2.3
SEGE        .set    BIT4 ; P2.4
SEGF        .set    BIT5 ; P2.5
SEGG        .set    BIT6 ; P2.6
SEGDP       .set    BIT7 ; P2.7

DIG1        .set    BIT0 ; P3.0
DIG2        .set    BIT1 ; P3.1
DIG3        .set    BIT2 ; P3.2
DIG4        .set    BIT3 ; P3.3
DIGCOL      .set    BIT7 ; P3.7

digit       .set    R4   ; Set of flags for state machine
display     .set    R5   ; Display digits
digit1		.set	R7
digit2		.set	R8
digit3		.set	R9
digit4		.set	R10
_main
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w #WDTPW+WDTCNTCL+WDTTMSEL+WDTIS_7+WDTSSEL__ACLK,&WDTCTL ; Interval mode with ACLK
			bis.w #WDTIE, &SFRIE1                                       ; enable interrupts for the watchdog

SetupSeg   ; bic.b   #SEGA+SEGB+SEGC+SEGD+SEGE+SEGF+SEGG+SEGDP,&P2OUT
           ; bic.b   #DIG1+DIG2+DIG3+DIG4+DIGCOL,&P3OUT
            bis.b   #SEGA+SEGB+SEGC+SEGD+SEGE+SEGF+SEGG,&P2DIR
            bis.b   #DIG1+DIG2+DIG3+DIG4,&P3DIR
            bic.b   #SEGA+SEGB+SEGC+SEGD+SEGE+SEGF+SEGG+SEGDP,&P2OUT
            bic.b   #DIG1+DIG2+DIG3+DIG4+DIGCOL,&P3OUT

;SetupTA0	mov.w   #CCIE,&TA0CCTL0           ; TACCR0 interrupt enabled
            ;mov.w   #49999,&TA0CCR0           ; count to 49999 for 50ms delay
            ;bis.w   #TASSEL__SMCLK+MC__UP,&TA0CTL ; SMCLK no input divisions

SetupTA1	mov.w   #CCIE,&TA1CCTL0            ; TACCR0 interrupt enabled
            mov.w   #62499,&TA1CCR0             ; 0.5s delay
            mov.w   #TASSEL__SMCLK+MC__UP+ID_3,&TA1CTL  ; SMCLK, continuous mode, /8

UnlockGPIO  bic.w   #LOCKLPM5,&PM5CTL0      ; Disable the GPIO power-on default
                                            ; high-impedance mode to activate
                                            ; previously configured port settings


			mov.w	#5, digit
			mov 	#MSG, display

			nop
			bis.b   #GIE, SR                ; enable all interrupts
			nop
			jmp		$

CHARS
            .byte   SEGA+SEGB+SEGC+SEGD+SEGE+SEGF      ; 0
            .byte        SEGB+SEGC                     ; 1
            .byte   SEGA+SEGB+     SEGD+SEGE+     SEGG ; 2
            .byte   SEGA+SEGB+SEGC+SEGD+          SEGG ; 3
            .byte        SEGB+SEGC+          SEGF+SEGG ; 4
            .byte   SEGA+     SEGC+SEGD+     SEGF+SEGG ; 5
            .byte   SEGA+     SEGC+SEGD+SEGE+SEGF+SEGG ; 6
            .byte   SEGA+SEGB+SEGC                     ; 7
            .byte   SEGA+SEGB+SEGC+SEGD+SEGE+SEGF+SEGG ; 8
            .byte   SEGA+SEGB+SEGC+SEGD+     SEGF+SEGG ; 9
            .byte	SEGA+          SEGD+SEGE+SEGF+SEGG ; E
            .byte	SEGA+          SEGD+SEGE+SEGF	   ; C
            .byte	                     SEGE+    SEGG ; r
            .byte 								  SEGG ; Dash
            .byte	0x00							   ; Space

MSG
			.byte	14
			.byte	14
			.byte	14
			.byte	14
			.byte	10
			.byte	11
			.byte	10
			.byte	13
			.byte	3
			.byte	3
			.byte	6
			.byte	2
			.byte	13
			.byte	12
			.byte	1
			.byte	1
			.byte	8
			.byte	2
			.byte	9
			.byte	1
			.byte	1
			.byte	9

STOP
			.byte	14
			.byte	14
			.byte	14
			.byte	14

MSGLength	.equ	22

sDIG        .byte   0
			.byte   DIG4
			.byte   DIG3
			.byte   DIG2
			.byte   DIG1
			.byte	0

TIMER1_A0_ISR
			inc		display
			cmp		#STOP, display
			jne		T1END
			mov		#MSG, display


;ChangeDigit

;			bic.b	#DIG1+DIG2+DIG3+DIG4, &P3OUT
;			mov.b	MSG(digit), display

;			bis.b	CHARS(display), &P2OUT
;			mov.b   @display, R6
;			bis.b	CHARS(R6), P2OUT

T1END:		reti

WDT_ISR

			push	display

			rra		digit
			jnz		UpdateDisplay
			mov		#DIG4, digit
;			reti

UpdateDisplay

			clr.b	P2OUT
			mov.b	digit, P3OUT

Condition1
			cmp		#DIG1, digit
			jz		IsDigit1

Condition2
			cmp		#DIG2, digit
			jz		IsDigit2

Condition3
			cmp		#DIG3, digit
			jz		IsDigit3

Condition4
			cmp		#DIG4, digit
			jz		IsDigit4

IsDigit1
			jmp		UpdateDigit

IsDigit2
			add		#1, display
			jmp		UpdateDigit

IsDigit3
			add		#2, display
			jmp		UpdateDigit

IsDigit4
			add		#3, display
			jmp		UpdateDigit

UpdateDigit

			mov.b   @display, R6
			mov.b	CHARS(R6), P2OUT
ISREnd
			pop		display
			reti
			nop


 ;MSG
 			;.byte
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            .sect   WDT_VECTOR              ; Watchdog Timer
            .short  WDT_ISR
            .sect   TIMER1_A0_VECTOR        ; Timer1_A3 CC0 Interrupt Vector
            .short  TIMER1_A0_ISR
            .end

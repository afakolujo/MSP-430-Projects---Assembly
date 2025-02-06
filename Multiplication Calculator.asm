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
            .global _main
            .global __STACK_END
            .sect   .stack                  ; Make stack linker segment ?known?

            .text                           ; Assemble to Flash memory
            .retain                         ; Ensure current section gets linked
            .retainrefs
TRUE		.set	1
FALSE		.set	0

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

BTN1		.set	BIT7 ; P4.7
BTN2		.set	BIT3 ; P1.3
BTN3		.set    BIT5 ; P1.5

digit       .set    R4   ; Set of flags for state machine
a			.set    R5
abcd		.set    R6
b			.set    R7
bbcd		.set    R8
m			.set    R9
mbcd		.set    R10
state		.set    R11
display		.set    R12

static		.set	0
AA			.set	1
BB			.set	2
A_B			.set	3

_main
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w #WDTPW+WDTCNTCL+WDTTMSEL+WDTIS_7+WDTSSEL__ACLK,&WDTCTL ; Interval mode with ACLK
			bis.w #WDTIE, &SFRIE1                                       ; enable interrupts for the watchdog

SetupSeg    bic.b   #SEGA+SEGB+SEGC+SEGD+SEGE+SEGF+SEGG+SEGDP,&P2OUT
            bic.b   #DIG1+DIG2+DIG3+DIG4+DIGCOL,&P3OUT
            bis.b   #SEGA+SEGB+SEGC+SEGD+SEGE+SEGF+SEGG+SEGDP,&P2DIR
            bis.b   #DIG1+DIG2+DIG3+DIG4+DIGCOL,&P3DIR
            bic.b   #SEGA+SEGB+SEGC+SEGD+SEGE+SEGF+SEGG+SEGDP,&P2OUT
            bis.b   #DIGCOL,&P3OUT

SetupPB		bic.b   #BTN1, &P4DIR
			bic.b   #BTN3+BTN2, &P1DIR
			bis.b   #BTN1, &P4REN
			bis.b   #BTN3+BTN2, &P1REN
			bis.b   #BTN1, &P4OUT
			bis.b   #BTN3+BTN2, &P1OUT
			bis.b   #BTN1, &P4IES
			bis.b   #BTN3+BTN2, &P1IES
			bis.b   #BTN1, &P4IE
			bis.b   #BTN3+BTN2, &P1IE

SetupADC12  bis.w   #ADC12SHT0_10+ADC12MSC+ADC12ON, &ADC12CTL0
			bis.w   #ADC12SHP+ADC12SSEL_3+ADC12CONSEQ_2,&ADC12CTL1    ; Make ADC in consecutive mode
			bis.w   #ADC12RES_2,&ADC12CTL2  ; 12-bit conversion results
            bis.w   #ADC12INCH_10,&ADC12MCTL0; A10 ADC input select; Vref=AVCC
            bis.w   #ADC12IE0,&ADC12IER0    ; Enable ADC conv complete interrupt
			bis.w   #ADC12ENC+ADC12SC, &ADC12CTL0 ; Start conversions

UnlockGPIO  bic.w   #LOCKLPM5,&PM5CTL0      ; Disable the GPIO power-on default
                                            ; high-impedance mode to activate
                                            ; previously configured port settings

			bic.b   #BTN2+BTN3, &P1IFG      ; Reset interrupts here,
			bic.b   #BTN1, &P4IFG           ; unlocking the GPIO tends to trigger an interrupt


			clr		R14
			clr		R13
			mov		#0, R12
			mov		#8, digit
			mov		#0, a
			mov		#0, abcd
			mov		#0, b
			mov		#0, bbcd
			mov		#0, m
			mov		#0, mbcd




SetupTA0	mov.w   #CCIE,&TA0CCTL0           ; TACCR0 interrupt enabled
            mov.w   #49999,&TA0CCR0           ; count to 49999 for 50ms delay
            bis.w   #TASSEL__SMCLK,&TA0CTL ; SMCLK no input divisions


;SetupTA1	mov.w   #CCIE,&TA1CCTL0            ; TACCR0 interrupt enabled
 ;           mov.w   #62499,&TA1CCR0             ; 0.5s delay
  ;          mov.w   #TASSEL__SMCLK+MC__UP+ID_3,&TA1CTL  ; SMCLK, continuous mode, /8

;SetupTA2	mov.w   #CCIE,&TA2CCTL0            ; TACCR0 interrupt enabled
 ;           mov.w   #9999,&TA2CCR0             ; 10ms delay
  ;          mov.w   #TASSEL__SMCLK+MC__UP+ID_0,&TA2CTL  ; SMCLK, continuous mode, /8

            nop
			bis.b   #GIE, SR                ; enable all interrupts
			nop
			jmp		$


;-------------------------------------------------------------------------------
ADC12_ISR;  ADC12 interrupt service routine
;-------------------------------------------------------------------------------
            add.w   &ADC12IV,PC             ; add offset to PC
            reti                            ; Vector  0:  No interrupt
            reti                            ; Vector  2:  ADC12MEMx Overflow
            reti                            ; Vector  4:  Conversion time overflow
            reti                            ; Vector  6:  ADC12HI
            reti                            ; Vector  8:  ADC12LO
            reti                            ; Vector 10:  ADC12IN
            jmp     MEM0                    ; Vector 12:  ADC12MEM0 Interrupt
            reti                            ; Vector 14:  ADC12MEM1
            reti                            ; Vector 16:  ADC12MEM2
            reti                            ; Vector 18:  ADC12MEM3
            reti                            ; Vector 20:  ADC12MEM4
            reti                            ; Vector 22:  ADC12MEM5
            reti                            ; Vector 24:  ADC12MEM6
            reti                            ; Vector 26:  ADC12MEM7
            reti                            ; Vector 28:  ADC12MEM8
            reti                            ; Vector 30:  ADC12MEM9
            reti                            ; Vector 32:  ADC12MEM10
            reti                            ; Vector 34:  ADC12MEM11
            reti                            ; Vector 36:  ADC12MEM12
            reti                            ; Vector 38:  ADC12MEM13
            reti                            ; Vector 40:  ADC12MEM14
            reti                            ; Vector 42:  ADC12MEM15
            reti                            ; Vector 44:  ADC12MEM16
            reti                            ; Vector 46:  ADC12MEM17
            reti                            ; Vector 48:  ADC12MEM18
            reti                            ; Vector 50:  ADC12MEM19
            reti                            ; Vector 52:  ADC12MEM20
            reti                            ; Vector 54:  ADC12MEM21
            reti                            ; Vector 56:  ADC12MEM22
            reti                            ; Vector 58:  ADC12MEM23
            reti                            ; Vector 60:  ADC12MEM24
            reti                            ; Vector 62:  ADC12MEM25
            reti                            ; Vector 64:  ADC12MEM26
            reti                            ; Vector 66:  ADC12MEM27
            reti                            ; Vector 68:  ADC12MEM28
            reti                            ; Vector 70:  ADC12MEM29
            reti                            ; Vector 72:  ADC12MEM30
            reti                            ; Vector 74:  ADC12MEM31
            reti                            ; Vector 76:  ADC12RDY

MEM0
			push 	R15
			push 	R14
			mov.w   &ADC12MEM0, R15			; Mov the MEM0 value, clears flags
			rrum	#3, R15					; roll right unassigned 3 times
			rrum	#2,	R15					; roll right unassigned 2 times
			cmp		#99, R15				; compare 99 with r15
			jl		CheckStateAA			; if it's lower jump to check the state
			mov		#99, R15				; move 99 into the register
CheckStateAA
			cmp		#AA, state				; check if the state is to edit the first one
			jne		CheckStateBB			; if it's not AA check BB
			mov		R15, a					; move R15 to a
			call	#DoubleDabble			; call the double dabble function
			mov		R14, abcd				; move R14 into the a binary coded decimal
			swpb    display					; swap bit of the display
			bic     #0xFF, display			; clear the high bits
			bis     abcd, display			; bit set the a binary coded decimal into the display
			swpb	display					; swap the bits again
			jmp		ADC_end

CheckStateBB
			cmp		#BB, state				; check if the state is to edit the second one
			jne		ADC_end					; if it's not BB jump to the end
			mov		R15, b					; move R15 to b
			call	#DoubleDabble			; call the double dabble function
			mov		R14, bbcd				; move R14 into the b binary coded decimal
			bic     #0xFF, display			; clear the high bits
			bis     bbcd, display			; bit set the b binary coded decimal into the display
			jmp		ADC_end

ADC_end
			pop 	R14
			pop 	R15
			reti

DoubleDabble:
			push 	R15
			push 	R13
			push 	R12
			clr 	R14
			mov #16, R12
DabbleLoop
			clrc							; clear carry before shift for 0 padding
			rlc		R15						; shift R15 to R14 through the carry bit
			rlc		R14
			dec		R12
			jz		DabbleRet
DabbleOnes
			mov		R14, R13
			and		#0x000F, R13			; keeps ones mask everything else
			cmp		#0x5, R13
			jl		DabbleTens				; if less than 5 skip dabble
			add		#0x3, R14				; else dabble ones

DabbleTens
			mov		R14, R13
			and		#0x00F0, R13			; keeps tens  mask everything else
			cmp		#0x50, R13
			jl		DabbleHundreds			; if less than 50 skip dabble
			add		#0x30, R14				; else dabble tens

DabbleHundreds
			mov		R14, R13
			and		#0x0F00, R13			; keeps hundreds mask everything else
			cmp		#0x500, R13
			jl		DabbleLoop				; if less than 500 skip dabble
			add		#0x300, R14				; else dabble hundreds
			jmp		DabbleLoop				; else jump back to the dabble loop

DabbleRet
			pop 	R12
			pop 	R13
			pop 	R15
			ret								; R14 contains CHARS values and R15 is 0
;-------------------------------------------------------------------------------
;WDT - Multiplexing
;-------------------------------------------------------------------------------
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
WDT_ISR
			push    display		; pushes the display register into the SP
			rra		digit		; roll right to assess the next number
			jnz		Check_DIG4	; if the number is not zero jump to check the fourth digit
			mov		#8, digit	; move 8 to the register

Check_DIG4
			clr.b	P2OUT
			bic.b	#0x0F, P3OUT	; clear stored digit
			bis.b	digit, P3OUT	; set new digit to be multiplexed
			cmp		#DIG4, digit	; check if the fourth digit if the one being multiplexed
			jne		Check_DIG3		; if not check the next digit
			and		#0xF, display	; mask the digit
			mov.b	CHARS(display), P2OUT ; move the digit from the look up table into the display
			jmp		WDT_ISR_END
Check_DIG3
			rrum	#4, display		; roll right multiple unassigned
			cmp		#DIG3, digit	; check if the third digit if the one being multiplexed
			jne		Check_DIG2
			and		#0xF, display	; mask the digit
			mov.b	CHARS(display), P2OUT ; move the digit from the look up table into the display
			jmp		WDT_ISR_END
Check_DIG2
			rrum	#4, display		; roll right multiple unassigned
			cmp		#DIG2, digit	; check if the second digit if the one being multiplexed
			jne		Check_DIG1
			and		#0xF, display	; mask the digit
			mov.b	CHARS(display), P2OUT ; move the digit from the look up table into the display
			jmp		WDT_ISR_END
Check_DIG1
			rrum	#4, display		; roll right multiple unassigned
			cmp		#DIG1, digit	; check if the first digit if the one being multiplexed
			jne		WDT_ISR_END
			and		#0xF, display	; mask the digit
			mov.b	CHARS(display), P2OUT; move the digit from the look up table into the display
			jmp		WDT_ISR_END
WDT_ISR_END
			pop		display
			reti

;-------------------------------------------------------------------------------
; TA0_ISR
;-------------------------------------------------------------------------------
TIMER0_A0_ISR
 			cmp		#A_B, state		; checks which state
 			jne		CheckBTN1		; if the state isn't equal check the button
 			mov		#static, state	; move static into the state
 			mov		#0, R12			; make everything zero to start at 0
			mov		#0, a
			mov		#0, abcd
			mov		#0, b
			mov		#0, bbcd
			mov		#0, m
			mov		#0, mbcd
 			jmp		TIMER0_A0_ISR_END
CheckBTN1
 			;cmp		#BB, state
 			bit.b   #BTN1, P4IN		; tests if the button is being pressed
 			jnz		CheckBTN2		; if not check if the other button is being pressed
 			mov		#BB, state		; if it is pressed move the state to alter the numbers into the state
CheckBTN2
			bit.b   #BTN2, P1IN		; test the second button
			;cmp		#A_B, state
			jnz		CheckBTN3		; if not check the other button
			mov     a, 		MPY		; multiplication function
			mov     b, 	OP2			; multiplied with the second operand
 			mov		#A_B, state		; move the multiplied A and B into the state
			mov 	RES0, 	m		; moves the result into the multiplicate register
			mov 	m, R15			; move the multiplate into the stack register
			call 	#DoubleDabble	; call the double dabble function
			mov 	R14, mbcd		; move R14 into the multiplied binary coded decimal
			mov 	R14, display	; move it into the display
CheckBTN3
 			;cmp		#AA, state
 			bit.b   #BTN3, P1IN		; check if button 3 is pressed
			jnz		TIMER0_A0_ISR_END ; jump if it's no zero to the end
 			mov		#AA, state		; move the state to alter the first two numbers

TIMER0_A0_ISR_END
			bic     #MC__UP, &TA0CTL; stop the timer
			reti
;-------------------------------------------------------------------------------
; PORT1 ISR
;-------------------------------------------------------------------------------
PORT1_ISR
			clr P1IFG	; clear the flag
			bis #MC__UP+TACLR, &TA0CTL ; start the timer
			reti
;-------------------------------------------------------------------------------
; PORT4 ISR
;-------------------------------------------------------------------------------
PORT4_ISR
			clr P4IFG	; clear the timer
			bis #MC__UP+TACLR, &TA0CTL ; start the timer
			reti
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
            .sect   WDT_VECTOR              ; Watchdog Timer
            .short  WDT_ISR
            .sect   TIMER0_A0_VECTOR        ; Timer1_A3 CC1 Interrupt Vector
            .short  TIMER0_A0_ISR
            .sect   PORT1_VECTOR            ; Port1 Interrupt Vector
            .short  PORT1_ISR
            .sect   PORT4_VECTOR            ; Port4 Interrupt Vector
            .short  PORT4_ISR
            .sect   ADC12_VECTOR            ; ADC12 Vector
            .short  ADC12_ISR               ;
            .end
            

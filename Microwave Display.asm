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
            .global _main
            .global __STACK_END
            .sect   .stack                  ; Make stack linker segment ?known?

            .text                           ; Assemble to Flash memory
            .retain                         ; Ensure current section gets linked
            .retainrefs


PBL			.set	BIT5 ; P1.5
PBM			.set	BIT3 ; P1.3
PBR			.set	BIT7 ; P4.7
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
countdown   .set    R5   ; Display the countdown
running		.set 	R6
blinking	.set	R7

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

UnlockGPIO  bic.w   #LOCKLPM5,&PM5CTL0      ; Disable the GPIO power-on default
                                            ; high-impedance mode to activate
                                            ; previously configured port settings

			bic.b   #BTN2+BTN3, &P1IFG      ; Reset interrupts here,
			bic.b   #BTN1, &P4IFG           ; unlocking the GPIO tends to trigger an interrupt


			mov.w	#5, digit
			clr		countdown
			mov.w	#0, running
			mov.w	#0, blinking


SetupTA0	;mov.w   #CCIE,&TA0CCTL0           ; TACCR0 interrupt enabled
            ;mov.w   #49999,&TA0CCR0           ; count to 49999 for 50ms delay
            bis.w   #TASSEL__SMCLK+MC_2,&TA0CTL ; SMCLK no input divisions


SetupTA1	mov.w   #CCIE,&TA1CCTL0            ; TACCR0 interrupt enabled
            mov.w   #62499,&TA1CCR0             ; 0.5s delay
            mov.w   #TASSEL__SMCLK+MC__UP+ID_3,&TA1CTL  ; SMCLK, continuous mode, /8

SetupTA2	mov.w   #CCIE,&TA2CCTL0            ; TACCR0 interrupt enabled
            mov.w   #9999,&TA2CCR0             ; 10ms delay
            mov.w   #TASSEL__SMCLK+MC__UP+ID_0,&TA2CTL  ; SMCLK, continuous mode, /8

            nop
			bis.b   #GIE, SR                ; enable all interrupts
			nop
			jmp		$
;-------------------------------------------------------------------------------
; TIMER0_A0_ISR
;-------------------------------------------------------------------------------
TIMER0_A0_ISR
			bic		#CCIE+CCIFG, TA0CCTL0	; clears the flag and the interrupt
			bit		#PBL, P1IN				; test the left push button
			jnz		TIMER0_A0_ISR_END
			cmp		#TRUE, running			; test if the timer is running
			jne		TIMER0_A0_ELSE
			mov		#FALSE, running			; stops the timer
			jmp		TIMER0_A0_ISR_END
TIMER0_A0_ELSE
			clrc
			dadd	#0x0100, countdown		; adds 1 second if the left push button is pressed

TIMER0_A0_ISR_END
			reti
;-------------------------------------------------------------------------------
; TIMER0_A1_ISR
;-------------------------------------------------------------------------------

TIMER0_A1_ISR
			bic		#CCIE+CCIFG, TA0CCTL1		; clears the interrupt and flag
			bit		#PBM, P1IN					; test if the middle button is pressed
			jnz		TIMER0_A1_ISR_END
			cmp		#TRUE, running				; if the timer is running
			jne		TIMER0_A1_ELSE
			mov		#FALSE, running				; stops the timer
			jmp		TIMER0_A1_ISR_END
TIMER0_A1_ELSE
			push	countdown					; puts countdown into the stack
			and     #0xFF00, countdown			; toggles the countdown
			cmp		#0, countdown				; tests if the countdown has reached zero
			pop		countdown					; pops it out of the countdown
			jeq		TIMER0_A1_ISR_END			; if it is zero it will reti
			clrc								; clears the carry
			dadd	#0x9900, countdown			; subtracts 1 secound
TIMER0_A1_ISR_END
			reti
;-------------------------------------------------------------------------------
; TIMER1_A0_ISR
;-------------------------------------------------------------------------------
TIMER1_A0_ISR
			cmp		#TRUE, blinking				; tests if the display is blinking
			jne		TIMER1_A0_ELSE
			xor.b	#0xFF, P2DIR
			xor.b	#0xFF, P3DIR
			jmp		TIMER1_A0_ISR_END
TIMER1_A0_ELSE
			bis.b	#0xFF, P2DIR
			bis.b	#0xFF, P3DIR
TIMER1_A0_ISR_END
			reti
;-------------------------------------------------------------------------------
; TIMER2_A0_ISR
;-------------------------------------------------------------------------------
TIMER2_A0_ISR
			cmp		#FALSE, running			; tests if the timer has ended
			jeq		TIMER2_A0_ISR_END

TIMER2_A0_ELSE
			clrc
			dadd	#0x9999, countdown		; subtracts by 1 ms

			cmp		#0,countdown			; tests if the countdown has reached zero
			jne		TIMER2_A0_ISR_END
			mov		#TRUE, blinking			; tests if the display is blinking
			bic		#MC_2, &TA0CTL			; stops the continuous timer
			mov		#FALSE, running			; tests if the timer has ended



TIMER2_A0_ISR_END
			reti
;-------------------------------------------------------------------------------
; PORT1_ISR
;-------------------------------------------------------------------------------
PORT1_ISR
			add		P1IV, PC
			reti
			reti
			reti
			reti
			jmp		PBM_ISR				; jumps to middle button ISR
			reti
			jmp		PBL_ISR				; jumps to left button ISR
			reti
			reti
PBM_ISR
			mov		#TA0R, TA0CCR1		; moves the timer register into the capture compare register
			add		#49999, TA0CCR1		; adds 50ms to the CCR
			bic		#CCIFG, TA0CCTL1	; clears the flag from the capture compare control
			bis		#CCIE, TA0CCTL1		; enables the interrupt
			jmp		STOPTIMER
			reti
PBL_ISR
			mov		#TA0R, TA0CCR0		; moves the timer register into the capture compare register
			add		#49999, TA0CCR0		; adds 50ms to the CCR
			bic		#CCIFG, TA0CCTL0	; clears the flag from the capture compare control
			bis		#CCIE, TA0CCTL0		; enables the interrupt
			jmp		STOPTIMER
			reti

STOPTIMER
			mov		#FALSE, running		; stops the timer
			reti
;-------------------------------------------------------------------------------
; PORT4_ISR
;-------------------------------------------------------------------------------
PORT4_ISR
			bic.b	#PBR, P4IFG			; clears the right push button interrupt flag
			cmp 	#0, countdown
			jeq     PORT4_ISR_END
			mov		#TRUE, running		; starts the timer
PORT4_ISR_END
			reti
;-------------------------------------------------------------------------------
; WDT_ISR
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
; multiplexing
WDT_ISR
			push	countdown
			rra		digit
			jnz		Check_DIG4
			mov		#8, digit

Check_DIG4
			clr.b	P2OUT
			bic.b	#0x0F, P3OUT
			bis.b	digit, P3OUT
			cmp		#DIG4, digit
			jne		Check_DIG3
			and		#0xF, countdown
			mov.b	CHARS(countdown), P2OUT
			jmp		WDT_ISR_END
Check_DIG3
			rrum	#4, countdown
			cmp		#DIG3, digit
			jne		Check_DIG2
			and		#0xF, countdown
			mov.b	CHARS(countdown), P2OUT
			jmp		WDT_ISR_END
Check_DIG2
			rrum	#4, countdown
			cmp		#DIG2, digit
			jne		Check_DIG1
			and		#0xF, countdown
			mov.b	CHARS(countdown), P2OUT
			jmp		WDT_ISR_END
Check_DIG1
			rrum	#4, countdown
			cmp		#DIG1, digit
			jne		WDT_ISR_END
			and		#0xF, countdown
			mov.b	CHARS(countdown), P2OUT
			jmp		WDT_ISR_END
WDT_ISR_END
			pop		countdown
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
            .sect   TIMER0_A1_VECTOR        ; Timer1_A3 CC2 Interrupt Vector
            .short  TIMER0_A1_ISR
            .sect   TIMER1_A0_VECTOR        ; Timer1_A3 CC0 Interrupt Vector
            .short  TIMER1_A0_ISR
            .sect   TIMER2_A0_VECTOR        ; Timer1_A3 CC2 Interrupt Vector
            .short  TIMER2_A0_ISR
            .sect   PORT1_VECTOR            ; Port1 Interrupt Vector
            .short  PORT1_ISR
            .sect   PORT4_VECTOR            ; Port4 Interrupt Vector
            .short  PORT4_ISR
            .end
            

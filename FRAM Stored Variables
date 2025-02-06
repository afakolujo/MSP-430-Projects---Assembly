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
			.global	_main
			.global	__STACK_END
			.sect	.stack
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

			.data
COUNTER 	.word	0
			.text
ShiftReg    .equ    R12                     ; Shift register for debouncing

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END, SP        ; Initialize stack pointer
StopWDT     mov.w   #WDTPW | WDTHOLD, &WDTCTL ; Stop watchdog timer

P1Setup     bic.b   #BIT0, &P1OUT		    ; Sets to be a pull up
			bis.b   #BIT0, &P1DIR

LEDSetup    bic.b   #BIT7, &P9OUT           ; Sets the LEDs up
            bis.b   #BIT7, &P9DIR
            bis.b   #BIT1+BIT2, &P1REN
            bis.b   #BIT1+BIT2, &P1OUT

UnlockGPIO  clr.w   &PM5CTL0   				; Unlock GPIO settings

            mov.w   #0, ShiftReg            ; Initialize shift register for debouncing


;-------------------------------------------------------------------------------
; Main loop: wait for S1 button press, count it, and blink LEDs when S2 button is pressed
;-------------------------------------------------------------------------------

MainLoop
			bit.b   #BIT2, &P1IN        	; Check if the second button is pressed
            jnz     State0              	; If not pressed, loops back to MainLoop

BlinkLEDs
			cmp.w   #0, COUNTER          	; Check if N is zero
            jeq     State0              	; If it is zero, goes to state0 to register a number
            dec.w   COUNTER              	; Decrement the blink counter
            bis.b   #BIT0, &P1OUT       	; Turns red LED on
            bis.b   #BIT7, &P9OUT        	; Turns green LED on
            mov.w   #50000, R5           	; Arbitrary delay to R5

Delay1
            dec.w   R5                   	; Decrements R5
            jnz     Delay1               	; Continues delay if the button isn't pressed

            bic.b   #BIT0, &P1OUT           ; Turns red LED off
            bic.b   #BIT7, &P9OUT           ; Turn green LED off
            mov.w   #50000, R6              ; Arbitrary delay value to R6
Delay2
            dec.w   R5                     ; Decrement R5
            jnz     Delay2                 ; Continues delay if the button isn't pressed


            jmp     BlinkLEDs              ; If it is pressed jump to BlinkLEDs


State0
            rla.w   ShiftReg               ; Shift the shift register
            bit.b   #BIT1, &P1IN           ; Check if button 1 is pressed
            jnz     MainLoop               ; If not pressed jump back to main loop
            bis.w	#BIT0,	ShiftReg

Test        cmp.w   #0xFFFF, ShiftReg      ; Checks if the shift register is full
            jne     State0                 ; If it's not full, goes back and keep debouncing
            inc.w   COUNTER                ; Increment the counter

State1
			rla		ShiftReg			   ; Shift the shift register
			bit.b	#BIT1, &P1IN		   ; Check if button 1 is pressed
			jnz     Test1                  ; If not pressed, jump to test 1
            bis.w	#BIT0,	ShiftReg

Test1		cmp.w   #0x00, ShiftReg        ; Check if the shift register is full of zeros
            jne     State1                 ; If it's not full of zeros, goes back and keep debouncing
            jmp		State0				   ; If it's full, goes back and keep debouncing
			nop

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
            

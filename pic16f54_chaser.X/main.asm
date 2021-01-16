; LED Chaser for PIC16F54
; Copyright 2021 J.B. Langston
;
; Permission is hereby granted, free of charge, to any person obtaining a 
; copy of this software and associated documentation files (the "Software"), 
; to deal in the Software without restriction, including without limitation 
; the rights to use, copy, modify, merge, publish, distribute, sublicense, 
; and/or sell copies of the Software, and to permit persons to whom the 
; Software is furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in
; all copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
; DEALINGS IN THE SOFTWARE.
    
PROCESSOR 16F54
#include <xc.inc>

; Configuration
  CONFIG  OSC = RC              ; Oscillator selection (RC, LP, XT, or HS)
  CONFIG  WDT = OFF             ; Watchdog timer enable
  CONFIG  CP = OFF              ; Code protection
  
; RAM
PSECT MainData,class=RAM,space=1,delta=1,noexec
wait1:	DS 1			; wait counters used by delay loops
wait2:	DS 1
delay:	DS 1			; starting value for outer wait counter

times:	DS 1			; number of times to run an effect

a1:	DS 1			; working registers for PORTA
a2:     DS 1

b1:     DS 1			; working registers for PORTB
b2:     DS 1
  
; STATUS bits
C EQU 0
Z EQU 2
    
; Reset Vector
PSECT resetVec,class=CODE,delta=2
resetVec:
    goto main

; Start of code
PSECT startCode,class=CODE,delta=2
    
main:    
    movlw 0			; all outputs
    tris PORTA
    tris PORTB

    movlw 16			; fill and drain
    movwf delay
    movlw 2
    movwf times
    clrf a2
    clrf b2
    call fill

    movlw 32			; classic cylon
    movwf delay
    movlw 00000001B
    movwf b1
    movlw 0000B
    clrf b2
    clrf a2
    movlw 8
    movwf times
    call shift
    
    movlw 00000011B		; ambidextrous cylon
    movwf b1
    movlw 1100B
    movwf a2
    clrf b2
    clrf a1
    movlw 8
    movwf times
    call shift
    
    movlw 64			; march two by two left/right
    movwf delay
    movlw 11001100B
    movwf b1
    movlw 1100B
    movwf a1
    clrf b2
    clrf a2
    movlw 32
    movwf times
    call shift
    
    goto main

; Note: left/right is from the numerical perspective of the bits
; not necessarily from the physical orientation of the LEDs
    
; slide LEDs in from one direction until display is full,
; then slide them out the other direction
fill:
    rrf a2		; Rotate another full LED into A2/B2 
    rrf b2
    clrf a1		; Initialize single sliding LED in A1/B1
    clrf b1
    bsf b1, 0
fill1:
    call display
    bcf STATUS, C
    rlf b1		; slide the single LED in A1/B1 left
    rlf a1
    movf a1, W		; exit inner loop once slider has hit the full LEDs
    andwf a2, W
    btfss STATUS, Z
    goto fill2
    movf b1, W
    andwf b2, W
    btfss STATUS, Z
    goto fill2
    btfss a1, 4		; exit inner loop once slider hits last LED
    goto fill1
fill2:
    bsf a2, 4		; prepare another full LED to rotate in
    btfss b2, 0
    goto fill
    bcf a2, 4
drain:
    movf a2, W		; Rotate out a full LED and calculate the starting
    rrf a2		; point for sliding LED from the last full LED
    xorwf a2, W
    movwf a1
    movf b2, W
    rrf b2
    xorwf b2, W
    movwf b1
    btfsc STATUS, C	; exit outer loop after all LEDs empty
    goto drain1
    decfsz times	; repeat specified number of times
    goto fill
    retlw 0
drain1:
    bcf STATUS, C	; clear incoming bit
    rlf b1		; slide the single LED left
    rlf a1
    call display
    btfss a1, 4		; exit inner loop once past the last LED
    goto drain1
    goto drain

; shift two display pattern left and right simulataneously
shift:
    bcf STATUS, C	; don't carry garbage into the display
    rlf b1		; A1/B1 goes left
    rlf a1
    rrf a2		; A2/B2 goes right
    rrf b2
    call display
    btfss a1, 3		; reverse once lit led hits the left end
    goto shift
shiftdown:
    bcf STATUS, C	; don't carry garbage into the display
    rrf a1		; Now, A1/B1 goes right
    rrf b1
    rlf b2		; A2/B2 goes left
    rlf a2
    call display
    btfss b1, 0		; reverse once lit led hits the right end
    goto shiftdown
    decfsz times	; repeat specified nubmer of times
    goto shift
    retlw 0

; display the current variables on both ports and wait
display:
    movf b1, W		; send combined B1/B2 to PORTB
    iorwf b2, W
    movwf PORTB
    movf a1, W		; send combined A1/A2 to PORTA
    iorwf a2, W
    movwf PORTA
    movf delay, W	; wait delay X 256 iterations
    movwf wait2
dloop:
    decfsz wait1
    goto dloop
    decfsz wait2
    goto dloop
    retlw 0
    
END resetVec
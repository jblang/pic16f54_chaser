; LCD Driver for PIC16F54
    
PROCESSOR 16F54
#include <xc.inc>

; Configuration
  CONFIG  OSC = RC              ; Oscillator selection bits (RC, LP, XT, or HS)
  CONFIG  WDT = OFF             ; Watchdog timer enable bit
  CONFIG  CP = OFF              ; Code protection bit
  
; RAM
PSECT MainData,class=RAM,space=1,delta=1,noexec
wc1:
    DS 1
wc2:
    DS 1
delay:
    DS 1
cnt:
    DS 1
a1:
    DS 1
b1:
    DS 1
a2:
    DS 1
b2:
    DS 1
    
C EQU 0
Z EQU 2
    
; Reset Vector
PSECT resetVec,class=CODE,delta=2
resetVec:
    goto main

; Start of code
PSECT startCode,class=CODE,delta=2
main:    
    movlw 0
    tris PORTA
    tris PORTB

    movlw 16
    movwf delay
    movlw 2
    movwf cnt
    clrf a2
    clrf b2
    call fill

    movlw 32
    movwf delay
    movlw 00000001B
    movwf b1
    movlw 0000B
    clrf b2
    clrf a2
    movlw 8
    movwf cnt
    call shift
    
    movlw 00000011B
    movwf b1
    movlw 1100B
    movwf a2
    clrf b2
    clrf a1
    movlw 8
    movwf cnt
    call shift
    
    movlw 64
    movwf delay
    movlw 11001100B
    movwf b1
    movlw 1100B
    movwf a1
    clrf b2
    clrf a2
    movlw 32
    movwf cnt
    call shift
    
    goto main
    

fill:
    rrf a2
    rrf b2
    clrf a1
    clrf b1
    bsf b1, 0
fill1:
    call display
    bcf STATUS, C
    rlf b1
    rlf a1
    movf a1, W
    andwf a2, W
    btfss STATUS, Z
    goto fill2
    movf b1, W
    andwf b2, W
    btfss STATUS, Z
    goto fill2
    btfss a1, 4
    goto fill1
fill2:
    bsf a2, 4
    btfss b2, 0
    goto fill
    bcf a2, 4
drain:
    movf a2, W
    rrf a2
    xorwf a2, W
    movwf a1
    movf b2, W
    rrf b2
    xorwf b2, W
    movwf b1
    btfsc STATUS, C
    goto drain1
    decfsz cnt
    goto fill
    retlw 0
drain1:
    bcf STATUS, C
    rlf b1
    rlf a1
    call display
    btfss a1, 4
    goto drain1
    goto drain

; shift two display variables left and right simulataneously
shift:
    bcf STATUS, C
    rlf b1
    rlf a1
    rrf a2
    rrf b2
    call display
    btfss a1, 3
    goto shift
shiftdown:
    bcf STATUS, C
    rrf a1
    rrf b1
    rlf b2
    rlf a2
    call display
    btfss b1, 0
    goto shiftdown
    decfsz cnt
    goto shift
    retlw 0

; display the current variables on both ports and wait
display:
    movf b1, W
    iorwf b2, W
    movwf PORTB
    movf a1, W
    iorwf a2, W
    movwf PORTA
    movf delay, W
    movwf wc2
dloop:
    nop
    decfsz wc1
    goto dloop
    decfsz wc2
    goto dloop
    retlw 0
    
END resetVec
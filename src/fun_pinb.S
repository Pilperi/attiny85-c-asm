/*
;===============================================================================
; ISR attiny85
;
; Globaali funktio pulse_pinb_asm joka näkyy C-puolelle.
;===============================================================================
*/
#define __SFR_OFFSET 0
#include <avr/io.h>

; Assembly-funktio, näkyy C-puolellekin (linkkausvaiheessa)
.global pulse_pinb_asm

;===============================================================================
.section .text

; Tykitä pulssit vuorotellen PINB0/1/2
; Palauta lopuksi lähtötilaan
pulse_pinb_asm:
    ; Nykytila talteen
    IN R18,PORTB
    ; Nollaa kaikki
    OUT PORTB,R1
    ; PINB0
    SBI PINB,PINB0
    SBI PINB,PINB0
    ; PINB1
    SBI PINB,PINB1
    SBI PINB,PINB1
    ; PINB2
    SBI PINB,PINB2
    SBI PINB,PINB2
    ; Palauta alkutilaan
    OUT PORTB,R18
    RET

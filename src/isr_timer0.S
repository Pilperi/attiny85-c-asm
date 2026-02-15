/*
;===============================================================================
; ISR attiny85
;
; Määritelmät heikkojen interrupt-rutiinien vahvoille versioille.
;===============================================================================
*/
#define __SFR_OFFSET 0
#include <avr/io.h>

.global isr_timer0_compa

;===============================================================================
.section .text.isr

isr_timer0_compa:
    DEC R16
    BRNE isr_timer0_compa_done
    LDI R24,lo8(397)
    LDI R25,hi8(397)
_isr_timer0_compa_loop1:
    SBIW R24,1
    BRNE _isr_timer0_compa_loop1
    LDI R18,1<<PINB1
    NOP
    OUT PINB,R18
    NOP
    NOP
    OUT PINB,R18
    LDI R16,20
isr_timer0_compa_done:
    RETI
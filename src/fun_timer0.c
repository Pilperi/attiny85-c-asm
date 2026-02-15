#include "timer0.h"
#include <avr/io.h>

void setup_timer0(void){
    // Kello seis
    TCCR0B = 0x00;
    TCNT0 = 0x00;
    // Aseta Output Compare arvot
    OCR0A = VAL_OCR0A;
    OCR0B = VAL_OCR0B;
    // Aseta Control Register arvot, millä moodilla operoidaan
    // (kello lähtee käyntiin)
    TCCR0A = VAL_TCCR0A;
    TCCR0B = VAL_TCCR0B;
    // Aseta kellon arvo
    TCNT0 = VAL_TCNT;
    // Interrupti-enable
    TIMSK = VAL_TIMSK;
}

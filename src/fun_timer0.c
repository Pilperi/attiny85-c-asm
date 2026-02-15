#include "timer0.h"
#include <avr/io.h>

void setup_timer0(void){
    // Kello seis ja nolliin
    TCCR0B = 0x00;
    TCNT0 = 0x00;
    // Aseta Output Compare arvot
    OCR0A = VAL_OCR0A;
    OCR0B = VAL_OCR0B;
    // Aseta Control Register arvot, millä moodilla operoidaan
    TCCR0A = VAL_TCCR0A; // Isoin osa toimintaparametreista
    TCCR0B = VAL_TCCR0B; // Kello lähtee käyntiin
    // Aseta kellon arvo
    TCNT0 = VAL_TCNT;
    // Interrupti-enable
    TIMSK = VAL_TIMSK;
}

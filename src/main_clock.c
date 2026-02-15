#include <stdint.h>
#include <avr/io.h>
#include "timer0.h"

register uint8_t COUNTER asm("r16");

void setup_pinnit(void){
    PORTB = 0x00;
    DDRB = 0xFF;
}


void main(void){
    setup_timer0();
    setup_pinnit();
    for(;;){
        __asm__("sei");
        __asm__("sleep");
    }
}

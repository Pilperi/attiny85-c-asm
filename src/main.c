#include <stdint.h>
#include <avr/io.h>

// Muualla määritelty assembly-funktio,
// Laittaa PINB0 ylös ja alas, sitten PINB1 ja lopuksi PINB2
extern void pulse_pinb(void);

// Paikallinen vastaava C-funktio
// Pinnejä saa togglattua kirjoittamalla 1 PINB-rekisteriin
void pulse_pinb_c(void){
    // Lähtötila talteen
    uint8_t nyky = PORTB;
    // Kaikki alas
    PORTB = 0;
    // PINB0 ylös ja alas
    PINB = 1<<0;
    PINB = 1<<0;
    // PINB1
    PINB = 1<<1;
    PINB = 1<<1;
    // PINB2
    PINB = 1<<2;
    PINB = 1<<2;
    // Lähtötila takaisin
    PORTB = nyky;
}

void main(void){
    // Pinnit alas ja ulostuloiksi
    PORTB = 0x00;
    DDRB = 0xFF;
    // Tykitä pulsseja PINB0/1/2 vuorotellen
    // Vertaa assembly-toteutusta C-toteutukseen
    for(;;){
        // ASM-toteutus
        pulse_pinb();
        // C-toteutus
        pulse_pinb_c();
    }
}

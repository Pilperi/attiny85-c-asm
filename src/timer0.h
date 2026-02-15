#ifndef _TIMER0_H
#define _TIMER0_H
#include <avr/io.h>
/* Timer0 asetusten arvot */


/* Normal, TOP 0xFF
PB0 päällä 255 µs
PB1 päällä 255 µs
PB1 vaihtaa tilaa 100 µs ennen PB0

Kello looppa aina 0-255-0-255 eli mätsit on aina 255 syklin välein.
Voi siis oikeastaan vaikuttaa vain siihen, kuinka paljon aikaeroa A ja B välillä on.
*/
#ifndef __PWM__
    #define VAL_TCNT 0x00
    // Normal mode, togglaa pinnejä mätseissä
    #define VAL_TCCR0A (0 << COM0A1)|(1 << COM0A0) | (0 << COM0B1)|(1 << COM0B0) | (0 << WGM01)|(0 << WGM00)
    #define VAL_TCCR0B (0 << WGM02) | (0 << CS02)|(0 << CS01)|(1 << CS00)
    // OCR0A aika loppupäästä
    #define VAL_OCR0A 223
    // OCR0B 100 sykliä aiemmin kuin OCR0A
    #define VAL_OCR0B 123
    // Ei interrupteja
    #define VAL_TIMSK 0x00


/* Phase Correct PWM, TOP 0xFF (ver. A)
PB0 päällä 95 % ajasta (484 µs päällä, 26 µs pois)
PB1 100 µs pulsseja 310 µs välein.
*/
#elif __PWM__==1
    #define VAL_TCNT 0x00
    // COM0A COM0B molemmat 10 : pinnit päällä alhaalta mätsiin ja mätsistä alas
    #define VAL_TCCR0A (0 << COM0A1)|(1 << COM0A0) | (0 << COM0B1)|(1 << COM0B0) | (0 << WGM01)|(0 << WGM00)
    // WGM 001 : PWM, Phase Correct
    #define VAL_TCCR0B (0 << WGM02) | (0 << CS02)|(0 << CS01)|(1 << CS00)
    // OCR0A 95 % päällä, 5 % pois: 255*0.95 = 242
    // OCR0B 100 µs päällä, 310 µs pois (2 x 255-100)
    #define VAL_OCR0A 242
    #define VAL_OCR0B 100
    // Ei interrupteja
    #define VAL_TIMSK 0x00


/* Phase Correct PWM, TOP 0xFF (ver. B)
PB0 pois päältä 95 %, päällä 5 % (484/26 µs)
PB1 310 µs pulsseja 100 µs välein
*/
#elif __PWM__==2
    #define VAL_TCNT 0x00
    // COM0A COM0B molemmat 11 : pois päällä alhaalta mätsiin ja mätsistä alas
    #define VAL_TCCR0A (1 << COM0A1)|(1 << COM0A0) | (1 << COM0B1)|(1 << COM0B0) | (0 << WGM01)|(1 << WGM00)
    // WGM 001 : PWM, Phase Correct
    #define VAL_TCCR0B (0 << WGM02) | (0 << CS02)|(0 << CS01)|(1 << CS00)
    // OCR0A 95 % pois päältä, 5 % päällä: 255*0.95 = 242
    // OCR0B 100 µs pois, loput 310 µs päällä
    #define VAL_OCR0A 242
    #define VAL_OCR0B 100
    // Ei interrupteja
    #define VAL_TIMSK 0x00


/* Clear Counter on Compare Match (CTC)
PB0 100 µs päällä, 100 µs pois
PB1 menee pois 10 µs PB0 mentyä päälle ja päälle 10 µs PB0 mentyä pois
    (ts. PB0 ja PB1 10 µs kerrallaan samassa tilassa, 100 µs välein)
*/
#elif __PWM__==3
    #define VAL_TCNT 0x00
    // COM0A COM0B molemmat 01 : toggle mätsin tapahtuessa
    // WGM 100 : CTC (clear on match)
    #define VAL_TCCR0A (0 << COM0A1)|(1 << COM0A0) | (0 << COM0B1)|(1 << COM0B0) | (1 << WGM01)|(0 << WGM00)
    #define VAL_TCCR0B (0 << WGM02) | (0 << CS02)|(0 << CS01)|(1 << CS00)
    // OCR0A togglaa 100 µs välein ja nollaa samalla laskurin
    // OCR0B 100 µs pois, loput 310 µs päällä
    #define VAL_OCR0A 100
    // OCR0B togglaa 10 µs nollauksesta
    // OCR0B arvon oltava pienempi kuin OCR0A tai sitä ei koskaan tapahdu
    #define VAL_OCR0B 10
    // Ei interrupteja
    #define VAL_TIMSK 0x00


/* Clear Counter on Compare Match (CTC)
PB0 pelkkä kellottaja, ei muuta pinnitilaa
PB1 lähettää 3 µs pulssin sekunnin välein

Kello pyörii 1/256 nopeudella, eli yksi kellotus on 256 µs.
Tällöin 195 kellotusta on 49920 µs eli 0,049920 s.
20 tällaista kellotusta on yhteensä 0.998400 s
eli 1600 µs (kellosykliä) vajaa.
ISR puolella hoidetaan assemblyllä tuo puuttuva 1600 sykliä
ja päästään tasan yhteen sekuntiin.
*/
#elif __PWM__==3
    #define VAL_TCNT 0x00
    // COM0A COM0B molemmat 01 : toggle mätsin tapahtuessa
    // WGM 100 : CTC (clear on match)
    #define VAL_TCCR0A (0 << COM0A1)|(1 << COM0A0) | (0 << COM0B1)|(0 << COM0B0) | (1 << WGM01)|(0 << WGM00)
    #define VAL_TCCR0B (0 << WGM02) | (1 << CS02)|(0 << CS01)|(0 << CS00)
    // OCR0A togglaa 100 µs välein ja nollaa samalla laskurin
    // OCR0B 100 µs pois, loput 310 µs päällä
    #define VAL_OCR0A 195
    // OCR0B togglaa 10 µs nollauksesta
    // OCR0B arvon oltava pienempi kuin OCR0A tai sitä ei koskaan tapahdu
    #define VAL_OCR0B 10
    // Interrupti, lasketaan kellotuksia n kpl
    #define VAL_TIMSK 1<<OCIE0A




#endif

void setup_timer0(void);
#endif
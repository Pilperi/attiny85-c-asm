/*
;===============================================================================
; ISR attiny85
;===============================================================================
*/
; __SFR_OFFSET pitää olla nolla tai muuten I/O-osoitteisiin lisätään 0x20
; (joku C-koodin yhteensopivuushomma)
; https://www.nongnu.org/avr-libc/user-manual/group__avr__sfr__notes.html
#define __SFR_OFFSET 0
#include <avr/io.h>

; Handlerit
; .weakref sijaan erilliset .weak heikolle määritykselle ja .set oletusarvolle
; https://stackoverflow.com/questions/46531064/is-it-possible-to-delay-resolving-a-weakreference-in-gcc-as-until-link-time-g/46547618#46547618

.weak isr_reset
.weak isr_int0
.weak isr_pcint0
.weak isr_timer1_compa
.weak isr_timer1_ovf
.weak isr_timer0_ovf
.weak isr_ee_rdy
.weak isr_ana_comp
.weak isr_adc
.weak isr_timer1_compb
.weak isr_timer0_compa
.weak isr_timer0_compb
.weak isr_wdt
.weak isr_usi_start
.weak isr_usi_ovf
.set isr_reset,isr_default_reset
.set isr_int0,isr_default
.set isr_pcint0,isr_default
.set isr_timer1_compa,isr_default
.set isr_timer1_ovf,isr_default
.set isr_timer0_ovf,isr_default
.set isr_ee_rdy,isr_default
.set isr_ana_comp,isr_default
.set isr_adc,isr_default
.set isr_timer1_compb,isr_default
.set isr_timer0_compa,isr_default
.set isr_timer0_compb,isr_default
.set isr_wdt,isr_default
.set isr_usi_start,isr_default
.set isr_usi_ovf,isr_default

; main mieluiten jossain C-puolella, mutta varuiksi defaultti
.weak main
.set main,_isr_default_main

; Assembly-funktio, näkyy C-puolellekin (linkkausvaiheessa)
.global pulse_pinb_asm

;===============================================================================
.section .isr_vector

; Interrupt vector
; Hypätään kustakin interruptista vastaavaan rutiiniin
rjmp isr_reset        ; RESET
rjmp isr_int0         ; INT0
rjmp isr_pcint0       ; PCINT0
rjmp isr_timer1_compa ; TIMER1_COMPA
rjmp isr_timer1_ovf   ; TIMER1_OVF
rjmp isr_timer0_ovf   ; TIMER0_OVF
rjmp isr_ee_rdy       ; EE_RDY
rjmp isr_ana_comp     ; ANA_COMP
rjmp isr_adc          ; ADC
rjmp isr_timer1_compb ; TIMER1_COMPB
rjmp isr_timer0_compa ; TIMER0_COMPA
rjmp isr_timer0_compb ; TIMER0_COMPB
rjmp isr_wdt          ; WDT
rjmp isr_usi_start    ; USI_START
rjmp isr_usi_ovf      ; USI_OVF

;===============================================================================
.section .text.isr

; Oletusreset
; Aseta R1 nollaksi (aina nolla)
; Aseta stack pointer järkevään osoitteeseen (muistin loppupääty)
; Hyppää main
isr_default_reset:
    LDI R18,0x00
    MOV R1,R18
    LDI	R18,lo8(RAMEND)
	STS	SPL,R18
	LDI	R18,hi8(RAMEND)
	STS	SPH,R18
    RJMP main

; Oletushandleri, pelkkä rjmp + reti
isr_default:
    reti

;===============================================================================
.section .text
; Varuiksi oletus-main (ikuinen loop)
_isr_default_main:
    RJMP _isr_default_main

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

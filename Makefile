# 2026-02-15
# Makefile projektille jossa sekaisin C:tä ja assemblyä.
# Tarjolla kaksi eri projektia jotka voi valita targetilla:
#	- pinb (oletus): Vilkuttaa pinnisignaalia vinhaan tahtiin
#	- clock: Demoaa kellojen eri käyttötapoja
#
# Esim. jos kutsuu `make clock` saa kellon binäärin
# ja pelkällä make tai `make pinb` saa pinb-vilkutusdemon.
#
# Lisäksi tarjolla:
#	- clean : poistaa luodut .o
#	- clear : poistaa koko buildikansion sisällön
#	- show  : listaa lähde- ja kohdetiedostot ja printtaa käännöksen disassemblyn
#	- send  : lähettää tulosbinäärin avrdudella sirulle


#########################################################################
#
# Perusmääritykset: kohdekansiot, käännösflagit ymv
#
#########################################################################
SHELL=/bin/bash

# Kohteen suoritinarkkitehtuuri
MMCU=attiny85
TARGET_ARCH=avr2

# Lähdekoodikansio
KOODIKANSIO=src

# Käännöksen tulokset
KOHDEKANSIO=build
KOHDEBIN=$(KOHDEKANSIO)/ulos.bin
KOHDE_ELF=$(KOHDEKANSIO)/ulos.elf

# Assemblyn kääntäjä ja sen vaatimat argumentit (suorittimen tyyppi ymv)
# !! avr-as on olemassa mutta se tekee jotain ihan muuta älä käytä
COMP_AS=avr-gcc
COMPFLAGS_AS=-mmcu=$(MMCU) -Os -c
# C-kääntäjä ja sen vaatimat argumentit
COMP_CC=avr-gcc
COMPFLAGS_C=-mmcu=$(MMCU) -Os -c

# Binäärin pyörittely eri muodoissa (elf -> bin)
BINCOPY=avr-objcopy
BINFLAGS=-g -O binary

# Linkkeri ja linkkeriskripti
LINKERSCRIPT=linker.ld
LINKER=avr-ld
LINKERFLAGS=-T $(LINKERSCRIPT)

# Lista kaikesta C-lähdekoodista
C_SOURCES := $(shell find $(KOODIKANSIO) -name '*.c')
C_FILENAMES := $(notdir $(C_SOURCES))
# Lista assembly-lähdekoodista
S_SOURCES := $(shell find $(KOODIKANSIO) -name '*.S')
S_FILENAMES := $(notdir $(S_SOURCES))
# Käännetyt versiot
# C:stä käännetyt .c.o ja assemblystä .S.o ja nämä uudelleennimetään myöhemmin sitten .o
C_OBJECTS := $(addprefix $(KOHDEKANSIO)/,$(C_FILENAMES:%.c=%.c.o))
S_OBJECTS := $(addprefix $(KOHDEKANSIO)/,$(S_FILENAMES:%.S=%.S.o))


#########################################################################
#
# Targettikohtaiset määritykset: mitkä .o tuupataan linkkerille
#
# Targettikohtaiset muuttujat voi olla lähdetiedostoja muttei targetteja,
# eli ei voi tehdä
#
#     pinb: O_OBJECTS_FROM_C = $(PINB_O_OBJECTS_FROM_C)
#     $(O_OBJECTS_FROM_C): $(O_OBJECTS_FROM_C)
#
# vaan pitää pistää omat erilliset targetit pinb_objects/clock_objects
# jotka sitten hoitaa oikeiden .o-tiedostojen valkkailun.
#
#########################################################################
.PHONY: newbin pinb clock
# Jaetut riippuvuudet
COMMON_O_OBJECTS_FROM_C = 
COMMON_O_OBJECTS_FROM_S = $(KOHDEKANSIO)/isr.o
# PINB-vilkutusdemo (default)
PINB_O_OBJECTS_FROM_C = $(KOHDEKANSIO)/main_pinb.o
PINB_O_OBJECTS_FROM_S = $(KOHDEKANSIO)/fun_pinb.o
pinb: O_OBJECTS_FROM_C = $(COMMON_O_OBJECTS_FROM_C) $(PINB_O_OBJECTS_FROM_C)
pinb: O_OBJECTS_FROM_S = $(COMMON_O_OBJECTS_FROM_S) $(PINB_O_OBJECTS_FROM_S)
pinb: C_COMPILER_TARGET_FLAGS = 
# Kellointerruptidemo
CLOCK_O_OBJECTS_FROM_C = $(KOHDEKANSIO)/main_clock.o $(KOHDEKANSIO)/fun_timer0.o
CLOCK_O_OBJECTS_FROM_S = $(KOHDEKANSIO)/isr_timer0.o
clock_base: O_OBJECTS_FROM_C = $(COMMON_O_OBJECTS_FROM_C) $(CLOCK_O_OBJECTS_FROM_C)
clock_base: O_OBJECTS_FROM_S = $(COMMON_O_OBJECTS_FROM_S) $(CLOCK_O_OBJECTS_FROM_S)
clock_normal: C_COMPILER_TARGET_FLAGS =-D__CLOCK_MODE_NORMAL
clock_pc: C_COMPILER_TARGET_FLAGS = -D__CLOCK_MODE_PHASE_CORRECT
clock_pc_inv: C_COMPILER_TARGET_FLAGS = -D__CLOCK_MODE_PHASE_CORRECT_INV
clock_ctc: C_COMPILER_TARGET_FLAGS = -D__CLOCK_MODE_CTC
clock_ctc_slow: C_COMPILER_TARGET_FLAGS = -D__CLOCK_MODE_CTC_SLOW


# Listaus
.PHONY: listaa
listaa:
	@echo
	@echo "Tarjolla:"
	@echo "---------"
	@echo "pinb (default)     : kanttiaalto PINB0/PINB1/PINB2"
	@echo "clock/clock_normal : kanttiaalto PB0/PB1, vaihe-ero signaaleissa"
	@echo "clock_pc           : PWM, PB0 95 % päällä ja PB1 100 µs pulsseja 310 µs välein"
	@echo "clock_pc_inv       : PWM, PB0 95 % pois päältä ja PB1 310 µs pulsseja 100 µs välein"
	@echo "clock_ctc          : AND-PWM, PB0 100 µs toggle ja PB1 10 µs samassa tilassa kerrallaan"
	@echo "clock_ctc_slow     : pulssiajoitus, PB1 lähettää 3 µs pulssin 1E6 µs välein"
	@echo


# PINB välkytysdemo
.PHONY: pinb_objects
pinb: $(KOHDEKANSIO) newbin shared_objects pinb_objects $(KOHDEBIN) $(LINKERSCRIPT)
	@echo 
	@echo Luotiin sovellus PINB
pinb_objects: $(PINB_O_OBJECTS_FROM_C) $(PINB_O_OBJECTS_FROM_S)


# TIMER0 demot
.PHONY: clock_objects
clock_base: $(KOHDEKANSIO) clear shared_objects clock_objects $(KOHDEBIN) $(LINKERSCRIPT)
	@echo 
	@echo Luotiin sovellus clock
clock_objects: $(CLOCK_O_OBJECTS_FROM_C) $(CLOCK_O_OBJECTS_FROM_S)
# Eri sorttiset kellodemot, kaikki vaatii yhteisesti clock_base,
# sävyt tulee lähinnä siitä mitä on asetettu targettikohtaisiksi
# kääntäjäflageiksi via $(C_COMPILER_TARGET_FLAGS)
clock: clock_normal
clock_normal: clock_base
	@echo "TIMER0 normaalimoodissa, 50-50 duty vaihe-erolla"
clock_pc: clock_base
	@echo "TIMER0 phase correct, PB0 95 % päällä / PB1 310 µs pulsseja 100 µs välein"
clock_pc_inv: clock_base
	@echo "TIMER0 phase correct inverted, PB0 95 % pois päältä / PB1 100 µs pulsseja 310 µs välein"
clock_ctc: clock_base
	@echo "TIMER0 clear timer on compare (CTC): PB0 ja PB1 100 µs kerrallaan samassa tilassa"
clock_ctc_slow: clock_base
	@echo "TIMER0 clear timer on compare (CTC) interruptilla: PB1 3 µs pulssi tasan sekunnin välein"

.PHONY: shared_objects
shared_objects: $(COMMON_O_OBJECTS_FROM_C) $(COMMON_O_OBJECTS_FROM_S)


#########################################################################
#
# Kohdetiedostojen hallinta: putsaus- ja printtioperaatiot ymv
#
#########################################################################

# Build-kansion luonti jos uupuu
$(KOHDEKANSIO):
	mkdir $(KOHDEKANSIO)

# "Poista" käännöstuotteet, jos olemassa.
# Linkataan joka kerta uudelleen, koska sovellus saattaa vaihtua.
# (esim. make clock tuottaa kellodemon binäärin, mutta jos myöhemmin
# haluttaisiin tehdä muu binääri, mitään ei tapahdu koska .bin on ajan tasalla.)
newbin:
ifneq ("$(wildcard $(KOHDEBIN))","")
	rm $(KOHDEBIN)
endif
ifneq ("$(wildcard $(KOHDE_ELF))","")
	rm $(KOHDE_ELF)
endif

# Poista väliaikatiedostot .o ja .elf
clean:
ifneq ("$(wildcard $(KOHDEKANSIO)/*.o)","")
	rm $(KOHDEKANSIO)/*.o
endif
ifneq ("$(wildcard $(KOHDEKANSIO)/*.elf)","")
	rm $(KOHDEKANSIO)/*.elf
endif

# Poista kaikki kohdekansion sisältä
clear: $(KOHDEKANSIO)
ifneq ("$(wildcard $(KOHDEKANSIO)/*)","")
	@echo 
	@echo Tyhjätään $(KOHDEKANSIO)
	rm $(wildcard $(KOHDEKANSIO)/*)
else
	@echo 
	@echo $(KOHDEKANSIO) on jo tyhjä
endif

# Näytä mitä tuli
show:
	@echo 
	@echo C_SOURCES $(C_SOURCES)
	@echo C_OBJECTS $(C_OBJECTS)
	@echo S_SOURCES $(S_SOURCES)
	@echo S_OBJECTS $(S_OBJECTS)
	@echo O_OBJECTS_FROM_C $(O_OBJECTS_FROM_C)
	@echo O_OBJECTS_FROM_S $(O_OBJECTS_FROM_S)
	test -f $(KOHDE_ELF) && (echo; echo ELF; avr-objdump -D -m $(TARGET_ARCH) -s $(KOHDE_ELF))
	test -f $(KOHDEBIN) && (echo; echo BIN; od -t x1 $(KOHDEBIN))

# Lähetä avrdudella laitteelle
send: $(KOHDEBIN)
	@echo 
	avrdude -c usbtiny -p $(MMCU) -n -U signature:r:/dev/null
	avrdude -c usbtiny -p $(MMCU) -U flash:w:$(KOHDEBIN):a

#########################################################################
#
# Koodin kääntö ja linkkaustargetit
#
#########################################################################

# Binäärin muodostus elffistä kopiointiohjelmalla
$(KOHDEBIN): $(KOHDE_ELF)
	@echo 
	$(BINCOPY) $(BINFLAGS) $(KOHDE_ELF) $(KOHDEBIN)

# Linkkaa .o-tiedostot linkkeriskriptillä elffiksi.
# O_OBJECTS_FROM_C ja O_OBJECTS_FROM_S sovelluskohtaisia.
$(KOHDE_ELF): $(O_OBJECTS_FROM_C) $(O_OBJECTS_FROM_S)
	@echo Link ELF
	@echo O_OBJECTS_FROM_C $(O_OBJECTS_FROM_C)
	@echo O_OBJECTS_FROM_S $(O_OBJECTS_FROM_S)
	$(LINKER) $(LINKERFLAGS) -o $(KOHDE_ELF) $(O_OBJECTS_FROM_C) $(O_OBJECTS_FROM_S)

# PINB-sovelluksen objektitiedostot, erikseen C:stä ja assemblystä
# Näin saa valkkailtua mitkä .o:t napataan mistäkin toteutuksesta
$(PINB_O_OBJECTS_FROM_C): $(C_OBJECTS)
	@echo 
	@echo C_OBJECTS $(C_OBJECTS)
	test "$@" != "" && cp $(patsubst %.o,%.c.o,$@) $@
$(PINB_O_OBJECTS_FROM_S): $(S_OBJECTS)
	@echo 
	@echo S_OBJECTS $(PINB_O_OBJECTS_FROM_S)
	test "$@" != "" && cp $(patsubst %.o,%.S.o,$@) $@

# Vastaavasti CLOCK-sovelluksen objektitiedostot:
$(CLOCK_O_OBJECTS_FROM_C): $(C_OBJECTS)
	@echo 
	@echo C_OBJECTS $(C_OBJECTS)
	test "$@" != "" && cp $(patsubst %.o,%.c.o,$@) $@
$(CLOCK_O_OBJECTS_FROM_S): $(S_OBJECTS)
	@echo 
	@echo S_OBJECTS $(S_OBJECTS)
	test "$@" != "" && cp $(patsubst %.o,%.S.o,$@) $@

# Molempien tarvitsemat objektitiedostot:
$(COMMON_O_OBJECTS_FROM_C): $(C_OBJECTS)
	@echo 
	@echo C_OBJECTS $(C_OBJECTS)
	test "$@" != "" && cp $(patsubst %.o,%.c.o,$@) $@
$(COMMON_O_OBJECTS_FROM_S): $(S_OBJECTS)
	@echo 
	@echo S_OBJECTS $(S_OBJECTS)
	test "$@" != "" && cp $(patsubst %.o,%.S.o,$@) $@

# Käännä kaikki .c-tiedostot .c.o-tiedostoiksi
$(C_OBJECTS): $(C_SOURCES)
	$(COMP_CC) $(COMPFLAGS_C) $(C_COMPILER_TARGET_FLAGS) -o $@ $(addprefix $(KOODIKANSIO)/,$(notdir $(patsubst %.c.o,%.c,$@)))
# Käännä kaikki .S-tiedostot .S.o-tiedostoiksi
$(S_OBJECTS): $(S_SOURCES)
	$(COMP_AS) $(COMPFLAGS_AS) -o $@ $(addprefix $(KOODIKANSIO)/,$(notdir $(patsubst %.S.o,%.S,$@)))

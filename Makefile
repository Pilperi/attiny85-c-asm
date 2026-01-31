# 2026-01-31
# Makefile projektille jossa sekaisin C:tä ja assemblyä
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

# Binäärin pyörittely eri muodoissa
BINCOPY=avr-objcopy
BINFLAGS=-g -O binary

# Linkkeri ja linkkeriskripti
# Pelkkä -T ei toimi vaan tarvii olla -dT
# Muutoin tuuppaa avr-gcc omat interruptit alkuun...
LINKER=avr-ld
LINKERFLAGS=-T linker.ld

# Lista C-lähdekoodista
C_SOURCES := $(shell find $(KOODIKANSIO) -name '*.c')
C_FILENAMES := $(notdir $(C_SOURCES))
# Lista assembly-lähdekoodista
S_SOURCES := $(shell find $(KOODIKANSIO) -name '*.S')
S_FILENAMES := $(notdir $(S_SOURCES))
# Käännetyt versiot
# C:stä käännetyt .c.o ja assemblystä .S.o ja nämä uudelleennimetään .o
C_OBJECTS := $(addprefix $(KOHDEKANSIO)/,$(C_FILENAMES:%.c=%.c.o))
S_OBJECTS := $(addprefix $(KOHDEKANSIO)/,$(S_FILENAMES:%.S=%.S.o))
O_OBJECTS := $(C_OBJECTS:%.c.o=%.o) $(S_OBJECTS:%.S.o=%.o)

all: $(KOHDEKANSIO) $(KOHDEBIN)

clear: $(KOHDEKANSIO)
	rm $(KOHDEKANSIO)/*.o
	rm $(KOHDEKANSIO)/*.bin
	rm $(KOHDEKANSIO)/*.elf

# Näytä mitä tuli
show:
	@echo C_SOURCES $(C_SOURCES)
	@echo C_OBJECTS $(C_OBJECTS)
	@echo S_SOURCES $(S_SOURCES)
	@echo S_OBJECTS $(S_OBJECTS)
	@echo O_OBJECTS $(O_OBJECTS)
	@echo
	@echo "ELF"
	avr-objdump -D -m $(TARGET_ARCH) -s $(KOHDE_ELF)
	@echo
	@echo "Binäärin sisältö"
	od -t x1 $(KOHDEBIN)

# Lähetä avrdudella laitteelle
send: $(KOHDEBIN)
	avrdude -c usbtiny -p $(MMCU) -n -U signature:r:/dev/null
	avrdude -c usbtiny -p $(MMCU) -U flash:w:$(KOHDEBIN):a

# Putsaa välitiedostot
clean:
	rm $(KOHDEKANSIO)/*.o
	rm $(KOHDEKANSIO)/*.elf

# Build-kansion luonti jos uupuu
$(KOHDEKANSIO):
	mkdir $(KOHDEKANSIO)

# Binäärin muodostus elffistä kopiointiohjelmalla
$(KOHDEBIN): $(KOHDE_ELF)
	$(BINCOPY) $(BINFLAGS) $(KOHDE_ELF) $(KOHDEBIN)

# Linkkaa .o-tiedostot linkkeriskriptillä elffiksi
$(KOHDE_ELF): $(O_OBJECTS)
	$(LINKER) $(LINKERFLAGS) -o $(KOHDE_ELF) $(O_OBJECTS)

# Uudelleennimeä .c.o ja .S.o muotoon .o
$(O_OBJECTS): $(C_OBJECTS) $(S_OBJECTS)
	bash -c 'for sf in $(KOHDEKANSIO)/*.S.o; do mv "$$sf" "$(KOHDEKANSIO)/$$(basename "$$sf" .S.o).o"; done'
	bash -c 'for cf in $(KOHDEKANSIO)/*.c.o; do mv "$$cf" "$(KOHDEKANSIO)/$$(basename "$$cf" .c.o).o"; done'

# Käännä .c-tiedostot .c.o-tiedostoiksi
$(C_OBJECTS): $(C_SOURCES)
	$(COMP_CC) $(COMPFLAGS_C) -o $@ $<

# Käännä .S-tiedostot .S.o-tiedostoiksi
$(S_OBJECTS): $(S_SOURCES)
	$(COMP_AS) $(COMPFLAGS_AS) -o $@ $<

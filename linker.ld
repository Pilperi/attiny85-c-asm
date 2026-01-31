/* Linkerfile attiny85 */

MEMORY
{
    /* Ohjelmamuisti ainoa johon voidaan kirjoittaa */
    program_memory : org = 0x0000, len = 0x0FFF
    /*
    SRAM hoidettu virtuaalisen offsetin kautta, laitteessa alkaa 0x0060.
    Vaikkei voida ohjelmoidessa kirjoittaa dataa, voidaan silti allokoida
    ja tarkistaa että mahtuuhan sinne mitä meinataan tuupata.
     */
    sram : org = 0x80000060, len = 512
}

SECTIONS
{
    /* Suoritettava koodi */
	. = ORIGIN(program_memory);
        .text : {
            build/isr.o(.isr_vector); /* Koodin alussa interrupt-jumpit */
            build/isr.o(.text.isr);   /* Jumppien kohteet lähellä */
            build/isr.o(.text);       /* Mahdollinen muu koodi sitten */
            build/main.o(.text*);     /* Kaikki muu suoritettava koodi */
        } >program_memory
	/* Alustettu data */
        .data : {
	        build/*(.data);
            }
	/* Alustamaton data */
	.bss : {	  
	    build/*(.bss);
	}
}
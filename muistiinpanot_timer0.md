2026-02-15
# Muistiinpanoja ATtiny85 TIMER0 käytöstä

Osana assemblyn ja C:n yhdistelyä tutustuin vähän suorittimen kellon käyttöön. Yleinen käyttökohde assemblyn käytölle kun on juurikin tarkkojen ajoitusten luominen, kun tietää tarkkaan montako kellosykliä mikäkin homma vie. En myöskään ole TIMER-puolen hommiin ollenkaan koskenut, niin hyvä saada se tutuksi. Tämä itse kellon toiminta on vähän erillinen juttu yleisestä C:n ja assemblyn yhdistelystä, niin laitan omaksi erilliseksi dokumentiksi.

## TIMER0

ATTinyn Timer/Counter0 on masiinan 8-bittinen kellokoneisto. Perusmuodossaan se laskee 0-255 uudestaan ja uudestaan, ja väliin voi pistää toimintapisteitä ja interrupteja. Useimmiten sitä ajetaan samalla keskuskellolla kuin muutakin systeemiä (IO-kello), mutta on kuitenkin oma erillinen alisysteeminsä. Sen vahvuus on siinä, että sillä voi generoida ajastettuja eventtejä interruptien kautta (`TIMER0_OVF`, `TIMER0_COMPA`, `TIMER0_COMPB`), mutta sen lisäksi sillä voi ajaa kanttiaaltomuotoja kahdella pinnillä ihan ilman interrupteja. Toisin sanottuna jos tarvii masiinaa jonkuntahtisen kanttiaallon tai kahden tuottamiseen, voi vaan pistää pinnit nakuttamaan ja tehdä keskusyksikön kellosykleillä jotain aikakriittistä tai muuten vaan tärkeää, tai laittaa vaikka koko masiinan lepotilaan ja säästää virtaa.

Kellon lähteenä voi käyttää IO-kelloa sellaisenaan tai hidastettuna 8/64/256/1024-osaan. Suorittimen perustaajuus on 8 MHz joka tehdasasetuksilla hidastettu 1 MHz. Tällöin tarjolla on aikaresoluutiot 1 µs, 8 µs, ..., 1024 µs per kelloyksikkö. Sen lisäksi voi käyttää nousevaa tai laskevaa reunaa `PB2`-pinnissä (`T0`). Kätevä jos haluaa laskea jotain ulkoisia eventtejä, vaikka että kymmenen napinpainalluksen jälkeen tapahtuu jotain mutta muuten nukutaan ja säästetään virtaa.

Kellon voi myös asettaa tiettyyn arvoon, mutta siinä on tiettyjä kommervinkkejä. Etenkin vertailumätsien arvot menee joissain toimintamoodeissa inee jonkun bufferin kautta, ja jos tekee juttuja väärässä järkässä niin saattaa käydä ettei bufferiarvot mene koskaan perille. Yleensä varmin rautalankaratkaisu on laittaa kello seis, säätää mitä ikinä haluaakaan kellokontrolleissa säätää ja sitten pistää kello takaisin käyntiin. Kello on seis kun bitit `CS02..CS00` on nollassa, eli varma malli on `fun_timer0.c` käytetty

```C
void setup_timer0(void){
    // Kello seis ja nolliin
    TCCR0B = 0x00;
    TCNT0 = 0x00;
    // Aseta Output Compare arvot
    OCR0A = VAL_OCR0A;
    OCR0B = VAL_OCR0B;
    // Aseta Control Register arvot, millä moodilla operoidaan
    // Kello lähtee käyntiin kun TCCR0B asetetaan
    TCCR0A = VAL_TCCR0A;
    TCCR0B = VAL_TCCR0B;
    // Aseta kellon arvo
    TCNT0 = VAL_TCNT;
    // Interrupti-enable
    TIMSK = VAL_TIMSK;
}
```
Kellovalintabitit `CS02..CS00` sijaitsee kaikki `TCCR0B` alapäässä, niin voimaratkaisu on kirjoittaa koko rekisteri nollaan ja laittaa sinne oikeat arvot vasta ihan tosi lopuksi.

## OCR0A ja OCR0B

Tarjolla on overflow-interruptin lisäksi kaksi mätsirekisteriä A ja B. Niissä olevia arvoja verrataan jatkuvasti `TCNT0` rullaavaan arvoon, ja kun ne on samat niin reagoidaan. Yleensä reaktio on että vastaavien pinnien `PB0` (A) ja `PB1` (B) arvoja sörkitään automaattisesti, tehdään interrupti, tai sekä että. Sörkkimisvaihtoehtoina on yleensä
- Ei mitään
- Vaihda tilaa
- Aseta
- Nollaa

`PB0` ja `PB1` arvot pitää `DDRB`-rekisterissä olla kohdillaan että mitään tapahtuu.

Sekä A että B toimii saman perustoiminnon ympärillä, ts. jos on valittu tietty toimintamalli timerille niin sekä A että B toimii sen mukaan. Esimerkiksi normaalimoodissa `OCR0A` ja `OCR0B` kautta voi vaikuttaa oikeastaan vain kanttiaaltojen vaihe-eroon ja molemmat tekee juttuja aina 255 syklin välein. Myöhemmin on avattu lisää eri toimintamalleja esimerkkien kautta.

Jos tarvitsee molempia vertailukanavia niin kannattaa aina laittaa luvuista isompi `OCR0A` ja pienempi `OCR0B`. Lähinnä relevantti CTC-moodissa, missä laskuri nollaa aina kun saavuttaa `OCR0A` arvon eikä `OCR0B` asti siksi koskaan päästäisi jos se olisi isompi, mutta hyvä pitää muutenkin rutiinina.
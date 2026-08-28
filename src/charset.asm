; charset.asm -- charset custom per Daytona (task 3 della roadmap MVP).
;
; Strategia: si copia il set di caratteri "maiuscole + grafica" della ROM
; caratteri ($d000-$d7ff) nella RAM a charset_base, cosi' si ottiene gratis un
; font leggibile completo (lettere, cifre, punteggiatura) senza doverlo
; disegnare a mano. I codici carattere 128-132 (nella ROM sono le versioni
; "invertite" di altri caratteri, che non usiamo) vengono poi sovrascritti con
; le 5 tile della pista -- vedi ARCHITECTURE.md par. 3/6 per il ragionamento.

TILE_ROAD    = 128
TILE_CURB    = 129
TILE_GRASS   = 130
TILE_PIT     = 131
TILE_FINISH  = 132

charset_init:
    lda $01
    pha                     ; salva la configurazione dei banchi per ripristinarla dopo
    and #%11111011
    sta $01                 ; CHAREN=0: espone la ROM caratteri al posto dell'I/O ($d000-$dfff)

    ldx #$00
charset_copy_loop:
    lda $d000, x
    sta charset_base, x
    lda $d100, x
    sta charset_base + $100, x
    lda $d200, x
    sta charset_base + $200, x
    lda $d300, x
    sta charset_base + $300, x
    lda $d400, x
    sta charset_base + $400, x
    lda $d500, x
    sta charset_base + $500, x
    lda $d600, x
    sta charset_base + $600, x
    lda $d700, x
    sta charset_base + $700, x
    inx
    bne charset_copy_loop

    pla
    sta $01                 ; ripristina I/O al posto della ROM caratteri

    ldx #$00
charset_patch_loop:
    lda tile_road, x
    sta charset_base + (TILE_ROAD * 8), x
    lda tile_curb, x
    sta charset_base + (TILE_CURB * 8), x
    lda tile_grass, x
    sta charset_base + (TILE_GRASS * 8), x
    lda tile_pit, x
    sta charset_base + (TILE_PIT * 8), x
    lda tile_finish, x
    sta charset_base + (TILE_FINISH * 8), x
    inx
    cpx #$08
    bne charset_patch_loop

    rts

; Tile 8x8 hi-res (1bpp): bit=1 -> colore da color RAM, bit=0 -> vic_cbg.
; Pattern segnaposto, pensati per essere distinguibili a colpo d'occhio;
; da rifinire con arte reale (CharPad) in una iterazione successiva.
tile_road:
    !byte %00000000, %00100000, %00000000, %00000100
    !byte %00000000, %00010000, %00000000, %01000000
tile_curb:
    !byte %11100000, %11000001, %10000011, %00000111
    !byte %00001110, %00011100, %00111000, %01110000
tile_grass:
    !byte %10100101, %01000010, %00100001, %10010100
    !byte %01001010, %00100101, %10010010, %01001001
tile_pit:
    !byte %11111111, %10000000, %11111111, %00000001
    !byte %11111111, %10000000, %11111111, %00000001
tile_finish:
    !byte %11001100, %11001100, %00110011, %00110011
    !byte %11001100, %11001100, %00110011, %00110011

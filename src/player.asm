; player.asm -- sprite del giocatore, setup iniziale (task 5 della roadmap MVP).
; Sprite hi-res a un colore, segnaposto: rettangolo con muso stretto in cima.
; Verra' sostituito con arte multicolor reale (CharPad/SpritePad) in una
; iterazione successiva -- vedi ARCHITECTURE.md par. 1/6.

PLAYER_START_X = 140
PLAYER_START_Y = 200

player_init:
    ldx #$00
player_sprite_copy:
    lda player_sprite_data, x
    sta sprite_base, x
    inx
    cpx #64
    bne player_sprite_copy

    lda #(sprite_base / 64)
    sta screen_base + $3f8       ; puntatore sprite 0 (screen RAM $07f8)

    lda #%00000001
    sta vic_sactive                ; abilita sprite 0

    lda #PLAYER_START_X
    sta vic_xs0
    sta zp_player_x
    lda #PLAYER_START_Y
    sta vic_ys0

    lda #viccolor_WHITE
    sta vic_cs0                    ; colore sprite 0

    lda #$00
    sta zp_player_speed
    rts

; 24x21 px, muso (2 righe strette) + corpo (19 righe piu' larghe).
player_sprite_data:
    !byte %00011111, %11111000, %00000000
    !byte %00011111, %11111000, %00000000
    !byte %00111111, %11111100, %00000000
    !byte %00111111, %11111100, %00000000
    !byte %00111111, %11111100, %00000000
    !byte %00111111, %11111100, %00000000
    !byte %00111111, %11111100, %00000000
    !byte %00111111, %11111100, %00000000
    !byte %00111111, %11111100, %00000000
    !byte %00111111, %11111100, %00000000
    !byte %00111111, %11111100, %00000000
    !byte %00111111, %11111100, %00000000
    !byte %00111111, %11111100, %00000000
    !byte %00111111, %11111100, %00000000
    !byte %00111111, %11111100, %00000000
    !byte %00111111, %11111100, %00000000
    !byte %00111111, %11111100, %00000000
    !byte %00111111, %11111100, %00000000
    !byte %00111111, %11111100, %00000000
    !byte %00111111, %11111100, %00000000
    !byte %00111111, %11111100, %00000000
    !byte %00000000                          ; padding a 64 byte

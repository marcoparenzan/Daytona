; testpattern.asm -- pattern statico di verifica per il charset custom
; (task 3 della roadmap MVP). Riempie lo schermo con le 5 tile e stampa una
; scritta di prova, per confermare che sia il font (copiato dalla ROM) sia le
; tile patchate renderizzino correttamente. Verra' sostituito dal rendering
; vero (HUD in hud.asm task 4, pista in track.asm task 6/7) -- vedi
; ARCHITECTURE.md par. 7.

test_string:
    !byte 4,1,25,20,15,14,1,32,3,8,1,18,19,5,20,32,20,5,19,20,0   ; "DAYTONA CHARSET TEST"

render_test_pattern:
    ; 1. riempi tutto lo schermo (1000 caratteri) con TILE_ROAD
    ldx #$00
fill_road_loop:
    lda #TILE_ROAD
    sta screen_base, x
    sta screen_base + $100, x
    sta screen_base + $200, x
    inx
    bne fill_road_loop
    ldx #$00
fill_road_tail:
    lda #TILE_ROAD
    sta screen_base + $300, x
    inx
    cpx #232
    bne fill_road_tail

    ; 2. riga 2 (colonne 0-39): TILE_CURB
    ldx #$00
fill_curb_loop:
    lda #TILE_CURB
    sta screen_base + 80, x
    inx
    cpx #40
    bne fill_curb_loop

    ; 3. riga 4: TILE_GRASS
    ldx #$00
fill_grass_loop:
    lda #TILE_GRASS
    sta screen_base + 160, x
    inx
    cpx #40
    bne fill_grass_loop

    ; 4. riga 6, colonna 5: singola TILE_PIT
    lda #TILE_PIT
    sta screen_base + 245        ; riga 6 * 40 colonne + colonna 5

    ; 5. riga 8: TILE_FINISH
    ldx #$00
fill_finish_loop:
    lda #TILE_FINISH
    sta screen_base + 320, x
    inx
    cpx #40
    bne fill_finish_loop

    ; 6. scritta di prova, riga 0
    lda #<screen_base
    sta zp_dst_lo
    lda #>screen_base
    sta zp_dst_hi
    lda #<test_string
    ldy #>test_string
    jsr print_string

    ; 7. color RAM: grigio chiaro dappertutto (leggibile su sfondo nero)
    ldx #$00
fill_color_loop:
    lda #viccolor_GRAY3
    sta color_ram, x
    sta color_ram + $100, x
    sta color_ram + $200, x
    inx
    bne fill_color_loop
    ldx #$00
fill_color_tail:
    lda #viccolor_GRAY3
    sta color_ram + $300, x
    inx
    cpx #232
    bne fill_color_tail

    rts

print_string:
    ; A/Y = puntatore lo/hi alla stringa da stampare (screen code, terminata da 0)
    ; zp_dst_lo/zp_dst_hi (gia' impostati dal chiamante) = puntatore alla destinazione in screen RAM
    sta zp_str_lo
    sty zp_str_hi
    ldy #$00
print_string_loop:
    lda (zp_str_lo), y
    beq print_string_done
    sta (zp_dst_lo), y
    iny
    bne print_string_loop
print_string_done:
    rts

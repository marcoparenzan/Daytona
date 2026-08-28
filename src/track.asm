; track.asm -- scroll verticale della pista (task 6 della roadmap MVP).
;
; Tecnica standard C64: fine-scroll a 8 passi via i bit 0-2 di vic_controlv
; ($d011); ogni 8 tick (un carattere intero) si scorre lo screen RAM di una
; riga -- SOLO le colonne 0-33 (TRACK_WIDTH), l'area HUD 34-39 non viene mai
; toccata -- e si riempie la riga che entra dall'alto con il pattern pista.
; Velocita' guidata da zp_player_speed tramite un accumulatore stile
; Bresenham: piu' e' alta, piu' spesso scatta un tick di scroll.
;
; Pista MVP: dritta, senza corsia box ne' variazioni (arrivano nei task 7/9).
; colonne 0-1 erba, 2 cordolo, 3-30 strada, 31 cordolo, 32-33 erba.

TRACK_WIDTH = 34
TRACK_ROWS  = 25

scroll_init:
    lda #$00
    sta zp_fine_scroll
    lda #$00
    sta zp_scroll_accum
    rts

update_scroll:
    lda zp_scroll_accum
    clc
    adc zp_player_speed
    sta zp_scroll_accum
    bcc update_scroll_apply
    jsr scroll_tick
update_scroll_apply:
    lda vic_controlv
    and #%11111000
    ora zp_fine_scroll
    sta vic_controlv
    rts

scroll_tick:
    lda zp_fine_scroll
    cmp #$07
    beq scroll_coarse
    inc zp_fine_scroll
    rts

scroll_coarse:
    lda #$00
    sta zp_fine_scroll
    jsr shift_rows_down
    jsr fill_new_top_row
    rts

; Copia la riga 23 nella 24, poi 22->23, ... fino a 0->1 (24 righe, colonne
; 0-33 soltanto). La vecchia riga 24 viene sovrascritta (esce dallo schermo);
; la riga 0 resta con contenuto vecchio finche' fill_new_top_row non la rifa'.
shift_rows_down:
    lda #<(screen_base + 23 * 40)
    sta zp_scroll_src_lo
    lda #>(screen_base + 23 * 40)
    sta zp_scroll_src_hi
    lda #<(screen_base + 24 * 40)
    sta zp_scroll_dst_lo
    lda #>(screen_base + 24 * 40)
    sta zp_scroll_dst_hi

    lda #24
    sta zp_scroll_rows_left

shift_rows_loop:
    ldy #$00
shift_rows_copy:
    lda (zp_scroll_src_lo), y
    sta (zp_scroll_dst_lo), y
    iny
    cpy #TRACK_WIDTH
    bne shift_rows_copy

    lda zp_scroll_src_lo
    sec
    sbc #40
    sta zp_scroll_src_lo
    lda zp_scroll_src_hi
    sbc #$00
    sta zp_scroll_src_hi

    lda zp_scroll_dst_lo
    sec
    sbc #40
    sta zp_scroll_dst_lo
    lda zp_scroll_dst_hi
    sbc #$00
    sta zp_scroll_dst_hi

    dec zp_scroll_rows_left
    bne shift_rows_loop
    rts

fill_new_top_row:
    ldy #$00
fill_top_grass_l:
    lda #TILE_GRASS
    sta screen_base + 0, y
    iny
    cpy #2
    bne fill_top_grass_l

    lda #TILE_CURB
    sta screen_base + 2

    ldy #3
fill_top_road:
    lda #TILE_ROAD
    sta screen_base + 0, y
    iny
    cpy #31
    bne fill_top_road

    lda #TILE_CURB
    sta screen_base + 31

    ldy #32
fill_top_grass_r:
    lda #TILE_GRASS
    sta screen_base + 0, y
    iny
    cpy #TRACK_WIDTH
    bne fill_top_grass_r
    rts

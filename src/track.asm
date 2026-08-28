; track.asm -- scroll verticale della pista (task 6 della roadmap MVP).
;
; Scroll a scatti interi di una riga carattere (8px), SENZA fine-scroll a
; sotto-pixel: niente tocca mai i bit 0-2 di vic_controlv ($d011). Il motivo:
; quel registro sposta verticalmente TUTTA la riga video, non solo alcune
; colonne -- quindi anche l'area HUD (colonne 34-39, che non viene mai
; toccata dallo shift di riga) "ballerebbe" verticalmente insieme alla pista.
; Un vero split orizzontale (Y-scroll diverso a meta' riga) richiederebbe
; temporizzazione a livello di singolo ciclo, troppo fragile per l'MVP.
; Risultato: HUD perfettamente ferma, pista che scorre a scatti invece che
; fluida -- compromesso accettabile.
;
; Lo shift riga copre SOLO le colonne 0-33 (TRACK_WIDTH), mai la 34-39.
; Velocita' guidata da zp_player_speed tramite un accumulatore stile
; Bresenham: piu' e' alta, piu' spesso scatta uno shift di riga.
;
; Pista MVP: dritta, senza variazioni di tracciato (curve ecc. fuori scope MVP).
; colonne 0-1 erba, 2 cordolo, 3 corsia box (fissa, vedi pitstop.asm),
; 4-30 strada, 31 cordolo, 32-33 erba.

TRACK_WIDTH = 34
TRACK_ROWS  = 25

scroll_init:
    lda #$00
    sta zp_scroll_accum
    rts

update_scroll:
    lda zp_player_speed
    asl
    asl                     ; velocita' x4: a piena velocita' l'accumulatore puro dava
                            ; solo ~1.5 righe/sec, troppo lento per una corsa
    clc
    adc zp_scroll_accum
    sta zp_scroll_accum
    bcc update_scroll_done
    jsr shift_rows_down
    jsr fill_new_top_row
    jsr score_add_meter
update_scroll_done:
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

    lda #TILE_PIT
    sta screen_base + 3     ; colonna 3 = corsia box fissa (vedi pitstop.asm, PIT_LANE_X)

    ldy #4
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

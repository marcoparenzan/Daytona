; hud.asm -- HUD statico (task 4 della roadmap MVP).
;
; Etichette fisse SPEED/SCORE/TIME/CARS sul bordo destro dello schermo
; (colonne 34-39, come nell'originale Le Mans -- vedi ARCHITECTURE.md par. 1).
; Provano che il posizionamento in screen RAM funziona end-to-end. I valori
; numerici live verranno aggiunti nel task 10 (punteggio/timer).

HUD_COL = 34

hud_label_speed:
    !byte 19,16,5,5,4,0            ; "SPEED"
hud_label_score:
    !byte 19,3,15,18,5,0           ; "SCORE"
hud_label_time:
    !byte 20,9,13,5,0              ; "TIME"
hud_label_cars:
    !byte 3,1,18,19,0              ; "CARS"

draw_static_hud:
    lda #<(screen_base + 2 * 40 + HUD_COL)
    sta zp_dst_lo
    lda #>(screen_base + 2 * 40 + HUD_COL)
    sta zp_dst_hi
    lda #<hud_label_speed
    ldy #>hud_label_speed
    jsr print_string

    lda #<(screen_base + 6 * 40 + HUD_COL)
    sta zp_dst_lo
    lda #>(screen_base + 6 * 40 + HUD_COL)
    sta zp_dst_hi
    lda #<hud_label_score
    ldy #>hud_label_score
    jsr print_string

    lda #<(screen_base + 10 * 40 + HUD_COL)
    sta zp_dst_lo
    lda #>(screen_base + 10 * 40 + HUD_COL)
    sta zp_dst_hi
    lda #<hud_label_time
    ldy #>hud_label_time
    jsr print_string

    lda #<(screen_base + 14 * 40 + HUD_COL)
    sta zp_dst_lo
    lda #>(screen_base + 14 * 40 + HUD_COL)
    sta zp_dst_hi
    lda #<hud_label_cars
    ldy #>hud_label_cars
    jsr print_string

    rts

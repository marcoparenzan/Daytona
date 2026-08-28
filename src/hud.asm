; hud.asm -- HUD statico (task 4) + valori live (task 10) della roadmap MVP.
;
; Etichette fisse SPEED/SCORE/TIME/CARS sul bordo destro dello schermo
; (colonne 34-39, come nell'originale Le Mans -- vedi ARCHITECTURE.md par. 1),
; con i valori numerici una riga sotto ciascuna etichetta.

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

; --- valori live (task 10) ---
; Una riga sotto ciascuna etichetta (righe 3/7/11/15), stessa colonna HUD_COL.

update_hud_values:
    jsr update_hud_speed
    jsr update_hud_score
    jsr update_hud_time
    jsr update_hud_cars
    rts

update_hud_speed:
    lda zp_player_speed
    jsr bin_to_3digits
    lda zp_conv_tens
    clc
    adc #48
    sta screen_base + 3 * 40 + HUD_COL
    lda zp_conv_ones
    clc
    adc #48
    sta screen_base + 3 * 40 + HUD_COL + 1
    rts

update_hud_score:
    lda #<(screen_base + 7 * 40 + HUD_COL)
    sta zp_dst_lo
    lda #>(screen_base + 7 * 40 + HUD_COL)
    sta zp_dst_hi
    lda zp_score_hi
    jsr write_bcd_digits

    lda #<(screen_base + 7 * 40 + HUD_COL + 2)
    sta zp_dst_lo
    lda #>(screen_base + 7 * 40 + HUD_COL + 2)
    sta zp_dst_hi
    lda zp_score_mid
    jsr write_bcd_digits

    lda #<(screen_base + 7 * 40 + HUD_COL + 4)
    sta zp_dst_lo
    lda #>(screen_base + 7 * 40 + HUD_COL + 4)
    sta zp_dst_hi
    lda zp_score_lo
    jsr write_bcd_digits
    rts

update_hud_time:
    lda #<(screen_base + 11 * 40 + HUD_COL)
    sta zp_dst_lo
    lda #>(screen_base + 11 * 40 + HUD_COL)
    sta zp_dst_hi
    lda zp_timer_seconds
    jsr write_bcd_digits
    rts

update_hud_cars:
    lda zp_overtake_total
    jsr bin_to_3digits
    lda zp_conv_hundreds
    clc
    adc #48
    sta screen_base + 15 * 40 + HUD_COL
    lda zp_conv_tens
    clc
    adc #48
    sta screen_base + 15 * 40 + HUD_COL + 1
    lda zp_conv_ones
    clc
    adc #48
    sta screen_base + 15 * 40 + HUD_COL + 2
    rts

; Scrive un byte BCD (2 cifre) come 2 caratteri a (zp_dst_lo),0 e (zp_dst_lo),1.
write_bcd_digits:
    pha
    lsr
    lsr
    lsr
    lsr
    clc
    adc #48
    ldy #$00
    sta (zp_dst_lo), y
    pla
    and #$0f
    clc
    adc #48
    ldy #$01
    sta (zp_dst_lo), y
    rts

; Converte A (0-255, binario) in 3 cifre decimali via sottrazioni ripetute:
; zp_conv_hundreds, zp_conv_tens, zp_conv_ones.
bin_to_3digits:
    ldx #$00
b3_hundreds:
    cmp #100
    bcc b3_hundreds_done
    sec
    sbc #100
    inx
    jmp b3_hundreds
b3_hundreds_done:
    stx zp_conv_hundreds
    ldy #$00
b3_tens:
    cmp #10
    bcc b3_tens_done
    sec
    sbc #10
    iny
    jmp b3_tens
b3_tens_done:
    sty zp_conv_tens
    sta zp_conv_ones
    rts

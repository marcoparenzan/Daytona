; score.asm -- punteggio, streak sorpassi, timer con estensioni (task 10).
;
; Punteggio e timer tenuti in BCD (packed decimal): ogni nibble e' gia' una
; cifra, comodo da stampare senza conversione. zp_score_* sono 3 byte (6
; cifre, fino a 999999). Regole dall'originale Le Mans (vedi ARCHITECTURE.md
; par. 1): 2 punti/metro percorso, +1000 ogni 10 sorpassi consecutivi senza
; crash (un crash azzera la striscia, vedi pitstop.asm), timer 60s con +20s
; ogni soglia di 20000 punti superata.

SCORE_PER_METER = $02   ; BCD
STREAK_BONUS_AT = 10    ; sorpassi consecutivi per il bonus (contatore binario, non BCD)

TIME_START = $99        ; 99 secondi, BCD -- allungato da 60s per comodita' di test
                         ; durante lo sviluppo (l'originale usa 60s, vedi ARCHITECTURE.md)
TIME_BONUS = $20        ; +20 secondi ogni soglia, BCD

score_init:
    sed
    lda #$00
    sta zp_score_lo
    sta zp_score_mid
    sta zp_score_hi
    cld
    lda #$00
    sta zp_overtake_streak
    sta zp_overtake_total
    sta zp_threshold_lo
    sta zp_threshold_mid
    lda #$02
    sta zp_threshold_hi     ; prima soglia: 020000 = 20000
    lda #TIME_START
    sta zp_timer_seconds
    lda #$00
    sta zp_timer_frames
    rts

; Chiamata da track.asm ad ogni riga scrollata (un "metro" di gioco).
score_add_meter:
    sed
    lda zp_score_lo
    clc
    adc #SCORE_PER_METER
    sta zp_score_lo
    lda zp_score_mid
    adc #$00
    sta zp_score_mid
    lda zp_score_hi
    adc #$00
    sta zp_score_hi
    cld
    jsr score_check_threshold
    rts

; Chiamata da traffic.asm quando un'auto esce da sotto (sorpasso pulito, non crash).
register_overtake:
    inc zp_overtake_total
    inc zp_overtake_streak
    lda zp_overtake_streak
    cmp #STREAK_BONUS_AT
    bcc register_overtake_done
    lda #$00
    sta zp_overtake_streak
    sed
    lda zp_score_lo
    clc
    adc #$00
    sta zp_score_lo
    lda zp_score_mid
    adc #$10                ; +1000 punti: mid += 10 (BCD), propaga il riporto
    sta zp_score_mid
    lda zp_score_hi
    adc #$00
    sta zp_score_hi
    cld
    jsr score_check_threshold
register_overtake_done:
    rts

; Confronto multi-byte BCD score >= threshold (il confronto binario standard
; funziona anche su cifre BCD valide, l'ordinamento dei byte e' preservato).
; Se vero: estende il timer e alza la soglia successiva di altri 20000.
score_check_threshold:
    sec
    lda zp_score_lo
    sbc zp_threshold_lo
    lda zp_score_mid
    sbc zp_threshold_mid
    lda zp_score_hi
    sbc zp_threshold_hi
    bcc score_check_threshold_done   ; score < threshold: niente da fare

    sed
    lda zp_timer_seconds
    clc
    adc #TIME_BONUS
    sta zp_timer_seconds
    cld

    sed
    lda zp_threshold_mid
    clc
    adc #$00
    sta zp_threshold_mid
    lda zp_threshold_hi
    adc #$02                ; soglia successiva: +20000 (hi += 2 BCD)
    sta zp_threshold_hi
    cld
score_check_threshold_done:
    rts

; Un secondo ogni 50 frame (PAL). Il conto si ferma a 0 (game over non
; gestito in MVP -- fuori scope task 10, vedi ARCHITECTURE.md Fase 2+).
update_timer:
    inc zp_timer_frames
    lda zp_timer_frames
    cmp #50
    bne update_timer_done
    lda #$00
    sta zp_timer_frames

    lda zp_timer_seconds
    beq update_timer_done
    sed
    sec
    sbc #$01
    cld
    sta zp_timer_seconds
update_timer_done:
    rts

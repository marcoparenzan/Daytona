; sfx.asm -- effetti sonori diretti via SID (task 11 della roadmap MVP).
;
; Voce 1 = motore (continuo, frequenza legata a zp_player_speed).
; Voce 2 = crash (burst di rumore, un colpo per urto).
; Voce 3 = box (tono breve all'ingresso in corsia box).
;
; Tutte le voci SFX usano sustain=0: dopo l'attacco/decadimento il suono si
; spegne da solo, senza bisogno di un timer per il "release" manuale -- per
; ri-innescare basta forzare gate OFF poi ON (l'attacco riparte solo sul
; fronte di salita del bit gate, vedi sid.a).
;
; NOTA: se in futuro si aggiunge la musica GoatTracker (task 12/Fase 2),
; questa mappatura voci 1/2/3 va rivista (GT2 tipicamente usa tutte e 3) --
; vedi ARCHITECTURE.md par. 1 (audio) e Fase 2+.

sfx_init:
    lda #$0f
    sta sid_filter_volume        ; volume massimo, nessun filtro

    ; motore: dente di sega continuo, risposta immediata ai cambi di velocita'
    lda #$00
    sta sid_v1_attack_decay
    lda #$f0
    sta sid_v1_sustain_release    ; sustain pieno, release 0 -- resta acceso finche' gira il motore
    lda #(sid_VOICECONTROL_SAWTOOTH | sid_VOICECONTROL_ON)
    sta sid_v1_control

    ; crash: rumore, sustain 0 -> si spegne da solo dopo il decadimento
    lda #$08
    sta sid_v2_attack_decay
    lda #$00
    sta sid_v2_sustain_release
    lda #$00
    sta sid_v2_control

    ; box: tono triangolare breve, sustain 0
    lda #$20
    sta sid_v3_attack_decay
    lda #$00
    sta sid_v3_sustain_release
    lda #$00
    sta sid_v3_control
    rts

; Da chiamare ogni frame: aggiorna la frequenza del motore in base alla velocita'.
; freq_hi da $05 (~75Hz, minimo) a $14 (~300Hz, massimo) -- registro SID basso,
; range da "rombo" invece del fischio acuto della prima versione (freq_hi
; partiva da $10=16 arrivando oltre $4F, cioe' ben sopra 1000Hz).
update_engine:
    lda zp_player_speed
    lsr
    lsr                     ; velocita' / 4 -> 0-15
    clc
    adc #$05
    sta sid_v1_freq_hi
    rts

; Da chiamare una volta per urto (vedi collision.asm).
sfx_trigger_crash:
    lda #sid_VOICECONTROL_NOISE
    sta sid_v2_control            ; gate off: garantisce il fronte di salita al trigger sotto
    lda #$60
    sta sid_v2_freq_hi
    lda #(sid_VOICECONTROL_NOISE | sid_VOICECONTROL_ON)
    sta sid_v2_control
    rts

; Da chiamare una volta all'ingresso in corsia box (vedi pitstop.asm).
sfx_trigger_pit:
    lda #sid_VOICECONTROL_TRIANGLE
    sta sid_v3_control
    lda #$30
    sta sid_v3_freq_hi
    lda #(sid_VOICECONTROL_TRIANGLE | sid_VOICECONTROL_ON)
    sta sid_v3_control
    rts

; pitstop.asm -- stato box: crash -> ingresso forzato in corsia box -> riparazione
; a tempo -> ripartenza pulita (task 9 della roadmap MVP).
;
; A differenza dell'originale, l'ingresso in corsia box e' una transizione di
; stato UNA TANTUM (si fissa la X del giocatore sulla corsia box al momento
; dell'urto), non una forza continua che tira il giocatore ogni frame -- quello
; era il fastidioso bug dell'originale (risucchio anche in uscita, vedi
; ARCHITECTURE.md par. 1). Durante la riparazione lo sterzo e' disabilitato
; (physics.asm ignora l'input mentre zp_pit_state != STATE_NORMAL); alla fine
; il controllo torna normale senza alcun residuo di "risucchio".

STATE_NORMAL    = 0
STATE_REPAIRING = 1

PIT_LANE_X  = 48    ; colonna 3 in pixel (24 + 3*8), coerente con track.asm
REPAIR_TIME = 120   ; frame di riparazione (~2.4s a 50Hz)

pitstop_init:
    lda #STATE_NORMAL
    sta zp_pit_state
    rts

; Chiamata da collision.asm quando il player e' coinvolto in una collisione.
enter_pit:
    lda zp_pit_state
    bne enter_pit_already   ; gia' in riparazione: ignora ulteriori urti
    lda #$00
    sta zp_overtake_streak  ; il crash azzera la striscia (non il totale sorpassi, vedi score.asm)
    lda #STATE_REPAIRING
    sta zp_pit_state
    lda #REPAIR_TIME
    sta zp_pit_timer
    lda #PIT_LANE_X
    sta zp_player_x
    sta vic_xs0
    lda #viccolor_ORANGE
    sta vic_cs0
enter_pit_already:
    rts

update_pitstop:
    lda zp_pit_state
    beq update_pitstop_done   ; STATE_NORMAL: niente da fare
    dec zp_pit_timer
    bne update_pitstop_done
    lda #STATE_NORMAL
    sta zp_pit_state
    lda #viccolor_WHITE
    sta vic_cs0
update_pitstop_done:
    rts

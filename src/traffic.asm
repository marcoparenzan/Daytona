; traffic.asm -- spawn e movimento del traffico (task 7 della roadmap MVP).
;
; Pool di 4 slot, uno per sprite hardware (1-4; lo sprite 0 e' il giocatore).
; Ogni slot ha una corsia X fissa e una velocita' "di mondo" propria: la
; posizione Y sullo schermo si sposta ogni frame di (player_speed - velocita'
; dello slot), con segno. Se lo slot e' piu' lento del giocatore il delta e'
; positivo -> l'auto scende verso il basso (il giocatore la sta sorpassando).
; Se e' piu' veloce, il delta e' negativo -> l'auto risale verso l'alto (si
; allontana in avanti). Codice srotolato per slot invece che indicizzato: i
; registri sprite del VIC-II non sono un array pulito, meglio esplicito che
; rischiare un altro bug di indirizzamento come quello gia' preso in track.asm.
;
; Collisioni (sprite-sprite via $D01E) arrivano nel task 8.

TRAFFIC_LANE0_X = 60
TRAFFIC_LANE1_X = 114
TRAFFIC_LANE2_X = 168
TRAFFIC_LANE3_X = 222

TRAFFIC_SPEED_SLOW   = 5    ; molto piu' lenta del giocatore -> si viene sorpassati spesso
TRAFFIC_SPEED_MED    = 15
TRAFFIC_SPEED_MED2   = 20
TRAFFIC_SPEED_FAST   = 35   ; comunque sotto PLAYER_MAX_SPEED -> a tutto gas si sorpassa chiunque

TRAFFIC_MAX_STEP    = 3      ; clamp al delta Y per frame -- vedi nota in traffic_move_slot0
TRAFFIC_SPAWN_Y     = 40
TRAFFIC_SPAWN_EVERY = 90     ; frame tra un tentativo di spawn e il successivo (~1.8s a 50Hz)
TRAFFIC_DESPAWN_HI  = 250    ; oltre questo Y (in basso) l'auto e' uscita dallo schermo
TRAFFIC_DESPAWN_LO  = 4      ; sotto questo Y (in alto) l'auto e' fuggita in avanti -- margine
                              ; ampio rispetto a TRAFFIC_SPAWN_Y cosi' resta visibile piu' a lungo

traffic_active: !byte 0, 0, 0, 0
traffic_x:      !byte 0, 0, 0, 0
traffic_y:      !byte 0, 0, 0, 0
traffic_speed:  !byte 0, 0, 0, 0

traffic_init:
    lda #$00
    sta traffic_active
    sta traffic_active + 1
    sta traffic_active + 2
    sta traffic_active + 3
    sta zp_traffic_spawn_timer

    lda #(sprite_base / 64)
    sta screen_base + $3f9
    sta screen_base + $3fa
    sta screen_base + $3fb
    sta screen_base + $3fc

    lda #viccolor_RED
    sta vic_cs1
    sta vic_cs2
    sta vic_cs3
    sta vic_cs4
    rts

update_traffic:
    inc zp_traffic_spawn_timer
    lda zp_traffic_spawn_timer
    cmp #TRAFFIC_SPAWN_EVERY
    bne traffic_move_all
    lda #$00
    sta zp_traffic_spawn_timer
    jsr traffic_try_spawn

traffic_move_all:
    jsr traffic_move_slot0
    jsr traffic_move_slot1
    jsr traffic_move_slot2
    jsr traffic_move_slot3
    rts

; --- spawn: nel primo slot libero, altrimenti non fa nulla ---
traffic_try_spawn:
    lda traffic_active
    beq spawn_slot0
    lda traffic_active + 1
    beq spawn_slot1
    lda traffic_active + 2
    beq spawn_slot2
    lda traffic_active + 3
    beq spawn_slot3
    rts

spawn_slot0:
    lda #TRAFFIC_LANE0_X
    sta traffic_x
    lda #TRAFFIC_SPAWN_Y
    sta traffic_y
    lda #TRAFFIC_SPEED_SLOW
    sta traffic_speed
    lda #$01
    sta traffic_active
    lda vic_sactive
    ora #%00000010
    sta vic_sactive
    rts

spawn_slot1:
    lda #TRAFFIC_LANE1_X
    sta traffic_x + 1
    lda #TRAFFIC_SPAWN_Y
    sta traffic_y + 1
    lda #TRAFFIC_SPEED_FAST
    sta traffic_speed + 1
    lda #$01
    sta traffic_active + 1
    lda vic_sactive
    ora #%00000100
    sta vic_sactive
    rts

spawn_slot2:
    lda #TRAFFIC_LANE2_X
    sta traffic_x + 2
    lda #TRAFFIC_SPAWN_Y
    sta traffic_y + 2
    lda #TRAFFIC_SPEED_MED
    sta traffic_speed + 2
    lda #$01
    sta traffic_active + 2
    lda vic_sactive
    ora #%00001000
    sta vic_sactive
    rts

spawn_slot3:
    lda #TRAFFIC_LANE3_X
    sta traffic_x + 3
    lda #TRAFFIC_SPAWN_Y
    sta traffic_y + 3
    lda #TRAFFIC_SPEED_MED2
    sta traffic_speed + 3
    lda #$01
    sta traffic_active + 3
    lda vic_sactive
    ora #%00010000
    sta vic_sactive
    rts

; --- movimento, uno slot per volta ---
traffic_move_slot0:
    lda traffic_active
    beq traffic_move_slot0_done
    lda zp_player_speed
    sec
    sbc traffic_speed
    ; clamp del delta con segno a +/-TRAFFIC_MAX_STEP: applicato 1:1 ogni frame
    ; l'auto sparirebbe in pochi frame (a differenza dello scroll pista, che
    ; avanza per accumulatore, non 1:1) -- vedi nota in cima al file.
    bmi traffic_clamp_neg0
    cmp #(TRAFFIC_MAX_STEP + 1)
    bcc traffic_clamp_done0
    lda #TRAFFIC_MAX_STEP
    jmp traffic_clamp_done0
traffic_clamp_neg0:
    cmp #(256 - TRAFFIC_MAX_STEP)
    bcs traffic_clamp_done0
    lda #(256 - TRAFFIC_MAX_STEP)
traffic_clamp_done0:
    clc
    adc traffic_y
    sta traffic_y
    cmp #TRAFFIC_DESPAWN_HI
    bcs traffic_overtake_slot0   ; uscita dal basso = sorpasso pulito
    cmp #TRAFFIC_DESPAWN_LO
    bcc traffic_hide_slot0        ; uscita dall'alto (piu' veloce, fuggita) = nessun credito
    lda traffic_y
    sta vic_ys1
    lda traffic_x
    sta vic_xs1
traffic_move_slot0_done:
    rts
traffic_overtake_slot0:
    jsr register_overtake
traffic_hide_slot0:
    lda #$00
    sta traffic_active
    lda vic_sactive
    and #%11111101
    sta vic_sactive
    rts

traffic_move_slot1:
    lda traffic_active + 1
    beq traffic_move_slot1_done
    lda zp_player_speed
    sec
    sbc traffic_speed + 1
    bmi traffic_clamp_neg1
    cmp #(TRAFFIC_MAX_STEP + 1)
    bcc traffic_clamp_done1
    lda #TRAFFIC_MAX_STEP
    jmp traffic_clamp_done1
traffic_clamp_neg1:
    cmp #(256 - TRAFFIC_MAX_STEP)
    bcs traffic_clamp_done1
    lda #(256 - TRAFFIC_MAX_STEP)
traffic_clamp_done1:
    clc
    adc traffic_y + 1
    sta traffic_y + 1
    cmp #TRAFFIC_DESPAWN_HI
    bcs traffic_overtake_slot1
    cmp #TRAFFIC_DESPAWN_LO
    bcc traffic_hide_slot1
    lda traffic_y + 1
    sta vic_ys2
    lda traffic_x + 1
    sta vic_xs2
traffic_move_slot1_done:
    rts
traffic_overtake_slot1:
    jsr register_overtake
traffic_hide_slot1:
    lda #$00
    sta traffic_active + 1
    lda vic_sactive
    and #%11111011
    sta vic_sactive
    rts

traffic_move_slot2:
    lda traffic_active + 2
    beq traffic_move_slot2_done
    lda zp_player_speed
    sec
    sbc traffic_speed + 2
    bmi traffic_clamp_neg2
    cmp #(TRAFFIC_MAX_STEP + 1)
    bcc traffic_clamp_done2
    lda #TRAFFIC_MAX_STEP
    jmp traffic_clamp_done2
traffic_clamp_neg2:
    cmp #(256 - TRAFFIC_MAX_STEP)
    bcs traffic_clamp_done2
    lda #(256 - TRAFFIC_MAX_STEP)
traffic_clamp_done2:
    clc
    adc traffic_y + 2
    sta traffic_y + 2
    cmp #TRAFFIC_DESPAWN_HI
    bcs traffic_overtake_slot2
    cmp #TRAFFIC_DESPAWN_LO
    bcc traffic_hide_slot2
    lda traffic_y + 2
    sta vic_ys3
    lda traffic_x + 2
    sta vic_xs3
traffic_move_slot2_done:
    rts
traffic_overtake_slot2:
    jsr register_overtake
traffic_hide_slot2:
    lda #$00
    sta traffic_active + 2
    lda vic_sactive
    and #%11110111
    sta vic_sactive
    rts

traffic_move_slot3:
    lda traffic_active + 3
    beq traffic_move_slot3_done
    lda zp_player_speed
    sec
    sbc traffic_speed + 3
    bmi traffic_clamp_neg3
    cmp #(TRAFFIC_MAX_STEP + 1)
    bcc traffic_clamp_done3
    lda #TRAFFIC_MAX_STEP
    jmp traffic_clamp_done3
traffic_clamp_neg3:
    cmp #(256 - TRAFFIC_MAX_STEP)
    bcs traffic_clamp_done3
    lda #(256 - TRAFFIC_MAX_STEP)
traffic_clamp_done3:
    clc
    adc traffic_y + 3
    sta traffic_y + 3
    cmp #TRAFFIC_DESPAWN_HI
    bcs traffic_overtake_slot3
    cmp #TRAFFIC_DESPAWN_LO
    bcc traffic_hide_slot3
    lda traffic_y + 3
    sta vic_ys4
    lda traffic_x + 3
    sta vic_xs4
traffic_move_slot3_done:
    rts
traffic_overtake_slot3:
    jsr register_overtake
traffic_hide_slot3:
    lda #$00
    sta traffic_active + 3
    lda vic_sactive
    and #%11101111
    sta vic_sactive
    rts

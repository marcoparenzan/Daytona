; physics.asm -- sterzo e velocita' base (task 5 della roadmap MVP).
; Nessuno scroll ancora (arriva nel task 6): qui si prova solo che
; input -> sprite risponda correttamente.

PLAYER_MIN_X      = 30
PLAYER_MAX_X      = 250
PLAYER_STEP       = 2
PLAYER_MAX_SPEED  = 63

update_physics:
    lda zp_pit_state
    bne physics_repairing   ; in riparazione: sterzo E accelerazione ignorati (auto ferma, motore
                             ; a zero -- vedi pitstop.asm che azzera zp_player_speed all'ingresso)

    lda zp_joy_state
    and #%00000100          ; bit2 = sinistra (0 = premuto)
    bne physics_check_right
    lda zp_player_x
    sec
    sbc #PLAYER_STEP
    cmp #PLAYER_MIN_X
    bcs physics_store_left
    lda #PLAYER_MIN_X
physics_store_left:
    sta zp_player_x

physics_check_right:
    lda zp_joy_state
    and #%00001000          ; bit3 = destra (0 = premuto)
    bne physics_check_fire
    lda zp_player_x
    clc
    adc #PLAYER_STEP
    cmp #(PLAYER_MAX_X + 1)
    bcc physics_store_right
    lda #PLAYER_MAX_X
physics_store_right:
    sta zp_player_x

physics_check_fire:
    lda zp_joy_state
    and #%00010000          ; bit4 = fire (0 = premuto)
    bne physics_decel
    lda zp_player_speed
    cmp #PLAYER_MAX_SPEED
    beq physics_apply
    inc zp_player_speed
    jmp physics_apply

physics_decel:
    lda zp_player_speed
    beq physics_apply
    dec zp_player_speed

physics_apply:
    lda zp_player_x
    sta vic_xs0
    rts

physics_repairing:
    rts

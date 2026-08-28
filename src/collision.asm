; collision.asm -- collisioni player-traffico (task 8 della roadmap MVP).
;
; Usa il registro hardware $D01E (collisione sprite-sprite): la lettura
; azzera il registro da sola (vedi ACME_Lib vic.a, "reading clears register!"),
; quindi va letto UNA sola volta per frame. Se il bit dello sprite player
; (bit0) e' settato, il player e' stato coinvolto in almeno una collisione
; (essendo l'unica altra categoria di sprite attiva, e' per forza traffico).
;
; La reazione (colore, ingresso in corsia box, timer di riparazione) e'
; gestita da pitstop.asm (task 9): qui ci si limita a rilevare l'urto.

check_collision:
    lda vic_ss_collided
    and #%00000001
    beq check_collision_done
    jsr sfx_trigger_crash
    jsr enter_pit
check_collision_done:
    rts

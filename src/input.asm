; input.asm -- lettura joystick porta 2 (task 5 della roadmap MVP).
; cia1_pra ($dc00): bit0=su bit1=giu bit2=sinistra bit3=destra bit4=fire,
; tutti attivi bassi (0 = premuto) -- vedi ACME_Lib cbm/c64/cia1.a.

read_input:
    lda cia1_pra
    sta zp_joy_state
    rts

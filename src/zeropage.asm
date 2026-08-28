; zeropage.asm -- allocazione zero page, un byte per riga con proprietario.
; $FB-$FE sono la zona "libera per programmi utente" per convenzione C64 diffusa,
; sicura anche per un programma che prende il controllo completo della macchina
; come il nostro (vedi ARCHITECTURE.md par. 5).

zp_str_lo = $fb   ; testpattern.asm: puntatore lo alla stringa da stampare (print_string)
zp_str_hi = $fc   ; testpattern.asm: puntatore hi alla stringa da stampare (print_string)
zp_dst_lo = $fd   ; testpattern.asm: puntatore lo alla destinazione in screen RAM (print_string)
zp_dst_hi = $fe   ; testpattern.asm: puntatore hi alla destinazione in screen RAM (print_string)

zp_joy_state    = $f9   ; input.asm: ultimo stato letto da cia1_pra (joystick porta 2)
zp_player_x     = $f8   ; physics.asm: posizione X dello sprite giocatore (0-255)
zp_player_speed = $f7   ; physics.asm: velocita' corrente (0-PLAYER_MAX_SPEED), guida lo scroll (track.asm)

; ATTENZIONE: per l'indirizzamento indiretto (zp),y del 6502 il byte alto DEVE
; stare a "lo+1" -- non spostare i due membri di ciascuna coppia senza tenerli adiacenti.
zp_scroll_rows_left = $f0   ; track.asm: contatore righe rimanenti durante lo shift
zp_scroll_accum     = $f1   ; track.asm: accumulatore stile Bresenham per la velocita' di scroll
zp_scroll_src_lo    = $f2   ; track.asm: puntatore riga sorgente durante lo shift (byte alto a $f3)
zp_scroll_src_hi    = $f3
zp_scroll_dst_lo    = $f4   ; track.asm: puntatore riga destinazione durante lo shift (byte alto a $f5)
zp_scroll_dst_hi    = $f5
; $f6 libero (era zp_fine_scroll, rimosso: niente piu' scroll a sotto-pixel, vedi track.asm)
zp_traffic_spawn_timer = $fa   ; traffic.asm: contatore frame verso il prossimo tentativo di spawn

; $f0-$fe sono ormai tutti occupati: si prosegue nella zona bassa ($02+), sicura
; per un programma che non richiama piu' BASIC/KERNAL (vedi nota in cima al file).
zp_pit_state = $02   ; pitstop.asm: STATE_NORMAL o STATE_REPAIRING
zp_pit_timer = $03   ; pitstop.asm: frame rimanenti di riparazione

; score.asm -- punteggio/timer in BCD (un nibble = una cifra, comodo da stampare)
zp_score_lo         = $04
zp_score_mid        = $05
zp_score_hi         = $06
zp_overtake_streak  = $07   ; sorpassi consecutivi senza crash (azzerato in pitstop.asm)
zp_overtake_total   = $08   ; sorpassi totali di sessione (per l'HUD "CARS")
zp_threshold_lo     = $09   ; prossima soglia punteggio per il bonus tempo, BCD
zp_threshold_mid    = $0a
zp_threshold_hi     = $0b
zp_timer_seconds    = $0c   ; BCD, conto alla rovescia
zp_timer_frames     = $0d   ; frame dall'ultimo secondo scalato

; hud.asm -- scratch per la conversione binario -> cifre decimali (speed, cars)
zp_conv_hundreds = $0e
zp_conv_tens     = $0f
zp_conv_ones     = $10

; $e0/$e1 riservati al player GoatTracker (music.asm, opzione -ZE0 di gt2reloc) --
; non riutilizzare per altre variabili.

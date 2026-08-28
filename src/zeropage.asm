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
zp_fine_scroll      = $f6   ; track.asm: passo di fine-scroll corrente (0-7), specchio dei bit0-2 di vic_controlv

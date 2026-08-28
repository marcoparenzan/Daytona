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
zp_player_speed = $f7   ; physics.asm: velocita' corrente (0-PLAYER_MAX_SPEED), non ancora usata per lo scroll (task 6)

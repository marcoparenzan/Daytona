; main.asm -- entry point. Include tutti i moduli in ordine.
; Assemblato con: tools/acme/acme.exe -f cbm -o build/daytona.prg src/main.asm (vedi scripts/build.ps1)

!source "memmap.asm"
!source "zeropage.asm"

* = $0801
!byte $0c, $08, $0a, $00, $9e, $20, $32, $30, $36, $34, $00, $00, $00   ; "10 SYS 2064" -> code_start

!source "irq.asm"
!source "charset.asm"
!source "testpattern.asm"
!source "hud.asm"
!source "input.asm"
!source "physics.asm"
!source "player.asm"
!source "track.asm"
!source "traffic.asm"
!source "collision.asm"
!source "pitstop.asm"
!source "score.asm"
!source "sfx.asm"
!source "music.asm"

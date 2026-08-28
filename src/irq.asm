; irq.asm -- avvio e catena IRQ raster.
;
; MVP (task 2, skeleton boot): un solo raster IRQ per frame, alla riga 0.
; Per ora incrementa il colore del bordo ad ogni frame: e' la prova visiva
; che l'IRQ gira in modo stabile, senza freeze ne' doppie interruzioni.
; Fisica/scroll/traffico/collisioni/HUD verranno agganciati qui nei task successivi
; (vedi ARCHITECTURE.md par. 6 per la struttura completa prevista).
;
; Nomi dei registri da ACME_Lib (vic_*, cia1_*, cia2_*) -- vedi memmap.asm.

* = code_start

init:
    sei

    lda #$7f
    sta cia1_icr        ; disabilita interrupt del timer CIA1 (altrimenti confligge con l'IRQ raster)
    sta cia2_icr        ; disabilita interrupt del timer CIA2
    lda cia1_icr         ; ack di eventuali IRQ CIA1 pendenti
    lda cia2_icr         ; ack di eventuali IRQ CIA2 pendenti

    jsr charset_init
    lda #$18
    sta vic_ram           ; screen RAM $0400, charset custom a charset_base ($2000)
    lda #viccolor_BLACK
    sta vic_cbg            ; sfondo nero (le tile/il testo usano color RAM come inchiostro)
    jsr render_test_pattern
    jsr draw_static_hud
    jsr player_init
    jsr scroll_init

    lda vic_controlv
    and #%01111111      ; bit 7 a 0 -> riga raster su 8 bit (< 256)
    sta vic_controlv
    lda #$00
    sta vic_line         ; interrompi alla riga raster 0 (inizio schermo)

    lda #$01
    sta vic_irqmask       ; abilita l'IRQ raster nel VIC-II

    lda #<irq_handler
    sta sys_irq_vector
    lda #>irq_handler
    sta sys_irq_vector+1

    cli

main_loop:
    jmp main_loop

irq_handler:
    inc vic_cborder      ; bordo cambia colore ogni frame: prova visiva che l'IRQ e' stabile
    jsr read_input
    jsr update_physics
    jsr update_scroll
    lda #$ff
    sta vic_irq           ; ack IRQ VIC-II (azzera tutti i flag pendenti)
    jmp kernal_irq_exit    ; rientra nella coda standard del KERNAL (ripristina registri, RTI)

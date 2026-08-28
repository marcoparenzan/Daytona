; music.asm -- aggancio del player GoatTracker nell'IRQ (task 12 della roadmap MVP).
;
; Il player e i dati del brano sono un binario gia' assemblato e rilocato da
; GoatTracker (tools/goattracker/win32/gt2reloc.exe), non sorgente ACME: il
; player.s originale e' scritto per l'assemblatore di Magnus Lind (Exomizer),
; non portabile direttamente (vedi il commento in cima a quel file). Si
; include quindi il binario gia' pronto via !binary, piazzato a music_base
; ($4000, sopra charset/sprite/schermo -- vedi ARCHITECTURE.md par. 5).
;
; Rigenerare assets/gen/music.bin da un .sng con:
;   tools/goattracker/win32/gt2reloc.exe <file.sng> assets/gen/music.bin -W40 -ZE0 -P
; (zero page $E0/$E1 riservati al player: verificare che restino liberi in
; zeropage.asm se si aggiungono nuove variabili in futuro).
;
; assets/src/music/placeholder.sng e' un esempio incluso con GoatTracker (non
; un brano composto per Daytona) -- provato ad orecchio dall'utente, confermato
; funzionante. Il player scrive sulle stesse voci SID 1/2/3 usate dagli SFX
; diretti (sfx.asm): l'utente ha scelto di tenerlo comunque attivo ogni frame
; (jsr music_play in irq.asm) accettando la possibile interferenza, invece di
; lasciarlo dormiente. Da rivedere in Fase 2+ (voci dedicate, brano vero
; composto per Daytona invece del placeholder) -- vedi ARCHITECTURE.md.

music_base = $4000

* = music_base
!binary "../assets/gen/music.bin"

; A = numero di subtune (0 = il primo/unico)
music_init:
    lda #$00
    jsr music_base
    rts

; da richiamare una volta per frame quando si decide di attivare la musica
music_play:
    jsr music_base + 3
    rts

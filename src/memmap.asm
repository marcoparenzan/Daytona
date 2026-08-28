; memmap.asm -- fonte di verita' unica per gli indirizzi di memoria del gioco.
; Vedi ARCHITECTURE.md par. 5 per i vincoli (allineamento charset 2KB, sprite 64 byte, ecc).

; Costanti per i registri notevoli (VIC-II, CIA1, CIA2) dalla libreria standard
; inclusa con ACME: tools/acme/acme/ACME_Lib/cbm/c64/*.a (vic.a, cia1.a, cia2.a, sid.a).
; La sintassi con parentesi angolari <...> cerca dentro ACME_Lib invece che nella
; cartella corrente -- vedi tools/acme/acme/docs/Lib.txt.
!source <cbm/c64/vic.a>
!source <cbm/c64/cia1.a>
!source <cbm/c64/cia2.a>
!source <cbm/c64/sid.a>

; Non presenti in ACME_Lib per il C64 (sono indirizzi RAM/ROM del sistema operativo,
; non registri hardware): li definiamo qui.
sys_irq_vector    = $0314   ; CINV -- vettore IRQ indiretto usato dalla routine hardware del KERNAL ($ff48)
kernal_irq_exit   = $ea81    ; coda della routine IRQ standard del KERNAL: ripristina i registri ed esegue RTI

code_start   = $0810   ; ATTENZIONE: deve combaciare con "SYS 2064" nello stub BASIC in main.asm

charset_base = $2000   ; 2KB, allineato per $D018 (charset custom, task 3)
sprite_base  = $3000    ; allineato a 64 byte -- puntatori sprite = indirizzo/64 (task 5)
screen_base  = $0400    ; screen RAM di default, banco VIC 0
color_ram    = $d800    ; indirizzo hardware fisso

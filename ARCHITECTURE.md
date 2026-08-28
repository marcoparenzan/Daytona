# Daytona — Architettura e Piano

Documento vivo: aggiornarlo quando cambiano decisioni tecniche, memory map o roadmap.

## 1. Riferimento: Le Mans (C64, 1982, HAL Laboratory)

Daytona è un remake spirituale, non un porting 1:1. Meccaniche originali usate come base:

- Vista dall'alto, scroll verticale, auto del giocatore fissa in basso schermo.
- Sterzo via paddle (originale) — **in Daytona: joystick porta 2**, sinistra/destra sterza.
- Fire tenuto = accelera, rilasciato = decelera (mantenuto identico).
- Traffico da sorpassare; collisione → fumo + rientro forzato ai box (corsia a sinistra) per riparare, con perdita di tempo.
- Bug noto dell'originale: risucchio "magnetico" verso i box anche in uscita. **Non va replicato**: la transizione crash→box→ripartenza deve essere una state machine pulita.
- Punteggio: 2 punti/metro percorso. Bonus +1000 ogni 10 sorpassi consecutivi senza crash (un crash azzera la striscia).
- Timer: 60s iniziali, estensione ogni 20.000 punti raggiunti.
- HUD sul bordo destro: velocità, punteggio, tempo, auto sorpassate.
- Fasi giorno / notte (fari accesi, visibilità ridotta) / neve-ghiaccio (aderenza alterata) — **fasi Daytona: giorno in MVP, notte/pioggia in Fase 2+**.
- Nessuna musica nell'originale, solo SFX — **Daytona aggiunge musica SID** (GoatTracker 2) oltre alle SFX.

## 2. Decisioni di progetto

| Area | Scelta | Motivazione |
|---|---|---|
| Assembler | ACME | Puro 6502/6510, leggero, nessuna JVM richiesta (vs KickAssembler), più diretto di cc65/ca65 per un progetto asm puro |
| Emulatore | VICE `x64sc` | Cycle-exact, timing corretto per IRQ raster (vs `x64` più veloce ma meno accurato) |
| Charmap/tile | **CharPad Classic** (free, Subchrist Software) | Standard scena C64, esporta charset/tilemap già in binario pronto per `!binary` — nessuna conversione necessaria |
| PETSCII/schermate | **Petmate 9** (open source) | Editor PETSCII dedicato per bozze HUD/schermate testuali |
| Grafica (fallback) | PNG → script PowerShell custom (`png2charset.ps1`, `png2sprite.ps1`, via `System.Drawing`) | Percorso alternativo senza CharPad, nessuna dipendenza extra (niente Python/Pillow), riproducibile da versionamento |
| Musica | GoatTracker 2 | Standard de facto per SID tracker, player relocabile integrabile in IRQ |
| Controlli MVP | Joystick porta 2 | Paddle scomode su setup moderni; joystick è lo standard |
| Scope MVP | Un solo stage "giorno" | Validare il game loop end-to-end prima di aggiungere varianti |

## 3. Toolchain

Tutto portabile, in `tools/` (non versionato), installato da `scripts/setup-tools.ps1`, nessun privilegio amministrativo richiesto.

- `tools/acme/acme.exe` — cross-assembler
- `tools/vice/x64sc.exe`, `tools/vice/c1541.exe` — emulatore + packaging disco
- `tools/charpad/` — CharPad Classic (editor charset/tile, download manuale da itch.io: nessun URL diretto stabile, lo script segnala dove salvare lo zip)
- `tools/petmate9/` — Petmate 9 (editor PETSCII, installer da lanciare una volta manualmente)
- `tools/goattracker/` — tracker SID + player driver (Fase 1.5/2)
- `tools/VERSIONS.md` — versioni/URL pinnati per riproducibilità

Charset e tile: il percorso primario è **autorare in CharPad Classic** ed esportare direttamente il binario C64-ready (nessuna conversione necessaria). `png2charset.ps1`/`png2sprite.ps1` restano come pipeline alternativa/leggera (PNG generico → binario) per chi non usa CharPad o per iterazioni rapide su sprite.

## 4. Struttura del codice sorgente

```
src/
├── main.asm       # stub BASIC, entry point, !source di tutti i moduli
├── memmap.asm     # fonte di verità unica per tutti gli indirizzi
├── zeropage.asm   # allocazione zero-page documentata (owner per byte)
├── irq.asm        # catena IRQ raster
├── input.asm      # lettura joystick porta 2               [task 5]
├── physics.asm    # velocità/accelerazione/sterzo           [task 5]
├── scroll.asm     # scroll verticale pista                   [task 6]
├── track.asm      # pattern pista (strada/cordolo/erba/pit)  [task 6]
├── traffic.asm    # spawn/movimento traffico                 [task 7]
├── collision.asm  # collisioni player-traffico ($D01E)       [task 8]
├── pitstop.asm    # stato crash → box → riparazione          [task 9]
├── score.asm      # punteggio, streak, timer                 [task 10]
├── hud.asm        # rendering HUD bordo destro                [task 4/10]
├── sfx.asm        # SID diretto: motore/crash/box              [task 11]
└── music.asm      # hook player GoatTracker nell'IRQ            [task 12]
```

I moduli marcati `[task N]` vengono creati quando si affronta quel task della roadmap (niente file vuoti/placeholder anticipati).

## 5. Memory map

| Indirizzo | Contenuto | Note |
|---|---|---|
| `$0801` | Stub BASIC (`SYS` di avvio) | ACME `-f cbm` scrive l'indirizzo di caricamento dal primo `* =` |
| `$0810`+ | Codice di gioco (`main.asm` e moduli `!source`) | Subito dopo lo stub |
| `$2000`–`$27FF` | Charset custom (2KB) | Deve iniziare su boundary 2KB per `$D018` |
| `$2800`–`$2FFF` | Tabelle pattern pista, tabelle AI traffico | |
| `$3000`+ | Dati sprite (player, traffico, fumo) | Allineati a 64 byte (puntatori sprite = indirizzo/64) |
| `$0400`–`$07E7` | Screen RAM (default banco VIC 0) | Nessun bank switching in MVP |
| `$D800`–`$DBE7` | Color RAM | Indirizzo hardware fisso |
| `$4000`+ | Player + dati musica GoatTracker rilocati | Sopra i blocchi grafici |

Zero page (range da confermare libero da conflitti KERNAL/BASIC, indicativamente `$02`–`$8F`):
`zp_player_x`, `zp_player_speed`, `zp_scroll_offset_lo/hi`, `zp_traffic_ptr`, `zp_temp0/1/2`, `zp_score_lo/mid/hi`, `zp_frame_counter` — ogni byte documentato in `src/zeropage.asm`.

## 6. VIC-II e IRQ

- **Modalità**: caratteri hi-res standard per lo sfondo (leggibilità a velocità), sprite multicolor per le auto (livree a più colori). Coesistono senza conflitti.
- **Banco VIC**: banco 0 (`$0000`–`$3FFF`), nessun bank switching in MVP.
- **IRQ**: un singolo raster IRQ per frame in MVP (struttura predisposta per raster-split futuro):
  1. Ack IRQ VIC (`$D019`)
  2. Play musica GT2 (silenziosa/placeholder finché non composta)
  3. Lettura joystick porta 2 (`$DC00`, bit0=up bit1=down bit2=left bit3=right bit4=fire, active-low)
  4. Fisica/scroll/traffico/collisioni/punteggio/HUD
  5. `RTI`

## 7. Roadmap MVP

1. ✅ Bring-up toolchain (ACME, VICE, Petmate 9, GoatTracker scaricati e verificati; CharPad da scaricare a mano)
2. ✅ Skeleton boot (stub BASIC + IRQ raster stabile) -- verificato via monitor remoto VICE (bordo che cicla stabilmente, PC fermo in `main_loop`, nessun freeze/trap KERNAL)
3. ✅ Charset custom + pattern statico di verifica -- font ROM copiato in RAM + 5 tile patchate (road/curb/grass/pit/finish, codici 128-132), verificato via dump memoria VICE ← **stato attuale**
4. ✅ HUD statico -- etichette SPEED/SCORE/TIME/CARS su colonna 34, righe 2/6/10/14, verificate via dump memoria VICE
5. ✅ Sprite player + input joystick + fisica base -- sprite segnaposto hi-res, sterzo/velocita' verificati via monitor VICE (poke su `$DC00` -> clamp esatto a `PLAYER_MIN_X`)
6. Scroll verticale pista ← **stato attuale**
7. Spawn/movimento traffico
8. Collisioni player-traffico
9. Stato box (crash → riparazione → ripartenza pulita)
10. Punteggio/timer + HUD live
11. SFX dirette SID
12. Hook player GoatTracker nell'IRQ

### Fase 2+ (fuori scope MVP)

- Stage notte (fari, visibilità ridotta)
- Stage pioggia/neve-ghiaccio (aderenza alterata)
- Supporto paddle
- Brano musicale composto (oltre all'hook player già presente)
- Valutazione upgrade a CharPad per il workflow grafico

## 8. Verifica

Per ogni task, uso del monitor ML di VICE (`tools/vice/x64sc.exe -moncommands ...` o monitor interattivo) per ispezionare memoria (charset, screen RAM, tabelle), conferma visiva di rendering/scroll/collisioni, test deliberato delle transizioni crash→box→ripartenza (nessun risucchio residuo), verifica udibile delle SFX, controllo che l'hook musicale non sfori il budget frame dell'IRQ.

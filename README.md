# Daytona (C64)

Remake in salsa endurance/prototipi di **Le Mans** (Commodore 64, 1982, HAL Laboratory).
Vista dall'alto, scroll verticale, sorpassi, box, punteggio a tempo — vedi [ARCHITECTURE.md](ARCHITECTURE.md) per il piano completo (meccaniche, memory map, roadmap).

## Requisiti

- Windows 11, PowerShell 7+ (`pwsh`)
- Connessione internet solo per il primo `setup-tools.ps1` (scarica il toolchain in locale)

Nessuna dipendenza esterna per la conversione asset: gli script `png2charset.ps1`/`png2sprite.ps1` usano `System.Drawing` (già disponibile su Windows), niente Python/Pillow da installare.

Nessun altro requisito: tutto il toolchain (assembler, emulatore, tracker) è portabile e installato in `tools/` (non versionato), senza permessi di amministratore.

## Setup (una tantum)

```powershell
.\scripts\setup-tools.ps1
```

Scarica ed estrae in `tools/`:

- **ACME** — cross-assembler 6502/6510 → `tools/acme/acme.exe`
- **VICE** (`x64sc`, `c1541`) — emulatore C64 cycle-exact + monitor ML → `tools/vice/`
- **CharPad Classic** (free, Subchrist Software) — editor charset/tile C64, esporta binario già pronto per l'assembler → `tools/charpad/`. Download automatico non disponibile (itch.io non ha URL diretti stabili): lo script segnala dove scaricarlo a mano e dove salvare lo zip.
- **Petmate 9** — editor PETSCII open-source per schermate/font → `tools/petmate9/` (è un installer: va lanciato una volta manualmente dopo l'estrazione, nessun privilegio admin richiesto)
- **GoatTracker 2** — tracker musicale SID → `tools/goattracker/` (fase 2, musica composta è stretch goal)

Versioni pinnate documentate in `tools/VERSIONS.md` (creato dallo script).

## Build

```powershell
.\scripts\build.ps1
```

Rigenera gli asset da `assets/src/` (charset/sprite via gli script Python), poi assembla `src/main.asm` con ACME producendo `build/daytona.prg`.

Opzioni:
- `-Disk` — impacchetta anche `build/daytona.d64` tramite `c1541`.
- `-Force` — forza la rigenerazione degli asset anche se non modificati.

## Run

```powershell
.\scripts\run.ps1
```

Lancia `x64sc -autostart build/daytona.prg`.

Opzioni:
- `-Disk` — avvia da `build/daytona.d64` invece che dal `.prg`.
- `-Monitor` — apre direttamente il monitor ML di VICE (utile per debug/breakpoint).

## Controlli

Joystick in **porta 2**:

| Input | Azione |
|---|---|
| Sinistra / Destra | Sterza |
| Fire (tenuto) | Accelera |
| Fire (rilasciato) | Decelera |

(Le paddle dell'originale non sono supportate nell'MVP — vedi roadmap Fase 2+ in ARCHITECTURE.md.)

## Struttura del progetto

```
Daytona/
├── tools/        # toolchain portabile (git-ignored, da setup-tools.ps1)
├── scripts/      # setup/build/run + conversione asset, tutto .ps1
├── src/          # sorgenti ACME (.asm)
├── assets/
│   ├── src/      # arte sorgente versionata (PNG, .sng GoatTracker)
│   └── gen/      # output generato dagli script (git-ignored)
└── build/        # output finale .prg / .d64 (git-ignored)
```

## Stato del progetto

In sviluppo — vedi la roadmap MVP e le fasi successive in [ARCHITECTURE.md](ARCHITECTURE.md).

<#
.SYNOPSIS
    Converte assets/src/sprites.png (griglia di frame 12x21 "pixel logici" multicolor)
    in assets/gen/sprites.bin + assets/gen/sprites.asm, pronti per !binary in ACME.

.DESCRIPTION
    Convenzione dell'immagine sorgente (sprite VIC-II multicolor, 24x21 fisici / 12x21 logici):
    - Griglia di celle CellWidth x CellHeight (default 12x21 pixel logici: un pixel
      logico = 2 bit = una colonna doppia sullo schermo reale), un frame per cella,
      letti riga per riga da sinistra a destra a partire dal frame 0.
    - Il pixel (0,0) dell'intera immagine e' lo sfondo/trasparente (codice 00).
    - Il primo colore distinto incontrato scandendo l'immagine (frame 0 in poi) diventa
      "multicolor 1" (codice 01, registro condiviso $D025); il secondo colore distinto
      diventa "multicolor 2" (codice 11, registro condiviso $D026) -- questi due colori
      sono CONDIVISI da tutti gli sprite hardware, quindi devono essere coerenti in
      tutto il foglio.
    - Qualsiasi altro colore in un frame e' trattato come colore individuale dello
      sprite (codice 10, registro $D027+n) -- al massimo UNO per frame: e' un limite
      hardware del VIC-II (sfondo + 2 condivisi + 1 individuale = 4 colori max/frame).
    - Nessuna dipendenza esterna: usa System.Drawing (incluso in Windows).

    NOTA: convenzione da validare contro l'arte reale quando verra' prodotta (task 5
    della roadmap MVP) -- vedi ARCHITECTURE.md.
#>
[CmdletBinding()]
param(
    [string]$InputPath = (Join-Path $PSScriptRoot '..\assets\src\sprites.png'),
    [string]$OutputBin = (Join-Path $PSScriptRoot '..\assets\gen\sprites.bin'),
    [string]$OutputAsm = (Join-Path $PSScriptRoot '..\assets\gen\sprites.asm'),
    [int]$CellWidth = 12,
    [int]$CellHeight = 21,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $InputPath)) {
    Write-Output "Nessuno sprite sheet sorgente in $InputPath: niente da generare."
    exit 0
}

if ((Test-Path $OutputBin) -and -not $Force) {
    $srcTime = (Get-Item $InputPath).LastWriteTimeUtc
    $outTime = (Get-Item $OutputBin).LastWriteTimeUtc
    if ($outTime -ge $srcTime) {
        Write-Output "$OutputBin e' aggiornato (usa -Force per rigenerare comunque)."
        exit 0
    }
}

Add-Type -AssemblyName System.Drawing

function Get-ColorKey($color) {
    return ('{0:X2}{1:X2}{2:X2}' -f $color.R, $color.G, $color.B)
}

$bmp = [System.Drawing.Bitmap]::new($InputPath)
try {
    if (($bmp.Width % $CellWidth) -ne 0 -or ($bmp.Height % $CellHeight) -ne 0) {
        throw "Dimensioni immagine $($bmp.Width)x$($bmp.Height) non multiple di ${CellWidth}x${CellHeight}."
    }

    $cols = $bmp.Width / $CellWidth
    $rows = $bmp.Height / $CellHeight
    $frameCount = $cols * $rows

    $bg = $bmp.GetPixel(0, 0)
    $bgKey = Get-ColorKey $bg

    # Passata 1: individua globalmente i due colori condivisi (multicolor1/multicolor2)
    # nell'ordine in cui compaiono nel foglio (frame 0 in poi, riga per riga).
    $sharedOrder = [System.Collections.Generic.List[string]]::new()
    $sharedColor = @{}
    for ($r = 0; $r -lt $rows -and $sharedOrder.Count -lt 2; $r++) {
        for ($c = 0; $c -lt $cols -and $sharedOrder.Count -lt 2; $c++) {
            $baseX = $c * $CellWidth
            $baseY = $r * $CellHeight
            for ($py = 0; $py -lt $CellHeight -and $sharedOrder.Count -lt 2; $py++) {
                for ($px = 0; $px -lt $CellWidth -and $sharedOrder.Count -lt 2; $px++) {
                    $pixel = $bmp.GetPixel($baseX + $px, $baseY + $py)
                    if ($pixel.A -eq 0) { continue }
                    $key = Get-ColorKey $pixel
                    if ($key -eq $bgKey) { continue }
                    if (-not $sharedColor.ContainsKey($key)) {
                        $sharedColor[$key] = $pixel
                        $sharedOrder.Add($key)
                    }
                }
            }
        }
    }
    $mcolor1Key = if ($sharedOrder.Count -ge 1) { $sharedOrder[0] } else { $null }
    $mcolor2Key = if ($sharedOrder.Count -ge 2) { $sharedOrder[1] } else { $null }

    # Passata 2: per ogni frame, impacchetta 21 righe x 3 byte (12 pixel logici x 2 bit)
    $allBytes = [System.Collections.Generic.List[byte]]::new()
    $frameNotes = [System.Collections.Generic.List[string]]::new()

    for ($r = 0; $r -lt $rows; $r++) {
        for ($c = 0; $c -lt $cols; $c++) {
            $frameIndex = $r * $cols + $c
            $baseX = $c * $CellWidth
            $baseY = $r * $CellHeight
            $individualKey = $null

            for ($py = 0; $py -lt $CellHeight; $py++) {
                $codes = New-Object int[] $CellWidth
                for ($px = 0; $px -lt $CellWidth; $px++) {
                    $pixel = $bmp.GetPixel($baseX + $px, $baseY + $py)
                    $key = Get-ColorKey $pixel
                    if ($pixel.A -eq 0 -or $key -eq $bgKey) {
                        $codes[$px] = 0
                    }
                    elseif ($key -eq $mcolor1Key) {
                        $codes[$px] = 1
                    }
                    elseif ($key -eq $mcolor2Key) {
                        $codes[$px] = 3
                    }
                    else {
                        if ($null -eq $individualKey) {
                            $individualKey = $key
                        }
                        elseif ($key -ne $individualKey) {
                            throw "Frame $frameIndex ($InputPath): troppi colori distinti (sfondo + 2 condivisi + individuale e' il massimo per sprite multicolor)."
                        }
                        $codes[$px] = 2
                    }
                }

                # Impacchetta 12 pixel logici (2 bit ciascuno) in 3 byte, MSB primo
                for ($byteIdx = 0; $byteIdx -lt 3; $byteIdx++) {
                    $b = 0
                    for ($n = 0; $n -lt 4; $n++) {
                        $pixelIdx = $byteIdx * 4 + $n
                        $shift = 6 - ($n * 2)
                        $b = $b -bor ($codes[$pixelIdx] -shl $shift)
                    }
                    $allBytes.Add([byte]$b)
                }
            }

            $allBytes.Add(0) # pad a 64 byte (63 dati + 1) per l'allineamento puntatore sprite
            $indivDesc = if ($individualKey) { "individuale=#$individualKey" } else { 'individuale=(nessuno)' }
            $frameNotes.Add("; frame $frameIndex : $indivDesc")
        }
    }

    $binDir = Split-Path -Parent $OutputBin
    $asmDir = Split-Path -Parent $OutputAsm
    New-Item -ItemType Directory -Force -Path $binDir | Out-Null
    New-Item -ItemType Directory -Force -Path $asmDir | Out-Null

    [System.IO.File]::WriteAllBytes($OutputBin, $allBytes.ToArray())

    $asmDirFull = (Resolve-Path $asmDir).Path
    $binFull = [System.IO.Path]::GetFullPath($OutputBin)
    $binRelative = [System.IO.Path]::GetRelativePath($asmDirFull, $binFull).Replace('\', '/')

    $mc1Desc = if ($mcolor1Key) { "#$mcolor1Key (-> `$D025)" } else { '(non usato)' }
    $mc2Desc = if ($mcolor2Key) { "#$mcolor2Key (-> `$D026)" } else { '(non usato)' }

    $asmLines = @(
        '; Auto-generato da scripts/png2sprite.ps1 -- non modificare a mano.'
        "; Sorgente: $InputPath ($frameCount frame, $cols x $rows celle da ${CellWidth}x${CellHeight})"
        "; multicolor1 condiviso: $mc1Desc"
        "; multicolor2 condiviso: $mc2Desc"
    )
    $asmLines += $frameNotes
    $asmLines += 'sprite_data:'
    $asmLines += "!binary `"$binRelative`""
    $asmLines -join "`n" | Set-Content -Path $OutputAsm -Encoding utf8

    Write-Output "OK: $OutputBin ($($allBytes.Count) byte, $frameCount frame) + $OutputAsm"
}
finally {
    $bmp.Dispose()
}

<#
.SYNOPSIS
    Converte assets/src/charset.png (griglia di celle 8x8, hi-res 1bpp) in
    assets/gen/charset.bin + assets/gen/charset.asm, pronti per !binary in ACME.

.DESCRIPTION
    Convenzione dell'immagine sorgente:
    - Griglia di celle CellSize x CellSize (default 8x8), una per carattere,
      lette riga per riga da sinistra a destra a partire dal carattere 0.
    - Il pixel in alto a sinistra dell'intera immagine (0,0) definisce il colore
      di sfondo (bit 0). Qualsiasi pixel diverso da quello (o non trasparente
      diversamente) e' considerato primo piano (bit 1).
    - Nessuna dipendenza esterna: usa System.Drawing (incluso in Windows).
#>
[CmdletBinding()]
param(
    [string]$InputPath = (Join-Path $PSScriptRoot '..\assets\src\charset.png'),
    [string]$OutputBin = (Join-Path $PSScriptRoot '..\assets\gen\charset.bin'),
    [string]$OutputAsm = (Join-Path $PSScriptRoot '..\assets\gen\charset.asm'),
    [int]$CellSize = 8,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $InputPath)) {
    Write-Output "Nessun charset sorgente in $InputPath: niente da generare."
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

$bmp = [System.Drawing.Bitmap]::new($InputPath)
try {
    if (($bmp.Width % $CellSize) -ne 0 -or ($bmp.Height % $CellSize) -ne 0) {
        throw "Dimensioni immagine $($bmp.Width)x$($bmp.Height) non multiple di $CellSize."
    }

    $cols = $bmp.Width / $CellSize
    $rows = $bmp.Height / $CellSize
    $charCount = $cols * $rows
    if ($charCount -gt 256) {
        throw "Troppi caratteri ($charCount): il charset C64 supporta al massimo 256 celle da $CellSize x $CellSize."
    }

    $bg = $bmp.GetPixel(0, 0)

    $bytes = [System.Collections.Generic.List[byte]]::new()

    for ($r = 0; $r -lt $rows; $r++) {
        for ($c = 0; $c -lt $cols; $c++) {
            $baseX = $c * $CellSize
            $baseY = $r * $CellSize
            for ($py = 0; $py -lt $CellSize; $py++) {
                $rowByte = 0
                for ($px = 0; $px -lt $CellSize; $px++) {
                    $pixel = $bmp.GetPixel($baseX + $px, $baseY + $py)
                    $isBackground = ($pixel.A -eq 0) -or
                        ($pixel.R -eq $bg.R -and $pixel.G -eq $bg.G -and $pixel.B -eq $bg.B)
                    if (-not $isBackground) {
                        $bit = 7 - $px
                        $rowByte = $rowByte -bor (1 -shl $bit)
                    }
                }
                $bytes.Add([byte]$rowByte)
            }
        }
    }

    # Pad a 2KB (256 caratteri x 8 byte) per rispettare l'allineamento charset del VIC-II ($D018)
    while ($bytes.Count -lt 2048) { $bytes.Add(0) }

    $binDir = Split-Path -Parent $OutputBin
    $asmDir = Split-Path -Parent $OutputAsm
    New-Item -ItemType Directory -Force -Path $binDir | Out-Null
    New-Item -ItemType Directory -Force -Path $asmDir | Out-Null

    [System.IO.File]::WriteAllBytes($OutputBin, $bytes.ToArray())

    $asmDirFull = (Resolve-Path $asmDir).Path
    $binFull = [System.IO.Path]::GetFullPath($OutputBin)
    $binRelative = [System.IO.Path]::GetRelativePath($asmDirFull, $binFull).Replace('\', '/')

    $asmLines = @(
        '; Auto-generato da scripts/png2charset.ps1 -- non modificare a mano.'
        "; Sorgente: $InputPath ($charCount caratteri, $cols x $rows celle da $CellSize`px)"
        'charset_data:'
        "!binary `"$binRelative`""
    )
    $asmLines -join "`n" | Set-Content -Path $OutputAsm -Encoding utf8

    Write-Output "OK: $OutputBin ($($bytes.Count) byte, $charCount caratteri) + $OutputAsm"
}
finally {
    $bmp.Dispose()
}

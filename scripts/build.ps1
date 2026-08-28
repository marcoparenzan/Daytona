<#
.SYNOPSIS
    Rigenera gli asset (se presenti sorgenti in assets/src), poi assembla src/main.asm
    con ACME producendo build/daytona.prg (e opzionalmente build/daytona.d64).
#>
[CmdletBinding()]
param(
    [switch]$Disk,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$acmeDir = Join-Path $root 'tools\acme'
$viceDir = Join-Path $root 'tools\vice'
$srcMain = Join-Path $root 'src\main.asm'
$buildDir = Join-Path $root 'build'
$prg = Join-Path $buildDir 'daytona.prg'

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

# 1. Rigenera asset da assets/src, solo se ci sono sorgenti PNG (non ancora presenti nelle prime iterazioni)
$assetsSrc = Join-Path $root 'assets\src'
$pngs = Get-ChildItem -Path $assetsSrc -Filter '*.png' -ErrorAction SilentlyContinue
if ($pngs) {
    Write-Output 'Rigenero asset da assets/src ...'
    $forceArg = @{}
    if ($Force) { $forceArg['Force'] = $true }

    # Le due chiamate propagano un'eccezione terminante in caso di errore
    # (script figli con $ErrorActionPreference = 'Stop' + throw), che risale qui
    # grazie a $ErrorActionPreference = 'Stop' impostato sopra.
    $charsetScript = Join-Path $root 'scripts\png2charset.ps1'
    if (Test-Path $charsetScript) {
        & $charsetScript @forceArg
    }

    $spriteScript = Join-Path $root 'scripts\png2sprite.ps1'
    if (Test-Path $spriteScript) {
        & $spriteScript @forceArg
    }
}
else {
    Write-Output 'Nessun asset sorgente in assets/src ancora: salto la generazione (ok per lo skeleton boot).'
}

# 2. Assembla con ACME
$acme = Get-ChildItem -Path $acmeDir -Filter 'acme.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $acme) {
    throw "acme.exe non trovato in $acmeDir. Esegui prima .\scripts\setup-tools.ps1"
}
if (-not (Test-Path $srcMain)) {
    throw "$srcMain non trovato."
}

$srcDir = Join-Path $root 'src'
$genDir = Join-Path $root 'assets\gen'

# ACME cerca la cartella ACME_Lib (usata per !source <cbm/c64/vic.a> ecc.) nella
# directory indicata dalla variabile d'ambiente ACME, non accanto all'eseguibile.
$env:ACME = Join-Path (Split-Path -Parent $acme.FullName) 'ACME_Lib'

$labels = Join-Path $buildDir 'daytona.vice-labels.txt'

Write-Output "Assemblo $srcMain -> $prg"
& $acme.FullName -f cbm -o $prg -I $srcDir -I $genDir --vicelabels $labels $srcMain
if ($LASTEXITCODE -ne 0) {
    throw "ACME ha fallito (exit code $LASTEXITCODE)."
}
Write-Output "OK: $prg"

# 3. Disco opzionale
if ($Disk) {
    $c1541 = Get-ChildItem -Path $viceDir -Filter 'c1541.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $c1541) {
        throw "c1541.exe non trovato in $viceDir. Esegui prima .\scripts\setup-tools.ps1"
    }

    $d64 = Join-Path $buildDir 'daytona.d64'
    if (Test-Path $d64) { Remove-Item $d64 -Force }

    & $c1541.FullName -format 'daytona,01' d64 $d64 -write $prg daytona
    if ($LASTEXITCODE -ne 0) {
        throw "c1541 ha fallito (exit code $LASTEXITCODE)."
    }
    Write-Output "OK: $d64"
}

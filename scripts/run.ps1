<#
.SYNOPSIS
    Lancia build/daytona.prg (o .d64 con -Disk) in x64sc (VICE).
#>
[CmdletBinding()]
param(
    [switch]$Disk,
    [switch]$Monitor
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$viceDir = Join-Path $root 'tools\vice'
$buildDir = Join-Path $root 'build'

$x64sc = Get-ChildItem -Path $viceDir -Filter 'x64sc.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $x64sc) {
    throw "x64sc.exe non trovato in $viceDir. Esegui prima .\scripts\setup-tools.ps1"
}

$target = if ($Disk) { Join-Path $buildDir 'daytona.d64' } else { Join-Path $buildDir 'daytona.prg' }
if (-not (Test-Path $target)) {
    $diskFlag = if ($Disk) { ' -Disk' } else { '' }
    throw "$target non trovato. Esegui prima .\scripts\build.ps1$diskFlag"
}

$viceArgs = @('-autostart', $target)

if ($Monitor) {
    $monitorScript = Join-Path $root 'scripts\monitor-startup.txt'
    if (Test-Path $monitorScript) {
        $viceArgs += @('-moncommands', $monitorScript)
    }
    else {
        $viceArgs += '-console'
    }
}

Write-Output "Avvio $($x64sc.FullName) $($viceArgs -join ' ')"
& $x64sc.FullName @viceArgs

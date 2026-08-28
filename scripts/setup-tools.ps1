<#
.SYNOPSIS
    Scarica ed estrae il toolchain portabile (ACME, VICE, GoatTracker 2) in tools/.
    Idempotente: se un tool e' gia' presente non lo riscarica (usa -Force per forzare).
    Nessun privilegio di amministratore richiesto.
#>
[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$toolsDir = Join-Path $root 'tools'
$downloadsDir = Join-Path $root 'scratch\downloads'

New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null
New-Item -ItemType Directory -Force -Path $downloadsDir | Out-Null

$tools = @(
    [pscustomobject]@{
        Name         = 'acme'
        Version      = '0.97'
        Url          = 'https://sourceforge.net/projects/acme-crossass/files/win32/acme0.97win.zip/download'
        ZipName      = 'acme0.97win.zip'
        Dest         = Join-Path $toolsDir 'acme'
        CheckFile    = 'acme.exe'
        AutoDownload = $true
    },
    [pscustomobject]@{
        Name         = 'vice'
        Version      = '3.10'
        Url          = 'https://sourceforge.net/projects/vice-emu/files/releases/binaries/windows/GTK3VICE-3.10-win64.zip/download'
        ZipName      = 'GTK3VICE-3.10-win64.zip'
        Dest         = Join-Path $toolsDir 'vice'
        CheckFile    = 'x64sc.exe'
        AutoDownload = $true
    },
    [pscustomobject]@{
        Name         = 'charpad'
        Version      = '2.86 Free Edition'
        Url          = 'https://subchristsoftware.itch.io/charpad-c64-free'
        ZipName      = 'CharPadFree286_v2.zip'
        Dest         = Join-Path $toolsDir 'charpad'
        CheckFile    = '*.exe'
        # itch.io non offre URL diretti stabili senza API key: scaricare a mano dalla
        # pagina e salvare lo zip in scratch/downloads/, poi rilanciare questo script.
        AutoDownload = $false
    },
    [pscustomobject]@{
        Name         = 'petmate9'
        Version      = '0.9.20'
        Url          = 'https://wbochar.com/files/petmate9-0.9.20-win-x64-setup.zip'
        ZipName      = 'petmate9-0.9.20-win-x64-setup.zip'
        Dest         = Join-Path $toolsDir 'petmate9'
        CheckFile    = '*.exe'
        AutoDownload = $true
    },
    [pscustomobject]@{
        Name         = 'goattracker'
        Version      = '2.77'
        Url          = 'https://sourceforge.net/projects/goattracker2/files/GoatTracker%202/2.77/GoatTracker_2.77.zip/download'
        ZipName      = 'GoatTracker_2.77.zip'
        Dest         = Join-Path $toolsDir 'goattracker'
        CheckFile    = 'goattrk2.exe'
        AutoDownload = $true
    }
)

function Get-FlattenedTool {
    param([string]$Dest)
    # Se lo zip estrae un'unica sottocartella, ne solleva il contenuto di un livello
    # cosi' i path restano prevedibili (es. tools/acme/acme.exe, non tools/acme/acme0.97win/acme.exe)
    $items = Get-ChildItem -Path $Dest -Force
    if ($items.Count -eq 1 -and $items[0].PSIsContainer) {
        $inner = $items[0].FullName
        Get-ChildItem -Path $inner -Force | Move-Item -Destination $Dest -Force
        Remove-Item -Path $inner -Recurse -Force
    }
}

$versionLines = @(
    '# Toolchain versions (pinned)'
    ''
    "Aggiornato da setup-tools.ps1 il $(Get-Date -Format 'yyyy-MM-dd')"
    ''
)

foreach ($tool in $tools) {
    $existing = Get-ChildItem -Path $tool.Dest -Filter $tool.CheckFile -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

    if ($existing -and -not $Force) {
        Write-Output "[$($tool.Name)] gia' presente: $($existing.FullName)"
    }
    else {
        $zipPath = Join-Path $downloadsDir $tool.ZipName

        if (-not $tool.AutoDownload) {
            if (-not (Test-Path $zipPath)) {
                Write-Warning "[$($tool.Name)] download automatico non disponibile (nessun URL diretto stabile). Scarica manualmente da $($tool.Url), salva lo zip come $zipPath, poi rilancia questo script."
                continue
            }
            Write-Output "[$($tool.Name)] trovato zip scaricato manualmente: $zipPath"
        }
        else {
            Write-Output "[$($tool.Name)] scarico v$($tool.Version) da $($tool.Url) ..."

            $downloadOk = $true
            try {
                curl.exe -L --fail --silent --show-error -o $zipPath $tool.Url
                if ($LASTEXITCODE -ne 0) { $downloadOk = $false }
            }
            catch {
                $downloadOk = $false
            }

            if (-not $downloadOk -or -not (Test-Path $zipPath) -or (Get-Item $zipPath).Length -lt 1024) {
                Write-Warning "[$($tool.Name)] download fallito o file non valido. Scarica manualmente da $($tool.Url) salvandolo come $zipPath, poi rilancia questo script."
                continue
            }
        }

        New-Item -ItemType Directory -Force -Path $tool.Dest | Out-Null
        Write-Output "[$($tool.Name)] estraggo in $($tool.Dest) ..."
        Expand-Archive -Path $zipPath -DestinationPath $tool.Dest -Force
        Get-FlattenedTool -Dest $tool.Dest

        $existing = Get-ChildItem -Path $tool.Dest -Filter $tool.CheckFile -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($existing) {
            Write-Output "[$($tool.Name)] OK: $($existing.FullName)"
            if ($tool.Name -eq 'petmate9') {
                Write-Output "  Nota: e' un installer (non portabile) -- eseguirlo una volta manualmente, si installa per l'utente corrente senza privilegi admin."
            }
        }
        else {
            Write-Warning "[$($tool.Name)] estratto ma $($tool.CheckFile) non trovato: verifica il contenuto di $($tool.Dest)"
        }
    }

    $versionLines += "- $($tool.Name): v$($tool.Version) -- $($tool.Url)"
}

$versionLines -join "`n" | Set-Content -Path (Join-Path $toolsDir 'VERSIONS.md') -Encoding utf8

Write-Output ''
Write-Output 'Setup completato. Versioni pinnate in tools/VERSIONS.md.'

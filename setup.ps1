# Instalador de um comando para Windows.
# Uso: powershell -ExecutionPolicy Bypass -File setup.ps1 [-Disc "C:\caminho\NASCAR Rumble (USA).cue"]
param([string]$Disc)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

Write-Host "=== NASCAR Rumble Recompiled - instalacao ===" -ForegroundColor Cyan

# Git (o Git for Windows tambem fornece o bash usado pelos scripts)
$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
    Write-Host "Git nao encontrado. Instale com: winget install Git.Git  (e reabra o PowerShell)" -ForegroundColor Red
    exit 1
}
$bash = Join-Path (Split-Path (Split-Path $git.Source)) 'bin\bash.exe'
if (-not (Test-Path $bash)) { $bash = 'C:\Program Files\Git\bin\bash.exe' }
if (-not (Test-Path $bash)) {
    Write-Host "bash.exe do Git for Windows nao encontrado." -ForegroundColor Red
    exit 1
}

# Python
$pyOk = $false
foreach ($c in 'python', 'py') {
    try { & $c -c "import sys; sys.exit(sys.version_info < (3, 9))" 2>$null; if ($LASTEXITCODE -eq 0) { $pyOk = $true; break } } catch {}
}
if (-not $pyOk) {
    Write-Host "Python 3.9+ nao encontrado. Instale com: winget install Python.Python.3.12  (e reabra o PowerShell)" -ForegroundColor Red
    exit 1
}

# Disco: pede o .cue se nao foi informado
if (-not $Disc) {
    Add-Type -AssemblyName System.Windows.Forms
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = 'Selecione o arquivo .cue do NASCAR Rumble (USA)'
    $dlg.Filter = 'Imagem de disco (*.cue)|*.cue'
    if ($dlg.ShowDialog() -ne 'OK') { Write-Host 'Cancelado.'; exit 1 }
    $Disc = $dlg.FileName
}
if (-not (Test-Path $Disc)) { Write-Host "Arquivo nao encontrado: $Disc" -ForegroundColor Red; exit 1 }

Write-Host "Disco: $Disc"
Write-Host "Isso pode levar de 20 a 40 minutos. Nao feche esta janela." -ForegroundColor Yellow

& $bash -lc "cd '$($PSScriptRoot -replace '\','/')' && bash scripts/setup.sh '$($Disc -replace '\','/')'"
if ($LASTEXITCODE -ne 0) { Write-Host "A instalacao falhou. Veja as mensagens acima." -ForegroundColor Red; exit $LASTEXITCODE }

$exe = Join-Path $PSScriptRoot 'build-release\NascarRumble_Recompiled.exe'
Write-Host "`nPronto! Jogo em: $exe" -ForegroundColor Green
$ws = New-Object -ComObject WScript.Shell
$lnk = $ws.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) 'NASCAR Rumble Recompiled.lnk'))
$lnk.TargetPath = $exe
$lnk.WorkingDirectory = Split-Path $exe
$lnk.Save()
Write-Host "Atalho criado na Area de Trabalho."

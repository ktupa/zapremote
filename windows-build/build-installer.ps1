param(
    [string]$NsisExe = "C:\Program Files (x86)\NSIS\makensis.exe",
    [string]$RustDeskExe = ".\rustdesk.exe"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

if (-not (Test-Path $RustDeskExe)) {
    throw "Arquivo nao encontrado: $RustDeskExe"
}

if (-not (Test-Path $NsisExe)) {
    throw "NSIS nao encontrado em: $NsisExe"
}

Copy-Item $RustDeskExe "$root\rustdesk.exe" -Force
& $NsisExe "$root\ZAPRemote-v3.nsi"
Write-Host "Instalador gerado em: $root\ZAPRemote-Setup-v3.exe"

[CmdletBinding()]
param(
    [string]$SourceRoot,
    [switch]$SkipRestart,
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'CodexDreamSkinGundam'),
    [string]$StartupDirectory = [Environment]::GetFolderPath('Startup')
)

$ErrorActionPreference = 'Stop'
$adapterRoot = $PSScriptRoot
if (-not $SourceRoot) { $SourceRoot = $adapterRoot }
$stateRoot = $InstallRoot
$skinRoot = Join-Path $stateRoot 'skin'
$startupDir = $StartupDirectory
$startupCmd = Join-Path $startupDir 'Codex RX-78 Skin.cmd'

foreach ($required in @('dream-skin.css','runtime\renderer-inject.js','theme\theme.json','theme\background.jpg')) {
    $path = Join-Path $SourceRoot $required
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Source asset missing: $path" }
}

$package = Get-AppxPackage -Name OpenAI.Codex | Select-Object -First 1
if (-not $package) { throw '未检测到 Windows 版 Codex（OpenAI.Codex）。请先从官方渠道安装并至少启动一次。' }

if (Test-Path -LiteralPath (Join-Path $adapterRoot 'Test-Skin.ps1')) {
    & (Join-Path $adapterRoot 'Test-Skin.ps1') -SourceRoot $SourceRoot
}

New-Item -ItemType Directory -Force -Path $skinRoot, (Join-Path $skinRoot 'runtime'), (Join-Path $skinRoot 'theme'), $startupDir | Out-Null
Copy-Item -Force -LiteralPath (Join-Path $SourceRoot 'dream-skin.css') -Destination (Join-Path $skinRoot 'dream-skin.css')
Copy-Item -Force -LiteralPath (Join-Path $SourceRoot 'runtime\renderer-inject.js') -Destination (Join-Path $skinRoot 'runtime\renderer-inject.js')
Copy-Item -Force -LiteralPath (Join-Path $SourceRoot 'theme\theme.json') -Destination (Join-Path $skinRoot 'theme\theme.json')
Copy-Item -Force -LiteralPath (Join-Path $SourceRoot 'theme\background.jpg') -Destination (Join-Path $skinRoot 'theme\background.jpg')
foreach ($name in @('windows-skin.json','Inject-Skin.ps1','Verify-Skin.ps1','Start-Skin.ps1','Uninstall-Skin.ps1','Test-Skin.ps1','README.md')) {
    Copy-Item -Force -LiteralPath (Join-Path $adapterRoot $name) -Destination (Join-Path $skinRoot $name)
}

$startScript = Join-Path $skinRoot 'Start-Skin.ps1'
$startupBody = "@echo off`r`nstart `"`" /min powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$startScript`"`r`n"
[IO.File]::WriteAllText($startupCmd, $startupBody, [Text.UTF8Encoding]::new($false))

if (-not $SkipRestart) {
    & $startScript -SkinRoot $skinRoot
    & (Join-Path $skinRoot 'Verify-Skin.ps1') -Port 9341 -WaitSeconds 45
}

Write-Host "SKIN_INSTALLED · $skinRoot"
Write-Host "AUTOSTART_INSTALLED · $startupCmd"

[CmdletBinding()]
param(
    [switch]$KeepFiles,
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'CodexDreamSkinGundam'),
    [string]$StartupDirectory = [Environment]::GetFolderPath('Startup')
)

$ErrorActionPreference = 'Stop'
$stateRoot = $InstallRoot
$startupCmd = Join-Path $StartupDirectory 'Codex RX-78 Skin.cmd'
$pidPath = Join-Path $stateRoot 'injector.pid'

if (Test-Path -LiteralPath $pidPath) {
    $injectorPid = 0
    if ([int]::TryParse((Get-Content -Raw -LiteralPath $pidPath).Trim(), [ref]$injectorPid)) {
        Stop-Process -Id $injectorPid -Force -ErrorAction SilentlyContinue
    }
}

if (Test-Path -LiteralPath $startupCmd) { Remove-Item -LiteralPath $startupCmd -Force }
Get-Process -Name ChatGPT -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
Start-Process -FilePath explorer.exe -ArgumentList 'shell:AppsFolder\OpenAI.Codex_2p2nqsd0c76g0!App'

if (-not $KeepFiles -and (Test-Path -LiteralPath $stateRoot)) {
    $resolved = [IO.Path]::GetFullPath($stateRoot)
    $expected = [IO.Path]::GetFullPath($InstallRoot)
    if ($resolved -ne $expected) { throw "Refusing unexpected delete target: $resolved" }
    if ([IO.Path]::GetFileName($resolved.TrimEnd('\')) -ne 'CodexDreamSkinGundam') {
        throw "拒绝删除非皮肤专用目录：$resolved"
    }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}

Write-Host 'SKIN_UNINSTALLED · Codex restarted normally.'

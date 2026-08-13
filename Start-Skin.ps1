[CmdletBinding()]
param(
    [string]$SkinRoot = $PSScriptRoot,
    [switch]$NoRestart
)

$ErrorActionPreference = 'Stop'
$config = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $SkinRoot 'windows-skin.json') | ConvertFrom-Json
$port = [int]$config.port
$stateRoot = Split-Path -Parent $SkinRoot
$log = Join-Path $stateRoot 'skin.log'

$package = Get-AppxPackage -Name OpenAI.Codex | Sort-Object Version -Descending | Select-Object -First 1
if (-not $package) { throw 'OpenAI Codex Windows app is not installed.' }
$exe = Join-Path $package.InstallLocation 'app\ChatGPT.exe'
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw "Codex executable not found: $exe" }

if (-not $NoRestart) {
    Get-Process -Name ChatGPT -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
}

$listening = $false
try {
    Invoke-RestMethod -Uri "http://127.0.0.1:$port/json/version" -TimeoutSec 2 | Out-Null
    $listening = $true
} catch {}
if (-not $listening) {
    Start-Process -FilePath $exe -ArgumentList @("--remote-debugging-address=127.0.0.1", "--remote-debugging-port=$port") -WindowStyle Hidden
}

$deadline = (Get-Date).AddSeconds(35)
do {
    try {
        Invoke-RestMethod -Uri "http://127.0.0.1:$port/json/version" -TimeoutSec 2 | Out-Null
        break
    } catch {
        if ((Get-Date) -ge $deadline) { throw "Codex debug port $port did not become ready." }
        Start-Sleep -Seconds 1
    }
} while ($true)

$injector = Join-Path $SkinRoot 'Inject-Skin.ps1'
Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -ArgumentList @('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File',"`"$injector`"",'-Port',"$port",'-SkinRoot',"`"$SkinRoot`"",'-Watch','-IntervalSeconds',"$($config.watchIntervalSeconds)",'-LogPath',"`"$log`"") `
    -WindowStyle Hidden

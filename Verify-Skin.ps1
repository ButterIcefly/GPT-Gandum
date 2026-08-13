[CmdletBinding()]
param(
    [int]$Port = 9341,
    [int]$WaitSeconds = 0
)

$ErrorActionPreference = 'Stop'

function Invoke-CdpEvaluate {
    param([string]$WebSocketUrl, [string]$Expression)
    $socket = [System.Net.WebSockets.ClientWebSocket]::new()
    $token = [Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds(10))
    try {
        [void]$socket.ConnectAsync([Uri]$WebSocketUrl, $token.Token).GetAwaiter().GetResult()
        $body = @{ id = 1; method = 'Runtime.evaluate'; params = @{ expression = $Expression; returnByValue = $true } } | ConvertTo-Json -Depth 8 -Compress
        $bytes = [Text.Encoding]::UTF8.GetBytes($body)
        [void]$socket.SendAsync([ArraySegment[byte]]::new($bytes), [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $token.Token).GetAwaiter().GetResult()
        do {
            $stream = [IO.MemoryStream]::new()
            $buffer = New-Object byte[] 65536
            do {
                $part = $socket.ReceiveAsync([ArraySegment[byte]]::new($buffer), $token.Token).GetAwaiter().GetResult()
                if ($part.Count -gt 0) { [void]$stream.Write($buffer, 0, $part.Count) }
            } until ($part.EndOfMessage)
            $message = [Text.Encoding]::UTF8.GetString($stream.ToArray()) | ConvertFrom-Json
        } until ($message.id -eq 1)
        if ($message.error) { throw ($message.error | ConvertTo-Json -Compress) }
        Write-Output -NoEnumerate $message.result.result.value
    }
    finally {
        try { $socket.Dispose() } catch {}
        $token.Dispose()
    }
}

$expression = @'
(() => {
  const el = document.getElementById("codex-dream-skin-style");
  if (!el) return { found: false };
  const css = el.textContent || "";
  const home = document.querySelector("[role=main].dream-skin-home");
  let homeCheck = null;
  if (home) {
    const input = document.querySelector("textarea, [contenteditable=true]");
    if (!input) homeCheck = { ok: false, why: "home input missing" };
    else {
      const r = input.getBoundingClientRect();
      const visible = r.height > 0 && r.top >= 0 && r.top < innerHeight;
      homeCheck = { ok: visible, why: visible ? "" : `input outside viewport y=${Math.round(r.top)}` };
    }
  }
  return {
    found: true,
    bytes: css.length,
    hasGlass: css.includes("backdrop-filter"),
    hasBrand: css.includes("--skin-nameplate"),
    hasWallpaper: css.includes("data:image") || css.includes("background-image"),
    state: Boolean(window.__CODEX_DREAM_SKIN_STATE__),
    polaroidAbsent: !document.getElementById("ds-polaroid-draggable"),
    homeCheck
  };
})()
'@

$deadline = (Get-Date).AddSeconds($WaitSeconds)
$lastReasons = [Collections.Generic.List[string]]::new()
do {
    try {
        $targetResponse = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/json/list" -TimeoutSec 3
        foreach ($target in $targetResponse) {
            if ($target.type -ne 'page' -or -not $target.webSocketDebuggerUrl) { continue }
            try {
                $info = Invoke-CdpEvaluate -WebSocketUrl $target.webSocketDebuggerUrl -Expression $expression
                if ($info.found -and $info.hasGlass -and $info.state -and $info.polaroidAbsent -and (-not $info.homeCheck -or $info.homeCheck.ok)) {
                    Write-Host ('SKIN_OK · {0} KB · brand={1} · wallpaper={2} · polaroid=removed · home={3}' -f [Math]::Round($info.bytes / 1KB), $info.hasBrand, $info.hasWallpaper, $(if ($info.homeCheck) { $info.homeCheck.ok } else { 'n/a' }))
                    exit 0
                }
                $lastReasons.Add(('{0} => {1}' -f $target.url, ($info | ConvertTo-Json -Compress -Depth 5)))
            }
            catch { $lastReasons.Add(('{0} => ERROR {1}' -f $target.url, $_.Exception.Message)) }
        }
    }
    catch { $lastReasons.Add(('LIST => ERROR {0}' -f $_.Exception.Message)) }
    if ((Get-Date) -ge $deadline) { break }
    Start-Sleep -Seconds 2
} while ($true)

Write-Host "SKIN_MISSING · no verified skin found on 127.0.0.1:$Port"
$lastReasons | Select-Object -Last 10 | ForEach-Object { Write-Host "  $_" }
exit 1

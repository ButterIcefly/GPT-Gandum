[CmdletBinding()]
param(
    [int]$Port = 9341,
    [string]$SkinRoot = $PSScriptRoot,
    [switch]$Watch,
    [int]$IntervalSeconds = 4,
    [string]$LogPath,
    [string]$PidPath = (Join-Path (Split-Path -Parent $SkinRoot) 'injector.pid')
)

$ErrorActionPreference = 'Stop'
$StyleId = 'codex-dream-skin-style'
$StateKey = '__CODEX_DREAM_SKIN_STATE__'
Add-Type -AssemblyName System.Web.Extensions
$JsonSerializer = [Web.Script.Serialization.JavaScriptSerializer]::new()
$JsonSerializer.MaxJsonLength = [int]::MaxValue

function ConvertTo-JavaScriptJsonString {
    param([AllowEmptyString()][string]$Value)
    return $JsonSerializer.Serialize($Value)
}

function Write-SkinLog {
    param([string]$Message)
    $line = '{0:u} {1}' -f (Get-Date), $Message
    Write-Host $line
    if ($LogPath) {
        Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
    }
}

function Get-SkinPayload {
    $cssPath = Join-Path $SkinRoot 'dream-skin.css'
    $rendererPath = Join-Path $SkinRoot 'runtime\renderer-inject.js'
    $themePath = Join-Path $SkinRoot 'theme\theme.json'
    $artPath = Join-Path $SkinRoot 'theme\background.jpg'
    foreach ($path in @($cssPath, $rendererPath, $themePath, $artPath)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Missing skin asset: $path"
        }
    }

    $css = Get-Content -Raw -Encoding UTF8 -LiteralPath $cssPath
    # Windows-specific finishing layer. The upstream skin treats every sidebar
    # navigation row as a separate glass tile; in Codex for Windows that also
    # catches the four environment summary rows. Keep those rows lightweight
    # and flatten the primary sidebar into a quieter, contemporary material.
    $css += @'

/* ===== Codex Windows sidebar refinement ===== */
html.codex-dream-skin.codex-dream-skin.codex-dream-skin
  aside.app-shell-left-panel:not(#ds-modern):not(#ds-modern):not(#ds-modern) {
  background: linear-gradient(180deg,
    rgb(var(--ds-panel-rgb) / .54),
    rgb(var(--ds-panel-rgb) / .40) 58%,
    rgb(var(--ds-panel-rgb) / .46)) !important;
  border: 0 !important;
  border-right: 1px solid rgb(255 255 255 / .24) !important;
  border-radius: 0 20px 20px 0 !important;
  box-shadow: 12px 0 36px rgb(var(--ds-bg-rgb) / .10),
    inset -1px 0 rgb(var(--ds-muted-rgb) / .06) !important;
  backdrop-filter: blur(28px) saturate(145%) !important;
  -webkit-backdrop-filter: blur(28px) saturate(145%) !important;
}

html.codex-dream-skin.codex-dream-skin.codex-dream-skin
  aside.app-shell-left-panel:not(#ds-modern):not(#ds-modern) nav > :is(button, a) {
  margin-block: 2px !important;
  background: transparent !important;
  background-image: none !important;
  border-color: transparent !important;
  border-radius: 10px !important;
  box-shadow: none !important;
  backdrop-filter: none !important;
  -webkit-backdrop-filter: none !important;
  transform: none !important;
}

html.codex-dream-skin.codex-dream-skin.codex-dream-skin
  aside.app-shell-left-panel:not(#ds-modern):not(#ds-modern) nav > :is(button, a):hover {
  background: rgb(var(--ds-panel-rgb) / .28) !important;
  border-color: rgb(255 255 255 / .16) !important;
  box-shadow: inset 0 1px rgb(255 255 255 / .18) !important;
  transform: none !important;
}

html.codex-dream-skin.codex-dream-skin.codex-dream-skin
  aside.app-shell-left-panel:not(#ds-modern):not(#ds-modern) :is([aria-current="page"], [class~="bg-token-list-hover-background"]) {
  background: linear-gradient(90deg,
    rgb(var(--ds-accent-rgb) / .13),
    rgb(var(--ds-panel-rgb) / .28)) !important;
  border-color: rgb(var(--ds-accent-rgb) / .16) !important;
  border-radius: 10px !important;
  box-shadow: inset 3px 0 var(--ds-accent),
    inset 0 1px rgb(255 255 255 / .18) !important;
  backdrop-filter: none !important;
  -webkit-backdrop-filter: none !important;
}

html.codex-dream-skin.codex-dream-skin.codex-dream-skin main.main-surface:not(.dream-skin-home-shell)
  .dream-skin-environment-panel:not(#ds-modern):not(#ds-modern) {
  background: linear-gradient(180deg,
    rgb(var(--ds-panel-rgb) / .52),
    rgb(var(--ds-panel-rgb) / .40)) !important;
  border-color: rgb(255 255 255 / .22) !important;
  box-shadow: 0 14px 38px rgb(var(--ds-bg-rgb) / .11),
    inset 0 1px rgb(255 255 255 / .28) !important;
  backdrop-filter: blur(26px) saturate(140%) !important;
  -webkit-backdrop-filter: blur(26px) saturate(140%) !important;
}

html.codex-dream-skin.codex-dream-skin.codex-dream-skin main.main-surface:not(.dream-skin-home-shell)
  .dream-skin-environment-row:not(#ds-modern):not(#ds-modern) {
  min-height: 30px !important;
  margin-block: 3px !important;
  padding: 4px 7px !important;
  background: rgb(var(--ds-panel-rgb) / .14) !important;
  background-image: none !important;
  border: 1px solid rgb(var(--ds-muted-rgb) / .10) !important;
  border-radius: 8px !important;
  box-shadow: none !important;
  backdrop-filter: none !important;
  -webkit-backdrop-filter: none !important;
  transform: none !important;
}

html.codex-dream-skin.codex-dream-skin.codex-dream-skin main.main-surface:not(.dream-skin-home-shell)
  .dream-skin-environment-row:not(#ds-modern):not(#ds-modern):hover {
  background: rgb(var(--ds-accent-rgb) / .07) !important;
  border-color: rgb(var(--ds-accent-rgb) / .13) !important;
  box-shadow: none !important;
  transform: none !important;
}
'@
    $renderer = Get-Content -Raw -Encoding UTF8 -LiteralPath $rendererPath
    # Windows DOM compatibility must live inside the renderer's own mutation
    # observer. Doing this only in the outer four-second watcher causes a
    # visible glass/native/artwork flash during route transitions.
    $oldShellMain = 'const shellMain = document.querySelector("main.main-surface") || document.querySelector("main");'
    $newShellMain = @'
const windowsMain = document.querySelector('main[class*="MainContentSurface"]');
    if (windowsMain && !windowsMain.classList.contains("main-surface")) {
      windowsMain.classList.add("main-surface");
    }
    const shellMain = document.querySelector("main.main-surface") || document.querySelector("main");
    setAttribute(root, "data-ds-route", shellMain ? "app" : "settings");
'@
    if (-not $renderer.Contains($oldShellMain)) { throw 'Renderer shell-main compatibility anchor was not found.' }
    $renderer = $renderer.Replace($oldShellMain, $newShellMain.Trim())

    $polaroidCall = 'try { ensureDraggablePolaroid(Boolean(home)); } catch {}'
    if (-not $renderer.Contains($polaroidCall)) { throw 'Renderer polaroid compatibility anchor was not found.' }
    $renderer = $renderer.Replace($polaroidCall, 'try { document.getElementById(POLA_ID)?.remove(); } catch {}')

    $observerAnchor = 'const observer = new MutationObserver(() => scheduleEnsure({ route: true }));'
    $observerReplacement = @'
const markWindowsEnvironmentPanel = () => {
    const wanted = new Set(["\u53d8\u66f4", "\u672c\u5730", "main", "\u63d0\u4ea4\u6216\u63a8\u9001"]);
    const rows = [...document.querySelectorAll('.group\\/summary-panel-item')]
      .filter((el) => wanted.has((el.innerText || el.textContent || "").trim()));
    if (rows.length !== 4) return;
    rows.forEach((el) => el.classList.add("dream-skin-environment-row"));
    let panel = rows[0].parentElement;
    while (panel && !rows.every((el) => panel.contains(el))) panel = panel.parentElement;
    if (panel) panel.classList.add("dream-skin-environment-panel");
  };
  markWindowsEnvironmentPanel();
  const observer = new MutationObserver(() => {
    // Fast Windows path: prevent a native/glass/artwork flash while the generic
    // scheduler is coalescing the rest of the route layout work.
    const windowsMain = document.querySelector('main[class*="MainContentSurface"]');
    if (windowsMain && !windowsMain.classList.contains("main-surface")) {
      windowsMain.classList.add("main-surface");
      document.documentElement?.setAttribute("data-ds-route", "app");
    }
    document.getElementById(POLA_ID)?.remove();
    markWindowsEnvironmentPanel();
    scheduleEnsure({ route: true });
  });
'@
    if (-not $renderer.Contains($observerAnchor)) { throw 'Renderer mutation-observer compatibility anchor was not found.' }
    $renderer = $renderer.Replace($observerAnchor, $observerReplacement.Trim())
    $themeObject = Get-Content -Raw -Encoding UTF8 -LiteralPath $themePath | ConvertFrom-Json
    $themeObject | Add-Member -NotePropertyName artKey -NotePropertyValue ('sha256:' + (Get-FileHash -Algorithm SHA256 -LiteralPath $artPath).Hash.ToLowerInvariant()) -Force
    $themeJson = $themeObject | ConvertTo-Json -Depth 20 -Compress
    $artBytes = [System.IO.File]::ReadAllBytes($artPath)
    $artData = 'data:image/jpeg;base64,' + [Convert]::ToBase64String($artBytes)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $revision = ([BitConverter]::ToString($sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($css)))).Replace('-', '').ToLowerInvariant().Substring(0, 16)
    }
    finally { $sha256.Dispose() }

    $script = $renderer
    $script = $script.Replace('__DREAM_SKIN_VERSION_JSON__', (ConvertTo-JavaScriptJsonString ('windows-{0}' -f $revision)))
    $script = $script.Replace('__DREAM_SKIN_STYLE_REVISION_JSON__', (ConvertTo-JavaScriptJsonString $revision))
    $script = $script.Replace('__DREAM_SKIN_CSS_JSON__', (ConvertTo-JavaScriptJsonString $css))
    $script = $script.Replace('__DREAM_SKIN_ART_JSON__', (ConvertTo-JavaScriptJsonString $artData))
    $script = $script.Replace('__DREAM_SKIN_THEME_JSON__', $themeJson)
    if ($script -match '__DREAM_SKIN_[A-Z_]+__') {
        throw 'Renderer template still contains unresolved placeholders.'
    }
    if ($script.Length -lt 1000000 -or -not $script.Contains('backdrop-filter')) {
        throw "Compiled payload is unexpectedly small or incomplete: $($script.Length) characters."
    }
    Write-Output -NoEnumerate $script
}

function Invoke-CdpCommand {
    param(
        [Parameter(Mandatory)][string]$WebSocketUrl,
        [Parameter(Mandatory)][string]$Method,
        [hashtable]$Params = @{}
    )
    $socket = [System.Net.WebSockets.ClientWebSocket]::new()
    $timeout = [Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds(12))
    try {
        [void]$socket.ConnectAsync([Uri]$WebSocketUrl, $timeout.Token).GetAwaiter().GetResult()
        $request = @{ id = 1; method = $Method; params = $Params } | ConvertTo-Json -Depth 12 -Compress
        $bytes = [Text.Encoding]::UTF8.GetBytes($request)
        $segment = [ArraySegment[byte]]::new($bytes)
        [void]$socket.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $timeout.Token).GetAwaiter().GetResult()

        do {
            $stream = [IO.MemoryStream]::new()
            $buffer = New-Object byte[] 65536
            do {
                $result = $socket.ReceiveAsync([ArraySegment[byte]]::new($buffer), $timeout.Token).GetAwaiter().GetResult()
                if ($result.Count -gt 0) { [void]$stream.Write($buffer, 0, $result.Count) }
            } until ($result.EndOfMessage)
            $json = [Text.Encoding]::UTF8.GetString($stream.ToArray()) | ConvertFrom-Json
        } until ($json.id -eq 1)
        if ($json.error) { throw ($json.error | ConvertTo-Json -Compress) }
        Write-Output -NoEnumerate $json.result
    }
    finally {
        try { $socket.Dispose() } catch {}
        $timeout.Dispose()
    }
}

function Get-CdpPages {
    try {
        $targets = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/json/list" -TimeoutSec 3
        return @($targets | Where-Object { $_.type -eq 'page' -and $_.webSocketDebuggerUrl })
    }
    catch { return @() }
}

function Install-SkinOnce {
    param([string]$Payload)
    $pages = @(Get-CdpPages)
    if ($pages.Count -eq 0) { return 0 }
    $installed = 0
    foreach ($page in $pages) {
        if ($page.url -match 'initialRoute=.*(?:avatar|overlay|tray)') { continue }
        try {
            $probe = Invoke-CdpCommand -WebSocketUrl $page.webSocketDebuggerUrl -Method 'Runtime.evaluate' -Params @{
                expression = "Boolean(document.documentElement && document.body)"
                returnByValue = $true
            }
            if (-not $probe.result.value) { continue }
            # Prime the class before first injection; subsequent route changes are
            # handled synchronously by the renderer's own mutation observer.
            [void](Invoke-CdpCommand -WebSocketUrl $page.webSocketDebuggerUrl -Method 'Runtime.evaluate' -Params @{
                expression = @"
(function () {
  var candidates = document.querySelectorAll('main[class*="MainContentSurface"]');
  for (var i = 0; i < candidates.length; i += 1) {
    candidates[i].classList.add('main-surface');
  }
  return candidates.length;
})()
"@
                returnByValue = $true
            })
            [void](Invoke-CdpCommand -WebSocketUrl $page.webSocketDebuggerUrl -Method 'Runtime.evaluate' -Params @{
                expression = @"
(function () {
  var style = document.getElementById('$StyleId');
  if (!style) return false;
  var cssText = style.textContent || '';
  if (cssText.length >= 100000 && cssText.indexOf('Codex Windows sidebar refinement') !== -1) return false;
  try {
    var state = window['$StateKey'];
    if (state && typeof state.cleanup === 'function') state.cleanup();
  } catch (error) {}
  style = document.getElementById('$StyleId');
  if (style && style.parentNode) style.parentNode.removeChild(style);
  try { delete window['$StateKey']; } catch (error) {}
  return true;
})()
"@
                returnByValue = $true
            })
            $result = Invoke-CdpCommand -WebSocketUrl $page.webSocketDebuggerUrl -Method 'Runtime.evaluate' -Params @{
                expression = $Payload
                awaitPromise = $true
                returnByValue = $true
                userGesture = $false
            }
            if ($result.exceptionDetails) {
                $description = $result.exceptionDetails.exception.description
                if (-not $description) { $description = $result.exceptionDetails.text }
                throw "Renderer evaluation failed: $description"
            }
            if ($result.result.value.installed) { $installed++ }
        }
        catch {
            Write-SkinLog "Injection skipped for $($page.url): $($_.Exception.Message)"
        }
    }
    Write-Output -NoEnumerate $installed
}

$mutex = $null
$ownsMutex = $false
try {
    if ($Watch) {
        $createdNew = $false
        $mutex = [Threading.Mutex]::new($true, 'Local\CodexDreamSkinGundam.Injector', [ref]$createdNew)
        if (-not $createdNew) {
            Write-SkinLog 'Another skin injector is already running.'
            exit 0
        }
        $ownsMutex = $true
        [IO.File]::WriteAllText($PidPath, [string]$PID, [Text.UTF8Encoding]::new($false))
    }

    $payload = Get-SkinPayload
    $lastCount = -1
    do {
        $count = Install-SkinOnce -Payload $payload
        if ($count -ne $lastCount) {
            Write-SkinLog "Injected skin into $count page(s) on port $Port."
            $lastCount = $count
        }
        if (-not $Watch) { break }
        Start-Sleep -Seconds ([Math]::Max(1, $IntervalSeconds))
    } while ($true)

    if (-not $Watch -and $lastCount -lt 1) { exit 1 }
}
finally {
    if ($Watch -and (Test-Path -LiteralPath $PidPath)) {
        try {
            if ((Get-Content -Raw -LiteralPath $PidPath).Trim() -eq [string]$PID) {
                Remove-Item -LiteralPath $PidPath -Force
            }
        } catch {}
    }
    if ($ownsMutex) {
        try { $mutex.ReleaseMutex() } catch {}
    }
    if ($mutex) { $mutex.Dispose() }
}

[CmdletBinding()]
param([string]$SourceRoot)

$ErrorActionPreference = 'Stop'
if (-not $SourceRoot) { $SourceRoot = $PSScriptRoot }
$scripts = Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.ps1'
$errors = @()
foreach ($script in $scripts) {
    $tokens = $null
    $parseErrors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { $errors += $parseErrors }
}
if ($errors.Count) {
    $errors | ForEach-Object { Write-Error $_.Message }
    exit 1
}

$renderer = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $SourceRoot 'runtime\renderer-inject.js')
$placeholders = [regex]::Matches($renderer, '__DREAM_SKIN_[A-Z_]+__') | ForEach-Object Value | Sort-Object -Unique
$expected = @('__DREAM_SKIN_ART_JSON__','__DREAM_SKIN_CSS_JSON__','__DREAM_SKIN_STYLE_REVISION_JSON__','__DREAM_SKIN_THEME_JSON__','__DREAM_SKIN_VERSION_JSON__')
if (Compare-Object $expected $placeholders) { throw 'Unexpected renderer template placeholders.' }

$css = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $SourceRoot 'dream-skin.css')
foreach ($needle in @('backdrop-filter','--skin-nameplate','data:image')) {
    if (-not $css.Contains($needle)) { throw "CSS marker missing: $needle" }
}
$injectorSource = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'Inject-Skin.ps1')
if (-not $injectorSource.Contains('JavaScriptSerializer')) {
    throw 'Injector must use a true JSON string serializer; PowerShell 5.1 ConvertTo-Json wraps strings in a value object.'
}
foreach ($anchor in @('MainContentSurface','document.getElementById(POLA_ID)?.remove()','Fast Windows path')) {
    if (-not $injectorSource.Contains($anchor)) { throw "Windows compatibility anchor missing: $anchor" }
}
$theme = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $SourceRoot 'theme\theme.json') | ConvertFrom-Json
if (-not $theme.name) { throw 'Theme name is missing.' }

$checksumPath = Join-Path $PSScriptRoot 'SHA256SUMS.txt'
if (Test-Path -LiteralPath $checksumPath) {
    foreach ($line in Get-Content -Encoding UTF8 -LiteralPath $checksumPath) {
        if (-not $line.Trim() -or $line.TrimStart().StartsWith('#')) { continue }
        if ($line -notmatch '^([0-9a-fA-F]{64})\s+\*(.+)$') { throw "Invalid checksum line: $line" }
        $expectedHash = $matches[1].ToUpperInvariant()
        $relativePath = $matches[2]
        $filePath = Join-Path $PSScriptRoot $relativePath
        if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) { throw "Checksummed file missing: $relativePath" }
        $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $filePath).Hash
        if ($actualHash -ne $expectedHash) { throw "Checksum mismatch: $relativePath" }
    }
}

Write-Host "STATIC_TEST_OK · $($scripts.Count) PowerShell scripts · $($placeholders.Count) renderer placeholders · theme=$($theme.name)"

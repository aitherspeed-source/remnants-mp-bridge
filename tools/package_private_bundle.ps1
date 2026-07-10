param(
    [string]$OutputDirectory = (Join-Path (Split-Path -Parent $PSScriptRoot) 'dist')
)

$ErrorActionPreference = 'Stop'
$modRoot = Split-Path -Parent $PSScriptRoot
$template = Join-Path $PSScriptRoot 'friend_bundle'
$source = Join-Path $modRoot 'src\42'
$agent = Join-Path $modRoot 'java\build\RemnantsMPBridgeAgent.jar'
$metadata = Get-Content -LiteralPath (Join-Path $source 'mod.info')
$versionLine = $metadata | Where-Object { $_ -match '^version=' } | Select-Object -First 1
if (-not $versionLine) { throw 'mod.info does not contain a version.' }
$version = $versionLine.Substring('version='.Length).Trim()
$bundleName = "RemnantsMPBridge-$version"
$stage = Join-Path $OutputDirectory $bundleName
$zip = Join-Path $OutputDirectory "$bundleName.zip"

foreach ($required in @($template, (Join-Path $source 'mod.info'), $agent)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing bundle input: $required" }
}
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
Copy-Item -LiteralPath $template -Destination $stage -Recurse
$payload = Join-Path $stage 'payload'
New-Item -ItemType Directory -Path $payload | Out-Null
$runtimeMod = Join-Path $payload 'RemnantsMPBridge'
New-Item -ItemType Directory -Path $runtimeMod | Out-Null
Copy-Item -Path (Join-Path $source '*') -Destination $runtimeMod -Recurse
$versioned = Join-Path $runtimeMod '42'
New-Item -ItemType Directory -Path $versioned | Out-Null
Copy-Item -Path (Join-Path $source '*') -Destination $versioned -Recurse
Copy-Item -LiteralPath $agent -Destination (Join-Path $payload 'RemnantsMPBridgeAgent.jar')

# Project Zomboid compares client/server mod files byte-for-byte. Normalize the
# runtime text payload so Git checkout settings cannot create false mismatches.
foreach ($runtimeText in Get-ChildItem -LiteralPath $runtimeMod -Recurse -File |
        Where-Object { $_.Extension -eq '.lua' -or $_.Name -eq 'mod.info' }) {
    $text = [IO.File]::ReadAllText($runtimeText.FullName)
    $text = $text.Replace("`r`n", "`n").Replace("`r", "`n")
    [IO.File]::WriteAllText($runtimeText.FullName, $text, [Text.UTF8Encoding]::new($false))
}

$checksumLines = Get-ChildItem -LiteralPath $stage -Recurse -File |
    Sort-Object FullName |
    ForEach-Object {
        $relative = $_.FullName.Substring($stage.Length + 1).Replace('\', '/')
        "$((Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash)  $relative"
    }
[IO.File]::WriteAllLines((Join-Path $stage 'CHECKSUMS.sha256'), $checksumLines, [Text.UTF8Encoding]::new($false))
Compress-Archive -LiteralPath $stage -DestinationPath $zip -CompressionLevel Optimal
$item = Get-Item -LiteralPath $zip
$hash = Get-FileHash -Algorithm SHA256 -LiteralPath $zip
Remove-Item -LiteralPath $stage -Recurse -Force
Write-Output "Bundle: $($item.FullName)"
Write-Output "Bytes: $($item.Length)"
Write-Output "SHA256: $($hash.Hash)"

param(
    [string]$ZomboidUserHome = (Join-Path $env:USERPROFILE 'Zomboid')
)

$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modRoot = Split-Path -Parent $scriptRoot
$source = Join-Path $modRoot 'src\42'
$destination = Join-Path $ZomboidUserHome 'mods\RemnantsMPBridge'
$versionedDestination = Join-Path $destination '42'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'

if (-not (Test-Path -LiteralPath (Join-Path $source 'mod.info'))) {
    throw "Missing bridge source: $source"
}

if (Test-Path -LiteralPath $destination) {
    $backup = "$destination.codex-backup-$stamp"
    Copy-Item -LiteralPath $destination -Destination $backup -Recurse -Force
    Write-Output "Existing local deployment backed up: $backup"
}

New-Item -ItemType Directory -Path $destination -Force | Out-Null
New-Item -ItemType Directory -Path $versionedDestination -Force | Out-Null

# The root metadata keeps the local mod discoverable in the Mods UI. The Build
# 42 versioned copy is required by the listen-server mod loader.
Copy-Item -Path (Join-Path $source '*') -Destination $destination -Recurse -Force
Copy-Item -Path (Join-Path $source '*') -Destination $versionedDestination -Recurse -Force

foreach ($required in @(
    (Join-Path $destination 'mod.info'),
    (Join-Path $versionedDestination 'mod.info'),
    (Join-Path $versionedDestination 'media\lua\server\RemnantsMPBridge\BridgeServer.lua')
)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Deployment verification failed: $required"
    }
}

Write-Output "Deployed local bridge root: $destination"
Write-Output "Deployed Build 42 bridge: $versionedDestination"


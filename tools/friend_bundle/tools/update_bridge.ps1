$ErrorActionPreference = 'Stop'
$repository = 'aitherspeed-source/remnants-mp-bridge'
$manifestUrl = "https://github.com/$repository/releases/latest/download/latest.json"
$installedModInfo = Join-Path $env:USERPROFILE 'Zomboid\mods\RemnantsMPBridge\mod.info'
$workRoot = Join-Path ([IO.Path]::GetTempPath()) ("RemnantsMPBridgeUpdate-" + [guid]::NewGuid().ToString('N'))

function Get-InstalledVersion {
    if (-not (Test-Path -LiteralPath $installedModInfo)) { return 'not-installed' }
    $line = Get-Content -LiteralPath $installedModInfo |
        Where-Object { $_ -match '^version=' } | Select-Object -First 1
    if (-not $line) { return 'unknown' }
    return $line.Substring('version='.Length).Trim()
}

try {
    Write-Output "Checking $repository for updates..."
    $manifest = Invoke-RestMethod -Uri $manifestUrl -Headers @{ 'User-Agent' = 'RemnantsMPBridgeUpdater' }
    if (-not $manifest.version -or -not $manifest.assetUrl -or -not $manifest.sha256) {
        throw 'The release manifest is incomplete.'
    }
    $installedVersion = Get-InstalledVersion
    if ($installedVersion -eq [string]$manifest.version) {
        Write-Output "Already up to date: $installedVersion"
        exit 0
    }

    New-Item -ItemType Directory -Path $workRoot | Out-Null
    $zipPath = Join-Path $workRoot 'update.zip'
    Write-Output "Downloading $installedVersion -> $($manifest.version)..."
    Invoke-WebRequest -Uri ([string]$manifest.assetUrl) -OutFile $zipPath `
        -Headers @{ 'User-Agent' = 'RemnantsMPBridgeUpdater' }
    $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath).Hash
    if ($actualHash -ne ([string]$manifest.sha256).ToUpperInvariant()) {
        throw "Checksum mismatch. Expected $($manifest.sha256), received $actualHash."
    }

    $extractPath = Join-Path $workRoot 'extracted'
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath
    $installer = Get-ChildItem -LiteralPath $extractPath -Recurse -File -Filter friend_install.ps1 |
        Where-Object { $_.FullName -match '[\\/]tools[\\/]friend_install\.ps1$' } |
        Select-Object -First 1
    if (-not $installer) { throw 'Downloaded release does not contain the bridge installer.' }
    & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $installer.FullName -Mode Install
    if ($LASTEXITCODE -ne 0) { throw "Downloaded installer failed with exit code $LASTEXITCODE." }
    $verifiedVersion = Get-InstalledVersion
    if ($verifiedVersion -ne [string]$manifest.version) {
        throw "Install verification failed: expected $($manifest.version), found $verifiedVersion."
    }
    Write-Output "Updated successfully to $verifiedVersion. Restart Project Zomboid."
    exit 0
} catch {
    Write-Error $_.Exception.Message
    exit 1
} finally {
    if (Test-Path -LiteralPath $workRoot) {
        Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

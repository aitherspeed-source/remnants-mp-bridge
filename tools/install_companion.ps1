param(
    [ValidateSet('Install', 'Uninstall')]
    [string]$Mode = 'Install',

    [string]$ProjectZomboidHome = 'D:\Steam\steamapps\common\ProjectZomboid',

    [string]$AgentJar
)

$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modRoot = Split-Path -Parent $scriptRoot
if (-not $AgentJar) {
    $AgentJar = Join-Path $modRoot 'java\build\RemnantsMPBridgeAgent.jar'
}

$launchJson = Join-Path $ProjectZomboidHome 'ProjectZomboid64.json'
$targetAgent = Join-Path $ProjectZomboidHome 'RemnantsMPBridgeAgent.jar'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$backup = "$launchJson.RemnantsMPBridgeBackup.$stamp"
$agentName = 'RemnantsMPBridgeAgent.jar'

function Get-TextArray($value) {
    if ($null -eq $value) { return @() }
    return @($value | ForEach-Object { [string]$_ })
}

function Is-BridgeClassPath([string]$value) {
    if (-not $value) { return $false }
    return [IO.Path]::GetFileName($value.Trim('"')) -ieq $agentName
}

function Is-BridgeAgentArg([string]$value) {
    if (-not $value.StartsWith('-javaagent:', [StringComparison]::OrdinalIgnoreCase)) { return $false }
    return Is-BridgeClassPath $value.Substring('-javaagent:'.Length)
}

function Save-LaunchConfig($config) {
    Copy-Item -LiteralPath $launchJson -Destination $backup -Force
    $json = $config | ConvertTo-Json -Depth 20
    [IO.File]::WriteAllText($launchJson, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
    $null = Get-Content -LiteralPath $launchJson -Raw | ConvertFrom-Json
}

if (-not (Test-Path -LiteralPath $launchJson)) {
    throw "Missing launch configuration: $launchJson"
}

$config = Get-Content -LiteralPath $launchJson -Raw | ConvertFrom-Json
$classpath = @(Get-TextArray $config.classpath | Where-Object { -not (Is-BridgeClassPath $_) })
$vmArgs = @(Get-TextArray $config.vmArgs | Where-Object { -not (Is-BridgeAgentArg $_) })

if ($Mode -eq 'Install') {
    if (-not (Test-Path -LiteralPath $AgentJar)) {
        throw "Missing built companion jar: $AgentJar"
    }

    $hasNpcfwClassPath = @($classpath | Where-Object { [IO.Path]::GetFileName($_.Trim('"')) -ieq 'NPCFW.jar' }).Count -gt 0
    $hasNpcfwAgent = @($vmArgs | Where-Object { $_.StartsWith('-javaagent:', [StringComparison]::OrdinalIgnoreCase) -and $_ -match 'NPCFW\.jar' }).Count -gt 0
    if (-not $hasNpcfwClassPath -or -not $hasNpcfwAgent) {
        throw 'Project Remnants Java agent is not installed. Run its supplied installer first, verify Project Remnants in single-player, then rerun this installer.'
    }

    Copy-Item -LiteralPath $AgentJar -Destination $targetAgent -Force
    $classpath += $agentName
    $vmArgs += "-javaagent:$agentName"
    $config.classpath = $classpath
    $config.vmArgs = $vmArgs
    Save-LaunchConfig $config

    $installed = Get-Content -LiteralPath $launchJson -Raw | ConvertFrom-Json
    $classCount = @(Get-TextArray $installed.classpath | Where-Object { Is-BridgeClassPath $_ }).Count
    $agentCount = @(Get-TextArray $installed.vmArgs | Where-Object { Is-BridgeAgentArg $_ }).Count
    if ($classCount -ne 1 -or $agentCount -ne 1) {
        throw "Install verification failed. Restore backup: $backup"
    }

    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $targetAgent).Hash
    Write-Output "Installed companion: $targetAgent"
    Write-Output "SHA256: $hash"
    Write-Output "Launch backup: $backup"
    Write-Output 'ProjectZomboidServer.bat was not changed.'
    exit 0
}

$config.classpath = $classpath
$config.vmArgs = $vmArgs
Save-LaunchConfig $config
if (Test-Path -LiteralPath $targetAgent) {
    Remove-Item -LiteralPath $targetAgent -Force
}

Write-Output 'Removed Remnants MP Bridge companion launch entries and game-root jar.'
Write-Output "Pre-uninstall launch backup: $backup"
Write-Output 'Project Remnants entries and ProjectZomboidServer.bat were not changed.'

param(
    [ValidateSet('Install', 'Uninstall')]
    [string]$Mode = 'Install'
)

$ErrorActionPreference = 'Stop'
$bundleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$payload = Join-Path $bundleRoot 'payload'
$agentSource = Join-Path $payload 'RemnantsMPBridgeAgent.jar'
$modSource = Join-Path $payload 'RemnantsMPBridge'
$modDestination = Join-Path $env:USERPROFILE 'Zomboid\mods\RemnantsMPBridge'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$agentName = 'RemnantsMPBridgeAgent.jar'

function Get-SteamLibraries {
    $libraries = [Collections.Generic.List[string]]::new()
    $roots = @()
    try {
        $steamPath = (Get-ItemProperty -LiteralPath 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamPath
        if ($steamPath) { $roots += $steamPath }
    } catch {}
    $roots += @(
        'C:\Program Files (x86)\Steam',
        'C:\Program Files\Steam',
        'D:\Steam',
        'E:\Steam'
    )
    foreach ($root in $roots | Select-Object -Unique) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        $libraries.Add($root)
        $vdf = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            foreach ($line in Get-Content -LiteralPath $vdf) {
                if ($line -match '"path"\s+"([^"]+)"') {
                    $path = $Matches[1] -replace '\\\\', '\'
                    if (Test-Path -LiteralPath $path) { $libraries.Add($path) }
                }
            }
        }
    }
    return @($libraries | Select-Object -Unique)
}

function Find-GameHome($libraries) {
    foreach ($library in $libraries) {
        $candidate = Join-Path $library 'steamapps\common\ProjectZomboid'
        if (Test-Path -LiteralPath (Join-Path $candidate 'ProjectZomboid64.json')) {
            return $candidate
        }
    }
    throw 'Project Zomboid was not found in the detected Steam libraries.'
}

function Find-ProjectRemnants($libraries) {
    foreach ($library in $libraries) {
        $candidate = Join-Path $library 'steamapps\workshop\content\108600\3738362476\mods\ProjectRemnants'
        if (Test-Path -LiteralPath (Join-Path $candidate 'NPCFW.jar')) { return $candidate }
    }
    return $null
}

function Get-TextArray($value) {
    if ($null -eq $value) { return @() }
    return @($value | ForEach-Object { [string]$_ })
}

function Is-BridgeClassPath([string]$value) {
    return $value -and [IO.Path]::GetFileName($value.Trim('"')) -ieq $agentName
}

function Is-BridgeAgentArg([string]$value) {
    return $value -and
        $value.StartsWith('-javaagent:', [StringComparison]::OrdinalIgnoreCase) -and
        (Is-BridgeClassPath $value.Substring('-javaagent:'.Length))
}

try {
    $libraries = Get-SteamLibraries
    $gameHome = Find-GameHome $libraries
    $launchJson = Join-Path $gameHome 'ProjectZomboid64.json'
    $targetAgent = Join-Path $gameHome $agentName
    $launchBackup = "$launchJson.RemnantsMPBridgeBackup.$stamp"
    $config = Get-Content -LiteralPath $launchJson -Raw | ConvertFrom-Json
    $classpath = @(Get-TextArray $config.classpath | Where-Object { -not (Is-BridgeClassPath $_) })
    $vmArgs = @(Get-TextArray $config.vmArgs | Where-Object { -not (Is-BridgeAgentArg $_) })

    if ($Mode -eq 'Install') {
        if (-not (Test-Path -LiteralPath $agentSource) -or
                -not (Test-Path -LiteralPath (Join-Path $modSource 'mod.info'))) {
            throw 'The bundle payload is incomplete. Extract the entire ZIP and try again.'
        }
        $remnantsHome = Find-ProjectRemnants $libraries
        if (-not $remnantsHome) {
            throw 'Project Remnants Workshop item 3738362476 is not downloaded in a detected Steam library.'
        }
        $hasNpcfwClassPath = @($classpath | Where-Object {
            [IO.Path]::GetFileName($_.Trim('"')) -ieq 'NPCFW.jar'
        }).Count -gt 0
        $hasNpcfwAgent = @($vmArgs | Where-Object {
            $_.StartsWith('-javaagent:', [StringComparison]::OrdinalIgnoreCase) -and $_ -match 'NPCFW\.jar'
        }).Count -gt 0
        if (-not $hasNpcfwClassPath -or -not $hasNpcfwAgent) {
            $remnantsInstaller = Join-Path $remnantsHome 'root\install_project_remnants.ps1'
            if (-not (Test-Path -LiteralPath $remnantsInstaller)) {
                throw 'Project Remnants Java agent is missing and its supplied installer could not be found. Verify the Workshop download.'
            }
            Write-Output 'Project Remnants Java agent is missing; running its supplied installer...'
            & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass `
                -File $remnantsInstaller -ProjectZomboidPath $gameHome -NoPause
            if ($LASTEXITCODE -ne 0) {
                throw "Project Remnants supplied installer failed with exit code $LASTEXITCODE."
            }
            $config = Get-Content -LiteralPath $launchJson -Raw | ConvertFrom-Json
            $classpath = @(Get-TextArray $config.classpath | Where-Object { -not (Is-BridgeClassPath $_) })
            $vmArgs = @(Get-TextArray $config.vmArgs | Where-Object { -not (Is-BridgeAgentArg $_) })
            $hasNpcfwClassPath = @($classpath | Where-Object {
                [IO.Path]::GetFileName($_.Trim('"')) -ieq 'NPCFW.jar'
            }).Count -gt 0
            $hasNpcfwAgent = @($vmArgs | Where-Object {
                $_.StartsWith('-javaagent:', [StringComparison]::OrdinalIgnoreCase) -and $_ -match 'NPCFW\.jar'
            }).Count -gt 0
            if (-not $hasNpcfwClassPath -or -not $hasNpcfwAgent) {
                throw 'Project Remnants supplied installer completed but its Java launch entries could not be verified.'
            }
        }

        if (Test-Path -LiteralPath $modDestination) {
            Copy-Item -LiteralPath $modDestination -Destination "$modDestination.codex-backup-$stamp" -Recurse -Force
            Remove-Item -LiteralPath $modDestination -Recurse -Force
        }
        New-Item -ItemType Directory -Path (Split-Path -Parent $modDestination) -Force | Out-Null
        Copy-Item -LiteralPath $modSource -Destination $modDestination -Recurse -Force
        Copy-Item -LiteralPath $agentSource -Destination $targetAgent -Force
        $classpath += $agentName
        $vmArgs += "-javaagent:$agentName"
    } else {
        if (Test-Path -LiteralPath $modDestination) {
            Move-Item -LiteralPath $modDestination -Destination "$modDestination.uninstalled-$stamp"
        }
        if (Test-Path -LiteralPath $targetAgent) { Remove-Item -LiteralPath $targetAgent -Force }
    }

    Copy-Item -LiteralPath $launchJson -Destination $launchBackup -Force
    $config.classpath = $classpath
    $config.vmArgs = $vmArgs
    [IO.File]::WriteAllText(
        $launchJson,
        ($config | ConvertTo-Json -Depth 20) + [Environment]::NewLine,
        [Text.UTF8Encoding]::new($false))
    $verified = Get-Content -LiteralPath $launchJson -Raw | ConvertFrom-Json

    if ($Mode -eq 'Install') {
        $classCount = @(Get-TextArray $verified.classpath | Where-Object { Is-BridgeClassPath $_ }).Count
        $agentCount = @(Get-TextArray $verified.vmArgs | Where-Object { Is-BridgeAgentArg $_ }).Count
        if ($classCount -ne 1 -or $agentCount -ne 1) {
            throw "Launch verification failed. Restore $launchBackup"
        }
        Write-Output "Game: $gameHome"
        Write-Output "Mod: $modDestination"
        Write-Output "Agent SHA256: $((Get-FileHash -Algorithm SHA256 $targetAgent).Hash)"
        Write-Output "Launch backup: $launchBackup"
    } else {
        Write-Output 'Bridge removed. Project Remnants was not changed.'
        Write-Output "Launch backup: $launchBackup"
    }
    exit 0
} catch {
    Write-Error $_.Exception.Message
    exit 1
}

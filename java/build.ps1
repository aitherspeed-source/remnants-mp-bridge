param(
    [Parameter(Mandatory = $true)]
    [string]$JdkHome,

    [string]$ProjectZomboidHome = 'D:\Steam\steamapps\common\ProjectZomboid',

    [string]$ProjectRemnantsHome = 'D:\Steam\steamapps\workshop\content\108600\3738362476\mods\ProjectRemnants'
)

$ErrorActionPreference = 'Stop'

$javac = Join-Path $JdkHome 'bin\javac.exe'
$jarTool = Join-Path $JdkHome 'bin\jar.exe'
$gameJar = Join-Path $ProjectZomboidHome 'projectzomboid.jar'
$npcfwJar = Join-Path $ProjectRemnantsHome 'NPCFW.jar'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceRoot = Join-Path $scriptRoot 'src\main\java'
$resourceRoot = Join-Path $scriptRoot 'src\main\resources'
$buildRoot = Join-Path $scriptRoot 'build'
$classesRoot = Join-Path $buildRoot 'classes'
$outputJar = Join-Path $buildRoot 'RemnantsMPBridgeAgent.jar'

foreach ($required in @($javac, $jarTool, $gameJar, $npcfwJar)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing required file: $required"
    }
}

if (Test-Path -LiteralPath $buildRoot) {
    $resolvedBuild = (Resolve-Path -LiteralPath $buildRoot).Path
    $resolvedScript = (Resolve-Path -LiteralPath $scriptRoot).Path
    if (-not $resolvedBuild.StartsWith($resolvedScript + [IO.Path]::DirectorySeparatorChar)) {
        throw 'Refusing to clean a build folder outside the Java project.'
    }
    Remove-Item -LiteralPath $resolvedBuild -Recurse -Force
}

New-Item -ItemType Directory -Path $classesRoot | Out-Null
$sources = @(Get-ChildItem -LiteralPath $sourceRoot -Recurse -Filter '*.java' | Select-Object -ExpandProperty FullName)
if ($sources.Count -eq 0) {
    throw 'No Java sources found.'
}

$classpath = "$gameJar;$npcfwJar"
& $javac --release 25 -encoding UTF-8 -classpath $classpath -d $classesRoot @sources
if ($LASTEXITCODE -ne 0) {
    throw "javac failed with exit code $LASTEXITCODE"
}

$manifest = Join-Path $resourceRoot 'META-INF\MANIFEST.MF'
& $jarTool --create --file $outputJar --manifest $manifest -C $classesRoot .
if ($LASTEXITCODE -ne 0) {
    throw "jar failed with exit code $LASTEXITCODE"
}

$hash = Get-FileHash -Algorithm SHA256 -LiteralPath $outputJar
Write-Output "Built: $outputJar"
Write-Output "SHA256: $($hash.Hash)"


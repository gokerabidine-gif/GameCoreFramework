[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$EngineRoot,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),

    [Parameter()]
    [ValidateSet('Development', 'Shipping')]
    [string]$Configuration = 'Development',

    [Parameter()]
    [ValidateSet('ASTC', 'DXT', 'ETC2')]
    [string]$CookFlavor,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputDirectory = (Join-Path (Split-Path -Parent $PSScriptRoot) 'Build/Android')
)

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$engineRoot = (Resolve-Path -LiteralPath $EngineRoot).Path
$projectFile = Join-Path $projectRoot 'GCF_SampleProject.uproject'
$preflight = Join-Path $PSScriptRoot 'Test-AndroidPortPrerequisites.ps1'
$runUat = Join-Path $engineRoot 'Engine/Build/BatchFiles/RunUAT.bat'
$buildVersionFile = Join-Path $engineRoot 'Engine/Build/Build.version'

foreach ($required in @($projectFile, $preflight, $runUat, $buildVersionFile)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "Required file was not found: $required"
    }
}

try {
    $engineVersion = Get-Content -LiteralPath $buildVersionFile -Raw | ConvertFrom-Json
}
catch {
    throw "Could not parse Unreal Engine Build.version: $($_.Exception.Message)"
}

if ([int]$engineVersion.MajorVersion -ne 5 -or [int]$engineVersion.MinorVersion -ne 7) {
    throw "This project targets Unreal Engine 5.7. Detected engine version $($engineVersion.MajorVersion).$($engineVersion.MinorVersion)."
}

Write-Host 'Running project/dependency preflight...'
& $preflight -ProjectRoot $projectRoot
if ($LASTEXITCODE -ne 0) {
    throw 'Preflight failed. Resolve missing/invalid project descriptors and the seven Lyra plugin dependencies before packaging.'
}

$outputPath = [System.IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $outputPath -Force | Out-Null

$uatArgs = @(
    'BuildCookRun',
    "-project=$projectFile",
    '-noP4',
    '-platform=Android',
    "-clientconfig=$Configuration",
    '-build',
    '-cook',
    '-stage',
    '-pak',
    '-package',
    '-archive',
    "-archivedirectory=$outputPath",
    '-unattended',
    '-utf8output'
)

if (-not [string]::IsNullOrWhiteSpace($CookFlavor)) {
    $uatArgs += "-cookflavor=$CookFlavor"
}

Write-Host "Starting Unreal Automation Tool for Android ($Configuration)..."
Write-Host "Engine: $engineRoot"
Write-Host "Project: $projectFile"
Write-Host "Output: $outputPath"

& $runUat @uatArgs
$uatExitCode = $LASTEXITCODE
if ($uatExitCode -ne 0) {
    throw "RunUAT failed with exit code $uatExitCode. Review the Android SDK/NDK/JDK setup and the full UAT log."
}

$apk = Get-ChildItem -LiteralPath $outputPath -Filter '*.apk' -File -Recurse | Select-Object -First 1
if ($null -eq $apk) {
    throw "RunUAT returned success but no APK was found under: $outputPath"
}

Write-Host "APK created: $($apk.FullName)" -ForegroundColor Green
Write-Host 'This script does not install the APK or certify device/runtime correctness.'

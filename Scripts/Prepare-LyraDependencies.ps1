[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$LyraPluginsPath,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$requiredPlugins = @(
    'CommonGame',
    'CommonUser',
    'CommonLoadingScreen',
    'GameplayMessageRouter',
    'ModularGameplayActors',
    'GameSubtitles',
    'UIExtension'
)

$sourceRoot = (Resolve-Path -LiteralPath $LyraPluginsPath).Path
$destinationRoot = Join-Path (Resolve-Path -LiteralPath $ProjectRoot).Path 'Plugins'

if (-not (Test-Path -LiteralPath $destinationRoot -PathType Container)) {
    throw "Project Plugins directory was not found: $destinationRoot"
}

# Validate every source before copying anything, so a partial copy is avoided.
$validated = foreach ($plugin in $requiredPlugins) {
    $source = Join-Path $sourceRoot $plugin
    $descriptor = Join-Path $source ($plugin + '.uplugin')

    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        throw "Missing Lyra plugin folder: $source"
    }
    if (-not (Test-Path -LiteralPath $descriptor -PathType Leaf)) {
        throw "Missing plugin descriptor: $descriptor"
    }

    try {
        $null = Get-Content -LiteralPath $descriptor -Raw | ConvertFrom-Json
    }
    catch {
        throw "Invalid JSON plugin descriptor: $descriptor. $($_.Exception.Message)"
    }

    $destination = Join-Path $destinationRoot $plugin
    if (Test-Path -LiteralPath $destination) {
        throw "Destination already exists; refusing to overwrite it: $destination"
    }

    [PSCustomObject]@{
        Name = $plugin
        Source = $source
        Destination = $destination
    }
}

Write-Host 'All seven UE/Lyra plugin folders and descriptors passed validation.'
Write-Host 'The project .gitignore excludes these dependency folders, so they remain local and are not pushed to GitHub.'
Write-Host 'Use -WhatIf first to preview the copy.'

foreach ($item in $validated) {
    if ($PSCmdlet.ShouldProcess($item.Destination, "Copy Lyra plugin $($item.Name)")) {
        Copy-Item -LiteralPath $item.Source -Destination $item.Destination -Recurse
        if (-not (Test-Path -LiteralPath (Join-Path $item.Destination ($item.Name + '.uplugin')) -PathType Leaf)) {
            throw "Post-copy verification failed for plugin: $($item.Name)"
        }
        Write-Host "Copied and verified: $($item.Name)"
    }
}

Write-Host 'Dependency preparation finished. This script does not compile or package the Unreal project.'

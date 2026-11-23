[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$projectFile = Join-Path $projectRoot 'GCF_SampleProject.uproject'
$frameworkDescriptor = Join-Path $projectRoot 'Plugins/GameCoreFramework/GameCoreFramework.uplugin'

$requiredLyraPlugins = @(
    'CommonGame',
    'CommonUser',
    'CommonLoadingScreen',
    'GameplayMessageRouter',
    'ModularGameplayActors',
    'GameSubtitles',
    'UIExtension'
)

$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$passed = [System.Collections.Generic.List[string]]::new()

function Read-JsonFile {
    param([string]$Path, [string]$Label)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $script:errors.Add(("Missing {0}: {1}" -f $Label, $Path))
        return $null
    }

    try {
        return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json)
    }
    catch {
        $script:errors.Add(("Invalid JSON in {0}: {1} ({2})" -f $Label, $Path, $_.Exception.Message))
        return $null
    }
}

$project = Read-JsonFile -Path $projectFile -Label 'project descriptor'
if ($null -ne $project) {
    if ([string]$project.EngineAssociation -ne '5.7') {
        $warnings.Add("Project EngineAssociation is '$($project.EngineAssociation)', not 5.7.")
    }
    else {
        $passed.Add('Project descriptor is valid JSON and targets Unreal Engine 5.7.')
    }

    $gameModule = @($project.Modules | Where-Object { $_.Name -eq 'GCF_SampleProject' -and $_.Type -eq 'Runtime' })
    if ($gameModule.Count -eq 0) {
        $errors.Add('The project descriptor has no GCF_SampleProject Runtime module.')
    }
    else {
        $passed.Add('Runtime game module is declared in the project descriptor.')
    }
}

$framework = Read-JsonFile -Path $frameworkDescriptor -Label 'GameCoreFramework plugin descriptor'
if ($null -ne $framework) {
    $passed.Add('GameCoreFramework plugin descriptor is valid JSON.')

    foreach ($plugin in $requiredLyraPlugins) {
        $pluginDescriptor = Join-Path $projectRoot ("Plugins/{0}/{0}.uplugin" -f $plugin)
        $descriptor = Read-JsonFile -Path $pluginDescriptor -Label "$plugin plugin descriptor"
        if ($null -eq $descriptor) {
            continue
        }

        $passed.Add("$plugin descriptor exists and contains valid JSON.")

        foreach ($module in @($descriptor.Modules)) {
            if ($null -eq $module) { continue }

            $allow = @($module.PlatformAllowList)
            if ($allow.Count -eq 0) { $allow = @($module.WhitelistPlatforms) }
            $deny = @($module.PlatformDenyList)
            if ($deny.Count -eq 0) { $deny = @($module.BlacklistPlatforms) }

            if ($allow.Count -gt 0 -and ($allow -notcontains 'Android')) {
                $warnings.Add("$plugin module '$($module.Name)' has a platform allow-list that does not include Android.")
            }
            if ($deny -contains 'Android') {
                $warnings.Add("$plugin module '$($module.Name)' explicitly denies Android.")
            }
        }
    }
}

if ($errors.Count -gt 0) {
    Write-Host "`nFAILED CHECKS:" -ForegroundColor Red
    foreach ($item in $errors) { Write-Host "  - $item" -ForegroundColor Red }
}

if ($warnings.Count -gt 0) {
    Write-Host "`nWARNINGS REQUIRING MANUAL REVIEW:" -ForegroundColor Yellow
    foreach ($item in $warnings) { Write-Host "  - $item" -ForegroundColor Yellow }
}

if ($passed.Count -gt 0) {
    Write-Host "`nPASSED CHECKS:" -ForegroundColor Green
    foreach ($item in $passed) { Write-Host "  - $item" -ForegroundColor Green }
}

Write-Host "`nSummary: $($passed.Count) passed, $($warnings.Count) warnings, $($errors.Count) errors."
Write-Host 'This is a descriptor/dependency preflight only. It does not prove Android compatibility, compile C++, cook assets, or create an APK.'

if ($errors.Count -gt 0) {
    exit 1
}

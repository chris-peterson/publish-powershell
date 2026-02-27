#!/usr/bin/env pwsh

param(
    [Parameter(Mandatory)]
    [string]
    $ApiKey,

    [Parameter()]
    [switch]
    $SkipValidation,

    [Parameter()]
    [switch]
    $SkipPublish
)

$ErrorActionPreference = 'Stop'

$Results = @()

Get-ChildItem -Recurse -Filter '*.psd1' | ForEach-Object {
    $Manifest   = Import-PowerShellDataFile -Path $_
    $ModuleDir  = $_.Directory
    $ModuleName = $_.Directory.Name
    $Version    = $Manifest.ModuleVersion
    $Status     = 'unknown'

    if (-not $SkipValidation) {
        foreach ($Module in $Manifest.RequiredModules) {
            $Name = if ($Module -is [string]) { $Module } else { $Module.ModuleName }
            if (-not (Get-Module -ListAvailable -Name $Name)) {
                Install-PSResource -Name $Name -Scope AllUsers -TrustRepository
            }
        }
        try {
            Test-ModuleManifest -Path $_ | Out-Null
        } catch {
            Write-Error "$_`nHint: use 'SkipValidation' to bypass manifest validation."
        }
    }

    if ($SkipPublish) {
        $Status = 'skipped'
    } else {
        try {
            Publish-PSResource -ApiKey $ApiKey -Path $ModuleDir
            $Status = 'published'
        } catch {
            Write-Error "$_`nHint: use 'SkipPublish' to test without publishing."
        }
    }

    $Results += [PSCustomObject]@{
        Name    = $ModuleName
        Version = $Version
        Status  = $Status
    }
}

foreach ($r in $Results) {
    $icon = switch ($r.Status) { 'published' { '✅' } 'skipped' { '⏭️' } default { '❓' } }
    Write-Host "$icon $($r.Name) $($r.Version)"
}

if ($env:GITHUB_STEP_SUMMARY) {
    $md = "## Publish PowerShell Module`n`n"
    $md += "| Module | Version | Status |`n"
    $md += "| --- | --- | --- |`n"
    foreach ($r in $Results) {
        $icon = switch ($r.Status) { 'published' { '✅' } 'skipped' { '⏭️' } default { '❓' } }
        $link = "[$($r.Name)](https://www.powershellgallery.com/packages/$($r.Name))"
        $md += "| $link | $($r.Version) | $icon $($r.Status) |`n"
    }
    $md | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append
}

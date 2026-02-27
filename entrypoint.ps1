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

    Write-Host "--- " -NoNewline
    Write-Host "$ModuleName $Version" -ForegroundColor Cyan -NoNewline
    Write-Host " ---"

    if (-not $SkipValidation) {
        foreach ($Module in $Manifest.RequiredModules) {
            $Name = if ($Module -is [string]) { $Module } else { $Module.ModuleName }
            if (-not (Get-Module -ListAvailable -Name $Name)) {
                Write-Host "  Installing required module '$Name'..." -ForegroundColor Yellow
                Install-PSResource -Name $Name -Scope AllUsers -TrustRepository
            }
        }
        try {
            Write-Host "  Validating manifest..." -ForegroundColor Gray
            Test-ModuleManifest -Path $_ | Out-Null
        } catch {
            Write-Error "$_`nHint: use 'SkipValidation' to bypass manifest validation."
        }
    }

    if ($SkipPublish) {
        Write-Host "  Publish skipped" -ForegroundColor Yellow
        $Status = 'skipped'
    } else {
        try {
            Write-Host "  Publishing..." -ForegroundColor Gray
            Publish-PSResource -ApiKey $ApiKey -Path $ModuleDir
            Write-Host "  Published successfully" -ForegroundColor Green
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

Write-Host ""
foreach ($r in $Results) {
    $color = switch ($r.Status) { 'published' { 'Green' } 'skipped' { 'Yellow' } default { 'Red' } }
    $icon  = switch ($r.Status) { 'published' { '✅' } 'skipped' { '⏭️' } default { '❓' } }
    Write-Host "$icon " -NoNewline
    Write-Host "$($r.Name) $($r.Version)" -ForegroundColor White -NoNewline
    Write-Host " ($($r.Status))" -ForegroundColor $color
}

if ($env:GITHUB_STEP_SUMMARY) {
    $md = ""
    $Published = $Results | Where-Object { $_.Status -eq 'published' }
    $Other     = $Results | Where-Object { $_.Status -ne 'published' }

    if ($Published) {
        $md += "## Published Modules`n`n"
        $md += "| Module | Version |`n"
        $md += "| --- | --- |`n"
        foreach ($r in $Published) {
            $link = "[$($r.Name)](https://www.powershellgallery.com/packages/$($r.Name)/$($r.Version))"
            $md += "| $link | $($r.Version) |`n"
        }
    }

    if ($Other) {
        $md += "`n## Other Modules`n`n"
        $md += "| Module | Version | Status |`n"
        $md += "| --- | --- | --- |`n"
        foreach ($r in $Other) {
            $icon = switch ($r.Status) { 'skipped' { '⏭️' } default { '❓' } }
            $md += "| $($r.Name) | $($r.Version) | $icon $($r.Status) |`n"
        }
    }

    if ($md) {
        $md | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append
    }
}

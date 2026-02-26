#!/usr/bin/env pwsh

$ErrorActionPreference = 'Stop'

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

Get-ChildItem -Recurse -Filter '*.psd1' | ForEach-Object {
    Write-Host "Processing '$_'..."

    $Manifest   = Import-PowerShellDataFile -Path $_
    $ModuleDir  = $_.Directory
    $ModuleName = $_.Directory.Name

    # Test-ModuleManifest will fail if a required module is not installed,
    # so install everything first
    foreach ($Module in $Manifest.RequiredModules) {
        $Name = if ($Module -is [string]) { $Module } else { $Module.ModuleName }
        if (-not (Get-Module -ListAvailable -Name $Name)) {
            Write-Host "`tInstalling required module '$Name'..."
            Install-PSResource -Name $Name -Scope AllUsers -TrustRepository
        }
    }

    if ($SkipValidation) {
        Write-Host "`tSkipping manifest validation"
    } else {
        try {
            Write-Host "`tValidating '$ModuleName' manifest..."
            Test-ModuleManifest -Path $_
        } catch {
            Write-Error "$_`nHint: use 'SkipValidation' to bypass manifest validation."
        }
    }

    if ($SkipPublish) {
        Write-Host "`tSkipping publish"
    } else {
        try {
            Write-Host "`tPublishing '$ModuleName'..."
            Publish-PSResource -ApiKey $ApiKey -Path $ModuleDir
            Write-Host "`tPublished '$ModuleName'"
        } catch {
            Write-Error "$_`nHint: use 'SkipPublish' to test without publishing."
        }
    }
}

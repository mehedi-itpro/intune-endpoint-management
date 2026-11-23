<#
.SYNOPSIS
    Create the three Windows Update rings from policies/update-ring-*.json.

.DESCRIPTION
    Rings are created unassigned. Assign each to its matching group afterwards:
        Ring0 -> INT-DEV-Ring0-Pilot
        Ring1 -> INT-DEV-Ring1-Early
        Ring2 -> INT-DEV-Ring2-Broad
    Existing rings with the same display name are skipped.

.EXAMPLE
    .\scripts\03-New-UpdateRings.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$PolicyFolder = (Join-Path $PSScriptRoot '..\policies')
)

$uri   = 'https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations'
$files = Get-ChildItem -Path $PolicyFolder -Filter 'update-ring-*.json' | Sort-Object Name
if (-not $files) { throw "No update-ring-*.json files found in $PolicyFolder" }

foreach ($file in $files) {
    $body = Get-Content -Raw -Path $file.FullName | ConvertFrom-Json
    $name = $body.displayName

    $existing = Invoke-MgGraphRequest -Method GET -Uri ("{0}?`$filter=displayName eq '{1}'" -f $uri, $name)
    if ($existing.value.Count -gt 0) {
        Write-Host "SKIP   '$name' already exists" -ForegroundColor Yellow
        continue
    }

    if ($PSCmdlet.ShouldProcess($name, 'Create update ring (unassigned)')) {
        $created = Invoke-MgGraphRequest -Method POST -Uri $uri -Body ($body | ConvertTo-Json -Depth 10) -ContentType 'application/json'
        Write-Host "CREATE '$name' -> id $($created.id)" -ForegroundColor Green
    }
}

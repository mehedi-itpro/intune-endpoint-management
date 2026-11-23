<#
.SYNOPSIS
    Create the Windows compliance policy from policies/compliance-windows-baseline.json.

.DESCRIPTION
    Posts the JSON body to Microsoft Graph. The policy is created UNASSIGNED so nothing
    changes on devices until you assign it deliberately (pilot ring first).
    Skips creation if a policy with the same display name already exists.

    Check property names against the current Graph reference before running; the
    windows10CompliancePolicy resource gets new properties over time.

.EXAMPLE
    .\scripts\02-New-CompliancePolicy.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$PolicyFile = (Join-Path $PSScriptRoot '..\policies\compliance-windows-baseline.json')
)

if (-not (Test-Path $PolicyFile)) { throw "Policy file not found: $PolicyFile" }

$body = Get-Content -Raw -Path $PolicyFile | ConvertFrom-Json
$name = $body.displayName
$uri  = 'https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies'

$existing = Invoke-MgGraphRequest -Method GET -Uri ("{0}?`$filter=displayName eq '{1}'" -f $uri, $name)
if ($existing.value.Count -gt 0) {
    Write-Host "SKIP   '$name' already exists (id $($existing.value[0].id))" -ForegroundColor Yellow
    return
}

if ($PSCmdlet.ShouldProcess($name, 'Create compliance policy (unassigned)')) {
    $created = Invoke-MgGraphRequest -Method POST -Uri $uri -Body ($body | ConvertTo-Json -Depth 10) -ContentType 'application/json'
    Write-Host "CREATE '$name' -> id $($created.id). Assign it to INT-DEV-Ring0-Pilot in the Intune admin center." -ForegroundColor Green
}

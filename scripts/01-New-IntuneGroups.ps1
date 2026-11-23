<#
.SYNOPSIS
    Create the Entra ID groups used for Intune targeting (see docs/02-groups-and-rollout-rings.md).

.DESCRIPTION
    Idempotent: groups that already exist (matched by display name) are skipped.
    Run with -WhatIf first to see what would be created.

.EXAMPLE
    .\scripts\01-New-IntuneGroups.ps1 -WhatIf
    .\scripts\01-New-IntuneGroups.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param()

$groups = @(
    @{
        Name = 'INT-DEV-Windows-All'
        Desc = 'All Intune-managed Windows devices (dynamic)'
        Rule = '(device.deviceOSType -eq "Windows") and (device.managementType -eq "MDM")'
    }
    @{
        Name = 'INT-DEV-Autopilot'
        Desc = 'All devices registered in Windows Autopilot (dynamic)'
        Rule = '(device.devicePhysicalIDs -any (_ -contains "[ZTDId]"))'
    }
    @{ Name = 'INT-DEV-Ring0-Pilot';  Desc = 'IT team devices - receive changes first (assigned)'; Rule = $null }
    @{ Name = 'INT-DEV-Ring1-Early';  Desc = 'Early adopters, about 10 percent of fleet (assigned)'; Rule = $null }
    @{ Name = 'INT-DEV-Ring2-Broad';  Desc = 'Everyone else (assigned or dynamic once stable)'; Rule = $null }
    @{ Name = 'INT-DEV-Exclude-Policies'; Desc = 'Break-glass: devices excluded from restrictive policies (assigned, keep empty)'; Rule = $null }
)

foreach ($g in $groups) {
    $existing = Get-MgGroup -Filter "displayName eq '$($g.Name)'" -ConsistencyLevel eventual -ErrorAction Stop
    if ($existing) {
        Write-Host "SKIP   $($g.Name) (already exists)" -ForegroundColor Yellow
        continue
    }

    if ($PSCmdlet.ShouldProcess($g.Name, 'Create Entra group')) {
        $params = @{
            DisplayName     = $g.Name
            Description     = $g.Desc
            MailEnabled     = $false
            MailNickname    = ($g.Name -replace '[^a-zA-Z0-9]', '')
            SecurityEnabled = $true
        }
        if ($g.Rule) {
            $params.GroupTypes                    = @('DynamicMembership')
            $params.MembershipRule                = $g.Rule
            $params.MembershipRuleProcessingState = 'On'
        }
        $null = New-MgGroup @params
        Write-Host "CREATE $($g.Name)" -ForegroundColor Green
    }
}

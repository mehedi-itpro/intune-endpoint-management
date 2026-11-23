<#
.SYNOPSIS
    Connect to Microsoft Graph with the scopes used by the scripts in this repo.

.DESCRIPTION
    Dot-source this file or run it before any other script:
        . .\scripts\00-Connect-Graph.ps1

    Scopes are delegated, so you act with your own Intune/Entra role. Use a
    dedicated admin account (not your daily mailbox account) and request only
    what you need. Remove scopes you do not use from the list below.

    Requires: Microsoft.Graph PowerShell SDK v2
        Install-Module Microsoft.Graph -Scope CurrentUser
#>
[CmdletBinding()]
param(
    [string]$TenantId
)

$scopes = @(
    'Group.ReadWrite.All'                                   # 01 - create groups
    'DeviceManagementConfiguration.ReadWrite.All'           # 02, 03 - compliance + update policies
    'DeviceManagementManagedDevices.Read.All'               # 04, 05 - inventory, escrow audit
    'DeviceManagementManagedDevices.PrivilegedOperations.All' # 06 - wipe / retire / rotate keys
    'BitLockerKey.ReadBasic.All'                            # 05 - key metadata only, not the key itself
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    throw 'Microsoft.Graph module not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser'
}

$connectParams = @{ Scopes = $scopes; NoWelcome = $true }
if ($TenantId) { $connectParams.TenantId = $TenantId }

Connect-MgGraph @connectParams
$ctx = Get-MgContext
Write-Host ("Connected to tenant {0} as {1}" -f $ctx.TenantId, $ctx.Account) -ForegroundColor Green

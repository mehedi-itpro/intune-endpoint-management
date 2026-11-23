<#
.SYNOPSIS
    Run a remote action on one Intune-managed device, with confirmation and an audit line.

.DESCRIPTION
    Actions:
        Sync               - ask the device to check in now
        RotateBitLockerKeys- rotate the recovery key (use after a key has been read out)
        Retire             - remove company data and management, keep personal data
        Wipe               - factory reset (lost/stolen device, or reassignment)

    Retire and Wipe are destructive. They prompt for confirmation unless you pass
    -Confirm:$false, and -WhatIf shows what would happen without doing it.
    Every real action appends a line to .\output\device-actions.log.

.EXAMPLE
    .\scripts\06-Invoke-DeviceAction.ps1 -DeviceName PC-0042 -Action Sync
    .\scripts\06-Invoke-DeviceAction.ps1 -DeviceName PC-0042 -Action Wipe -Reason "Lost, ticket 1234" -WhatIf
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$DeviceName,
    [Parameter(Mandatory)][ValidateSet('Sync', 'RotateBitLockerKeys', 'Retire', 'Wipe')][string]$Action,
    [string]$Reason,
    [string]$LogFolder = (Join-Path $PSScriptRoot '..\output')
)

if (($Action -in @('Retire', 'Wipe')) -and -not $Reason) {
    throw "-Reason (for example a ticket number) is required for $Action."
}

$found = @(Get-MgDeviceManagementManagedDevice -All -Filter "deviceName eq '$DeviceName'")
if ($found.Count -eq 0) { throw "No managed device named '$DeviceName'." }
if ($found.Count -gt 1) {
    $found | Format-Table DeviceName, SerialNumber, UserPrincipalName, LastSyncDateTime
    throw "More than one device is named '$DeviceName'. Resolve the duplicate first."
}
$device = $found[0]

$base = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($device.Id)"
switch ($Action) {
    'Sync'                { $uri = "$base/syncDevice";          $body = $null }
    'RotateBitLockerKeys' { $uri = "$base/rotateBitLockerKeys"; $body = $null }
    'Retire'              { $uri = "$base/retire";              $body = $null }
    'Wipe'                { $uri = "$base/wipe"
                            $body = @{ keepEnrollmentData = $false; keepUserData = $false; useProtectedWipe = $false } | ConvertTo-Json }
}

$target = "{0} (serial {1}, user {2})" -f $device.DeviceName, $device.SerialNumber, $device.UserPrincipalName
if ($PSCmdlet.ShouldProcess($target, $Action)) {
    if ($body) { Invoke-MgGraphRequest -Method POST -Uri $uri -Body $body -ContentType 'application/json' }
    else       { Invoke-MgGraphRequest -Method POST -Uri $uri }

    if (-not (Test-Path $LogFolder)) { $null = New-Item -ItemType Directory -Path $LogFolder }
    $line = "{0:s}Z`t{1}`t{2}`t{3}`t{4}" -f (Get-Date).ToUniversalTime(), (Get-MgContext).Account, $Action, $target, $Reason
    Add-Content -Path (Join-Path $LogFolder 'device-actions.log') -Value $line
    Write-Host "$Action requested for $target" -ForegroundColor Green
}

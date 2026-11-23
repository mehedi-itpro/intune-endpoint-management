<#
.SYNOPSIS
    List Intune-managed Windows devices that have no BitLocker recovery key escrowed in Entra ID.

.DESCRIPTION
    Uses key metadata only (BitLockerKey.ReadBasic.All), so the recovery keys themselves
    are never read or printed. A device with no key is a device you cannot recover if the
    user is locked out, so treat this as a standing weekly check.

.EXAMPLE
    .\scripts\05-Get-BitLockerEscrowReport.ps1 | Format-Table -AutoSize
#>
[CmdletBinding()]
param()

$keys = Get-MgInformationProtectionBitlockerRecoveryKey -All
$keysByDevice = @{}
foreach ($k in $keys) {
    if ($k.DeviceId) { $keysByDevice[$k.DeviceId] = $true }
}

$devices = Get-MgDeviceManagementManagedDevice -All -Filter "operatingSystem eq 'Windows'"

$missing = foreach ($d in $devices) {
    if (-not $d.AzureAdDeviceId -or -not $keysByDevice.ContainsKey($d.AzureAdDeviceId)) {
        [pscustomobject]@{
            DeviceName = $d.DeviceName
            User       = $d.UserPrincipalName
            Serial     = $d.SerialNumber
            Encrypted  = $d.IsEncrypted
            LastSync   = $d.LastSyncDateTime
        }
    }
}

Write-Host ("Windows devices: {0}   without escrowed key: {1}" -f @($devices).Count, @($missing).Count) -ForegroundColor Cyan
$missing | Sort-Object DeviceName

<#
.SYNOPSIS
    Export a device inventory and a short health summary from Intune.

.DESCRIPTION
    Writes a timestamped CSV with the fields an IT lead usually asks for, and prints
    counts for compliance, encryption and stale devices. Output goes to .\output by
    default. Do not commit the output: it contains serial numbers and user names.

.PARAMETER StaleDays
    Devices that have not synced for this many days are flagged as stale.

.EXAMPLE
    .\scripts\04-Export-DeviceInventory.ps1 -StaleDays 30
#>
[CmdletBinding()]
param(
    [int]$StaleDays = 30,
    [string]$OutputFolder = (Join-Path $PSScriptRoot '..\output')
)

if (-not (Test-Path $OutputFolder)) { $null = New-Item -ItemType Directory -Path $OutputFolder }

$devices = Get-MgDeviceManagementManagedDevice -All -Filter "operatingSystem eq 'Windows'"
$cutoff  = (Get-Date).AddDays(-$StaleDays)

$report = foreach ($d in $devices) {
    $totalGb = if ($d.TotalStorageSpaceInBytes) { [math]::Round($d.TotalStorageSpaceInBytes / 1GB, 0) } else { $null }
    $freeGb  = if ($d.FreeStorageSpaceInBytes)  { [math]::Round($d.FreeStorageSpaceInBytes / 1GB, 0) } else { $null }
    [pscustomobject]@{
        DeviceName     = $d.DeviceName
        User           = $d.UserPrincipalName
        Manufacturer   = $d.Manufacturer
        Model          = $d.Model
        SerialNumber   = $d.SerialNumber
        OSVersion      = $d.OsVersion
        Compliance     = $d.ComplianceState
        Encrypted      = $d.IsEncrypted
        EnrolledOn     = $d.EnrolledDateTime
        LastSync       = $d.LastSyncDateTime
        Stale          = ($d.LastSyncDateTime -lt $cutoff)
        StorageTotalGB = $totalGb
        StorageFreeGB  = $freeGb
        AzureAdDevice  = $d.AzureAdDeviceId
    }
}

$file = Join-Path $OutputFolder ("device-inventory-{0:yyyyMMdd-HHmm}.csv" -f (Get-Date))
$report | Sort-Object DeviceName | Export-Csv -Path $file -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Devices total      : $($report.Count)"
Write-Host "Non-compliant      : $(@($report | Where-Object Compliance -ne 'compliant').Count)"
Write-Host "Not encrypted      : $(@($report | Where-Object { $_.Encrypted -ne $true }).Count)"
Write-Host "Stale (>$StaleDays d)     : $(@($report | Where-Object Stale).Count)"
Write-Host ""
Write-Host "OS version spread:"
$report | Group-Object OSVersion | Sort-Object Count -Descending | Format-Table Count, Name -AutoSize
Write-Host "Saved: $file"

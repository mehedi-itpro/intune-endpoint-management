<#
    Detection script for a Win32 app. Intune treats the app as installed only if this
    script writes something to STDOUT and exits 0.
    Detect by file version where possible, so an upgrade of the app is picked up too.
#>
$Path           = Join-Path $env:ProgramFiles 'ExampleApp\example.exe'
$MinimumVersion = [version]'1.0.0.0'

if (Test-Path $Path) {
    $v = [version](Get-Item $Path).VersionInfo.FileVersion
    if ($v -ge $MinimumVersion) {
        Write-Output "Detected version $v"
        exit 0
    }
}
exit 1

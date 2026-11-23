<#
    Win32 app install wrapper. Intune runs this in SYSTEM context.
    Copy the _template folder, rename it to the app name, drop the installer next to
    these scripts and edit the three variables below.
#>
$InstallerFile = 'app-installer.msi'                 # file name inside the package
$InstallerArgs = '/qn /norestart'                    # silent switches for this installer
$LogFile       = Join-Path $env:ProgramData 'IntuneApps\_template-install.log'

$null = New-Item -ItemType Directory -Force -Path (Split-Path $LogFile)
$installer = Join-Path $PSScriptRoot $InstallerFile
if (-not (Test-Path $installer)) { Write-Error "Installer not found: $installer"; exit 1 }

if ($installer -like '*.msi') {
    $msiArgs = "/i `"$installer`" $InstallerArgs /l*v `"$LogFile`""
    $p = Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArgs -Wait -PassThru
} else {
    $p = Start-Process -FilePath $installer -ArgumentList $InstallerArgs -Wait -PassThru
}

# 0 = success, 3010 = success but reboot required (let Intune handle the restart behaviour)
if ($p.ExitCode -in 0, 3010) { exit $p.ExitCode }
Write-Error "Installer exited with code $($p.ExitCode)"
exit $p.ExitCode

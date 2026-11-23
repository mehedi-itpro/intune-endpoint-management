<#
    Win32 app uninstall wrapper. For MSI apps use the product code of the installed version.
#>
$ProductCode = '{00000000-0000-0000-0000-000000000000}'   # replace with the real MSI product code

$p = Start-Process -FilePath 'msiexec.exe' -ArgumentList "/x $ProductCode /qn /norestart" -Wait -PassThru
if ($p.ExitCode -in 0, 3010, 1605) { exit 0 }   # 1605 = not installed, treat as success
exit $p.ExitCode

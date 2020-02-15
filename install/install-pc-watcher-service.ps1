. "$PSScriptRoot/../config/pc-watcher-config.ps1"

$nssm = "$PSScriptRoot/nssm-2.24/win64/nssm.exe"
$serviceName = 'pc-watcher'
$scriptPath = "$PSScriptRoot/../pc-watcher.ps1"


$arguments = '-ExecutionPolicy Bypass -NoProfile -File "{0}"' -f $scriptPath
& $nssm install $serviceName $powershell $arguments
& $nssm set $serviceName Start SERVICE_AUTO_START
& $nssm set $serviceName AppRotateFiles 1
& $nssm set $serviceName AppRotateBytes 1000000
& $nssm set $serviceName AppStdOut "$log_dir/pc-watcher-service.log"
& $nssm set $serviceName AppStdErr "$log_dir/pc-watcher-service.log"
& $nssm status $serviceName
Start-Service $serviceName
Get-Service $serviceName



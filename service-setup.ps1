$nssm = (Get-Command nssm).Source
$serviceName = 'pc-watcher'
$powershell = (Get-Command powershell).Source
$scriptPath = 'C:\Users\admin\Documents\GitHub\pc-watcher\pc-watcher.ps1'
$arguments = '-ExecutionPolicy Bypass -NoProfile -File "{0}"' -f $scriptPath
& $nssm install $serviceName $powershell $arguments
& $nssm status $serviceName


Start-Service $serviceName
Get-Service $serviceName

nssm edit $serviceName
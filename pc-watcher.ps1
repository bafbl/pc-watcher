# This script is a background task (run as a scheduled task that watches
# different aspects of the kids' computers:
#  Make sure TimesUpKidz is running
#  Make sure time has not been adjusted backwards
#  Take screenshots of certain users (that are only supposed to be used for school, robotics, etc)
#
# Installation
#   https://github.com/imseandavis/PSTerminalServices (MSI is included here)
#   Copy PSTerminalServices module to Documents/Powershell/Modules
#   Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser


Import-Module PSTerminalServices

$prev_epoch=Get-Date -UFormat %s
$save_dir="$PSScriptRoot/save"

. $PSScriptRoot/config/pc-watcher-config.ps1
. $PSScriptRoot/utils.ps1

$epoch_file="$save_dir/pc-watcher-epoch.txt"
$screenshot_dir="$save_dir/pc-watcher-screenshots"

New-Item -ItemType Directory -Force -Path $save_dir
New-Item -ItemType Directory -Force -Path $save_dir\logs
New-Item -ItemType Directory -Force -Path $screenshot_dir

$started_day=Get-Date -UFormat %Y%m%d

LogFile "$save_dir\logs\pc-watcher-log-$started_day.txt"

    
while ($true) {
  Start-Sleep (Get-Random -Minimum 5 -Maximum 30)

  $force_logout_reason=''

  $cur_date=Get-Date

  $cur_epoch=Get-Date -UFormat %s
  $diff_time=$cur_epoch - $prev_epoch
  $prev_epoch = $cur_epoch

  if ($diff_time -lt 0) {
    $time_status="Clock went backwards"
    $force_logout_reason=$time_status
  } else {
    $time_status="ok"
  }


  $timesupkidz_status=(Get-Service -Include TimesUpKidz).Status

  if ( $timesupkidz_status -ne 'Running' ) {
    $force_logout_reason="TimesUpKidz is not running"
  }

  #$my_hash=(Get-FileHash -Path $MyInvocation.MyCommand.Definition).Hash.substring(0,10)
  $my_hash="unk"

  Log "message=system_status tuk=$timesupkidz_status clock=$time_status myhash=$my_hash"

  Get-TSSession -State Active | ForEach-Object {
    $user=$_.UserName; 
    $session= $_.SessionId; 
    $station = $_.WindowStationName

    Log "message=session_details user_name=$user session_id=$session windows_station=$station"
    if ('' -eq $user) {
      continue;
    }

    if ($station -ne 'Console') {
      #Is users allowed to be logged in remotely
      if ( $allowed_remote_users.Contains('/' + $user + '/') ) {
        Log "message=remote_user_okay User is allowed to be logged in remotely: $user"
      } else {
        $force_logout_reason="User is not allowed to be logged in remotely"
      }
    }
              
    Log "message=summary active_user=$user tuk=$timesupkidz_status clock=$time_status force_logout_reason=$force_logout_reason"


    if ($force_logout_reason -ne '') {
      if ( $always_allow_users.Contains('/' + $user + '/') ) {
        Log "message=ignoring_problem Not forcing logout because $user is always allowed access"
        continue
      }

      Log "message=killing_processes cause=$force_logout_reason."
      Get-Process | Select -Property ID, SessionID | Where-Object { $_.SessionID -eq $session } | ForEach-Object { Stop-Process -ID $_.ID -Force -ErrorAction SilentlyContinue }
      Start-Sleep -Seconds 2
    }
  }
}
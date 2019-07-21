# This script is a background task (run as a scheduled task that watches
# different aspects of the kids' computers:
#  Make sure TimesUpKidz is running
#  Make sure time has not been adjusted backwards
#  Take screenshots of certain users (that are only supposed to be used for school, robotics, etc)
#
# Installation
#   https://github.com/imseandavis/PSTerminalServices (MSI is included here)
#

Import-Module PSTerminalServices

$prev_epoch=Get-Date -UFormat %s
$save_dir="$PSScriptRoot/save"

. $PSScriptRoot/config/pc-watcher-config.ps1
. $PSScriptRoot/utils.ps1

$epoch_file="$PSScriptRoot/save/pc-watcher-epoch.txt"
$screenshot_dir="$PSScriptRoot/save/pc-watcher-screenshots"

New-Item -ItemType Directory -Force -Path $save_dir
New-Item -ItemType Directory -Force -Path $save_dir\logs
New-Item -ItemType Directory -Force -Path $screenshot_dir

$started_day=Get-Date -UFormat %Y%m%d

LogFile "$save_dir\logs\pc-watcher-log-$started_day.txt"

    
while ($true) {
  Start-Sleep -Seconds 5
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

  Log Get-TSSession

  Get-TSSession -State Active | ForEach-Object {
    $user=$_.UserName; 
    $session= $_.SessionId; 
    $station = $_.WindowStationName

    Log "$user ($session) $station"
    if ('' -eq $user) {
      continue;
    }

    if ($station -ne 'Console') {
      #Is users allowed to be logged in remotely
      if ( $allowed_remote_users.Contains('/' + $user + '/') ) {
        Log "User is allowed to be logged in remotely: $user"
      } else {
        $force_logout_reason="User is not allowed to be logged in remotely"
      }
    }
              
    Log "$user tuk=$timesupkidz_status clock=$time_status force_logout_reason=$force_logout_reason"


    if ($force_logout_reason -ne '') {
      if ( $always_allow_users.Contains('/' + $user + '/') ) {
        Log "Not forcing logout because $user is always allowed access"
        continue
      }

      Log "Killing processes because: $force_logout_reason."
      Get-Process | Select -Property ID, SessionID | Where-Object { $_.SessionID -eq $session } | ForEach-Object { Stop-Process -ID $_.ID -Force -ErrorAction SilentlyContinue }
      Start-Sleep -Seconds 2
    }
  }
}
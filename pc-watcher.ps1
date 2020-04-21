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
#
# Note:
#   As screenshots get uploaded to aws, this will make it helpful to turn them into mpegs
#   cat *.jpg | ffmpeg -f image2pipe -r 10 -vcodec mjpeg -i - -vcodec libx264 out.mp4



$prev_epoch=Get-Date -UFormat %s
$save_dir="$PSScriptRoot/save"

. $PSScriptRoot/config/pc-watcher-config.ps1
. $PSScriptRoot/utils.ps1
. $PSScriptRoot/screenshot.ps1
. $PSScriptRoot/Write-Banner.ps1

Write-Banner Starting
Import-Module -Name c:\users\admin\Documents\WindowsPowerShell\modules\PSTerminalServices -Verbose

$epoch_file="$save_dir/pc-watcher-epoch.txt"
$lockout_file="$log_dir/lockout.txt"

New-Item -ItemType Directory -Force -Path $save_dir | Out-Null
New-Item -ItemType Directory -Force -Path $log_dir | Out-Null
New-Item -ItemType Directory -Force -Path $screenshot_dir | Out-Null

$started_day=Get-Date -UFormat %Y%m%d


    
while ($true) {
  Start-Sleep (Get-Random -Minimum 5 -Maximum 10)
  $CurrentDate = Get-Date

  $force_logout_reason=''

  $cur_date=Get-Date
  
  # Used to highlight problems in log. This is set to ALERT when an entry is unusual.
  $alert = ""

  $cur_epoch=Get-Date -UFormat %s
  $diff_time=$cur_epoch - $prev_epoch
  $prev_epoch = $cur_epoch

  if (Test-Path "$lockout_file")
  {
    Logit "Lockout file exists"
    $alert="ALERT"
    $force_logout_reason="|lockout file exists|$force_logout_reason"
  }

  if ($diff_time -lt 0) {
    $alert="ALERT"
    Logit "$cur_date ($cur_epoch) Clock went backwards: epoch was $prev_epoch- $diff_time"
    $time_status="Clock went backwards"
    $force_logout_reason="|$time_status|$force_logout_reason"
  } else {
    $time_status="ok"
  }

  # Remove small screenshots because they're blank
  # keep them for 10 minutes so we see when things are working
  $DateToDeleteBlankScreenshots = $currentDate.AddMinutes(-10)
  Get-ChildItem "$screenshot_dir" -Filter *.jpg -recurse -file | ? {$_.length -lt 90000} | Where-Object { $_.LastWriteTime -lt $DatetoDeleteBlankScreenshots } | % {Remove-Item $_.fullname}
  
  # Remove old screenshots
  $DatetoDelete = $CurrentDate.AddDays(-14)
  Get-ChildItem -recurse "$screenshot_dir" | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item -Force -Recurse

  $timesupkidz_status=(Get-Service -Include TimesUpKidz).Status

  if ( $timesupkidz_status -ne 'Running' ) {
    $alert="ALERT"
    $force_logout_reason="|TimesUpKidz is not running|$force_logout_reason"
  }

  #$my_hash=(Get-FileHash -Path $MyInvocation.MyCommand.Definition).Hash.substring(0,10)
  $my_hash="unk"

  Logit "msg=system_status tuk=$timesupkidz_status clock=$time_status myhash=$my_hash"

  # Check to see if any processes are being run by illegal users
  if ('' -ne "$disallowed_process_owners") {
    $bad_procs=(Get-Process -IncludeUserName | Where UserName -match "$disallowed_process_owners")
    if ('' -ne "$bad_procs") {
	  $alert="ALERT"
	  Logit "Processes running as $disallowed_process_owners - $bad_procs"

	  $force_logout_reason="|Process(es) owned by $disallowed_process_owners|$force_logout_reason"
	}
  }

  if ('' -ne "$limited_admin_user") {
    $bad=(Get-Process -Name TimesUpKidz -IncludeUserName -ErrorAction Ignore | Where UserName -match "$limited_admin_user")
    if ('' -ne "$bad") {
	  $alert="ALERT"
	  Logit "TimesUpKidz running as $limited_admin_user"

	  $force_logout_reason="|TimesUpKidz running as $limited_admin_user|$force_logout_reason"
	}
  }
  
  Get-TSSession -State Active | ForEach-Object {
    $user=$_.UserName; 
    $session= $_.SessionId; 
    $station = $_.WindowStationName
    $session_current_time = $_.CurrentTime
    $session_login_time = $_.LoginTime

    $time_since_login_minutes = [Math]::Round(($session_current_time - $session_login_time).TotalMinutes,1)

	if ( $user -eq "unlock" ) {
	  Logit "Unlocking pc-watcher because unlock has logged in"
	  $force_logout_reason="(one time)Done unlocking computer|$force_logout_reason"
	  if ( (Test-Path "$lockout_file") ) {
	    $now_epoch=(Get-Date -UFormat %s)
	    Rename-Item "$lockout_file" "$lockout_file.old.$now_epoch.txt"
	  }
	}
    Logit "msg=session_details user_name=$user session_id=$session windows_station=$station time_since_login=$time_since_login_minutes mins"
    if ('' -eq $user) {
      continue;
    }

    $sm_status="na"
    if ( $screenshot_users.Contains('/'+$user+'/') ) {
      if ( $time_since_login_minutes -ge 2 ) {
          #Check that screenmaster is running
          $sm=(Get-Process -Name ScreenMaster -IncludeUserName | Where UserName -match "$user")
          if ('' -eq "$sm") {
		      $sm_status="not-running"
              $alert="ALERT"
        	  $force_logout_reason="|ScreenMaster is not running as $user (even after $time_since_login_minutes minutes since login)|$force_logout_reason"    
          } else {
		      $sm_status="running"
		  }
       } else {
	     $sm_status="unk-new-session"
         Logit "Ignoring potential screenmaster problems in first minute of log in"
       }
    }
    if ($station -ne 'Console') {
      Logit "msg=remote_user_warning $user/$session@$station"
    }
    Logit "msg=summary active_user=$user tuk=$timesupkidz_status clock=$time_status sm_status=$sm_status force_logout_reason=$force_logout_reason"



    if ($force_logout_reason -ne '') {
      if ( $always_allow_users.Contains('/' + $user + '/') ) {
        Logit "msg=ignoring_problem Not forcing logout because $user is always allowed access"
        continue
      }

      $alert="ALERT"
	  # Create lockout file if this is not a one-time problem
	  if ( -not $force_logout_reason.Contains("(one time)") -and -not (Test-Path "$lockout_file") )
	  {  
  	    Logit "Writing force-logout reason to: $lockout_file"
	     New-Item "$lockout_file"
		 Set-Content "$lockout_file" "$cur_date - $force_logout_reason"
	  }
      Logit "msg=killing_processes cause=$force_logout_reason."
      Get-Process | Select -Property ID, SessionID | Where-Object { $_.SessionID -eq $session } | ForEach-Object { Stop-Process -ID $_.ID -Force -ErrorAction SilentlyContinue }
      Start-Sleep -Seconds 2
    }
  }
}
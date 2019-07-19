$prev_epoch=Get-Date -UFormat %s
$epoch_file="c:/users/admin/pc-watcher-epoch.txt"
$screenshot_dir="c:/users/admin/pc-watcher-screenshots"
$always_allow_users="/admin/"
$screenshot_users="max-school max-admin"
    
while ($true) {
  Start-Sleep -Seconds 5
  $force_logout_reason=''

  $cur_date=Get-Date

  $cur_epoch=Get-Date -UFormat %s
  $diff_time=$cur_epoch - $prev_epoch
  $prev_epoch = $cur_epoch

  (quser console) -replace "^>",''  |Select-Object -Skip 1 | ForEach-Object {
				$CurrentLine = $_.Trim() -Replace '\s+', ' ' -Split '\s'
				$console_user = $CurrentLine[0]
				$console_session = $CurrentLine[2]
				$console_status = $CurrentLine[3..$CurrentLine.Length]
     }
 
  if ( $cur_user -eq '' ) {
    "$cur_date - no user logged in"
    continue
  }

  $console_logonui=Get-Process logonui -ErrorAction Stop | Where-Object {$_.SessionID -eq $console_session}

  if ($console_logonui.Count -gt 0 ) {
    "$cur_date - console is locked"
    continue
  }

  if ($diff -lt 0) {
    $time_status="Clock went backwards"
    $force_logout_reason=$time_status
  } else {
    $time_status="ok"
  }



  $timesupkidz_status=(Get-Service -Include TimesUpKidz).Status

  if ( $timesupkidz_status -ne 'Running' ) {
    $force_logout_reason="TimesUpKidz is not running"
  }


  "$cur_date - $console_user tuk=$timesupkidz_status clock=$time_status force_logout_reason=$force_logout_reason"


  if ($force_logout_reason -ne '') {
    if ( $always_allow_users.Contains('/' + $console_user + '/') ) {
      "$cur_date - Not forcing logout because $console_user is always allowed access"
      continue
    }

    "$cur_date - Killing processes because: $force_logout_reason."
    #Get-Process | Select -Property ID, SessionID | Where-Object { $_.SessionID -eq $console_sessions } | ForEach-Object { Stop-Process -ID $_.ID -Force -ErrorAction SilentlyContinue }
    #Start-Sleep -Seconds 2
    #logoff
  } 
}
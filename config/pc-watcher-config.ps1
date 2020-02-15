#defaults
$save_dir="c:\users\admin\pc-watcher-data"
$log_dir="" # this will be made $save_dir/logs if it is not overridden within this file

# Usernames need to match $ENV:USERNAME
$always_allow_users="/admin/bert/"
$limited_admin_user="" #Needs to be set per computer below

#not presently used
$screenshot_users="/admin/rowan-school/max-school/e-sch/e-school/max-work/a-work"
$screenshot_dir="" #this will be relative to $save_dir if it not overridden in this file


#not presently used
$allowed_remote_users="$always_allow_users"
$disallowed_process_owners=""

switch ($ENV:COMPUTERNAME) {
  "MAXDESKTOP" {
    $save_dir="c:\users\admin\pc-watcher-data"

    $screenshot_users="/max-school/"
    break
    }
  "BASEMENT2019" {
    break
    }

  "MAXLAPTOP" {
    break
  }
  "DESKTOP-BMNE4KM" {
    #Max Thinkpad
    $save_dir="c:\pc-watcher-data"
    $limited_admin_user="max-admin"
    break
  }
  "ERIKLAPTOP" {
	$disallowed_process_owners="e-admin-local"
  }
}

if ( "$log_dir".Length -eq 0 ) {
  $log_dir="$save_dir/logs"
}

if ( "$screenshot_dir".Length -eq 0 ) {
  $screenshot_dir="$save_dir/screen-captures"
}

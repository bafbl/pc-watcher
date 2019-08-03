#defaults
$save_dir="c:\users\admin\pc-watcher-data"

$always_allow_users="/admin/bert/"
$screenshot_users="/rowan-school/"
$allowed_remote_users="$always_allow_users"

switch ($ENV:COMPUTERNAME) {
  "MAXDESKTOP" {
    $save_dir="c:\users\admin\pc-watcher-data"

    $always_allow_users="/admin/bert/"
    $screenshot_users="/rowan-school/"
    $allowed_remote_users="$always_allow_users"
    break
    }
  "BASEMENT2019" {
    break
    }

  "MAXLAPTOP" {
    break
  }
}
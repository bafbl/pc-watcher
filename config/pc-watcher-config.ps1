#defaults
$save_dir="c:\users\admin\pc-watcher-data"

# Usernames need to match $ENV:USERNAME
$always_allow_users="/admin/bert/"
$screenshot_users="/admmin/rowan-school/max-school/e-sch/e-school/"
$allowed_remote_users="$always_allow_users"

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
  "ERIKLAPTOP" {
    $screenshot_users="" #"/admin/e-sch/"
  }
}
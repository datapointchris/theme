#!/usr/bin/env bash
# Reads and writes Vivaldi's own profile.
#
# Vivaldi keeps its themes in each profile's Preferences and holds that file in
# memory while it runs, writing all of it back on exit. A write made while it is
# open is overwritten, so a theme is installed only while Vivaldi is closed. An
# apply that finds it open stages the theme as pending and leaves a waiter,
# which installs the pending theme once that Vivaldi exits.
#
# The waiter sources only this file, so nothing here reads lib.sh.

VIVALDI_STATE_DIR="$HOME/.cache/theme/vivaldi"
VIVALDI_PENDING_THEME="$VIVALDI_STATE_DIR/pending-theme.json"
VIVALDI_WAITER_PID_FILE="$VIVALDI_STATE_DIR/waiter.pid"

vivaldi_user_data_dir() {
  case "$(uname -s)" in
    Darwin) echo "$HOME/Library/Application Support/Vivaldi" ;;
    *) echo "${XDG_CONFIG_HOME:-$HOME/.config}/vivaldi" ;;
  esac
}

# A lock or pid file outlives the process that wrote it, and kill -0 answers for
# whatever process holds the number now, so a pid is trusted only while it still
# runs the expected program.
vivaldi_pid_is_vivaldi() {
  local pid="$1" comm
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  comm=$(ps -p "$pid" -o comm= 2>/dev/null) || return 1
  comm="${comm##*/}"
  [[ "$comm" == vivaldi-bin || "$comm" == Vivaldi ]]
}

# The pid of the Vivaldi holding this user-data dir, read from Chromium's own
# SingletonLock symlink, whose target is `<host>-<pid>`. The host is not
# compared, because macOS renames the host with the network while the lock
# keeps the name from launch.
vivaldi_running_pid() {
  local target pid
  target=$(readlink "$1/SingletonLock" 2>/dev/null) || return 1
  pid="${target##*-}"
  vivaldi_pid_is_vivaldi "$pid" || return 1
  echo "$pid"
}

# Each profile directory with its display name, tab-separated, from Local
# State, which is Vivaldi's own record of its profiles.
vivaldi_profiles() {
  jq -r '.profile.info_cache // {} | to_entries[] | [.key, (.value.name // .key)] | @tsv' "$1/Local State"
}

# Upsert one theme object into every profile's Preferences and select it.
#
# Both OS-schedule slots are pointed at it as well as `current`, because
# Vivaldi's default schedule follows the OS light/dark setting and reads those
# slots instead of `current`. Every other user theme stays installed. A profile
# that fails leaves the rest to be installed, and the call returns 1.
vivaldi_install_theme() {
  local dir="$1"
  local theme_json="$2"

  [[ -f "$dir/Local State" && -f "$theme_json" ]] || return 1

  local profiles
  profiles=$(vivaldi_profiles "$dir") || return 1

  local profile name prefs staged failed=0
  while IFS=$'\t' read -r profile name; do
    [[ -n "$profile" ]] || continue
    prefs="$dir/$profile/Preferences"
    [[ -f "$prefs" ]] || continue

    # Staged beside the file so the mv is a rename; mktemp's 0600 matches
    # Chromium's own mode for it.
    if ! staged=$(mktemp "$prefs.theme.XXXXXX"); then
      failed=1
      continue
    fi
    if jq -c --slurpfile theme "$theme_json" '
      $theme[0] as $t
      | .vivaldi.themes.user = ([(.vivaldi.themes.user // [])[] | select(.id != $t.id)] + [$t])
      | .vivaldi.themes.current = $t.id
      | .vivaldi.theme.schedule.o_s = ((.vivaldi.theme.schedule.o_s // {}) + {light: $t.id, dark: $t.id})
    ' "$prefs" >"$staged" && mv "$staged" "$prefs"; then
      continue
    fi
    rm -f "$staged"
    failed=1
  done <<<"$profiles"

  return "$failed"
}

# What each profile shows, one `<profile name>: <theme>` line apiece. The
# schedule decides which pref that is: `off` reads `current`, the default
# `system` reads the OS light and dark slots, and `timeline` reads a list of
# times this tool never writes. Absent prefs take Vivaldi's own defaults.
vivaldi_selected_themes() {
  local dir="$1" profile name
  while IFS=$'\t' read -r profile name; do
    [[ -n "$profile" ]] || continue
    jq -r --arg profile "$name" '
      ((.vivaldi.themes.user // []) | map({key: .id, value: .name}) | from_entries) as $names
      | (.vivaldi.theme.schedule // {}) as $s
      | ($s.o_s // {}) as $o
      | ($o.light // "Vivaldi1") as $light
      | ($o.dark // "Vivaldi2") as $dark
      | ($s.enabled // "system") as $mode
      | if $mode == "off" or $mode == 0 then ($names[.vivaldi.themes.current // "Vivaldi1"] // (.vivaldi.themes.current // "Vivaldi1"))
        elif $mode == "timeline" or $mode == 2 then "a timeline schedule"
        elif $light == $dark then ($names[$light] // $light)
        else "\($names[$light] // $light) when light, \($names[$dark] // $dark) when dark"
        end
      | "\($profile): \(.)"
    ' "$dir/$profile/Preferences" 2>/dev/null || echo "$name: unreadable"
  done < <(vivaldi_profiles "$dir")
}

# The waiter is trusted only while its pid still runs the waiter.
vivaldi_waiter_running() {
  local pid args
  pid=$(cat "$VIVALDI_WAITER_PID_FILE" 2>/dev/null) || return 1
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  args=$(ps -p "$pid" -o args= 2>/dev/null) || return 1
  [[ "$args" == *vivaldi-install-after-exit* ]]
}

# Stage a theme for the waiter. A later apply overwrites it, so the theme that
# lands is the last one applied while Vivaldi was open.
vivaldi_stage_theme() {
  mkdir -p "$VIVALDI_STATE_DIR" || return 1
  cp "$1" "$VIVALDI_PENDING_THEME.tmp" && mv "$VIVALDI_PENDING_THEME.tmp" "$VIVALDI_PENDING_THEME"
}

# The name of a staged theme no waiter will install. That is what a waiter
# leaves when its install failed, or when Vivaldi outlasted it at logout.
vivaldi_stranded_theme() {
  [[ -f "$VIVALDI_PENDING_THEME" ]] || return 1
  vivaldi_waiter_running && return 1
  jq -r '.name // .id' "$VIVALDI_PENDING_THEME" 2>/dev/null || echo "a theme"
}

# The waiter's body. It waits for the whole process to exit rather than for the
# lock to go, since Chromium may drop the lock before its last Preferences write.
# A Vivaldi relaunched within the poll interval already read the old file, so
# the wait moves on to that instance. A theme staged during the install is
# installed on the next pass.
#
# A logout or reboot sends SIGTERM to Vivaldi and to this at once. Vivaldi takes
# a moment to write and exit, so the TERM is answered with a bounded wait rather
# than by dying first. A failure leaves the theme staged, which the next apply
# reports.
vivaldi_install_after_exit() {
  local dir="$1"
  local claimed="$VIVALDI_STATE_DIR/installing-theme.json"

  mkdir -p "$VIVALDI_STATE_DIR"
  echo "$$" >"$VIVALDI_WAITER_PID_FILE"
  trap 'rm -f "$VIVALDI_WAITER_PID_FILE"' EXIT

  local deadline=""
  trap 'deadline=$((SECONDS + 15))' TERM HUP

  local pid
  while [[ -f "$VIVALDI_PENDING_THEME" ]]; do
    while pid=$(vivaldi_running_pid "$dir"); do
      while vivaldi_pid_is_vivaldi "$pid"; do
        if [[ -n "$deadline" ]] && ((SECONDS >= deadline)); then
          echo "Vivaldi outlasted the session; the staged theme stays pending" >&2
          return 1
        fi
        sleep 1
      done
    done

    mv "$VIVALDI_PENDING_THEME" "$claimed" || return 1
    if ! vivaldi_install_theme "$dir" "$claimed"; then
      [[ -f "$VIVALDI_PENDING_THEME" ]] || mv "$claimed" "$VIVALDI_PENDING_THEME"
      echo "Could not install the staged theme into $dir" >&2
      return 1
    fi
    rm -f "$claimed"
  done
}

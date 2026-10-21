#!/usr/bin/env bash
# Installs a generated Vivaldi theme into Vivaldi's own profile.
#
# Vivaldi keeps its themes in each profile's Preferences and holds that file in
# memory while it runs, writing all of it back on exit. A write made while it is
# open is therefore overwritten, so a theme is installed only while Vivaldi is
# closed. An apply that finds it open leaves a waiter behind, which installs
# whatever theme is current once that Vivaldi exits.

VIVALDI_WAITER_PID_FILE="$HOME/.cache/theme/vivaldi-waiter.pid"

vivaldi_user_data_dir() {
  case "$(uname -s)" in
    Darwin) echo "$HOME/Library/Application Support/Vivaldi" ;;
    *) echo "${XDG_CONFIG_HOME:-$HOME/.config}/vivaldi" ;;
  esac
}

# The pid of the Vivaldi holding this user-data dir, read from Chromium's own
# SingletonLock symlink, whose target is `<host>-<pid>`. A crash leaves the link
# naming a dead pid, which counts as not running.
vivaldi_running_pid() {
  local dir="$1"
  local target
  target=$(readlink "$dir/SingletonLock" 2>/dev/null) || return 1

  local host="${target%-*}" pid="${target##*-}"
  [[ "$host" == "$(uname -n)" ]] || return 1
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  echo "$pid"
}

# Upsert one theme object into every profile's Preferences and select it.
#
# Both OS-schedule slots are pointed at it as well as `current`, because
# Vivaldi's default schedule follows the OS light/dark setting and reads those
# slots instead of `current`. Every other user theme stays installed.
vivaldi_install_theme() {
  local dir="$1"
  local theme_json="$2"

  [[ -f "$dir/Local State" && -f "$theme_json" ]] || return 1

  local profiles
  profiles=$(jq -r '.profile.info_cache // {} | keys[]' "$dir/Local State") || return 1

  local profile prefs staged
  while IFS= read -r profile; do
    [[ -n "$profile" ]] || continue
    prefs="$dir/$profile/Preferences"
    [[ -f "$prefs" ]] || continue

    # Staged beside the file so the mv is a rename; mktemp's 0600 matches
    # Chromium's own mode for it.
    staged=$(mktemp "$prefs.theme.XXXXXX") || return 1
    if ! jq -c --slurpfile theme "$theme_json" '
      $theme[0] as $t
      | .vivaldi.themes.user = ([(.vivaldi.themes.user // [])[] | select(.id != $t.id)] + [$t])
      | .vivaldi.themes.current = $t.id
      | .vivaldi.theme.schedule.o_s = ((.vivaldi.theme.schedule.o_s // {}) + {light: $t.id, dark: $t.id})
    ' "$prefs" >"$staged"; then
      rm -f "$staged"
      return 1
    fi
    mv "$staged" "$prefs" || return 1
  done <<<"$profiles"
}

# Whether an earlier apply already left a waiter, which will install whatever
# theme is current when it fires, so one is enough.
vivaldi_waiter_running() {
  local pid
  pid=$(cat "$VIVALDI_WAITER_PID_FILE" 2>/dev/null) || return 1
  [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null
}

# Detach a waiter from this apply. A scheduled apply runs as a oneshot whose
# cgroup systemd kills on exit, so on Linux the waiter is its own transient
# service. On macOS the launchd agent sets AbandonProcessGroup, so nohup is
# enough there.
vivaldi_start_waiter() {
  local dir="$1"
  local waiter="$THEME_LIB_DIR/vivaldi-install-after-exit.sh"

  if [[ "$(uname -s)" != "Darwin" ]] && systemctl --user show-environment &>/dev/null; then
    systemd-run --user --collect --quiet -E HOME -E PATH -- "$waiter" "$dir" >/dev/null 2>&1 </dev/null
  else
    nohup "$waiter" "$dir" >/dev/null 2>&1 </dev/null &
    disown
  fi
}

# The waiter's body. It waits for the whole process to exit rather than for the
# lock to go, since Chromium may drop the lock before its last Preferences write.
# A Vivaldi relaunched within the poll interval already read the old file, so
# the wait moves on to that instance.
#
# A logout or reboot sends SIGTERM to Vivaldi and to this at once. Vivaldi takes
# a moment to write and exit, so the TERM is answered with a bounded wait rather
# than by dying first.
vivaldi_install_after_exit() {
  local dir="$1"

  mkdir -p "$(dirname "$VIVALDI_WAITER_PID_FILE")"
  echo "$$" >"$VIVALDI_WAITER_PID_FILE"
  trap 'rm -f "$VIVALDI_WAITER_PID_FILE"' EXIT

  local deadline=""
  trap 'deadline=$((SECONDS + 15))' TERM HUP

  local pid
  while pid=$(vivaldi_running_pid "$dir"); do
    while kill -0 "$pid" 2>/dev/null; do
      if [[ -n "$deadline" ]] && ((SECONDS >= deadline)); then
        return 1
      fi
      sleep 1
    done
  done

  local theme
  theme=$(cat "$CURRENT_THEME_FILE" 2>/dev/null) || return 1
  vivaldi_install_theme "$dir" "$THEMES_DIR/$theme/vivaldi.json"
}

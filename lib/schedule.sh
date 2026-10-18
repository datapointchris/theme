#!/usr/bin/env bash
# A timer that changes the theme while the user is present, one schedule per machine.

set -euo pipefail

[[ -n "${_THEME_SCHEDULE_SOURCED:-}" ]] && return 0
_THEME_SCHEDULE_SOURCED=1

THEME_SCHEDULE_TURN_HOURS=6
THEME_SCHEDULE_HOLD_HOURS=12
THEME_SCHEDULE_CHECK_MINUTES=5
# macOS reads input idleness itself. The hypridle listener in the help uses the same figure.
THEME_SCHEDULE_IDLE_SECONDS=600

THEME_SCHEDULE_UNIT="theme-schedule"
THEME_SCHEDULE_LABEL="com.datapointchris.theme-schedule"
THEME_SCHEDULE_STATE_FILE="$THEME_STATE_DIR/schedule.json"

# The service manager that runs the timer, or nothing. WSL has no display session to read.
schedule_supervisor() {
  case "$(detect_platform)" in
    macos) echo "launchd" ;;
    wsl) ;;
    *)
      if command -v systemctl &>/dev/null && command -v loginctl &>/dev/null; then
        echo "systemd"
      fi
      ;;
  esac
}

_schedule_systemd_dir() {
  echo "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
}

_schedule_plist() {
  echo "$HOME/Library/LaunchAgents/$THEME_SCHEDULE_LABEL.plist"
}

# On means the timer's definition is installed.
schedule_is_on() {
  case "$(schedule_supervisor)" in
    systemd) [[ -f "$(_schedule_systemd_dir)/$THEME_SCHEDULE_UNIT.timer" ]] ;;
    launchd) [[ -f "$(_schedule_plist)" ]] ;;
    *) return 1 ;;
  esac
}

# A weekday alone is ambiguous more than six days away, so those get the date.
_schedule_clock() {
  jq -nr --argjson t "$1" '
    if ($t - now) > -518400 and ($t - now) < 518400 then $t | strflocaltime("%a %H:%M")
    else $t | strflocaltime("%Y-%m-%d %H:%M")
    end'
}

# This machine's latest apply as {theme, trigger, at, due}. A row with no trigger was applied by hand.
schedule_last_apply() {
  get_history | jq -c \
    --arg machine "$(_storage_get_machine_id)" \
    --argjson turn "$((THEME_SCHEDULE_TURN_HOURS * 3600))" \
    --argjson hold "$((THEME_SCHEDULE_HOLD_HOURS * 3600))" '
    map(select(.action == "apply" and .machine == $machine)) | last // empty
    | (.trigger // "manual") as $trigger
    | (.ts | sub("[+-][0-9]{2}:[0-9]{2}$"; "Z") | fromdateiso8601) as $at
    | {
        theme,
        trigger: $trigger,
        at: $at,
        due: ($at + (if $trigger == "schedule" then $turn else $hold end))
      }'
}

# Prints why the user counts as away and succeeds, or prints "active" and fails.
schedule_away_reason() {
  if [[ "$(detect_platform)" == "macos" ]]; then
    local idle
    idle=$(ioreg -c IOHIDSystem 2>/dev/null | awk '/HIDIdleTime/ { print int($NF / 1000000000); exit }' || true)
    if [[ "${idle:-0}" -ge "$THEME_SCHEDULE_IDLE_SECONDS" ]]; then
      echo "no input for $(format_duration "$idle")"
      return 0
    fi
  else
    local session hints
    session=$(loginctl show-user "$(id -u)" -p Display --value 2>/dev/null || true)
    if [[ -z "$session" ]]; then
      echo "no display session"
      return 0
    fi
    hints=$(loginctl show-session "$session" -p IdleHint -p LockedHint 2>/dev/null || true)
    if [[ "$hints" == *"LockedHint=yes"* ]]; then
      echo "session $session is locked"
      return 0
    fi
    if [[ "$hints" == *"IdleHint=yes"* ]]; then
      echo "session $session is idle"
      return 0
    fi
  fi

  echo "active"
  return 1
}

# Prints "<verdict>\t<due epoch>\t<reason>" at a moment in epoch seconds.
# The verdict is waiting, away (due but nobody present) or due.
schedule_decide() {
  local now="$1"
  local due
  due=$(schedule_last_apply | jq -r '.due')
  due="${due:-$now}"

  if [[ "$now" -lt "$due" ]]; then
    printf 'waiting\t%s\t\n' "$due"
    return 0
  fi

  local reason
  if reason=$(schedule_away_reason); then
    printf 'away\t%s\t%s\n' "$due" "$reason"
    return 0
  fi

  printf 'due\t%s\t\n' "$due"
}

# Replaced through a rename, so `theme schedule status` never reads half a file.
_schedule_record() {
  local outcome="$1" detail="$2"
  mkdir -p "$THEME_STATE_DIR"
  local partial="$THEME_SCHEDULE_STATE_FILE.$$"
  jq -nc \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg outcome "$outcome" \
    --arg detail "$detail" \
    '{ts: $ts, outcome: $outcome, detail: $detail}' >"$partial"
  mv "$partial" "$THEME_SCHEDULE_STATE_FILE"
}

# The user manager carries only what the session imported. Without these, the restarted bar exits.
_schedule_missing_desktop_env() {
  [[ "$(detect_platform)" == "macos" ]] && return 0
  local missing=()
  [[ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]] || missing+=(WAYLAND_DISPLAY DISPLAY)
  if command -v hyprctl &>/dev/null && pgrep -u "$(id -u)" -x Hyprland &>/dev/null \
    && ! hyprctl version &>/dev/null; then
    missing+=(HYPRLAND_INSTANCE_SIGNATURE)
  fi
  echo "${missing[*]}"
}

# One check, which is what the timer runs.
schedule_run() {
  local verdict due reason
  IFS=$'\t' read -r verdict due reason < <(schedule_decide "$(date +%s)")

  case "$verdict" in
    waiting)
      _schedule_record waiting "next change due $(_schedule_clock "$due")"
      echo "waiting: next change due $(_schedule_clock "$due")"
      return 0
      ;;
    away)
      _schedule_record away "due since $(_schedule_clock "$due"), $reason"
      echo "away: due since $(_schedule_clock "$due"), $reason"
      return 0
      ;;
  esac

  local missing
  missing=$(_schedule_missing_desktop_env)
  if [[ -n "$missing" ]]; then
    local blocked="no usable $missing, so a change could not reach the desktop."
    blocked+=" From a terminal on the desktop, run: systemctl --user import-environment $missing"
    _schedule_record blocked "$blocked"
    echo "blocked: $blocked" >&2
    return 1
  fi

  # The draw weighs every machine's applies.
  sync_pull &>/dev/null || true

  local started status=0
  started=$(date +%s)
  # Backgrounded and waited on: called in a condition, the apply would run with errexit off.
  apply_random schedule &
  wait "$!" || status=$?

  # The history row is what the apply produced, so it decides the outcome.
  local last
  last=$(schedule_last_apply)
  if [[ -n "$last" ]] \
    && [[ "$(jq -r '.trigger' <<<"$last")" == "schedule" ]] \
    && [[ "$(jq -r '.at' <<<"$last")" -ge "$started" ]]; then
    _schedule_record applied "$(jq -r '.theme' <<<"$last")"
    # In the foreground, because the unit ends any process left behind.
    sync_push &>/dev/null || true
    return 0
  fi

  _schedule_record failed "the apply exited $status without writing its history row"
  echo "failed: the apply exited $status without writing its history row" >&2
  return 1
}

# The line `theme apply` prints while the schedule is on.
schedule_next_change_line() {
  local last
  last=$(schedule_last_apply)
  [[ -z "$last" ]] && return 0

  local due hours=$THEME_SCHEDULE_HOLD_HOURS
  due=$(jq -r '.due' <<<"$last")
  [[ "$(jq -r '.trigger' <<<"$last")" == "schedule" ]] && hours=$THEME_SCHEDULE_TURN_HOURS
  echo "Schedule: next change after $(_schedule_clock "$due") (${hours} h, once you are active)"
}

_schedule_write_systemd() {
  local dir
  dir=$(_schedule_systemd_dir)
  mkdir -p "$dir"

  # The enabling shell's PATH, since the user manager's lacks where jq, yq and gh usually live.
  cat >"$dir/$THEME_SCHEDULE_UNIT.service" <<EOF
[Unit]
Description=Change the theme when its scheduled turn is due

[Service]
Type=oneshot
Environment="PATH=$PATH"
ExecStart="$THEME_APP_DIR/bin/theme" schedule run
EOF

  cat >"$dir/$THEME_SCHEDULE_UNIT.timer" <<EOF
[Unit]
Description=Check every $THEME_SCHEDULE_CHECK_MINUTES minutes whether the theme's turn is due

[Timer]
OnCalendar=*:0/$THEME_SCHEDULE_CHECK_MINUTES

[Install]
WantedBy=timers.target
EOF
}

_schedule_write_launchd() {
  local plist
  plist=$(_schedule_plist)
  mkdir -p "$(dirname "$plist")"

  # AbandonProcessGroup stops launchd killing what the apply restarted when the job exits.
  cat >"$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$THEME_SCHEDULE_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$THEME_APP_DIR/bin/theme</string>
    <string>schedule</string>
    <string>run</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>$PATH</string>
  </dict>
  <key>StartInterval</key>
  <integer>$((THEME_SCHEDULE_CHECK_MINUTES * 60))</integer>
  <key>AbandonProcessGroup</key>
  <true/>
  <key>StandardErrorPath</key>
  <string>$THEME_STATE_DIR/schedule.log</string>
</dict>
</plist>
EOF
}

_schedule_unsupported() {
  echo "Error: the schedule needs systemd and logind, or launchd on macOS" >&2
  if [[ "$(detect_platform)" == "wsl" ]]; then
    echo "  WSL has no display session to tell whether you are present." >&2
  fi
  return 1
}

schedule_on() {
  case "$(schedule_supervisor)" in
    systemd)
      _schedule_write_systemd
      systemctl --user daemon-reload
      systemctl --user --quiet enable "$THEME_SCHEDULE_UNIT.timer"
      systemctl --user restart "$THEME_SCHEDULE_UNIT.timer"
      ;;
    launchd)
      _schedule_write_launchd
      launchctl bootout "gui/$(id -u)/$THEME_SCHEDULE_LABEL" 2>/dev/null || true
      launchctl bootstrap "gui/$(id -u)" "$(_schedule_plist)"
      ;;
    *)
      _schedule_unsupported
      return 1
      ;;
  esac

  echo "✓ Schedule on, checking every $THEME_SCHEDULE_CHECK_MINUTES minutes"
  echo "  A scheduled theme gets $THEME_SCHEDULE_TURN_HOURS h and one applied by hand $THEME_SCHEDULE_HOLD_HOURS h."
  echo "  A due change waits until you are active."
  _schedule_warn_idle_hint
}

schedule_off() {
  case "$(schedule_supervisor)" in
    systemd)
      local dir
      dir=$(_schedule_systemd_dir)
      systemctl --user --quiet disable --now "$THEME_SCHEDULE_UNIT.timer" 2>/dev/null || true
      rm -f "$dir/$THEME_SCHEDULE_UNIT.service" "$dir/$THEME_SCHEDULE_UNIT.timer"
      systemctl --user daemon-reload
      ;;
    launchd)
      launchctl bootout "gui/$(id -u)/$THEME_SCHEDULE_LABEL" 2>/dev/null || true
      rm -f "$(_schedule_plist)"
      ;;
    *)
      _schedule_unsupported
      return 1
      ;;
  esac

  echo "✓ Schedule off"
}

# IdleSinceHint 0 means IdleHint has not changed since login, which is how an unset hint looks.
_schedule_warn_idle_hint() {
  [[ "$(schedule_supervisor)" == "systemd" ]] || return 0

  local session since
  session=$(loginctl show-user "$(id -u)" -p Display --value 2>/dev/null || true)
  [[ -n "$session" ]] || return 0
  since=$(loginctl show-session "$session" -p IdleSinceHint --value 2>/dev/null || true)
  if [[ "$since" == "0" ]]; then
    echo "  ! IdleHint has not changed since login, so every check may read you as active."
    echo "    An idle daemon has to set it: see theme schedule --help"
  fi
}

_schedule_timer_state() {
  case "$(schedule_supervisor)" in
    systemd)
      echo "timer $(systemctl --user is-active "$THEME_SCHEDULE_UNIT.timer" 2>/dev/null || true)"
      ;;
    launchd)
      if launchctl print "gui/$(id -u)/$THEME_SCHEDULE_LABEL" &>/dev/null; then
        echo "agent loaded"
      else
        echo "agent not loaded"
      fi
      ;;
  esac
}

schedule_status() {
  echo ""
  echo "Theme Schedule"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if [[ -z "$(schedule_supervisor)" ]]; then
    echo "Status: not supported on $(detect_platform)"
    return 0
  fi

  local on=false
  schedule_is_on && on=true
  if [[ "$on" == true ]]; then
    echo "Status: On ✓ ($(_schedule_timer_state))"
  else
    echo "Status: Off"
  fi

  local last now
  last=$(schedule_last_apply)
  now=$(date +%s)
  if [[ -n "$last" ]]; then
    local theme at due how="by hand"
    theme=$(jq -r '.theme' <<<"$last")
    at=$(jq -r '.at' <<<"$last")
    due=$(jq -r '.due' <<<"$last")
    [[ "$(jq -r '.trigger' <<<"$last")" == "schedule" ]] && how="by the schedule"
    echo "Current: $(get_theme_display_info "$theme"), applied $how $(_schedule_clock "$at")"
    if [[ "$on" == true ]]; then
      if [[ "$now" -lt "$due" ]]; then
        echo "Next change: after $(_schedule_clock "$due"), once you are active"
      else
        echo "Next change: due since $(_schedule_clock "$due"), at the first check while you are active"
      fi
    fi
  fi

  local reason
  if reason=$(schedule_away_reason); then
    echo "Presence: away ($reason)"
  else
    echo "Presence: active"
  fi
  _schedule_warn_idle_hint

  if [[ -f "$THEME_SCHEDULE_STATE_FILE" ]]; then
    local checked outcome detail age
    checked=$(jq -r '.ts | fromdateiso8601' "$THEME_SCHEDULE_STATE_FILE")
    outcome=$(jq -r '.outcome' "$THEME_SCHEDULE_STATE_FILE")
    detail=$(jq -r '.detail' "$THEME_SCHEDULE_STATE_FILE")
    echo "Last check: $(_schedule_clock "$checked"), $outcome: $detail"
    age=$((now - checked))
    if [[ "$on" == true ]] && [[ "$age" -gt $((THEME_SCHEDULE_CHECK_MINUTES * 60 * 3)) ]]; then
      echo "  ! No check for $(format_duration "$age"), so the timer is not running."
    fi
  elif [[ "$on" == true ]]; then
    echo "Last check: none yet"
  fi

  if [[ "$on" == false ]]; then
    echo ""
    echo "Turn it on with: theme schedule on"
  fi
}

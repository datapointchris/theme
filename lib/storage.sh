#!/usr/bin/env bash
# Theme storage layer - unified JSONL history with machine context
# Single history file synced across machines via gist

set -euo pipefail

_STORAGE_APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Dev mode: use THEME_ENV=development (set via direnv in ~/tools/theme/.envrc)
if [[ "${THEME_ENV:-}" == "development" ]]; then
  THEME_STATE_DIR="$_STORAGE_APP_DIR/.dev-data"
else
  THEME_STATE_DIR="$HOME/.local/state/theme"
fi
THEME_HISTORY_FILE="$THEME_STATE_DIR/history.jsonl"

detect_platform() {
  if [[ -n "${PLATFORM:-}" ]]; then
    echo "$PLATFORM"
    return
  fi

  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  elif [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
    echo "wsl"
  elif [[ -f /etc/arch-release ]]; then
    echo "arch"
  elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo "${ID:-linux}"
  else
    echo "unknown"
  fi
}

_storage_get_machine_id() {
  local platform
  platform=$(detect_platform)
  local hostname
  hostname=$(hostname -s 2>/dev/null || echo "unknown")
  echo "${platform}-${hostname}"
}

log_action() {
  local action="$1"
  local theme="${2:-}"
  local message="${3:-}"

  if [[ -z "$action" ]]; then
    echo "Error: action required" >&2
    return 1
  fi

  mkdir -p "$THEME_STATE_DIR"

  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local platform
  platform=$(detect_platform)
  local machine
  machine=$(_storage_get_machine_id)

  local record
  if [[ -n "$message" ]]; then
    record=$(jq -nc \
      --arg ts "$timestamp" \
      --arg platform "$platform" \
      --arg machine "$machine" \
      --arg theme "$theme" \
      --arg act "$action" \
      --arg msg "$message" \
      '{ts: $ts, platform: $platform, machine: $machine, theme: $theme, action: $act, message: $msg}')
  else
    record=$(jq -nc \
      --arg ts "$timestamp" \
      --arg platform "$platform" \
      --arg machine "$machine" \
      --arg theme "$theme" \
      --arg act "$action" \
      '{ts: $ts, platform: $platform, machine: $machine, theme: $theme, action: $act}')
  fi

  echo "$record" >> "$THEME_HISTORY_FILE"
}

get_history() {
  if [[ -f "$THEME_HISTORY_FILE" ]]; then
    jq -s 'sort_by(.ts)' "$THEME_HISTORY_FILE"
  else
    echo "[]"
  fi
}

get_history_raw() {
  if [[ -f "$THEME_HISTORY_FILE" ]]; then
    jq -c '.' "$THEME_HISTORY_FILE" | sort
  fi
}

get_theme_stats() {
  local theme="$1"

  if [[ -z "$theme" ]]; then
    echo "Error: theme name required" >&2
    return 1
  fi

  get_history | jq --arg theme "$theme" '
    map(select(.theme == $theme)) |
    {
      theme: $theme,
      total_actions: length,
      likes: map(select(.action == "like")) | length,
      dislikes: map(select(.action == "dislike")) | length,
      notes: map(select(.action == "note")) | length,
      applies: map(select(.action == "apply")) | length,
      score: (map(select(.action == "like")) | length) - (map(select(.action == "dislike")) | length),
      last_used: map(select(.action == "apply")) | max_by(.ts) | .ts // "never",
      platforms: [.[].platform] | unique,
      machines: [.[].machine // "unknown"] | unique
    }
  '
}

calculate_usage_time() {
  local current_theme="$1"

  get_history | jq -r --arg current "$current_theme" '
    def parse_ts:
      if test("[+-][0-9]{2}:[0-9]{2}$") then
        gsub("[+-][0-9]{2}:[0-9]{2}$"; "Z") | fromdateiso8601
      else
        fromdateiso8601
      end;

    [map(select(.action == "apply")) | sort_by(.ts) | to_entries[]] as $applies |

    ($applies | map(
      . as $entry |
      $entry.key as $idx |
      $entry.value as $apply |

      if ($idx < (($applies | length) - 1)) then
        {
          theme: $apply.theme,
          duration: (($applies[$idx + 1].value.ts | parse_ts) - ($apply.ts | parse_ts))
        }
      elif $apply.theme == $current then
        {
          theme: $apply.theme,
          duration: ((now | floor) - ($apply.ts | parse_ts))
        }
      else
        null
      end
    ) | map(select(. != null))) as $durations |

    ($durations | group_by(.theme) | map({
      key: .[0].theme,
      value: (map(.duration) | add // 0)
    }) | from_entries)
  '
}

get_rankings() {
  local current_theme
  current_theme=$(get_current_theme 2>/dev/null || echo "")

  local usage_times
  usage_times=$(calculate_usage_time "$current_theme")

  get_history | jq -c --argjson usage "$usage_times" '
    group_by(.theme) |
    map({
      theme: .[0].theme,
      likes: map(select(.action == "like")) | length,
      dislikes: map(select(.action == "dislike")) | length,
      score: (map(select(.action == "like")) | length) - (map(select(.action == "dislike")) | length),
      last_used: (map(select(.action == "apply")) | max_by(.ts) | .ts // "never"),
      platforms: [.[].platform] | unique | join(","),
      usage_seconds: ($usage[.[0].theme] // 0),
      sort_key: (if (map(select(.action == "apply")) | length) > 0 then (map(select(.action == "apply")) | max_by(.ts) | .ts) else "0" end)
    }) |
    sort_by(.score, .sort_key) | reverse |
    .[]
  '
}

filter_by_theme() {
  local theme="$1"
  get_history | jq --arg theme "$theme" 'map(select(.theme == $theme))'
}

filter_by_action() {
  local action="$1"
  get_history | jq --arg action "$action" 'map(select(.action == $action))'
}

filter_by_platform() {
  local platform="$1"
  get_history | jq --arg platform "$platform" 'map(select(.platform == $platform))'
}

get_most_liked_themes() {
  local limit="${1:-10}"

  get_history | jq --arg limit "$limit" '
    group_by(.theme) |
    map({
      theme: .[0].theme,
      likes: map(select(.action == "like")) | length
    }) |
    sort_by(-.likes) |
    limit($limit | tonumber; .[])
  '
}

get_recently_used() {
  local limit="${1:-10}"

  get_history | jq --arg limit "$limit" '
    map(select(.action == "apply")) |
    sort_by(-.ts) |
    unique_by(.theme) |
    limit($limit | tonumber; .[])
  '
}

get_theme_notes() {
  local theme="$1"

  get_history | jq --arg theme "$theme" '
    map(select(.theme == $theme and .action == "note")) |
    sort_by(.ts) |
    .[]
  '
}

count_total_actions() {
  get_history | jq 'length'
}

count_themes_tracked() {
  get_history | jq 'group_by(.theme) | length'
}

list_tracked_themes() {
  get_history | jq -r 'group_by(.theme) | .[].theme' | sort -u
}

get_all_apply_counts() {
  get_history | jq -r '
    map(select(.action == "apply")) |
    group_by(.theme) |
    map({theme: .[0].theme, count: length}) |
    .[] |
    "\(.theme)\t\(.count)"
  '
}

validate_history_file() {
  if [[ ! -f "$THEME_HISTORY_FILE" ]]; then
    return 0
  fi

  if ! jq -e '.' "$THEME_HISTORY_FILE" >/dev/null 2>&1; then
    echo "Invalid JSON in: $THEME_HISTORY_FILE" >&2
    return 1
  fi

  return 0
}

reject_theme() {
  local theme="$1"
  local reason="${2:-No reason provided}"

  if [[ -z "$theme" ]]; then
    echo "Error: theme name required" >&2
    return 1
  fi

  log_action "reject" "$theme" "$reason"
}

unreject_theme() {
  local theme="$1"

  if [[ -z "$theme" ]]; then
    echo "Error: theme name required" >&2
    return 1
  fi

  log_action "unreject" "$theme"
}

is_theme_rejected() {
  local theme="$1"

  if [[ ! -f "$THEME_HISTORY_FILE" ]]; then
    return 1
  fi

  local last_action
  last_action=$(jq -s -r --arg theme "$theme" '
    map(select(.theme == $theme and (.action == "reject" or .action == "unreject"))) |
    sort_by(.ts) | last | .action // "none"
  ' "$THEME_HISTORY_FILE")

  [[ "$last_action" == "reject" ]]
}

get_rejected_theme_info() {
  local theme="$1"

  if [[ ! -f "$THEME_HISTORY_FILE" ]]; then
    echo "{}"
    return
  fi

  jq -s --arg theme "$theme" '
    map(select(.theme == $theme and .action == "reject")) |
    sort_by(.ts) | last // {}
  ' "$THEME_HISTORY_FILE"
}

list_rejected_themes() {
  if [[ ! -f "$THEME_HISTORY_FILE" ]]; then
    return
  fi

  jq -s -c '
    group_by(.theme) |
    map(
      . as $actions |
      ($actions | map(select(.action == "reject" or .action == "unreject")) | sort_by(.ts) | last) as $last |
      if $last.action == "reject" then
        {
          theme: .[0].theme,
          rejected_date: $last.ts,
          reason: $last.message,
          platforms: [$actions[].platform] | unique | join(",")
        }
      else
        null
      end
    ) |
    map(select(. != null)) |
    sort_by(.rejected_date) | reverse |
    .[]
  ' "$THEME_HISTORY_FILE"
}

init_storage() {
  if [[ ! -d "$THEME_STATE_DIR" ]]; then
    mkdir -p "$THEME_STATE_DIR"
  fi

  if [[ ! -f "$THEME_HISTORY_FILE" ]]; then
    touch "$THEME_HISTORY_FILE"
  fi
}

init_storage

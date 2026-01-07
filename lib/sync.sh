#!/usr/bin/env bash
# Theme sync layer - transparent GitHub Gist synchronization
# Keeps history synced across machines without user intervention

set -euo pipefail

_SYNC_APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Sync state file (alongside history)
THEME_SYNC_STATE_FILE="${THEME_STATE_DIR:-$HOME/.local/state/theme}/sync-state.json"
THEME_GIST_DESCRIPTION="theme-preferences"

_sync_check_gh() {
  if ! command -v gh &>/dev/null; then
    echo "Error: GitHub CLI (gh) not installed" >&2
    echo "Install with: brew install gh" >&2
    return 1
  fi

  if ! gh auth status &>/dev/null 2>&1; then
    echo "Error: Not authenticated with GitHub" >&2
    echo "Run: gh auth login" >&2
    return 1
  fi

  return 0
}

# Check if sync is enabled (disabled in dev mode)
is_sync_enabled() {
  [[ "${THEME_ENV:-}" == "development" ]] && return 1
  [[ -f "$THEME_SYNC_STATE_FILE" ]] && \
    jq -e '.enabled == true' "$THEME_SYNC_STATE_FILE" &>/dev/null
}

_sync_get_gist_id() {
  if [[ -f "$THEME_SYNC_STATE_FILE" ]]; then
    jq -r '.gist_id // empty' "$THEME_SYNC_STATE_FILE"
  fi
}

_sync_update_state() {
  local gist_id="$1"
  local enabled="${2:-true}"

  mkdir -p "$(dirname "$THEME_SYNC_STATE_FILE")"

  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  jq -n \
    --arg gist_id "$gist_id" \
    --arg last_sync "$timestamp" \
    --argjson enabled "$enabled" \
    '{gist_id: $gist_id, last_sync: $last_sync, enabled: $enabled}' \
    > "$THEME_SYNC_STATE_FILE"
}

_sync_find_gist() {
  gh gist list --limit 100 2>/dev/null | \
    grep -F "$THEME_GIST_DESCRIPTION" | \
    head -1 | \
    awk '{print $1}' || true
}

_sync_create_gist() {
  local history_file="$THEME_HISTORY_FILE"

  if [[ ! -f "$history_file" ]] || [[ ! -s "$history_file" ]]; then
    echo "{}" > /tmp/theme-history-init.jsonl
    history_file="/tmp/theme-history-init.jsonl"
  fi

  local gist_url
  gist_url=$(gh gist create "$history_file" \
    --desc "$THEME_GIST_DESCRIPTION" \
    --filename "history.jsonl" 2>/dev/null)

  echo "$gist_url" | grep -oE '[a-f0-9]{32}' | head -1

  rm -f /tmp/theme-history-init.jsonl
}

_sync_fetch_gist() {
  local gist_id="$1"

  gh gist view "$gist_id" --filename "history.jsonl" --raw 2>/dev/null
}

_sync_merge_histories() {
  local local_file="$1"
  local remote_content="$2"

  {
    [[ -f "$local_file" ]] && cat "$local_file"
    echo "$remote_content"
  } | jq -s '
    flatten |
    map(select(. != null and . != {} and type == "object")) |
    unique_by([.ts, .machine, .theme, .action]) |
    sort_by(.ts)
  ' | jq -c '.[]'
}

sync_init() {
  if [[ "${THEME_ENV:-}" == "development" ]]; then
    echo "✗ Sync is disabled in dev mode" >&2
    return 1
  fi

  echo "Initializing theme sync..."

  if ! _sync_check_gh; then
    return 1
  fi

  local gist_id
  gist_id=$(_sync_find_gist)

  if [[ -n "$gist_id" ]]; then
    echo "Found existing gist: $gist_id"

    echo "Merging with local history..."
    if sync_pull; then
      echo "✓ Merged remote history"
    fi
  else
    echo "Creating new gist..."
    gist_id=$(_sync_create_gist)

    if [[ -z "$gist_id" ]]; then
      echo "Error: Failed to create gist" >&2
      return 1
    fi

    echo "Created gist: $gist_id"
  fi

  _sync_update_state "$gist_id" true

  echo ""
  echo "✓ Sync initialized!"
  echo "  Gist ID: $gist_id"
  echo "  History will sync automatically."
}

sync_pull() {
  if ! is_sync_enabled; then
    return 0
  fi

  local gist_id
  gist_id=$(_sync_get_gist_id)

  if [[ -z "$gist_id" ]]; then
    return 1
  fi

  local remote_content
  if ! remote_content=$(_sync_fetch_gist "$gist_id" 2>/dev/null); then
    return 0
  fi

  if [[ -z "$remote_content" ]] || [[ "$remote_content" == "{}" ]]; then
    return 0
  fi

  local merged
  merged=$(_sync_merge_histories "$THEME_HISTORY_FILE" "$remote_content")

  if [[ -n "$merged" ]]; then
    echo "$merged" > "$THEME_HISTORY_FILE"
  fi

  if [[ -f "$THEME_SYNC_STATE_FILE" ]]; then
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local state
    state=$(cat "$THEME_SYNC_STATE_FILE")
    echo "$state" | jq --arg ts "$timestamp" '.last_sync = $ts' > "$THEME_SYNC_STATE_FILE"
  fi

  return 0
}

sync_push() {
  if ! is_sync_enabled; then
    return 0
  fi

  local gist_id
  gist_id=$(_sync_get_gist_id)

  if [[ -z "$gist_id" ]]; then
    return 1
  fi

  if [[ ! -f "$THEME_HISTORY_FILE" ]] || [[ ! -s "$THEME_HISTORY_FILE" ]]; then
    return 0
  fi

  sync_pull

  if gh gist edit "$gist_id" --filename "history.jsonl" "$THEME_HISTORY_FILE" &>/dev/null; then
    if [[ -f "$THEME_SYNC_STATE_FILE" ]]; then
      local timestamp
      timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      local state
      state=$(cat "$THEME_SYNC_STATE_FILE")
      echo "$state" | jq --arg ts "$timestamp" '.last_sync = $ts' > "$THEME_SYNC_STATE_FILE"
    fi
    return 0
  else
    return 0
  fi
}

sync_status() {
  echo ""
  echo "Theme Sync Status"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if [[ "${THEME_ENV:-}" == "development" ]]; then
    echo "Status: Disabled (dev mode)"
    echo ""
    echo "Sync is disabled in development mode to prevent"
    echo "test data from polluting production history."
    return
  fi

  if [[ ! -f "$THEME_SYNC_STATE_FILE" ]]; then
    echo "Status: Not initialized"
    echo ""
    echo "Run 'theme sync init' to set up sync."
    return
  fi

  local state
  state=$(cat "$THEME_SYNC_STATE_FILE")

  local enabled
  enabled=$(echo "$state" | jq -r '.enabled // false')

  local gist_id
  gist_id=$(echo "$state" | jq -r '.gist_id // "none"')

  local last_sync
  last_sync=$(echo "$state" | jq -r '.last_sync // "never"')

  if [[ "$enabled" == "true" ]]; then
    echo "Status: Enabled ✓"
  else
    echo "Status: Disabled"
  fi

  echo "Gist ID: $gist_id"
  echo "Last sync: $last_sync"
  echo ""

  if _sync_check_gh &>/dev/null; then
    echo "GitHub CLI: Authenticated ✓"
  else
    echo "GitHub CLI: Not authenticated"
  fi

  if [[ -f "$THEME_HISTORY_FILE" ]]; then
    local entry_count
    entry_count=$(wc -l < "$THEME_HISTORY_FILE" | xargs)
    echo "Local entries: $entry_count"
  fi
}

sync_off() {
  if [[ -f "$THEME_SYNC_STATE_FILE" ]]; then
    local state
    state=$(cat "$THEME_SYNC_STATE_FILE")
    echo "$state" | jq '.enabled = false' > "$THEME_SYNC_STATE_FILE"
    echo "✓ Sync disabled"
    echo ""
    echo "Run 'theme sync on' to re-enable."
  else
    echo "Sync was not initialized."
  fi
}

sync_on() {
  if [[ -f "$THEME_SYNC_STATE_FILE" ]]; then
    local state
    state=$(cat "$THEME_SYNC_STATE_FILE")
    echo "$state" | jq '.enabled = true' > "$THEME_SYNC_STATE_FILE"
    echo "✓ Sync enabled"

    sync_pull
    sync_push
  else
    echo "Sync was not initialized."
    echo "Run 'theme sync init' first."
  fi
}

sync_after_action() {
  if is_sync_enabled; then
    echo "✓ Synced via GitHub Gist"
    sync_push &>/dev/null &
    disown 2>/dev/null || true
  fi
}

sync_before_read() {
  if is_sync_enabled; then
    sync_pull &>/dev/null || true
    echo "✓ Synced via GitHub Gist"
  fi
}

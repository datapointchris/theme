#!/usr/bin/env bash
# One-time migration script for theme history
# Migrates from per-platform files to unified XDG-compliant format
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
THEMES_DIR="$THEME_APP_DIR/themes"

OLD_HISTORY="$HOME/dotfiles/platforms/common/.config/theme/history-macos.jsonl"
OLD_REJECTED="$HOME/.config/theme/rejected-themes-macos.json"
OLD_CURRENT="$HOME/.local/share/theme/current"
OLD_SYMLINK="$HOME/.config/theme/history-macos.jsonl"

NEW_STATE_DIR="$HOME/.local/state/theme"
NEW_HISTORY="$NEW_STATE_DIR/history.jsonl"
NEW_CURRENT="$NEW_STATE_DIR/current"

MACHINE_ID="macos-$(hostname -s)"

info() { echo "[info] $*"; }
success() { echo "[ok] $*"; }
error() { echo "[error] $*" >&2; }
warn() { echo "[warn] $*" >&2; }

build_theme_lookup() {
  declare -gA THEME_LOOKUP

  for theme_dir in "$THEMES_DIR"/*/; do
    [[ -d "$theme_dir" ]] || continue
    local canonical
    canonical=$(basename "$theme_dir")
    local yml="$theme_dir/theme.yml"

    if [[ -f "$yml" ]]; then
      local display_name
      display_name=$(grep 'display_name:' "$yml" | head -1 | sed 's/.*display_name: *"\{0,1\}\([^"]*\)"\{0,1\}.*/\1/' | xargs)

      if [[ -n "$display_name" ]]; then
        local lower_display
        lower_display=$(echo "$display_name" | tr '[:upper:]' '[:lower:]')
        THEME_LOOKUP["$lower_display"]="$canonical"
      fi
    fi

    THEME_LOOKUP["$canonical"]="$canonical"
    local lower_canonical
    lower_canonical=$(echo "$canonical" | tr '[:upper:]' '[:lower:]')
    THEME_LOOKUP["$lower_canonical"]="$canonical"
  done
}

normalize_theme_name() {
  local input="$1"
  local lower
  lower=$(echo "$input" | tr '[:upper:]' '[:lower:]')

  # Special case: "Nord" in history → "nordic" directory
  if [[ "$lower" == "nord" ]]; then
    echo "nordic"
    return
  fi

  if [[ -n "${THEME_LOOKUP[$lower]:-}" ]]; then
    echo "${THEME_LOOKUP[$lower]}"
    return
  fi

  local with_hyphens
  with_hyphens=$(echo "$lower" | tr '_' '-' | tr ' ' '-')
  if [[ -n "${THEME_LOOKUP[$with_hyphens]:-}" ]]; then
    echo "${THEME_LOOKUP[$with_hyphens]}"
    return
  fi

  warn "Could not normalize theme name: $input"
  echo "$lower"
}

migrate_history() {
  info "Building theme lookup table..."
  build_theme_lookup
  info "Found ${#THEME_LOOKUP[@]} theme name mappings"

  if [[ ! -f "$OLD_HISTORY" ]]; then
    error "Old history file not found: $OLD_HISTORY"
    exit 1
  fi

  local record_count
  record_count=$(wc -l < "$OLD_HISTORY" | tr -d ' ')
  info "Migrating $record_count history records from: $OLD_HISTORY"

  mkdir -p "$NEW_STATE_DIR"

  # Use jq to process all records at once (more reliable than bash loop)
  # First, build a jq script with all the mappings
  local jq_script='
    def normalize_theme:
      . as $t |
      ($t | ascii_downcase) as $lower |
      if $lower == "nord" then "nordic"
      elif $lower == "kanagawa" then "kanagawa"
      elif $lower == "rose pine" then "rose-pine"
      elif $lower == "popping and locking" then "popping-and-locking"
      elif $lower == "github dark" then "github-dark"
      elif $lower == "raycast dark" then "raycast-dark"
      elif $lower == "treehouse" then "treehouse"
      elif $lower == "terafox" then "terafox"
      elif $lower == "smyck" then "smyck"
      elif ($lower | gsub("_"; "-")) == "github-dark-dimmed" then "github-dark-dimmed"
      else ($lower | gsub(" "; "-") | gsub("_"; "-"))
      end;
    . + {machine: $machine, theme: (.theme | normalize_theme)}
  '

  jq -c --arg machine "$MACHINE_ID" "$jq_script" "$OLD_HISTORY" > "$NEW_HISTORY.tmp"

  local migrated
  migrated=$(wc -l < "$NEW_HISTORY.tmp" | tr -d ' ')
  info "Migrated $migrated history records"

  # Note: Old system already logged reject actions to history, so rejected-themes.json
  # entries are duplicates. Skip conversion - reject actions are already in history.
  if [[ -f "$OLD_REJECTED" ]]; then
    info "Note: reject actions already in history, skipping rejected-themes.json"
  fi

  jq -s 'sort_by(.ts)' "$NEW_HISTORY.tmp" | jq -c '.[]' > "$NEW_HISTORY"
  rm "$NEW_HISTORY.tmp"

  local final_count
  final_count=$(wc -l < "$NEW_HISTORY" | tr -d ' ')
  success "Written $final_count records to: $NEW_HISTORY"
}

migrate_current_theme() {
  if [[ -f "$OLD_CURRENT" ]]; then
    local current
    current=$(cat "$OLD_CURRENT")
    info "Moving current theme tracking: $current"
    echo "$current" > "$NEW_CURRENT"
    success "Current theme saved to: $NEW_CURRENT"
  else
    warn "No current theme file found at: $OLD_CURRENT"
  fi
}

cleanup_old_files() {
  info "Cleaning up old files..."

  if [[ -L "$OLD_SYMLINK" ]]; then
    rm "$OLD_SYMLINK"
    success "Removed symlink: $OLD_SYMLINK"
  fi

  if [[ -f "$OLD_REJECTED" ]]; then
    rm "$OLD_REJECTED"
    success "Removed: $OLD_REJECTED"
  fi

  if [[ -d "$HOME/.config/theme" ]] && [[ -z "$(ls -A "$HOME/.config/theme" 2>/dev/null)" ]]; then
    rmdir "$HOME/.config/theme"
    success "Removed empty directory: $HOME/.config/theme"
  fi

  info "Note: Dotfiles copy at $OLD_HISTORY kept for verification"
  info "Delete it manually after confirming migration: rm '$OLD_HISTORY'"
}

verify_migration() {
  info "Verifying migration..."

  local old_count new_count
  old_count=$(wc -l < "$OLD_HISTORY" | tr -d ' ')
  new_count=$(jq -s 'map(select(.action != "reject")) | length' "$NEW_HISTORY")

  if [[ "$old_count" -eq "$new_count" ]]; then
    success "Record count matches: $old_count"
  else
    warn "Record count mismatch: old=$old_count, new=$new_count (may include reject actions)"
  fi

  local display_names
  display_names=$(jq -r '.theme' "$NEW_HISTORY" | grep -E '^[A-Z]' || true)
  if [[ -z "$display_names" ]]; then
    success "All theme names normalized to canonical IDs"
  else
    warn "Some theme names may not be normalized:"
    echo "$display_names" | head -5
  fi

  local missing_machine
  missing_machine=$(jq -s 'map(select(.machine == null)) | length' "$NEW_HISTORY")
  if [[ "$missing_machine" -eq 0 ]]; then
    success "All records have machine field"
  else
    warn "$missing_machine records missing machine field"
  fi

  if [[ -f "$NEW_CURRENT" ]]; then
    success "Current theme file exists: $(cat "$NEW_CURRENT")"
  else
    warn "Current theme file missing"
  fi
}

main() {
  echo "=== Theme History Migration ==="
  echo ""

  if [[ -f "$NEW_HISTORY" ]]; then
    error "New history file already exists: $NEW_HISTORY"
    error "Delete it first if you want to re-run migration"
    exit 1
  fi

  migrate_history
  echo ""
  migrate_current_theme
  echo ""
  cleanup_old_files
  echo ""
  verify_migration
  echo ""
  success "Migration complete!"
}

main "$@"

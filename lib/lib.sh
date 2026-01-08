#!/usr/bin/env bash
# Theme library - core functions for theme management
# Applies themes directly from themes/ directory

set -euo pipefail

THEME_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
THEME_APP_DIR="$(cd "$THEME_LIB_DIR/.." && pwd)"

# Dev mode: use THEME_ENV=development (set via direnv in ~/tools/theme/.envrc)
if [[ "${THEME_ENV:-}" == "development" ]]; then
  THEME_STATE_DIR="$THEME_APP_DIR/.dev-data"
else
  THEME_STATE_DIR="$HOME/.local/state/theme"
fi

# Configuration - themes/ is the single source of truth
THEMES_DIR="$THEME_APP_DIR/themes"
CURRENT_THEME_FILE="$THEME_STATE_DIR/current"

#==============================================================================
# THEME ACCESS - scans themes/ directory
#==============================================================================

# List all theme directory names (the canonical names)
get_theme_names() {
  if [[ ! -d "$THEMES_DIR" ]]; then
    echo "Error: Themes directory not found: $THEMES_DIR" >&2
    return 1
  fi

  for dir in "$THEMES_DIR"/*/; do
    [[ -d "$dir" ]] && basename "$dir"
  done
}

# Get theme data from theme.yml
get_theme_by_name() {
  local name="$1"
  local theme_file="$THEMES_DIR/$name/theme.yml"

  if [[ ! -f "$theme_file" ]]; then
    # Try case-insensitive match
    for dir in "$THEMES_DIR"/*/; do
      local dir_name
      dir_name=$(basename "$dir")
      if [[ "${dir_name,,}" == "${name,,}" ]]; then
        theme_file="$THEMES_DIR/$dir_name/theme.yml"
        break
      fi
    done
  fi

  if [[ -f "$theme_file" ]]; then
    cat "$theme_file"
  else
    return 1
  fi
}

# Get a specific mapping from theme.yml meta section
get_theme_mapping() {
  local name="$1"
  local app="$2"
  local theme_file="$THEMES_DIR/$name/theme.yml"

  if [[ ! -f "$theme_file" ]]; then
    return 1
  fi

  APP="$app" yq ".meta.$app // \"\"" "$theme_file"
}

# Convert input to canonical theme directory name
theme_name_to_canonical() {
  local input="$1"

  # Check if directory exists directly
  if [[ -d "$THEMES_DIR/$input" ]]; then
    echo "$input"
    return
  fi

  # Try case-insensitive match
  for dir in "$THEMES_DIR"/*/; do
    local dir_name
    dir_name=$(basename "$dir")
    if [[ "${dir_name,,}" == "${input,,}" ]]; then
      echo "$dir_name"
      return
    fi
  done

  # Try matching against meta.display_name in theme.yml files
  for dir in "$THEMES_DIR"/*/; do
    local theme_file="$dir/theme.yml"
    if [[ -f "$theme_file" ]]; then
      local meta_name
      meta_name=$(yq '.meta.display_name // ""' "$theme_file" 2>/dev/null || echo "")
      if [[ "${meta_name,,}" == "${input,,}" ]]; then
        basename "$dir"
        return
      fi
    fi
  done

  # Return input as-is if no match
  echo "$input"
}

#==============================================================================
# THEME LISTING
#==============================================================================

list_themes() {
  get_theme_names
}

get_theme_display_info() {
  local theme="$1"
  local theme_file="$THEMES_DIR/$theme/theme.yml"

  if [[ ! -f "$theme_file" ]]; then
    echo "$theme"
    return
  fi

  local display_name source_type
  display_name=$(yq -r '.meta.display_name // ""' "$theme_file" 2>/dev/null)
  source_type=$(yq -r '.meta.neovim_colorscheme_source // ""' "$theme_file" 2>/dev/null)

  if [[ -z "$display_name" ]]; then
    display_name="$theme"
  fi

  local source_label=""
  case "$source_type" in
    generated) source_label=" (Generated)" ;;
    plugin) source_label=" (Neovim Plugin)" ;;
  esac

  echo "${display_name}${source_label}"
}

list_themes_with_status() {
  local current
  current=$(get_current_theme 2>/dev/null || echo "")

  while IFS= read -r theme; do
    local display_info
    display_info=$(get_theme_display_info "$theme")
    if [[ "$theme" == "$current" ]]; then
      echo "● $display_info (current)"
    else
      echo "  $display_info"
    fi
  done < <(get_theme_names)
}

count_themes() {
  get_theme_names | wc -l | xargs
}

#==============================================================================
# CURRENT THEME
#==============================================================================

get_current_theme() {
  if [[ -f "$CURRENT_THEME_FILE" ]]; then
    cat "$CURRENT_THEME_FILE"
  else
    echo ""
  fi
}

set_current_theme() {
  local theme="$1"
  mkdir -p "$(dirname "$CURRENT_THEME_FILE")"
  echo "$theme" > "$CURRENT_THEME_FILE"
}

#==============================================================================
# PLATFORM DETECTION
#==============================================================================

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
  else
    echo "linux"
  fi
}

#==============================================================================
# APP HANDLERS - Direct application from themes/ directory
#==============================================================================

# Get the theme directory path
get_theme_path() {
  local theme="$1"
  local canonical
  canonical=$(theme_name_to_canonical "$theme")

  local path="$THEMES_DIR/$canonical"
  if [[ -d "$path" ]]; then
    echo "$path"
  else
    echo ""
  fi
}

# Alias for backward compatibility
get_library_path() {
  get_theme_path "$@"
}

# Apply Ghostty theme
# Copies color config to themes/current.conf (imported via config-file directive)
apply_ghostty() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/ghostty.conf" ]]; then
    return 1
  fi

  local ghostty_theme_dir="$HOME/.config/ghostty/themes"
  mkdir -p "$ghostty_theme_dir"

  # Copy theme colors to current.conf
  cp "$lib_path/ghostty.conf" "$ghostty_theme_dir/current.conf"

  return 0
}

# Apply Kitty theme (Arch)
apply_kitty() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/kitty.conf" ]]; then
    return 1
  fi

  local kitty_theme_dir="$HOME/.config/kitty/themes"
  mkdir -p "$kitty_theme_dir"

  # Copy theme to kitty themes dir
  cp "$lib_path/kitty.conf" "$kitty_theme_dir/current-theme.conf"

  # Kitty auto-reloads when config changes
  return 0
}

# Apply tmux theme
apply_tmux() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/tmux.conf" ]]; then
    return 1
  fi

  local tmux_theme_dir="$HOME/.config/tmux/themes"
  mkdir -p "$tmux_theme_dir"

  # Copy theme to tmux themes dir
  cp "$lib_path/tmux.conf" "$tmux_theme_dir/current.conf"

  return 0
}

# Apply btop theme
apply_btop() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/btop.theme" ]]; then
    return 1
  fi

  local btop_theme_dir="$HOME/.config/btop/themes"
  mkdir -p "$btop_theme_dir"

  cp "$lib_path/btop.theme" "$btop_theme_dir/current.theme"

  # Update btop config to use current theme
  local btop_config="$HOME/.config/btop/btop.conf"
  if [[ -f "$btop_config" ]]; then
    if grep -q "^color_theme" "$btop_config"; then
      sed -i 's|^color_theme.*|color_theme = "current"|' "$btop_config"
    fi
  fi

  return 0
}

# Apply JankyBorders theme (macOS)
apply_borders() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/bordersrc" ]]; then
    return 1
  fi

  local borders_theme_dir="$HOME/.config/borders/themes"
  mkdir -p "$borders_theme_dir"

  cp "$lib_path/bordersrc" "$borders_theme_dir/current"
  chmod +x "$borders_theme_dir/current"

  # Restart borders if running
  if pgrep -x "borders" &>/dev/null; then
    pkill -x "borders" 2>/dev/null || true
    sleep 0.5
    "$HOME/.config/borders/bordersrc" >/dev/null 2>&1 &
    disown
  fi

  return 0
}

#==============================================================================
# OPACITY MANAGEMENT
#==============================================================================

# Opacity config directories (separate from main config, included via config-file directive)
GHOSTTY_OPACITY_DIR="$HOME/.config/ghostty/opacity"
GHOSTTY_OPACITY_FILE="$GHOSTTY_OPACITY_DIR/current.conf"
KITTY_OPACITY_DIR="$HOME/.config/kitty/opacity"
KITTY_OPACITY_FILE="$KITTY_OPACITY_DIR/current.conf"
WINDOWS_TERMINAL_OPACITY_FILE="$HOME/.config/windows-terminal/opacity.json"
TMUX_OPACITY_FILE="$HOME/.config/tmux/opacity.conf"

# Get current opacity from ghostty opacity config
get_ghostty_opacity() {
  if [[ -f "$GHOSTTY_OPACITY_FILE" ]]; then
    grep -E "^background-opacity\s*=" "$GHOSTTY_OPACITY_FILE" 2>/dev/null | sed 's/.*=\s*//' | tr -d ' ' || echo "1.0"
  else
    echo "1.0"
  fi
}

# Set ghostty opacity
set_ghostty_opacity() {
  local opacity="$1"
  mkdir -p "$GHOSTTY_OPACITY_DIR"
  echo "background-opacity = $opacity" > "$GHOSTTY_OPACITY_FILE"
}

# Get current opacity from kitty opacity config
get_kitty_opacity() {
  if [[ -f "$KITTY_OPACITY_FILE" ]]; then
    grep -E "^background_opacity\s+" "$KITTY_OPACITY_FILE" 2>/dev/null | awk '{print $2}' || echo "1.0"
  else
    echo "1.0"
  fi
}

# Set kitty opacity
set_kitty_opacity() {
  local opacity="$1"
  mkdir -p "$KITTY_OPACITY_DIR"
  echo "background_opacity $opacity" > "$KITTY_OPACITY_FILE"
}

# Get current opacity from windows terminal opacity config
get_windows_terminal_opacity() {
  if [[ -f "$WINDOWS_TERMINAL_OPACITY_FILE" ]]; then
    local pct
    pct=$(jq -r '.opacity // 100' "$WINDOWS_TERMINAL_OPACITY_FILE" 2>/dev/null)
    awk "BEGIN {printf \"%.2f\", $pct / 100}"
  else
    echo "1.0"
  fi
}

# Set windows terminal opacity (stores as 0-100 integer)
set_windows_terminal_opacity() {
  local opacity="$1"
  local pct
  pct=$(awk "BEGIN {printf \"%.0f\", $opacity * 100}")
  mkdir -p "$(dirname "$WINDOWS_TERMINAL_OPACITY_FILE")"
  echo "{\"opacity\": $pct}" > "$WINDOWS_TERMINAL_OPACITY_FILE"
}

# Set tmux opacity (uses 'default' bg when < 1.0, otherwise uses theme bg)
set_tmux_opacity() {
  local opacity="$1"
  local tmux_dir
  tmux_dir="$(dirname "$TMUX_OPACITY_FILE")"
  mkdir -p "$tmux_dir"

  if awk "BEGIN {exit !($opacity < 1.0)}"; then
    # Transparent - use default background
    cat > "$TMUX_OPACITY_FILE" << 'EOF'
# Transparent background (inherits from terminal)
set -g window-style 'bg=default'
set -g window-active-style 'bg=default'
EOF
  else
    # Opaque - use theme background (empty file, theme controls bg)
    cat > "$TMUX_OPACITY_FILE" << 'EOF'
# Opaque background (uses theme colors)
# No overrides needed - theme controls background
EOF
  fi

  # Reload tmux if running
  if command -v tmux &>/dev/null && tmux list-sessions &>/dev/null; then
    tmux source-file "$TMUX_OPACITY_FILE" 2>/dev/null || true
  fi
}

# Get current opacity (from first available terminal)
get_current_opacity() {
  local opacity

  if [[ -f "$GHOSTTY_OPACITY_FILE" ]]; then
    opacity=$(get_ghostty_opacity)
  elif [[ -f "$KITTY_OPACITY_FILE" ]]; then
    opacity=$(get_kitty_opacity)
  elif [[ -f "$WINDOWS_TERMINAL_OPACITY_FILE" ]]; then
    opacity=$(get_windows_terminal_opacity)
  else
    opacity="1.0"
  fi

  echo "$opacity"
}

# Change opacity by delta (e.g., 0.05 or -0.05)
change_opacity() {
  local delta="$1"
  local current
  current=$(get_current_opacity)

  # Calculate new opacity using awk for floating point
  local new_opacity
  new_opacity=$(awk "BEGIN {printf \"%.2f\", $current + $delta}")

  # Clamp between 0.5 and 1.0
  if awk "BEGIN {exit !($new_opacity < 0.5)}"; then
    new_opacity="0.50"
  elif awk "BEGIN {exit !($new_opacity > 1.0)}"; then
    new_opacity="1.00"
  fi

  # Apply to all terminals
  local applied=()

  set_ghostty_opacity "$new_opacity" && applied+=("ghostty")
  set_kitty_opacity "$new_opacity" && applied+=("kitty")
  set_windows_terminal_opacity "$new_opacity" && applied+=("windows-terminal")
  set_tmux_opacity "$new_opacity" && applied+=("tmux")

  echo "$current → $new_opacity (${applied[*]})"
}

# Wallpaper cache directory
WALLPAPER_CACHE_DIR="${WALLPAPER_CACHE_DIR:-$HOME/.cache/theme/wallpapers}"

# Wallpaper sources config file (path references, not copies)
WALLPAPER_SOURCES_FILE="${WALLPAPER_SOURCES_FILE:-$HOME/.config/theme/wallpaper-sources.conf}"

# Current wallpaper tracking
WALLPAPER_CURRENT_FILE="$THEME_STATE_DIR/wallpaper-current"

# Mode setting (which wallpaper types to include in rotation)
WALLPAPER_MODE_FILE="${WALLPAPER_MODE_FILE:-$HOME/.config/theme/wallpaper-mode}"

# All available generated styles (no source image needed)
WALLPAPER_GENERATED_STYLES=("plasma" "geometric" "hexagons" "circles" "swirl" "spotlight" "sphere" "spheres" "code" "banner")

# Source-based transform types (need source images like recolor)
WALLPAPER_SOURCE_TYPES=("recolor" "ascii" "lowpoly")

#==============================================================================
# WALLPAPER MODE MANAGEMENT
#==============================================================================

# List all available wallpaper modes/styles
list_available_wallpaper_modes() {
  for style in "${WALLPAPER_GENERATED_STYLES[@]}"; do
    echo "generated:$style"
  done
  for type in "${WALLPAPER_SOURCE_TYPES[@]}"; do
    echo "$type"
  done
}

# Get current wallpaper mode settings
# Returns: list of enabled modes, one per line, or "all" if not set
get_wallpaper_mode() {
  if [[ ! -f "$WALLPAPER_MODE_FILE" ]]; then
    echo "all"
    return
  fi

  local content
  content=$(cat "$WALLPAPER_MODE_FILE")

  if [[ -z "$content" ]]; then
    echo "all"
    return
  fi

  echo "$content"
}

# Set wallpaper mode to specific types
# Args: type1 [type2 ...]
# Special values: "all" enables everything
set_wallpaper_mode() {
  mkdir -p "$(dirname "$WALLPAPER_MODE_FILE")"

  if [[ "$1" == "all" ]]; then
    echo "all" > "$WALLPAPER_MODE_FILE"
    return
  fi

  : > "$WALLPAPER_MODE_FILE"
  for mode in "$@"; do
    echo "$mode" >> "$WALLPAPER_MODE_FILE"
  done
}

# Add a mode to current settings
add_wallpaper_mode() {
  local mode="$1"
  local current
  current=$(get_wallpaper_mode)

  if [[ "$current" == "all" ]]; then
    echo "Already set to 'all' - all modes enabled"
    return
  fi

  if echo "$current" | grep -qxF "$mode"; then
    echo "Mode already enabled: $mode"
    return
  fi

  mkdir -p "$(dirname "$WALLPAPER_MODE_FILE")"
  echo "$mode" >> "$WALLPAPER_MODE_FILE"
  echo "Added: $mode"
}

# Remove a mode from current settings
remove_wallpaper_mode() {
  local mode="$1"
  local current
  current=$(get_wallpaper_mode)

  if [[ "$current" == "all" ]]; then
    # Switch from "all" to explicit list minus the removed mode
    : > "$WALLPAPER_MODE_FILE"
    while IFS= read -r available; do
      [[ "$available" != "$mode" ]] && echo "$available" >> "$WALLPAPER_MODE_FILE"
    done < <(list_available_wallpaper_modes)
    echo "Removed: $mode (expanded from 'all')"
    return
  fi

  if ! echo "$current" | grep -qxF "$mode"; then
    echo "Mode not enabled: $mode"
    return
  fi

  { grep -vxF "$mode" "$WALLPAPER_MODE_FILE" || true; } > "${WALLPAPER_MODE_FILE}.tmp"
  mv "${WALLPAPER_MODE_FILE}.tmp" "$WALLPAPER_MODE_FILE"
  echo "Removed: $mode"
}

# Check if a wallpaper type is enabled by current mode
# Args: wallpaper_id (e.g., "generated:plasma" or "recolor:/path/to/file.jpg")
# Returns: 0 if enabled, 1 if not
is_wallpaper_type_enabled() {
  local wallpaper_id="$1"
  local current_mode
  current_mode=$(get_wallpaper_mode)

  if [[ "$current_mode" == "all" ]]; then
    return 0
  fi

  local wp_type="${wallpaper_id%%:*}"
  local wp_value="${wallpaper_id#*:}"

  if [[ "$wp_type" == "generated" ]]; then
    # Check exact match (generated:plasma) or category match (generated)
    if echo "$current_mode" | grep -qxF "generated:$wp_value"; then
      return 0
    fi
    if echo "$current_mode" | grep -qxF "generated"; then
      return 0
    fi
  else
    # Source-based types: recolor, ascii, lowpoly
    if echo "$current_mode" | grep -qxF "$wp_type"; then
      return 0
    fi
  fi

  return 1
}

# Check if a source-based type is enabled (recolor, ascii, lowpoly)
is_source_type_enabled() {
  local type="$1"
  local current_mode
  current_mode=$(get_wallpaper_mode)

  [[ "$current_mode" == "all" ]] && return 0
  echo "$current_mode" | grep -qxF "$type"
}

# Get list of enabled generated styles based on current mode
get_enabled_generated_styles() {
  local current_mode
  current_mode=$(get_wallpaper_mode)

  if [[ "$current_mode" == "all" ]]; then
    printf '%s\n' "${WALLPAPER_GENERATED_STYLES[@]}"
    return
  fi

  # Check for category "generated" (all generated styles)
  if echo "$current_mode" | grep -qxF "generated"; then
    printf '%s\n' "${WALLPAPER_GENERATED_STYLES[@]}"
    return
  fi

  # Check individual generated:style entries
  for style in "${WALLPAPER_GENERATED_STYLES[@]}"; do
    if echo "$current_mode" | grep -qxF "generated:$style"; then
      echo "$style"
    fi
  done
}

# Check if recolor mode is enabled
is_recolor_enabled() {
  local current_mode
  current_mode=$(get_wallpaper_mode)

  [[ "$current_mode" == "all" ]] && return 0
  echo "$current_mode" | grep -qxF "recolor"
}

#==============================================================================
# WALLPAPER SOURCE MANAGEMENT (path-based, no copying)
#==============================================================================

# Add a source path (file or directory) for wallpaper recoloring
# Stores path reference in wallpaper-sources.conf (no copying)
add_wallpaper_source() {
  local source_path="$1"

  if [[ ! -e "$source_path" ]]; then
    echo "Error: Path not found: $source_path" >&2
    return 1
  fi

  # Get absolute path
  local abs_path
  abs_path=$(cd "$(dirname "$source_path")" && pwd)/$(basename "$source_path")

  mkdir -p "$(dirname "$WALLPAPER_SOURCES_FILE")"

  if [[ -d "$abs_path" ]]; then
    # Directory source
    local prefix="dir:"
    local entry="${prefix}${abs_path}"

    # Check if already exists
    if [[ -f "$WALLPAPER_SOURCES_FILE" ]] && grep -qF "$entry" "$WALLPAPER_SOURCES_FILE" 2>/dev/null; then
      echo "Directory already added: $abs_path"
      return 0
    fi

    # Count images in directory
    local count
    count=$(find "$abs_path" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | wc -l | xargs)

    echo "$entry" >> "$WALLPAPER_SOURCES_FILE"
    echo "Added directory: $abs_path ($count images)"
  else
    # Single file
    local mime
    mime=$(file --mime-type -b "$abs_path" 2>/dev/null || echo "")
    if [[ ! "$mime" =~ ^image/ ]]; then
      echo "Error: Not an image file: $abs_path" >&2
      return 1
    fi

    local entry="file:${abs_path}"

    # Check if already exists
    if [[ -f "$WALLPAPER_SOURCES_FILE" ]] && grep -qF "$entry" "$WALLPAPER_SOURCES_FILE" 2>/dev/null; then
      echo "File already added: $abs_path"
      return 0
    fi

    echo "$entry" >> "$WALLPAPER_SOURCES_FILE"
    echo "Added file: $abs_path"
  fi
}

# List configured wallpaper sources (the config entries, not expanded images)
list_wallpaper_source_entries() {
  if [[ ! -f "$WALLPAPER_SOURCES_FILE" ]]; then
    return 0
  fi
  cat "$WALLPAPER_SOURCES_FILE"
}

# Expand all sources to actual image files (scans directories at runtime)
get_all_wallpaper_images() {
  if [[ ! -f "$WALLPAPER_SOURCES_FILE" ]]; then
    return 0
  fi

  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    [[ "$entry" =~ ^# ]] && continue

    local type="${entry%%:*}"
    local path="${entry#*:}"

    case "$type" in
      file)
        if [[ -f "$path" ]] && [[ -r "$path" ]]; then
          echo "$path"
        fi
        ;;
      dir)
        if [[ -d "$path" ]]; then
          find "$path" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null
        fi
        ;;
    esac
  done < "$WALLPAPER_SOURCES_FILE"
}

# Remove a wallpaper source entry
remove_wallpaper_source() {
  local input="$1"

  if [[ ! -f "$WALLPAPER_SOURCES_FILE" ]]; then
    echo "Error: No sources configured" >&2
    return 1
  fi

  # Try exact match first (with prefix)
  if grep -qF "$input" "$WALLPAPER_SOURCES_FILE" 2>/dev/null; then
    { grep -vF "$input" "$WALLPAPER_SOURCES_FILE" || true; } > "${WALLPAPER_SOURCES_FILE}.tmp"
    mv "${WALLPAPER_SOURCES_FILE}.tmp" "$WALLPAPER_SOURCES_FILE"
    echo "Removed: $input"
    return 0
  fi

  # Try matching path without prefix
  local match
  match=$(grep -E "(file:|dir:).*${input}" "$WALLPAPER_SOURCES_FILE" 2>/dev/null | head -1 || true)
  if [[ -n "$match" ]]; then
    { grep -vF "$match" "$WALLPAPER_SOURCES_FILE" || true; } > "${WALLPAPER_SOURCES_FILE}.tmp"
    mv "${WALLPAPER_SOURCES_FILE}.tmp" "$WALLPAPER_SOURCES_FILE"
    echo "Removed: $match"
    return 0
  fi

  echo "Error: Source not found: $input" >&2
  return 1
}

# Verify all source paths exist and are readable
verify_wallpaper_sources() {
  if [[ ! -f "$WALLPAPER_SOURCES_FILE" ]]; then
    echo "No sources configured."
    return 0
  fi

  local valid=0
  local broken=0

  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    [[ "$entry" =~ ^# ]] && continue

    local type="${entry%%:*}"
    local path="${entry#*:}"

    case "$type" in
      file)
        if [[ -f "$path" ]] && [[ -r "$path" ]]; then
          echo "  ✓ $entry"
          valid=$((valid + 1))
        else
          echo "  ✗ $entry (missing or unreadable)"
          broken=$((broken + 1))
        fi
        ;;
      dir)
        if [[ -d "$path" ]]; then
          local count
          count=$(find "$path" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | wc -l | xargs)
          echo "  ✓ $entry ($count images)"
          valid=$((valid + 1))
        else
          echo "  ✗ $entry (directory not found)"
          broken=$((broken + 1))
        fi
        ;;
      *)
        echo "  ? $entry (unknown type)"
        broken=$((broken + 1))
        ;;
    esac
  done < "$WALLPAPER_SOURCES_FILE"

  echo ""
  echo "Valid: $valid, Broken: $broken"
  [[ $broken -eq 0 ]]
}

# Remove broken source entries
clean_wallpaper_sources() {
  if [[ ! -f "$WALLPAPER_SOURCES_FILE" ]]; then
    echo "No sources configured."
    return 0
  fi

  local cleaned=0
  local temp_file="${WALLPAPER_SOURCES_FILE}.tmp"
  : > "$temp_file"

  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    [[ "$entry" =~ ^# ]] && { echo "$entry" >> "$temp_file"; continue; }

    local type="${entry%%:*}"
    local path="${entry#*:}"
    local keep=true

    case "$type" in
      file)
        if [[ ! -f "$path" ]] || [[ ! -r "$path" ]]; then
          echo "Removing: $entry (file missing)"
          keep=false
          cleaned=$((cleaned + 1))
        fi
        ;;
      dir)
        if [[ ! -d "$path" ]]; then
          echo "Removing: $entry (directory missing)"
          keep=false
          cleaned=$((cleaned + 1))
        fi
        ;;
    esac

    [[ "$keep" == "true" ]] && echo "$entry" >> "$temp_file"
  done < "$WALLPAPER_SOURCES_FILE"

  mv "$temp_file" "$WALLPAPER_SOURCES_FILE"
  echo ""
  echo "Cleaned $cleaned broken entries."
}

# Get a random source image (scans directories at runtime)
get_random_wallpaper_source() {
  local images=()

  while IFS= read -r img; do
    [[ -n "$img" ]] && images+=("$img")
  done < <(get_all_wallpaper_images)

  if [[ ${#images[@]} -eq 0 ]]; then
    return 1
  fi

  echo "${images[$((RANDOM % ${#images[@]}))]}"
}

# Get current wallpaper info
get_current_wallpaper() {
  if [[ -f "$WALLPAPER_CURRENT_FILE" ]]; then
    cat "$WALLPAPER_CURRENT_FILE"
  fi
}

# Set current wallpaper
set_current_wallpaper() {
  local wallpaper_id="$1"
  mkdir -p "$(dirname "$WALLPAPER_CURRENT_FILE")"
  echo "$wallpaper_id" > "$WALLPAPER_CURRENT_FILE"
}

# Apply wallpaper (macOS)
# Returns: wallpaper_id (e.g., "generated:plasma" or "recolor:/path/to/image.jpg")
apply_wallpaper() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/theme.yml" ]]; then
    return 1
  fi

  local wallpaper_dir="$HOME/.local/share/theme"
  mkdir -p "$wallpaper_dir"

  # Use unique filename to bypass macOS wallpaper cache
  local timestamp
  timestamp=$(date +%s)
  local wallpaper_file="$wallpaper_dir/wallpaper-${timestamp}.png"

  # Clean up old wallpaper files
  find "$wallpaper_dir" -name 'wallpaper-*.png' -mmin +1 -delete 2>/dev/null || true

  # Build list of available wallpapers based on mode settings
  local available=()
  local generators_dir
  generators_dir="$(dirname "${BASH_SOURCE[0]}")/generators"

  # Add enabled generated styles
  while IFS= read -r style; do
    [[ -n "$style" ]] && available+=("generated:$style")
  done < <(get_enabled_generated_styles)

  # Add source-based types if enabled and source images exist
  for source_type in "${WALLPAPER_SOURCE_TYPES[@]}"; do
    if is_source_type_enabled "$source_type"; then
      while IFS= read -r img; do
        [[ -n "$img" ]] && available+=("${source_type}:$img")
      done < <(get_all_wallpaper_images)
    fi
  done

  if [[ ${#available[@]} -eq 0 ]]; then
    echo "Error: No wallpapers available (check mode settings)" >&2
    return 1
  fi

  # Pick random from available
  local selected="${available[$((RANDOM % ${#available[@]}))]}"
  local wp_type="${selected%%:*}"
  local wp_value="${selected#*:}"
  local wallpaper_id=""

  case "$wp_type" in
    generated)
      # Check for special generators first
      case "$wp_value" in
        code)
          local code_gen="$generators_dir/wallpaper-code.sh"
          if [[ -f "$code_gen" ]]; then
            bash "$code_gen" "$lib_path/theme.yml" "$wallpaper_file" >/dev/null 2>&1 || return 1
          else
            return 1
          fi
          ;;
        banner)
          local banner_gen="$generators_dir/wallpaper-banner.sh"
          if [[ -f "$banner_gen" ]]; then
            bash "$banner_gen" "$lib_path/theme.yml" "$wallpaper_file" >/dev/null 2>&1 || return 1
          else
            return 1
          fi
          ;;
        *)
          # Standard ImageMagick styles
          local cache_file="$WALLPAPER_CACHE_DIR/$theme/${wp_value}.png"
          if [[ -f "$cache_file" ]]; then
            cp "$cache_file" "$wallpaper_file"
          else
            local generator_script="$generators_dir/wallpaper.sh"
            [[ ! -f "$generator_script" ]] && return 1
            bash "$generator_script" "$lib_path/theme.yml" "$wallpaper_file" "$wp_value" 1920 1080 >/dev/null 2>&1 || return 1
          fi
          ;;
      esac
      wallpaper_id="generated:$wp_value"
      ;;
    recolor)
      local gowall_gen="$generators_dir/wallpaper-gowall.sh"
      if [[ -f "$gowall_gen" ]]; then
        bash "$gowall_gen" "$lib_path/theme.yml" "$wp_value" "$wallpaper_file" >/dev/null 2>&1 || return 1
        wallpaper_id="recolor:$wp_value"
      else
        return 1
      fi
      ;;
    ascii)
      local ascii_gen="$generators_dir/wallpaper-ascii.sh"
      if [[ -f "$ascii_gen" ]]; then
        bash "$ascii_gen" "$lib_path/theme.yml" "$wp_value" "$wallpaper_file" >/dev/null 2>&1 || return 1
        wallpaper_id="ascii:$wp_value"
      else
        return 1
      fi
      ;;
    lowpoly)
      local lowpoly_gen="$generators_dir/wallpaper-lowpoly.sh"
      if [[ -f "$lowpoly_gen" ]]; then
        bash "$lowpoly_gen" "$lib_path/theme.yml" "$wp_value" "$wallpaper_file" >/dev/null 2>&1 || return 1
        wallpaper_id="lowpoly:$wp_value"
      else
        return 1
      fi
      ;;
    *)
      echo "Error: Unknown wallpaper type: $wp_type" >&2
      return 1
      ;;
  esac

  # Set as desktop wallpaper on macOS using Finder (more reliable than System Events)
  osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$wallpaper_file\"" 2>/dev/null || return 1

  # Track current wallpaper
  set_current_wallpaper "$wallpaper_id"

  # Output the selected style for status display
  if [[ "$wp_type" == "generated" ]]; then
    echo "$wp_value"
  else
    echo "$wp_type ($(basename "$wp_value"))"
  fi
  return 0
}

# Rotate wallpaper without changing theme (macOS)
# Selects a different wallpaper than current, applies it
# Args: [rejected_list] [weights_json]
#   rejected_list: newline-separated list of rejected wallpaper IDs
#   weights_json: JSON object mapping wallpaper ID to weight (default 1.0)
rotate_wallpaper() {
  local rejected_list="${1:-}"
  local weights_json="${2:-}"

  local theme
  theme=$(get_current_theme)

  if [[ -z "$theme" ]]; then
    echo "Error: No theme currently applied" >&2
    return 1
  fi

  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/theme.yml" ]]; then
    echo "Error: Theme not found: $theme" >&2
    return 1
  fi

  local wallpaper_dir="$HOME/.local/share/theme"
  mkdir -p "$wallpaper_dir"

  local timestamp
  timestamp=$(date +%s)
  local wallpaper_file="$wallpaper_dir/wallpaper-${timestamp}.png"

  find "$wallpaper_dir" -name 'wallpaper-*.png' -mmin +1 -delete 2>/dev/null || true

  # Build list of available wallpapers, excluding current and rejected
  local current_wallpaper
  current_wallpaper=$(get_current_wallpaper)

  # Convert rejected list to associative array for O(1) lookup
  declare -A rejected_map
  if [[ -n "$rejected_list" ]]; then
    while IFS= read -r wp; do
      [[ -n "$wp" ]] && rejected_map["$wp"]=1
    done <<< "$rejected_list"
  fi

  local available=()
  local weights=()

  # Add enabled generated styles (respects mode setting)
  while IFS= read -r style; do
    [[ -z "$style" ]] && continue
    local wp_id="generated:$style"
    # Skip current and rejected
    [[ "$wp_id" == "$current_wallpaper" ]] && continue
    [[ -n "${rejected_map[$wp_id]:-}" ]] && continue
    available+=("$wp_id")
    # Get weight from JSON or default to 1
    local weight=1
    if [[ -n "$weights_json" ]]; then
      weight=$(echo "$weights_json" | jq -r --arg wp "$wp_id" '.[$wp] // 1')
    fi
    weights+=("$weight")
  done < <(get_enabled_generated_styles)

  # Add source-based types if enabled and source images exist
  for source_type in "${WALLPAPER_SOURCE_TYPES[@]}"; do
    if is_source_type_enabled "$source_type"; then
      while IFS= read -r img; do
        [[ -z "$img" ]] && continue
        local wp_id="${source_type}:$img"
        [[ "$wp_id" == "$current_wallpaper" ]] && continue
        [[ -n "${rejected_map[$wp_id]:-}" ]] && continue
        available+=("$wp_id")
        local weight=1
        if [[ -n "$weights_json" ]]; then
          weight=$(echo "$weights_json" | jq -r --arg wp "$wp_id" '.[$wp] // 1')
        fi
        weights+=("$weight")
      done < <(get_all_wallpaper_images)
    fi
  done

  if [[ ${#available[@]} -eq 0 ]]; then
    echo "Error: No alternative wallpapers available" >&2
    return 1
  fi

  # Weighted random selection
  local total_weight=0
  for w in "${weights[@]}"; do
    total_weight=$(awk "BEGIN {print $total_weight + $w}")
  done

  local rand_val
  rand_val=$(awk "BEGIN {srand(); print rand() * $total_weight}")

  local cumulative=0
  local selected=""
  for i in "${!available[@]}"; do
    cumulative=$(awk "BEGIN {print $cumulative + ${weights[$i]}}")
    if awk "BEGIN {exit !($rand_val <= $cumulative)}"; then
      selected="${available[$i]}"
      break
    fi
  done

  # Fallback if something went wrong with weighting
  [[ -z "$selected" ]] && selected="${available[0]}"

  local wp_type="${selected%%:*}"
  local wp_value="${selected#*:}"
  local generators_dir
  generators_dir="$(dirname "${BASH_SOURCE[0]}")/generators"

  case "$wp_type" in
    generated)
      # Check for special generators first
      case "$wp_value" in
        code)
          local code_gen="$generators_dir/wallpaper-code.sh"
          if [[ -f "$code_gen" ]]; then
            bash "$code_gen" "$lib_path/theme.yml" "$wallpaper_file" >/dev/null 2>&1 || return 1
          else
            return 1
          fi
          ;;
        banner)
          local banner_gen="$generators_dir/wallpaper-banner.sh"
          if [[ -f "$banner_gen" ]]; then
            bash "$banner_gen" "$lib_path/theme.yml" "$wallpaper_file" >/dev/null 2>&1 || return 1
          else
            return 1
          fi
          ;;
        *)
          # Standard ImageMagick styles
          local cache_file="$WALLPAPER_CACHE_DIR/$theme/${wp_value}.png"
          if [[ -f "$cache_file" ]]; then
            cp "$cache_file" "$wallpaper_file"
          else
            local generator_script="$generators_dir/wallpaper.sh"
            [[ ! -f "$generator_script" ]] && return 1
            bash "$generator_script" "$lib_path/theme.yml" "$wallpaper_file" "$wp_value" 1920 1080 >/dev/null 2>&1 || return 1
          fi
          ;;
      esac
      ;;
    recolor)
      local gowall_gen="$generators_dir/wallpaper-gowall.sh"
      if [[ -f "$gowall_gen" ]]; then
        bash "$gowall_gen" "$lib_path/theme.yml" "$wp_value" "$wallpaper_file" >/dev/null 2>&1 || return 1
      else
        return 1
      fi
      ;;
    ascii)
      local ascii_gen="$generators_dir/wallpaper-ascii.sh"
      if [[ -f "$ascii_gen" ]]; then
        bash "$ascii_gen" "$lib_path/theme.yml" "$wp_value" "$wallpaper_file" >/dev/null 2>&1 || return 1
      else
        return 1
      fi
      ;;
    lowpoly)
      local lowpoly_gen="$generators_dir/wallpaper-lowpoly.sh"
      if [[ -f "$lowpoly_gen" ]]; then
        bash "$lowpoly_gen" "$lib_path/theme.yml" "$wp_value" "$wallpaper_file" >/dev/null 2>&1 || return 1
      else
        return 1
      fi
      ;;
    *)
      echo "Error: Unknown wallpaper type: $wp_type" >&2
      return 1
      ;;
  esac

  osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$wallpaper_file\"" 2>/dev/null || return 1

  set_current_wallpaper "$selected"

  # Output for display
  if [[ "$wp_type" == "generated" ]]; then
    echo "$wp_value"
  else
    echo "$wp_type ($(basename "$wp_value"))"
  fi
  return 0
}

# Apply Hyprland theme (Arch)
apply_hyprland() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/hyprland.conf" ]]; then
    return 1
  fi

  local hypr_theme_dir="$HOME/.config/hypr/themes"
  mkdir -p "$hypr_theme_dir"

  cp "$lib_path/hyprland.conf" "$hypr_theme_dir/current.conf"

  # Reload hyprland if running
  if command -v hyprctl &>/dev/null; then
    hyprctl reload 2>/dev/null || true
  fi

  return 0
}

# Apply waybar theme (Arch)
apply_waybar() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/waybar.css" ]]; then
    return 1
  fi

  local waybar_theme_dir="$HOME/.config/waybar/themes"
  mkdir -p "$waybar_theme_dir"

  cp "$lib_path/waybar.css" "$waybar_theme_dir/current.css"

  return 0
}

# Apply hyprlock theme (Arch)
apply_hyprlock() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/hyprlock.conf" ]]; then
    return 1
  fi

  local hyprlock_theme_dir="$HOME/.config/hypr/themes"
  mkdir -p "$hyprlock_theme_dir"

  cp "$lib_path/hyprlock.conf" "$hyprlock_theme_dir/hyprlock.conf"

  return 0
}

# Apply dunst theme (Arch)
# Uses drop-in directory: ~/.config/dunst/dunstrc.d/99-theme.conf
apply_dunst() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/dunst.conf" ]]; then
    return 1
  fi

  local dunst_dropin_dir="$HOME/.config/dunst/dunstrc.d"
  mkdir -p "$dunst_dropin_dir"

  cp "$lib_path/dunst.conf" "$dunst_dropin_dir/99-theme.conf"

  return 0
}

# Apply rofi theme (Arch)
apply_rofi() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/rofi.rasi" ]]; then
    return 1
  fi

  local rofi_theme_dir="$HOME/.config/rofi/themes"
  mkdir -p "$rofi_theme_dir"

  cp "$lib_path/rofi.rasi" "$rofi_theme_dir/current.rasi"

  return 0
}

# Apply Windows Terminal theme (WSL)
apply_windows_terminal() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/windows-terminal.json" ]]; then
    return 1
  fi

  # Get Windows username from WSL
  local windows_user
  windows_user=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
  [[ -z "$windows_user" ]] && return 1

  # Find Windows Terminal settings.json
  local wt_settings=""
  local paths=(
    "/mnt/c/Users/$windows_user/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
    "/mnt/c/Users/$windows_user/AppData/Local/Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState/settings.json"
    "/mnt/c/Users/$windows_user/AppData/Local/Microsoft/Windows Terminal/settings.json"
  )

  for path in "${paths[@]}"; do
    if [[ -f "$path" ]]; then
      wt_settings="$path"
      break
    fi
  done

  [[ -z "$wt_settings" ]] && return 1

  # Read theme JSON and merge into settings
  local theme_json
  theme_json=$(cat "$lib_path/windows-terminal.json")
  local theme_name
  theme_name=$(echo "$theme_json" | jq -r '.name')

  # Backup settings
  cp "$wt_settings" "${wt_settings}.backup"

  # Remove existing scheme with same name and add new one
  jq --argjson scheme "$theme_json" \
    '.schemes = [.schemes[] | select(.name != $scheme.name)] + [$scheme]' \
    "$wt_settings" > "${wt_settings}.tmp" && mv "${wt_settings}.tmp" "$wt_settings"

  # Set as active colorScheme for WSL profile
  local wsl_profile_guid
  wsl_profile_guid=$(jq -r '.profiles.list[] | select(.source == "Windows.Terminal.Wsl") | .guid' "$wt_settings" 2>/dev/null | head -1)
  if [[ -n "$wsl_profile_guid" ]]; then
    jq --arg guid "$wsl_profile_guid" --arg theme "$theme_name" \
      '(.profiles.list[] | select(.guid == $guid)).colorScheme = $theme' \
      "$wt_settings" > "${wt_settings}.tmp" && mv "${wt_settings}.tmp" "$wt_settings"
  fi

  return 0
}

#==============================================================================
# MAIN APPLY FUNCTION
#==============================================================================

# Apply theme to all available apps on current platform
apply_theme_to_apps() {
  local theme="$1"
  local platform
  platform=$(detect_platform)

  local applied=()
  local skipped=()

  _print_app_status() {
    local app="$1"
    local success="$2"
    if [[ "$success" == "true" ]]; then
      echo "  ✓ $app" >&2
    else
      echo "  ✗ $app (error)" >&2
    fi
  }

  # Check if theme exists in library
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]]; then
    echo "Warning: Theme '$theme' not in library, limited app support" >&2
  fi

  # Ghostty (macOS and Arch)
  if [[ "$platform" == "macos" ]] || [[ "$platform" == "arch" ]]; then
    if apply_ghostty "$theme" 2>/dev/null; then
      applied+=("ghostty")
      _print_app_status "ghostty" "true"
    else
      skipped+=("ghostty")
      _print_app_status "ghostty" "false"
    fi
  fi

  # Kitty (macOS and Arch)
  if [[ "$platform" == "macos" ]] || [[ "$platform" == "arch" ]]; then
    if apply_kitty "$theme" 2>/dev/null; then
      applied+=("kitty")
      _print_app_status "kitty" "true"
    else
      skipped+=("kitty")
      _print_app_status "kitty" "false"
    fi
  fi

  # JankyBorders (macOS only)
  if [[ "$platform" == "macos" ]]; then
    if apply_borders "$theme" 2>/dev/null; then
      applied+=("borders")
      _print_app_status "borders" "true"
    else
      skipped+=("borders")
      _print_app_status "borders" "false"
    fi
  fi

  # Wallpaper (macOS only)
  local wallpaper_id=""
  if [[ "$platform" == "macos" ]]; then
    local wallpaper_style
    if wallpaper_style=$(apply_wallpaper "$theme" 2>/dev/null); then
      applied+=("wallpaper")
      _print_app_status "wallpaper ($wallpaper_style)" "true"
      wallpaper_id=$(get_current_wallpaper)
    else
      skipped+=("wallpaper")
      _print_app_status "wallpaper" "false"
    fi
  fi

  # Tmux (all platforms)
  if apply_tmux "$theme" 2>/dev/null; then
    applied+=("tmux")
    _print_app_status "tmux" "true"
  else
    skipped+=("tmux")
    _print_app_status "tmux" "false"
  fi

  # Btop (all platforms)
  if apply_btop "$theme" 2>/dev/null; then
    applied+=("btop")
    _print_app_status "btop" "true"
  else
    skipped+=("btop")
    _print_app_status "btop" "false"
  fi

  # Hyprland (Arch only)
  if [[ "$platform" == "arch" ]]; then
    if apply_hyprland "$theme" 2>/dev/null; then
      applied+=("hyprland")
      _print_app_status "hyprland" "true"
    else
      skipped+=("hyprland")
      _print_app_status "hyprland" "false"
    fi

    if apply_waybar "$theme" 2>/dev/null; then
      applied+=("waybar")
      _print_app_status "waybar" "true"
    else
      skipped+=("waybar")
      _print_app_status "waybar" "false"
    fi

    if apply_hyprlock "$theme" 2>/dev/null; then
      applied+=("hyprlock")
      _print_app_status "hyprlock" "true"
    else
      skipped+=("hyprlock")
      _print_app_status "hyprlock" "false"
    fi

    if apply_dunst "$theme" 2>/dev/null; then
      applied+=("dunst")
      _print_app_status "dunst" "true"
    else
      skipped+=("dunst")
      _print_app_status "dunst" "false"
    fi

    if apply_rofi "$theme" 2>/dev/null; then
      applied+=("rofi")
      _print_app_status "rofi" "true"
    else
      skipped+=("rofi")
      _print_app_status "rofi" "false"
    fi
  fi

  # Windows Terminal (WSL only)
  if [[ "$platform" == "wsl" ]]; then
    if apply_windows_terminal "$theme" 2>/dev/null; then
      applied+=("windows-terminal")
      _print_app_status "windows-terminal" "true"
    else
      skipped+=("windows-terminal")
      _print_app_status "windows-terminal" "false"
    fi
  fi

  # Record current theme
  set_current_theme "$theme"

  # Return results
  echo "APPLIED:${applied[*]:-none}"
  echo "SKIPPED:${skipped[*]:-none}"
  echo "WALLPAPER:${wallpaper_id:-none}"
}

#==============================================================================
# UTILITY FUNCTIONS
#==============================================================================

format_duration() {
  local seconds="$1"

  if [[ "$seconds" -lt 60 ]]; then
    echo "${seconds}s"
  elif [[ "$seconds" -lt 3600 ]]; then
    local mins=$((seconds / 60))
    echo "${mins}m"
  elif [[ "$seconds" -lt 86400 ]]; then
    local hours=$((seconds / 3600))
    local mins=$(((seconds % 3600) / 60))
    if [[ "$mins" -gt 0 ]]; then
      echo "${hours}h ${mins}m"
    else
      echo "${hours}h"
    fi
  else
    local days=$((seconds / 86400))
    local hours=$(((seconds % 86400) / 3600))
    if [[ "$hours" -gt 0 ]]; then
      echo "${days}d ${hours}h"
    else
      echo "${days}d"
    fi
  fi
}

reload_tmux() {
  if command -v tmux &> /dev/null && tmux list-sessions &> /dev/null 2>&1; then
    tmux source-file ~/.config/tmux/tmux.conf 2>/dev/null || true
    return 0
  fi
  return 1
}

reload_kitty() {
  if command -v pkill &> /dev/null; then
    pkill -USR1 kitty 2>/dev/null || true
    return 0
  fi
  return 1
}

reload_hyprland() {
  if command -v hyprctl &> /dev/null; then
    hyprctl reload 2>/dev/null || true
    return 0
  fi
  return 1
}

reload_waybar() {
  if command -v killall &> /dev/null; then
    killall -SIGUSR2 waybar 2>/dev/null || true
    return 0
  fi
  return 1
}

reload_dunst() {
  if command -v killall &> /dev/null; then
    killall dunst 2>/dev/null || true
    # Dunst auto-restarts on next notification, or start it explicitly
    if command -v dunst &> /dev/null; then
      dunst &>/dev/null &
      disown
    fi
    return 0
  fi
  return 1
}

# Reload all applicable apps after theme apply
reload_apps() {
  local platform
  platform=$(detect_platform)
  local applied_apps="${1:-}"

  # tmux (all platforms)
  [[ "$applied_apps" == *"tmux"* ]] && reload_tmux

  # Platform-specific reloads
  if [[ "$platform" == "arch" ]]; then
    [[ "$applied_apps" == *"kitty"* ]] && reload_kitty
    [[ "$applied_apps" == *"hyprland"* ]] && reload_hyprland
    [[ "$applied_apps" == *"waybar"* ]] && reload_waybar
    [[ "$applied_apps" == *"dunst"* ]] && reload_dunst
    # btop requires manual restart
    # rofi loads theme on next launch
    # hyprlock loads theme on next lock
  fi
}

#==============================================================================
# PREVIEW IMAGE GENERATION
#==============================================================================

PREVIEW_CACHE_DIR="${PREVIEW_CACHE_DIR:-/tmp/theme-preview}"
PREVIEW_GENERATOR="$THEME_LIB_DIR/generators/preview.sh"

# Get cached preview path for a theme
get_cached_preview_path() {
  local theme_name="$1"
  local safe_name="${theme_name//[^a-zA-Z0-9-]/_}"
  echo "$PREVIEW_CACHE_DIR/${safe_name}.png"
}

# Generate a preview image for a theme
generate_theme_preview() {
  local theme_name="$1"
  local output_file="$2"
  local theme_dir="$THEMES_DIR/$theme_name"

  if [[ ! -d "$theme_dir" ]]; then
    echo "Error: Theme directory not found: $theme_dir" >&2
    return 1
  fi

  if [[ ! -f "$PREVIEW_GENERATOR" ]]; then
    echo "Error: Preview generator not found: $PREVIEW_GENERATOR" >&2
    return 1
  fi

  if ! command -v magick &>/dev/null; then
    echo "Error: ImageMagick not found" >&2
    return 1
  fi

  bash "$PREVIEW_GENERATOR" "$theme_dir" "$output_file"
}

# Get or generate a preview (uses cache)
get_or_generate_preview() {
  local theme_name="$1"
  local cache_file

  cache_file=$(get_cached_preview_path "$theme_name")

  mkdir -p "$PREVIEW_CACHE_DIR"

  if [[ -f "$cache_file" ]]; then
    echo "$cache_file"
    return 0
  fi

  if generate_theme_preview "$theme_name" "$cache_file" 2>/dev/null; then
    echo "$cache_file"
    return 0
  else
    return 1
  fi
}

# Validate a preview image file
validate_preview_image() {
  local image_file="$1"

  if [[ ! -f "$image_file" ]]; then
    echo "Error: File does not exist: $image_file" >&2
    return 1
  fi

  if [[ ! -s "$image_file" ]]; then
    echo "Error: File is empty: $image_file" >&2
    return 1
  fi

  local file_type
  file_type=$(file "$image_file")

  if [[ ! "$file_type" =~ PNG ]]; then
    echo "Error: Not a PNG image: $file_type" >&2
    return 1
  fi

  echo "$file_type"
  return 0
}

# Clear the preview cache
clear_preview_cache() {
  rm -rf "$PREVIEW_CACHE_DIR"
  mkdir -p "$PREVIEW_CACHE_DIR"
  echo "Preview cache cleared"
}

# Display theme details (for fzf preview header)
display_theme_details() {
  local theme_name="$1"
  local format="${2:-full}"
  local theme_file="$THEMES_DIR/$theme_name/theme.yml"

  if [[ ! -f "$theme_file" ]]; then
    echo "Theme not found: $theme_name"
    return 1
  fi

  local name author variant nvim_cs

  name=$(yq '.meta.display_name // "Unknown"' "$theme_file")
  author=$(yq '.meta.author // "Unknown"' "$theme_file")
  variant=$(yq '.meta.variant // "dark"' "$theme_file")
  nvim_cs=$(yq '.meta.neovim_colorscheme_name // .meta.id // "unknown"' "$theme_file")

  if [[ "$format" == "full" ]]; then
    echo "Theme: $name"
    echo "Author: $author"
    echo "Variant: $variant"
    echo "Neovim: $nvim_cs"
  else
    echo "$name by $author | $variant | nvim: $nvim_cs"
  fi
}

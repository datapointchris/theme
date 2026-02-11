#!/usr/bin/env bash
# Theme library - core functions for theme management
# Applies themes directly from themes/ directory

set -euo pipefail

THEME_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
THEME_APP_DIR="$(cd "$THEME_LIB_DIR/.." && pwd)"

# State directories:
# - THEME_LIVE_DIR: Always production - for files that apps watch (current theme, background)
# - THEME_STATE_DIR: Respects dev mode - for history files that shouldn't be polluted during dev
THEME_LIVE_DIR="$HOME/.local/state/theme"

if [[ "${THEME_ENV:-}" == "development" ]]; then
  THEME_STATE_DIR="$THEME_APP_DIR/.dev-data"
else
  THEME_STATE_DIR="$HOME/.local/state/theme"
fi

# Configuration - themes/ is the single source of truth
THEMES_DIR="$THEME_APP_DIR/themes"

# Live files - always in production so apps respond to changes
CURRENT_THEME_FILE="$THEME_LIVE_DIR/current"

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
      meta_name=$(yq -r '.meta.display_name // ""' "$theme_file" 2>/dev/null || echo "")
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

# Apply yazi theme (all platforms)
# Uses flavor system: copies to ~/.config/yazi/flavors/current.yazi/flavor.toml
apply_yazi() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/flavor.toml" ]]; then
    return 1
  fi

  local yazi_flavor_dir="$HOME/.config/yazi/flavors/current.yazi"
  mkdir -p "$yazi_flavor_dir"

  cp "$lib_path/flavor.toml" "$yazi_flavor_dir/flavor.toml"

  return 0
}

# Apply Firefox-based browser theme (all platforms)
# Copies userChrome.css to detected browser profiles
apply_firefox_based() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/userChrome.css" ]]; then
    return 1
  fi

  # Source browser profiles discovery
  local browser_profiles_lib="$THEME_LIB_DIR/browser-profiles.sh"
  if [[ ! -f "$browser_profiles_lib" ]]; then
    return 1
  fi
  source "$browser_profiles_lib"

  local applied=0
  local browsers=("zen" "librewolf" "firefox" "thunderbird")

  for browser in "${browsers[@]}"; do
    local profile
    if profile=$(find_browser_profile "$browser" 2>/dev/null); then
      local chrome_dir="$profile/chrome"
      mkdir -p "$chrome_dir"
      cp "$lib_path/userChrome.css" "$chrome_dir/userChrome.css"
      applied=$((applied + 1))
    fi
  done

  if [[ $applied -eq 0 ]]; then
    return 1
  fi

  return 0
}

# Apply bat syntax highlighter theme (all platforms)
# Copies .tmTheme to bat themes dir and rebuilds cache
apply_bat() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/bat.tmTheme" ]]; then
    return 1
  fi

  # Check if bat is installed
  if ! command -v bat &>/dev/null; then
    return 1
  fi

  local bat_themes_dir="$HOME/.config/bat/themes"
  mkdir -p "$bat_themes_dir"

  # Copy theme as "current.tmTheme" (mirrors ghostty/kitty pattern)
  # Bat config should have: --theme=current
  cp "$lib_path/bat.tmTheme" "$bat_themes_dir/current.tmTheme"

  # Rebuild bat cache to register the updated theme
  bat cache --build >/dev/null 2>&1 || true

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
WAYBAR_OPACITY_DIR="$HOME/.config/waybar/opacity"
WAYBAR_OPACITY_FILE="$WAYBAR_OPACITY_DIR/current.css"

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

# Get current opacity from waybar opacity config
get_waybar_opacity() {
  if [[ -f "$WAYBAR_OPACITY_FILE" ]]; then
    grep -E "^/\* opacity:" "$WAYBAR_OPACITY_FILE" 2>/dev/null | sed 's|.* opacity: \([0-9.]*\).*|\1|' || echo "1.0"
  else
    echo "1.0"
  fi
}

# Set waybar opacity
set_waybar_opacity() {
  local opacity="$1"
  mkdir -p "$WAYBAR_OPACITY_DIR"
  cat > "$WAYBAR_OPACITY_FILE" << EOF
/* Waybar opacity - managed by theme tool */
/* opacity: $opacity */
@define-color waybar-bg alpha(@bg, $opacity);
EOF

  # Reload waybar if running
  if pgrep -x waybar &>/dev/null; then
    killall -SIGUSR2 waybar 2>/dev/null || true
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

  # Apply to all terminals and waybar
  local applied=()

  set_ghostty_opacity "$new_opacity" && applied+=("ghostty")
  set_kitty_opacity "$new_opacity" && applied+=("kitty")
  set_windows_terminal_opacity "$new_opacity" && applied+=("windows-terminal")
  set_tmux_opacity "$new_opacity" && applied+=("tmux")
  set_waybar_opacity "$new_opacity" && applied+=("waybar")

  echo "$current → $new_opacity (${applied[*]})"
}

# Set opacity to an absolute value (0-100)
set_opacity() {
  local value="$1"

  # Validate input is a number between 0 and 100
  if ! [[ "$value" =~ ^[0-9]+$ ]] || [[ "$value" -lt 0 ]] || [[ "$value" -gt 100 ]]; then
    echo "Error: opacity must be a number between 0 and 100" >&2
    return 1
  fi

  local current
  current=$(get_current_opacity)

  # Convert 0-100 to 0.00-1.00
  local new_opacity
  new_opacity=$(awk "BEGIN {printf \"%.2f\", $value / 100}")

  # Apply to all terminals and waybar
  local applied=()

  set_ghostty_opacity "$new_opacity" && applied+=("ghostty")
  set_kitty_opacity "$new_opacity" && applied+=("kitty")
  set_windows_terminal_opacity "$new_opacity" && applied+=("windows-terminal")
  set_tmux_opacity "$new_opacity" && applied+=("tmux")
  set_waybar_opacity "$new_opacity" && applied+=("waybar")

  echo "$current → $new_opacity (${applied[*]})"
}

# Background cache directory
BACKGROUND_CACHE_DIR="${BACKGROUND_CACHE_DIR:-$HOME/.cache/theme/backgrounds}"

# Background sources config file (path references, not copies)
BACKGROUND_SOURCES_FILE="${BACKGROUND_SOURCES_FILE:-$HOME/.config/theme/background-sources.conf}"

# Current background tracking - always in production so background actually changes
BACKGROUND_CURRENT_FILE="$THEME_LIVE_DIR/background-current"

# Mode setting (which background types to include in rotation)
BACKGROUND_MODE_FILE="${BACKGROUND_MODE_FILE:-$HOME/.config/theme/background-mode}"

# All available generated styles (no source image needed)
BACKGROUND_GENERATED_STYLES=("plasma" "geometric" "hexagons" "circles" "swirl" "spotlight" "sphere" "spheres" "code" "banner")

# Source-based transform types (need source images like recolor)
BACKGROUND_SOURCE_TYPES=("recolor" "ascii" "lowpoly")

#==============================================================================
# BACKGROUND MODE MANAGEMENT
#==============================================================================

# List all available background modes/styles
list_available_background_modes() {
  for style in "${BACKGROUND_GENERATED_STYLES[@]}"; do
    echo "generated:$style"
  done
  for type in "${BACKGROUND_SOURCE_TYPES[@]}"; do
    echo "$type"
  done
}

# Get current background mode settings
# Returns: list of enabled modes, one per line, or "all" if not set
get_background_mode() {
  if [[ ! -f "$BACKGROUND_MODE_FILE" ]]; then
    echo "all"
    return
  fi

  local content
  content=$(cat "$BACKGROUND_MODE_FILE")

  if [[ -z "$content" ]]; then
    echo "all"
    return
  fi

  echo "$content"
}

# Set background mode to specific types
# Args: type1 [type2 ...]
# Special values: "all" enables everything
set_background_mode() {
  mkdir -p "$(dirname "$BACKGROUND_MODE_FILE")"

  if [[ "$1" == "all" ]]; then
    echo "all" > "$BACKGROUND_MODE_FILE"
    return
  fi

  : > "$BACKGROUND_MODE_FILE"
  for mode in "$@"; do
    echo "$mode" >> "$BACKGROUND_MODE_FILE"
  done
}

# Add a mode to current settings
add_background_mode() {
  local mode="$1"
  local current
  current=$(get_background_mode)

  if [[ "$current" == "all" ]]; then
    echo "Already set to 'all' - all modes enabled"
    return
  fi

  if echo "$current" | grep -qxF "$mode"; then
    echo "Mode already enabled: $mode"
    return
  fi

  mkdir -p "$(dirname "$BACKGROUND_MODE_FILE")"
  echo "$mode" >> "$BACKGROUND_MODE_FILE"
  echo "Added: $mode"
}

# Remove a mode from current settings
remove_background_mode() {
  local mode="$1"
  local current
  current=$(get_background_mode)

  if [[ "$current" == "all" ]]; then
    # Switch from "all" to explicit list minus the removed mode
    : > "$BACKGROUND_MODE_FILE"
    while IFS= read -r available; do
      [[ "$available" != "$mode" ]] && echo "$available" >> "$BACKGROUND_MODE_FILE"
    done < <(list_available_background_modes)
    echo "Removed: $mode (expanded from 'all')"
    return
  fi

  if ! echo "$current" | grep -qxF "$mode"; then
    echo "Mode not enabled: $mode"
    return
  fi

  { grep -vxF "$mode" "$BACKGROUND_MODE_FILE" || true; } > "${BACKGROUND_MODE_FILE}.tmp"
  mv "${BACKGROUND_MODE_FILE}.tmp" "$BACKGROUND_MODE_FILE"
  echo "Removed: $mode"
}

# Check if a background type is enabled by current mode
# Args: background_id (e.g., "generated:plasma" or "recolor:/path/to/file.jpg")
# Returns: 0 if enabled, 1 if not
is_background_type_enabled() {
  local background_id="$1"
  local current_mode
  current_mode=$(get_background_mode)

  if [[ "$current_mode" == "all" ]]; then
    return 0
  fi

  local bg_type="${background_id%%:*}"
  local bg_value="${background_id#*:}"

  if [[ "$bg_type" == "generated" ]]; then
    # Check exact match (generated:plasma) or category match (generated)
    if echo "$current_mode" | grep -qxF "generated:$bg_value"; then
      return 0
    fi
    if echo "$current_mode" | grep -qxF "generated"; then
      return 0
    fi
  else
    # Source-based types: recolor, ascii, lowpoly
    if echo "$current_mode" | grep -qxF "$bg_type"; then
      return 0
    fi
  fi

  return 1
}

# Check if a source-based type is enabled (recolor, ascii, lowpoly)
is_source_type_enabled() {
  local type="$1"
  local current_mode
  current_mode=$(get_background_mode)

  [[ "$current_mode" == "all" ]] && return 0
  echo "$current_mode" | grep -qxF "$type"
}

# Get list of enabled generated styles based on current mode
get_enabled_generated_styles() {
  local current_mode
  current_mode=$(get_background_mode)

  if [[ "$current_mode" == "all" ]]; then
    printf '%s\n' "${BACKGROUND_GENERATED_STYLES[@]}"
    return
  fi

  # Check for category "generated" (all generated styles)
  if echo "$current_mode" | grep -qxF "generated"; then
    printf '%s\n' "${BACKGROUND_GENERATED_STYLES[@]}"
    return
  fi

  # Check individual generated:style entries
  for style in "${BACKGROUND_GENERATED_STYLES[@]}"; do
    if echo "$current_mode" | grep -qxF "generated:$style"; then
      echo "$style"
    fi
  done
}

# Check if recolor mode is enabled
is_recolor_enabled() {
  local current_mode
  current_mode=$(get_background_mode)

  [[ "$current_mode" == "all" ]] && return 0
  echo "$current_mode" | grep -qxF "recolor"
}

#==============================================================================
# BACKGROUND SOURCE MANAGEMENT (path-based, no copying)
#==============================================================================

# Add a source path (file or directory) for background recoloring
# Stores path reference in background-sources.conf (no copying)
add_background_source() {
  local source_path="$1"

  if [[ ! -e "$source_path" ]]; then
    echo "Error: Path not found: $source_path" >&2
    return 1
  fi

  # Get absolute path
  local abs_path
  abs_path=$(cd "$(dirname "$source_path")" && pwd)/$(basename "$source_path")

  mkdir -p "$(dirname "$BACKGROUND_SOURCES_FILE")"

  if [[ -d "$abs_path" ]]; then
    # Directory source
    local prefix="dir:"
    local entry="${prefix}${abs_path}"

    # Check if already exists
    if [[ -f "$BACKGROUND_SOURCES_FILE" ]] && grep -qF "$entry" "$BACKGROUND_SOURCES_FILE" 2>/dev/null; then
      echo "Directory already added: $abs_path"
      return 0
    fi

    # Count images in directory
    local count
    count=$(find "$abs_path" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | wc -l | xargs)

    echo "$entry" >> "$BACKGROUND_SOURCES_FILE"
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
    if [[ -f "$BACKGROUND_SOURCES_FILE" ]] && grep -qF "$entry" "$BACKGROUND_SOURCES_FILE" 2>/dev/null; then
      echo "File already added: $abs_path"
      return 0
    fi

    echo "$entry" >> "$BACKGROUND_SOURCES_FILE"
    echo "Added file: $abs_path"
  fi
}

# List configured background sources (the config entries, not expanded images)
list_background_source_entries() {
  if [[ ! -f "$BACKGROUND_SOURCES_FILE" ]]; then
    return 0
  fi
  cat "$BACKGROUND_SOURCES_FILE"
}

# Expand all sources to actual image files (scans directories at runtime)
get_all_background_images() {
  if [[ ! -f "$BACKGROUND_SOURCES_FILE" ]]; then
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
  done < "$BACKGROUND_SOURCES_FILE"
}

# Remove a background source entry
remove_background_source() {
  local input="$1"

  if [[ ! -f "$BACKGROUND_SOURCES_FILE" ]]; then
    echo "Error: No sources configured" >&2
    return 1
  fi

  # Try exact match first (with prefix)
  if grep -qF "$input" "$BACKGROUND_SOURCES_FILE" 2>/dev/null; then
    { grep -vF "$input" "$BACKGROUND_SOURCES_FILE" || true; } > "${BACKGROUND_SOURCES_FILE}.tmp"
    mv "${BACKGROUND_SOURCES_FILE}.tmp" "$BACKGROUND_SOURCES_FILE"
    echo "Removed: $input"
    return 0
  fi

  # Try matching path without prefix
  local match
  match=$(grep -E "(file:|dir:).*${input}" "$BACKGROUND_SOURCES_FILE" 2>/dev/null | head -1 || true)
  if [[ -n "$match" ]]; then
    { grep -vF "$match" "$BACKGROUND_SOURCES_FILE" || true; } > "${BACKGROUND_SOURCES_FILE}.tmp"
    mv "${BACKGROUND_SOURCES_FILE}.tmp" "$BACKGROUND_SOURCES_FILE"
    echo "Removed: $match"
    return 0
  fi

  echo "Error: Source not found: $input" >&2
  return 1
}

# Verify all source paths exist and are readable
verify_background_sources() {
  if [[ ! -f "$BACKGROUND_SOURCES_FILE" ]]; then
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
  done < "$BACKGROUND_SOURCES_FILE"

  echo ""
  echo "Valid: $valid, Broken: $broken"
  [[ $broken -eq 0 ]]
}

# Remove broken source entries
clean_background_sources() {
  if [[ ! -f "$BACKGROUND_SOURCES_FILE" ]]; then
    echo "No sources configured."
    return 0
  fi

  local cleaned=0
  local temp_file="${BACKGROUND_SOURCES_FILE}.tmp"
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
  done < "$BACKGROUND_SOURCES_FILE"

  mv "$temp_file" "$BACKGROUND_SOURCES_FILE"
  echo ""
  echo "Cleaned $cleaned broken entries."
}

# Get a random source image (scans directories at runtime)
get_random_background_source() {
  local images=()

  while IFS= read -r img; do
    [[ -n "$img" ]] && images+=("$img")
  done < <(get_all_background_images)

  if [[ ${#images[@]} -eq 0 ]]; then
    return 1
  fi

  echo "${images[$((RANDOM % ${#images[@]}))]}"
}

# Get current background info
get_current_background() {
  if [[ -f "$BACKGROUND_CURRENT_FILE" ]]; then
    cat "$BACKGROUND_CURRENT_FILE"
  fi
}

# Set current background
set_current_background() {
  local background_id="$1"
  mkdir -p "$(dirname "$BACKGROUND_CURRENT_FILE")"
  echo "$background_id" > "$BACKGROUND_CURRENT_FILE"
}

# Set desktop wallpaper (platform-specific dispatcher)
set_desktop_wallpaper() {
  local background_file="$1"
  local platform
  platform=$(detect_platform)

  case "$platform" in
    macos)
      set_desktop_wallpaper_macos "$background_file"
      ;;
    arch)
      set_desktop_wallpaper_hyprland "$background_file"
      ;;
    wsl)
      set_desktop_wallpaper_wsl "$background_file"
      ;;
    *)
      echo "Warning: Background not supported on platform: $platform" >&2
      return 1
      ;;
  esac
}

# macOS: Set wallpaper via Finder AppleScript
set_desktop_wallpaper_macos() {
  local background_file="$1"
  osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$background_file\"" 2>/dev/null
}

# Arch/Hyprland: Set wallpaper via hyprpaper IPC
set_desktop_wallpaper_hyprland() {
  local background_file="$1"

  if ! pgrep -x hyprpaper &>/dev/null; then
    echo "Warning: hyprpaper not running" >&2
    return 1
  fi

  # Set wallpaper via IPC (hyprpaper 0.8+ only supports 'wallpaper' request)
  # Format: [monitor],[path],[fit_mode] - empty monitor = all monitors
  hyprctl hyprpaper wallpaper ",$background_file" 2>/dev/null || return 1

  # Also update stable path for hyprpaper config fallback on restart
  local stable_path="$HOME/.local/share/theme/background.png"
  cp "$background_file" "$stable_path" 2>/dev/null || true
}

# WSL: Set Windows wallpaper via PowerShell (experimental, may fail on restricted systems)
set_desktop_wallpaper_wsl() {
  local background_file="$1"

  # Get Windows username (may differ from Linux username)
  local win_user
  # shellcheck disable=SC2016  # $env:USERNAME is a PowerShell variable, not shell
  win_user=$(powershell.exe -NoProfile -Command 'Write-Host -NoNewline $env:USERNAME' 2>/dev/null | tr -d '\r')

  if [[ -z "$win_user" ]]; then
    echo "Warning: Could not determine Windows username" >&2
    return 1
  fi

  # Copy to Windows-accessible location
  local win_dir="/mnt/c/Users/$win_user/Pictures/theme"
  mkdir -p "$win_dir" 2>/dev/null || {
    echo "Warning: Could not create Windows directory: $win_dir" >&2
    return 1
  }

  local win_file="$win_dir/background.png"
  cp "$background_file" "$win_file" 2>/dev/null || {
    echo "Warning: Could not copy background to Windows path" >&2
    return 1
  }

  # Convert to Windows path format
  local win_path="C:\\Users\\$win_user\\Pictures\\theme\\background.png"

  # Set via PowerShell using SystemParametersInfo
  powershell.exe -NoProfile -Command "
    Add-Type -TypeDefinition '
    using System.Runtime.InteropServices;
    public class Wallpaper {
      public const int SPI_SETDESKWALLPAPER = 0x0014;
      public const int SPIF_UPDATEINIFILE = 0x01;
      public const int SPIF_SENDCHANGE = 0x02;
      [DllImport(\"user32.dll\", CharSet=CharSet.Auto)]
      static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
      public static void Set(string path) {
        SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, path, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
      }
    }';
    [Wallpaper]::Set('$win_path')
  " 2>/dev/null || {
    echo "Warning: PowerShell wallpaper command failed (may be restricted)" >&2
    return 1
  }
}

# Apply background
# Returns: background_id (e.g., "generated:plasma" or "recolor:/path/to/image.jpg")
apply_background() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/theme.yml" ]]; then
    return 1
  fi

  local background_dir="$HOME/.local/share/theme"
  mkdir -p "$background_dir"

  # Use unique filename to bypass macOS background cache
  local timestamp
  timestamp=$(date +%s)
  local background_file="$background_dir/background-${timestamp}.png"

  # Clean up old background files
  find "$background_dir" -name 'background-*.png' -mmin +1 -delete 2>/dev/null || true

  # Build list of available backgrounds based on mode settings
  local available=()
  local generators_dir
  generators_dir="$(dirname "${BASH_SOURCE[0]}")/generators"

  # Add enabled generated styles
  while IFS= read -r style; do
    [[ -n "$style" ]] && available+=("generated:$style")
  done < <(get_enabled_generated_styles)

  # Add source-based types if enabled and source images exist
  for source_type in "${BACKGROUND_SOURCE_TYPES[@]}"; do
    if is_source_type_enabled "$source_type"; then
      while IFS= read -r img; do
        [[ -n "$img" ]] && available+=("${source_type}:$img")
      done < <(get_all_background_images)
    fi
  done

  if [[ ${#available[@]} -eq 0 ]]; then
    echo "Error: No backgrounds available (check mode settings)" >&2
    return 1
  fi

  # Pick random from available
  local selected="${available[$((RANDOM % ${#available[@]}))]}"
  local bg_type="${selected%%:*}"
  local bg_value="${selected#*:}"
  local background_id=""

  case "$bg_type" in
    generated)
      # Check for special generators first
      case "$bg_value" in
        code)
          local code_gen="$generators_dir/background-code.sh"
          if [[ -f "$code_gen" ]]; then
            bash "$code_gen" "$lib_path/theme.yml" "$background_file" >/dev/null 2>&1 || return 1
          else
            return 1
          fi
          ;;
        banner)
          local banner_gen="$generators_dir/background-banner.sh"
          if [[ -f "$banner_gen" ]]; then
            bash "$banner_gen" "$lib_path/theme.yml" "$background_file" >/dev/null 2>&1 || return 1
          else
            return 1
          fi
          ;;
        *)
          # Standard ImageMagick styles
          local cache_file="$BACKGROUND_CACHE_DIR/$theme/${bg_value}.png"
          if [[ -f "$cache_file" ]]; then
            cp "$cache_file" "$background_file"
          else
            local generator_script="$generators_dir/background.sh"
            [[ ! -f "$generator_script" ]] && return 1
            bash "$generator_script" "$lib_path/theme.yml" "$background_file" "$bg_value" 1920 1080 >/dev/null 2>&1 || return 1
          fi
          ;;
      esac
      background_id="generated:$bg_value"
      ;;
    recolor)
      local gowall_gen="$generators_dir/background-gowall.sh"
      if [[ -f "$gowall_gen" ]]; then
        bash "$gowall_gen" "$lib_path/theme.yml" "$bg_value" "$background_file" >/dev/null 2>&1 || return 1
        background_id="recolor:$bg_value"
      else
        return 1
      fi
      ;;
    ascii)
      local ascii_gen="$generators_dir/background-ascii.sh"
      if [[ -f "$ascii_gen" ]]; then
        bash "$ascii_gen" "$lib_path/theme.yml" "$bg_value" "$background_file" >/dev/null 2>&1 || return 1
        background_id="ascii:$bg_value"
      else
        return 1
      fi
      ;;
    lowpoly)
      local lowpoly_gen="$generators_dir/background-lowpoly.sh"
      if [[ -f "$lowpoly_gen" ]]; then
        bash "$lowpoly_gen" "$lib_path/theme.yml" "$bg_value" "$background_file" >/dev/null 2>&1 || return 1
        background_id="lowpoly:$bg_value"
      else
        return 1
      fi
      ;;
    *)
      echo "Error: Unknown background type: $bg_type" >&2
      return 1
      ;;
  esac

  # Set as desktop background (platform-specific)
  set_desktop_wallpaper "$background_file" || return 1

  # Track current background
  set_current_background "$background_id"

  # Output the selected style for status display
  if [[ "$bg_type" == "generated" ]]; then
    echo "$bg_value"
  else
    echo "$bg_type ($(basename "$bg_value"))"
  fi
  return 0
}

# Rotate background without changing theme
# Selects a different background than current, applies it
# Args: [rejected_list] [weights_json]
#   rejected_list: newline-separated list of rejected background IDs
#   weights_json: JSON object mapping background ID to weight (default 1.0)
rotate_background() {
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

  local background_dir="$HOME/.local/share/theme"
  mkdir -p "$background_dir"

  local timestamp
  timestamp=$(date +%s)
  local background_file="$background_dir/background-${timestamp}.png"

  find "$background_dir" -name 'background-*.png' -mmin +1 -delete 2>/dev/null || true

  # Build list of available backgrounds, excluding current and rejected
  local current_background
  current_background=$(get_current_background)

  # Convert rejected list to associative array for O(1) lookup
  declare -A rejected_map
  if [[ -n "$rejected_list" ]]; then
    while IFS= read -r bg; do
      [[ -n "$bg" ]] && rejected_map["$bg"]=1
    done <<< "$rejected_list"
  fi

  local available=()
  local weights=()

  # Add enabled generated styles (respects mode setting)
  while IFS= read -r style; do
    [[ -z "$style" ]] && continue
    local bg_id="generated:$style"
    # Skip current and rejected
    [[ "$bg_id" == "$current_background" ]] && continue
    [[ -n "${rejected_map[$bg_id]:-}" ]] && continue
    available+=("$bg_id")
    # Get weight from JSON or default to 1
    local weight=1
    if [[ -n "$weights_json" ]]; then
      weight=$(echo "$weights_json" | jq -r --arg bg "$bg_id" '.[$bg] // 1')
    fi
    weights+=("$weight")
  done < <(get_enabled_generated_styles)

  # Add source-based types if enabled and source images exist
  for source_type in "${BACKGROUND_SOURCE_TYPES[@]}"; do
    if is_source_type_enabled "$source_type"; then
      while IFS= read -r img; do
        [[ -z "$img" ]] && continue
        local bg_id="${source_type}:$img"
        [[ "$bg_id" == "$current_background" ]] && continue
        [[ -n "${rejected_map[$bg_id]:-}" ]] && continue
        available+=("$bg_id")
        local weight=1
        if [[ -n "$weights_json" ]]; then
          weight=$(echo "$weights_json" | jq -r --arg bg "$bg_id" '.[$bg] // 1')
        fi
        weights+=("$weight")
      done < <(get_all_background_images)
    fi
  done

  if [[ ${#available[@]} -eq 0 ]]; then
    echo "Error: No alternative backgrounds available" >&2
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

  local bg_type="${selected%%:*}"
  local bg_value="${selected#*:}"
  local generators_dir
  generators_dir="$(dirname "${BASH_SOURCE[0]}")/generators"

  case "$bg_type" in
    generated)
      # Check for special generators first
      case "$bg_value" in
        code)
          local code_gen="$generators_dir/background-code.sh"
          if [[ -f "$code_gen" ]]; then
            bash "$code_gen" "$lib_path/theme.yml" "$background_file" >/dev/null 2>&1 || return 1
          else
            return 1
          fi
          ;;
        banner)
          local banner_gen="$generators_dir/background-banner.sh"
          if [[ -f "$banner_gen" ]]; then
            bash "$banner_gen" "$lib_path/theme.yml" "$background_file" >/dev/null 2>&1 || return 1
          else
            return 1
          fi
          ;;
        *)
          # Standard ImageMagick styles
          local cache_file="$BACKGROUND_CACHE_DIR/$theme/${bg_value}.png"
          if [[ -f "$cache_file" ]]; then
            cp "$cache_file" "$background_file"
          else
            local generator_script="$generators_dir/background.sh"
            [[ ! -f "$generator_script" ]] && return 1
            bash "$generator_script" "$lib_path/theme.yml" "$background_file" "$bg_value" 1920 1080 >/dev/null 2>&1 || return 1
          fi
          ;;
      esac
      ;;
    recolor)
      local gowall_gen="$generators_dir/background-gowall.sh"
      if [[ -f "$gowall_gen" ]]; then
        bash "$gowall_gen" "$lib_path/theme.yml" "$bg_value" "$background_file" >/dev/null 2>&1 || return 1
      else
        return 1
      fi
      ;;
    ascii)
      local ascii_gen="$generators_dir/background-ascii.sh"
      if [[ -f "$ascii_gen" ]]; then
        bash "$ascii_gen" "$lib_path/theme.yml" "$bg_value" "$background_file" >/dev/null 2>&1 || return 1
      else
        return 1
      fi
      ;;
    lowpoly)
      local lowpoly_gen="$generators_dir/background-lowpoly.sh"
      if [[ -f "$lowpoly_gen" ]]; then
        bash "$lowpoly_gen" "$lib_path/theme.yml" "$bg_value" "$background_file" >/dev/null 2>&1 || return 1
      else
        return 1
      fi
      ;;
    *)
      echo "Error: Unknown background type: $bg_type" >&2
      return 1
      ;;
  esac

  set_desktop_wallpaper "$background_file" || return 1

  set_current_background "$selected"

  # Output for display
  if [[ "$bg_type" == "generated" ]]; then
    echo "$bg_value"
  else
    echo "$bg_type ($(basename "$bg_value"))"
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

  # Background (macOS, Arch, WSL)
  local background_id=""
  if [[ "$platform" == "macos" ]] || [[ "$platform" == "arch" ]] || [[ "$platform" == "wsl" ]]; then
    local background_style
    if background_style=$(apply_background "$theme" 2>/dev/null); then
      applied+=("background")
      _print_app_status "background ($background_style)" "true"
      background_id=$(get_current_background)
    else
      skipped+=("background")
      _print_app_status "background" "false"
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

  # Yazi (all platforms)
  if apply_yazi "$theme" 2>/dev/null; then
    applied+=("yazi")
    _print_app_status "yazi" "true"
  else
    skipped+=("yazi")
    _print_app_status "yazi" "false"
  fi

  # Firefox-based browsers (all platforms)
  if apply_firefox_based "$theme" 2>/dev/null; then
    applied+=("browsers")
    _print_app_status "browsers" "true"
  else
    skipped+=("browsers")
    _print_app_status "browsers" "false"
  fi

  # bat syntax highlighter (all platforms)
  if apply_bat "$theme" 2>/dev/null; then
    applied+=("bat")
    _print_app_status "bat" "true"
  else
    skipped+=("bat")
    _print_app_status "bat" "false"
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
  echo "BACKGROUND:${background_id:-none}"
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

  if ! command -v convert &>/dev/null; then
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

# Display theme details with stats and history
display_theme_details() {
  local theme="$1"
  local format="${2:-full}"

  # Source storage.sh if needed (for preview script)
  if ! type -t get_theme_stats &>/dev/null; then
    source "$APP_DIR/lib/storage.sh" 2>/dev/null || true
  fi

  # Get display info
  local display_info
  display_info=$(get_theme_display_info "$theme")

  if [[ "$format" == "full" ]]; then
    echo ""
    echo "Current Theme: $display_info"
    echo "           ID: $theme"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
  else
    echo "━━━ $display_info ━━━"
  fi

  # Get stats from history
  if type -t get_theme_stats &>/dev/null; then
    local stats
    stats=$(get_theme_stats "$theme" 2>/dev/null)

    if [[ -n "$stats" ]] && [[ "$stats" != "null" ]] && [[ "$stats" != "{}" ]]; then
      local score=$(echo "$stats" | jq -r '.score // 0')
      local likes=$(echo "$stats" | jq -r '.likes // 0')
      local dislikes=$(echo "$stats" | jq -r '.dislikes // 0')
      local notes=$(echo "$stats" | jq -r '.notes // 0')
      local applies=$(echo "$stats" | jq -r '.applies // 0')
      local platforms=$(echo "$stats" | jq -r '.platforms | join(", ") // "none"')

      # Calculate usage time
      local usage_time="not used"
      if type -t calculate_usage_time &>/dev/null; then
        local current_theme
        current_theme=$(get_current_theme 2>/dev/null || echo "")
        local usage_times
        usage_times=$(calculate_usage_time "$current_theme")
        local usage_seconds=$(echo "$usage_times" | jq -r --arg theme "$theme" '.[$theme] // 0')
        if [[ "$usage_seconds" -gt 0 ]] && type -t format_duration &>/dev/null; then
          usage_time=$(format_duration "$usage_seconds")
        fi
      fi

      if [[ "$format" == "full" ]]; then
        echo "Stats:"
        printf "  Score: %+d (%d likes, %d dislikes)\n" "$score" "$likes" "$dislikes"
        printf "  Usage time: %s\n" "$usage_time"
        printf "  Notes: %d\n" "$notes"
        printf "  Times applied: %d\n" "$applies"
        printf "  Platforms: %s\n" "$platforms"
        local machines=$(echo "$stats" | jq -r '.machines | join(", ") // "unknown"')
        printf "  Machines: %s\n" "$machines"

        # Show history for this theme (tells the story)
        if type -t get_history &>/dev/null; then
          local history_count
          history_count=$(get_history | jq --arg theme "$theme" '[.[] | select(.theme == $theme)] | length')
          if [[ "$history_count" -gt 0 ]]; then
            echo ""
            echo "History:"
            get_history | jq -r --arg theme "$theme" '
              map(select(.theme == $theme)) |
              sort_by(.ts) |
              .[] |
              .action as $act |
              .ts[0:10] as $date |
              .message as $msg |
              if $act == "apply" then
                "  \($date)  applied"
              elif $act == "like" then
                if $msg then "  \($date)  liked: \($msg)" else "  \($date)  liked" end
              elif $act == "dislike" then
                if $msg then "  \($date)  disliked: \($msg)" else "  \($date)  disliked" end
              elif $act == "note" then
                "  \($date)  note: \($msg)"
              elif $act == "reject" then
                "  \($date)  rejected: \($msg)"
              elif $act == "unreject" then
                "  \($date)  unrejected"
              else
                "  \($date)  \($act)"
              end
            ' 2>/dev/null
          fi
        fi

        # Show app configs
        echo ""
        echo "App Configs:"
        local theme_dir="$THEMES_DIR/$theme"
        local theme_file="$theme_dir/theme.yml"

        # Check which config files exist
        local configs=""
        [[ -f "$theme_dir/ghostty.conf" ]] && configs+="Ghostty "
        [[ -f "$theme_dir/kitty.conf" ]] && configs+="Kitty "
        [[ -f "$theme_dir/tmux.conf" ]] && configs+="tmux "
        [[ -f "$theme_dir/btop.theme" ]] && configs+="btop "
        [[ -f "$theme_dir/bordersrc" ]] && configs+="JankyBorders "
        [[ -f "$theme_dir/hyprland.conf" ]] && configs+="Hyprland "
        [[ -f "$theme_dir/waybar.css" ]] && configs+="Waybar "
        [[ -f "$theme_dir/windows-terminal.json" ]] && configs+="WindowsTerminal "
        [[ -d "$theme_dir/neovim" ]] && configs+="Neovim(generated) "
        echo "  Available: ${configs:-none}"

        # Show Neovim colorscheme info
        if [[ -f "$theme_file" ]]; then
          local nvim_name nvim_source plugin_repo
          nvim_name=$(yq -r '.meta.neovim_colorscheme_name // .meta.id' "$theme_file")
          nvim_source=$(yq -r '.meta.neovim_colorscheme_source // "unknown"' "$theme_file")
          plugin_repo=$(yq -r '.meta.plugin // ""' "$theme_file")
          echo "  Neovim colorscheme: $nvim_name ($nvim_source)"
          [[ -n "$plugin_repo" && "$plugin_repo" != "null" ]] && echo "  Plugin: $plugin_repo"
        fi
      else
        # Compact format for preview
        printf "Score: %+d (%d↑ %d↓)" "$score" "$likes" "$dislikes"
        printf " | Used: %s" "$usage_time"
        echo ""
      fi
    fi
  fi
}

#!/usr/bin/env bash
# Generate a Hyprland Lua theme module from theme.yml
# Usage: hyprland.sh <theme.yml> [output-file]
#
# Enhanced generator using FULL color palette:
# - Active borders use accent color (base0D blue)
# - Inactive borders use subtle color (base02)
# - Group colors use distinct accents
# - The module returns the whole palette, so a config can reuse any color

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../theme.sh"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <theme.yml> [output-file]"
  exit 1
fi

input_file="$1"
output_file="${2:-}"

# Load palette into variables
eval "$(load_colors "$input_file")"

# Use extended palette colors when available, fall back to base16
UI_ACCENT="${EXTENDED_UI_ACCENT:-$BASE0D}"
UI_BORDER="${EXTENDED_UI_BORDER:-$BASE02}"

# Convert #RRGGBB to RRGGBB for hyprland rgb() format
strip_hash() {
  echo "${1#\#}"
}

generate() {
  cat <<EOF
-- ${THEME_NAME} - hyprland theme
-- Generated from theme.yml
-- Author: ${THEME_AUTHOR}
--
-- Applied as ~/.config/hypr/themes/current.lua, which a Hyprland config loads
-- with require('themes.current') after its own colors so these win.

local palette = {
  -- Base16
  base00 = 'rgb($(strip_hash "$BASE00"))', -- Main background
  base01 = 'rgb($(strip_hash "$BASE01"))', -- Lighter background
  base02 = 'rgb($(strip_hash "$BASE02"))', -- Selection
  base03 = 'rgb($(strip_hash "$BASE03"))', -- Comments
  base04 = 'rgb($(strip_hash "$BASE04"))', -- Dark foreground
  base05 = 'rgb($(strip_hash "$BASE05"))', -- Foreground
  base06 = 'rgb($(strip_hash "$BASE06"))', -- Light foreground
  base07 = 'rgb($(strip_hash "$BASE07"))', -- Brightest
  base08 = 'rgb($(strip_hash "$BASE08"))', -- Red
  base09 = 'rgb($(strip_hash "$BASE09"))', -- Orange
  base0A = 'rgb($(strip_hash "$BASE0A"))', -- Yellow
  base0B = 'rgb($(strip_hash "$BASE0B"))', -- Green
  base0C = 'rgb($(strip_hash "$BASE0C"))', -- Cyan
  base0D = 'rgb($(strip_hash "$BASE0D"))', -- Blue
  base0E = 'rgb($(strip_hash "$BASE0E"))', -- Magenta
  base0F = 'rgb($(strip_hash "$BASE0F"))', -- Brown

  -- Extended palette (when available)
  uiAccent = 'rgb($(strip_hash "$UI_ACCENT"))',
  uiBorder = 'rgb($(strip_hash "$UI_BORDER"))',
}

hl.config({
  -- Window borders
  general = {
    col = {
      active_border = palette.uiAccent,
      inactive_border = palette.uiBorder,
    },
  },

  -- Group borders
  group = {
    col = {
      border_active = palette.base0E,
      border_inactive = palette.base03,
      border_locked_active = palette.base09,
      border_locked_inactive = palette.base01,
    },
  },
})

return palette
EOF
}

if [[ -n "$output_file" ]]; then
  generate >"$output_file"
  echo "Generated: $output_file"
else
  generate
fi

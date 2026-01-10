#!/usr/bin/env bash
# Generate JankyBorders/SketchyBorders config from theme.yml
# Usage: borders.sh <theme.yml> [output-file]
#
# macOS window border styling using full color palette:
# - Active borders use accent color (base0D blue)
# - Inactive borders use subtle color (base02)
#
# Color format: 0xAARRGGBB (alpha, red, green, blue)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../theme.sh"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <theme.yml> [output-file]"
  exit 1
fi

input_file="$1"
output_file="${2:-}"

eval "$(load_colors "$input_file")"

# Use extended palette colors when available, fall back to base16
UI_ACCENT="${EXTENDED_UI_ACCENT:-$BASE0D}"
UI_BORDER="${EXTENDED_UI_BORDER:-$BASE02}"

# Convert #RRGGBB to 0xAARRGGBB format
hex_to_argb() {
  local hex="$1"
  local alpha="${2:-ff}"
  hex="${hex#\#}"
  echo "0x${alpha}${hex}"
}

generate() {
  cat << EOF
#!/bin/bash
# ${THEME_NAME} - JankyBorders theme
# Generated from theme.yml
# Author: ${THEME_AUTHOR}

options=(
  style=round
  width=8.0
  hidpi=on

  # Active window - use UI accent color
  active_color=$(hex_to_argb "$UI_ACCENT")

  # Inactive windows - use UI border color
  inactive_color=$(hex_to_argb "$UI_BORDER")

  # Glow effect using accent color
  active_color='glow($(hex_to_argb "$UI_ACCENT"))'

  blacklist="System Settings|System Information|QuickTime Player"
)

borders "\${options[@]}"
EOF
}

if [[ -n "$output_file" ]]; then
  generate > "$output_file"
  chmod +x "$output_file"
  echo "Generated: $output_file"
else
  generate
fi

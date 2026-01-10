#!/usr/bin/env bash
# Generate btop theme from theme.yml or palette.yml
# Usage: btop.sh <theme.yml|palette.yml> [output-file]
#
# Enhanced generator using FULL color palette:
# - All 16 base16 colors utilized
# - Extended palette fields when available (diagnostic_*, ui_*)
# - Semantic color choices for meters and graphs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../theme.sh"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <theme.yml|palette.yml> [output-file]"
  exit 1
fi

input_file="$1"
output_file="${2:-}"

# Load colors (auto-detects format)
eval "$(load_colors "$input_file")"

# Use extended palette colors when available, fall back to base16
# This ensures author-intended colors are used (e.g., brighter reds for errors in kanagawa)
DIAG_ERROR="${EXTENDED_DIAGNOSTIC_ERROR:-$BASE08}"
DIAG_WARNING="${EXTENDED_DIAGNOSTIC_WARNING:-$BASE09}"
DIAG_INFO="${EXTENDED_DIAGNOSTIC_INFO:-$BASE0D}"
DIAG_OK="${EXTENDED_DIAGNOSTIC_OK:-$BASE0B}"
UI_ACCENT="${EXTENDED_UI_ACCENT:-$BASE0D}"
UI_SELECTION="${EXTENDED_UI_SELECTION:-$BASE02}"
UI_BORDER="${EXTENDED_UI_BORDER:-$BASE01}"

# btop needs uppercase hex colors
generate() {
  cat << EOF
# ${THEME_NAME} - btop theme
# Generated from theme.yml
# Author: ${THEME_AUTHOR}

# Main background, empty for terminal default
theme[main_bg]="$(to_upper "$BASE00")"

# Main text color
theme[main_fg]="$(to_upper "$BASE05")"

# Title color for boxes - use accent color
theme[title]="$(to_upper "$BASE0C")"

# Highlight color for keyboard shortcuts - use UI accent
theme[hi_fg]="$(to_upper "$UI_ACCENT")"

# Background color of selected item in processes box - use UI selection
theme[selected_bg]="$(to_upper "$UI_SELECTION")"

# Foreground color of selected item in processes box
theme[selected_fg]="$(to_upper "$BASE06")"

# Color of inactive/disabled text
theme[inactive_fg]="$(to_upper "$BASE03")"

# Misc colors for processes box
theme[proc_misc]="$(to_upper "$UI_ACCENT")"

# Box outline colors - use UI border
theme[cpu_box]="$(to_upper "$UI_BORDER")"
theme[mem_box]="$(to_upper "$UI_BORDER")"
theme[net_box]="$(to_upper "$UI_BORDER")"
theme[proc_box]="$(to_upper "$UI_BORDER")"
theme[div_line]="$(to_upper "$UI_BORDER")"

# Temperature graph colors (gradient: info -> warning -> error for heat)
theme[temp_start]="$(to_upper "$DIAG_INFO")"
theme[temp_mid]="$(to_upper "$DIAG_WARNING")"
theme[temp_end]="$(to_upper "$DIAG_ERROR")"

# CPU graph colors (gradient: info -> accent -> bright)
theme[cpu_start]="$(to_upper "$DIAG_INFO")"
theme[cpu_mid]="$(to_upper "$BASE0C")"
theme[cpu_end]="$(to_upper "$BASE06")"

# Memory free meter (green = good/available)
theme[free_start]="$(to_upper "$DIAG_OK")"
theme[free_mid]="$(to_upper "$BASE0C")"
theme[free_end]="$(to_upper "$BASE06")"

# Memory cached meter (yellow/orange = cached/warning)
theme[cached_start]="$(to_upper "$BASE0A")"
theme[cached_mid]="$(to_upper "$DIAG_WARNING")"
theme[cached_end]="$(to_upper "$BASE06")"

# Memory available meter (blue = info/available)
theme[available_start]="$(to_upper "$DIAG_INFO")"
theme[available_mid]="$(to_upper "$BASE0C")"
theme[available_end]="$(to_upper "$BASE06")"

# Memory used meter (gradient: warning -> error as usage increases)
theme[used_start]="$(to_upper "$DIAG_WARNING")"
theme[used_mid]="$(to_upper "$DIAG_ERROR")"
theme[used_end]="$(to_upper "$BASE0A")"

# Download graph colors (green = incoming/good)
theme[download_start]="$(to_upper "$DIAG_OK")"
theme[download_mid]="$(to_upper "$BASE0C")"
theme[download_end]="$(to_upper "$BASE06")"

# Upload graph colors (magenta/purple for outgoing)
theme[upload_start]="$(to_upper "$BASE0E")"
theme[upload_mid]="$(to_upper "$UI_ACCENT")"
theme[upload_end]="$(to_upper "$BASE06")"

# Process tree colors
theme[process_start]="$(to_upper "$UI_ACCENT")"
theme[process_mid]="$(to_upper "$BASE0F")"
theme[process_end]="$(to_upper "$DIAG_ERROR")"

# Meter background
theme[meter_bg]="$(to_upper "$BASE04")"

# Graph text (brightest for readability)
theme[graph_text]="$(to_upper "$BASE07")"
EOF
}

if [[ -n "$output_file" ]]; then
  generate > "$output_file"
  echo "Generated: $output_file"
else
  generate
fi

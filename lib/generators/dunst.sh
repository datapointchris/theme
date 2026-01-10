#!/usr/bin/env bash
# Generate dunst notification color config from theme.yml
# Usage: dunst.sh <theme.yml> [output-file]
#
# Enhanced generator using FULL color palette:
# - Semantic colors for urgency levels
# - Distinct frame colors using base16 accents
# - Highlight colors for emphasis
#
# Applied via drop-in: ~/.config/dunst/dunstrc.d/99-theme.conf

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
DIAG_ERROR="${EXTENDED_DIAGNOSTIC_ERROR:-$BASE08}"
DIAG_INFO="${EXTENDED_DIAGNOSTIC_INFO:-$BASE0D}"
DIAG_HINT="${EXTENDED_DIAGNOSTIC_HINT:-$BASE0C}"
UI_ACCENT="${EXTENDED_UI_ACCENT:-$BASE0D}"
UI_BORDER="${EXTENDED_UI_BORDER:-$BASE02}"

generate() {
  cat << EOF
# ${THEME_NAME} - Dunst notification colors
# Generated from theme.yml
# Author: ${THEME_AUTHOR}

[global]
    # Separator between notifications - use UI border color
    separator_color = "${UI_BORDER}"

    # Progress bar colors - use accent
    highlight = "${UI_ACCENT}"

[urgency_low]
    # Low priority - subtle hint color
    background = "${BASE00}"
    foreground = "${BASE04}"
    frame_color = "${DIAG_HINT}"
    highlight = "${DIAG_HINT}"
    timeout = 5

[urgency_normal]
    # Normal priority - info/accent color
    background = "${BASE00}"
    foreground = "${BASE05}"
    frame_color = "${DIAG_INFO}"
    highlight = "${DIAG_INFO}"
    timeout = 10

[urgency_critical]
    # Critical priority - error color for maximum visibility
    background = "${BASE01}"
    foreground = "${BASE07}"
    frame_color = "${DIAG_ERROR}"
    highlight = "${DIAG_ERROR}"
    timeout = 0
EOF
}

if [[ -n "$output_file" ]]; then
  generate > "$output_file"
  echo "Generated: $output_file"
else
  generate
fi

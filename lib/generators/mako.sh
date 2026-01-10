#!/usr/bin/env bash
# Generate mako notification daemon theme from theme.yml
# Usage: mako.sh <theme.yml> [output-file]
#
# Enhanced generator using FULL color palette:
# - Urgency-based colors using base16 accents
# - Progress bar colors
# - Border colors per urgency level
#
# Mako uses INI format with hex colors

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

generate() {
  cat << EOF
# ${THEME_NAME} - Mako notification colors
# Generated from theme.yml
# Author: ${THEME_AUTHOR}

# Default colors - use info/accent for normal state
text-color=${BASE05}
background-color=${BASE00}
border-color=${DIAG_INFO}
progress-color=over ${UI_ACCENT}

# Low urgency - subtle hint color
[urgency=low]
text-color=${BASE04}
background-color=${BASE00}
border-color=${DIAG_HINT}

# Normal urgency - info/accent color
[urgency=normal]
text-color=${BASE05}
background-color=${BASE00}
border-color=${DIAG_INFO}

# Critical urgency - error color for maximum visibility
[urgency=critical]
text-color=${BASE07}
background-color=${BASE01}
border-color=${DIAG_ERROR}
EOF
}

if [[ -n "$output_file" ]]; then
  generate > "$output_file"
  echo "Generated: $output_file"
else
  generate
fi

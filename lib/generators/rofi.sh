#!/usr/bin/env bash
# Generate rofi color theme from theme.yml
# Usage: rofi.sh <theme.yml> [output-file]
#
# Enhanced generator using FULL color palette:
# - All 16 base16 colors
# - All ANSI colors for accent variety
# - Semantic aliases for easy styling
#
# Import in rofi config with: @import "themes/current.rasi"

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
DIAG_OK="${EXTENDED_DIAGNOSTIC_OK:-$BASE0B}"
UI_ACCENT="${EXTENDED_UI_ACCENT:-$BASE0D}"
UI_BORDER="${EXTENDED_UI_BORDER:-$SPECIAL_BORDER}"

generate() {
  cat << EOF
/* ${THEME_NAME} - Rofi colors */
/* Generated from theme.yml */
/* Author: ${THEME_AUTHOR} */

* {
    /* Base16 palette */
    base00: ${BASE00};  /* Main background */
    base01: ${BASE01};  /* Lighter background */
    base02: ${BASE02};  /* Selection background */
    base03: ${BASE03};  /* Comments, muted */
    base04: ${BASE04};  /* Dark foreground */
    base05: ${BASE05};  /* Default foreground */
    base06: ${BASE06};  /* Light foreground */
    base07: ${BASE07};  /* Brightest foreground */
    base08: ${BASE08};  /* Red */
    base09: ${BASE09};  /* Orange */
    base0A: ${BASE0A};  /* Yellow */
    base0B: ${BASE0B};  /* Green */
    base0C: ${BASE0C};  /* Cyan */
    base0D: ${BASE0D};  /* Blue */
    base0E: ${BASE0E};  /* Magenta */
    base0F: ${BASE0F};  /* Brown */

    /* Semantic colors */
    bg: ${SPECIAL_BG};
    bg-alt: ${BASE01};
    bg-selected: ${SPECIAL_SELECTION_BG};
    fg: ${SPECIAL_FG};
    fg-alt: ${BASE04};
    fg-muted: ${BASE03};
    fg-bright: ${BASE06};
    border: ${UI_BORDER};

    /* Status colors - use extended diagnostic colors when available */
    urgent: ${DIAG_ERROR};
    active: ${DIAG_OK};
    selected: ${UI_ACCENT};

    /* Named accent colors */
    red: ${ANSI_RED};
    green: ${ANSI_GREEN};
    yellow: ${ANSI_YELLOW};
    blue: ${ANSI_BLUE};
    magenta: ${ANSI_MAGENTA};
    cyan: ${ANSI_CYAN};
    orange: ${BASE09};

    /* Bright variants */
    bright-red: ${ANSI_BRIGHT_RED};
    bright-green: ${ANSI_BRIGHT_GREEN};
    bright-yellow: ${ANSI_BRIGHT_YELLOW};
    bright-blue: ${ANSI_BRIGHT_BLUE};
    bright-magenta: ${ANSI_BRIGHT_MAGENTA};
    bright-cyan: ${ANSI_BRIGHT_CYAN};
}
EOF
}

if [[ -n "$output_file" ]]; then
  generate > "$output_file"
  echo "Generated: $output_file"
else
  generate
fi

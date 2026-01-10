#!/usr/bin/env bash
# Generate waybar CSS from theme.yml
# Usage: waybar.sh <theme.yml> [output-file]
#
# Enhanced generator using FULL color palette:
# - All 16 base16 colors as CSS variables
# - All ANSI colors for accent variety
# - Special colors for backgrounds and selection

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
DIAG_ERROR="${EXTENDED_DIAGNOSTIC_ERROR:-$BASE08}"
DIAG_WARNING="${EXTENDED_DIAGNOSTIC_WARNING:-$BASE09}"
DIAG_INFO="${EXTENDED_DIAGNOSTIC_INFO:-$BASE0D}"
DIAG_OK="${EXTENDED_DIAGNOSTIC_OK:-$BASE0B}"
UI_BORDER="${EXTENDED_UI_BORDER:-$SPECIAL_BORDER}"

generate() {
  cat << EOF
/* ${THEME_NAME} - waybar theme */
/* Generated from theme.yml */
/* Author: ${THEME_AUTHOR} */

/* =============================================================================
   BASE16 PALETTE
   ============================================================================= */

/* Background tones */
@define-color base00 ${BASE00};  /* Main background */
@define-color base01 ${BASE01};  /* Lighter background */
@define-color base02 ${BASE02};  /* Selection background */

/* Foreground tones */
@define-color base03 ${BASE03};  /* Comments, muted */
@define-color base04 ${BASE04};  /* Dark foreground */
@define-color base05 ${BASE05};  /* Default foreground */
@define-color base06 ${BASE06};  /* Light foreground */
@define-color base07 ${BASE07};  /* Brightest foreground */

/* Accent colors */
@define-color base08 ${BASE08};  /* Red */
@define-color base09 ${BASE09};  /* Orange */
@define-color base0A ${BASE0A};  /* Yellow */
@define-color base0B ${BASE0B};  /* Green */
@define-color base0C ${BASE0C};  /* Cyan */
@define-color base0D ${BASE0D};  /* Blue */
@define-color base0E ${BASE0E};  /* Magenta */
@define-color base0F ${BASE0F};  /* Brown */

/* =============================================================================
   SEMANTIC ALIASES
   ============================================================================= */

/* Backgrounds */
@define-color bg ${SPECIAL_BG};
@define-color bg-dark ${BASE01};
@define-color bg-highlight ${BASE02};
@define-color bg-selection ${SPECIAL_SELECTION_BG};

/* Foregrounds */
@define-color fg ${SPECIAL_FG};
@define-color fg-dark ${BASE04};
@define-color fg-muted ${BASE03};
@define-color fg-bright ${BASE06};

/* Status colors - use extended diagnostic colors when available */
@define-color success ${DIAG_OK};
@define-color warning ${DIAG_WARNING};
@define-color error ${DIAG_ERROR};
@define-color info ${DIAG_INFO};

/* Named accent colors */
@define-color red ${ANSI_RED};
@define-color green ${ANSI_GREEN};
@define-color yellow ${ANSI_YELLOW};
@define-color blue ${ANSI_BLUE};
@define-color magenta ${ANSI_MAGENTA};
@define-color cyan ${ANSI_CYAN};
@define-color orange ${BASE09};

/* Bright variants */
@define-color bright-red ${ANSI_BRIGHT_RED};
@define-color bright-green ${ANSI_BRIGHT_GREEN};
@define-color bright-yellow ${ANSI_BRIGHT_YELLOW};
@define-color bright-blue ${ANSI_BRIGHT_BLUE};
@define-color bright-magenta ${ANSI_BRIGHT_MAGENTA};
@define-color bright-cyan ${ANSI_BRIGHT_CYAN};

/* Border - use extended UI border when available */
@define-color border ${UI_BORDER};
EOF
}

if [[ -n "$output_file" ]]; then
  generate > "$output_file"
  echo "Generated: $output_file"
else
  generate
fi

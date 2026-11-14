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
source "$SCRIPT_DIR/../contrast.sh"

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

# Every waybar module is a pill on bg-highlight with fg or an accent as its text.
# base02 is tuned as a selection under the theme's text, not under its accents,
# and some palettes put it near mid-grey, where no saturated red reaches 4.5:1.
# So the pill keeps base02 up to 1.45:1 over bg, the median across the themes,
# and is blended toward bg beyond it. Each color drawn on it is then solved.
PILL="$(band "$BASE02" "$SPECIAL_BG" 1.45 1)"

# Starts from whichever variant already reads higher on the pill, so the push
# toward white is the smallest the palette allows.
pill_text() {
  local start="$1" other
  for other in "${@:2}"; do
    if awk -v a="$(contrast_ratio "$other" "$PILL")" -v b="$(contrast_ratio "$start" "$PILL")" 'BEGIN { exit !(a > b) }'; then
      start="$other"
    fi
  done
  legible "$start" "$PILL" 4.5
}

PILL_FG="$(pill_text "$SPECIAL_FG")"
PILL_FG_DARK="$(pill_text "$BASE04")"
PILL_RED="$(pill_text "$ANSI_RED" "$ANSI_BRIGHT_RED")"
PILL_GREEN="$(pill_text "$ANSI_GREEN" "$ANSI_BRIGHT_GREEN")"
PILL_YELLOW="$(pill_text "$ANSI_YELLOW" "$ANSI_BRIGHT_YELLOW")"
PILL_BLUE="$(pill_text "$ANSI_BLUE" "$ANSI_BRIGHT_BLUE")"
PILL_MAGENTA="$(pill_text "$ANSI_MAGENTA" "$ANSI_BRIGHT_MAGENTA")"
PILL_CYAN="$(pill_text "$ANSI_CYAN" "$ANSI_BRIGHT_CYAN")"
PILL_ORANGE="$(pill_text "$BASE09")"

generate() {
  cat <<EOF
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
@define-color bg-highlight ${PILL};  /* Pill: base02, held near bg */
@define-color bg-selection ${SPECIAL_SELECTION_BG};

/* Foregrounds, each at 4.5:1 or more on bg-highlight */
@define-color fg ${PILL_FG};
@define-color fg-dark ${PILL_FG_DARK};
@define-color fg-muted ${BASE03};
@define-color fg-bright ${BASE06};

/* Status colors - use extended diagnostic colors when available */
@define-color success ${DIAG_OK};
@define-color warning ${DIAG_WARNING};
@define-color error ${DIAG_ERROR};
@define-color info ${DIAG_INFO};

/* Named accent colors, each at 4.5:1 or more on bg-highlight */
@define-color red ${PILL_RED};
@define-color green ${PILL_GREEN};
@define-color yellow ${PILL_YELLOW};
@define-color blue ${PILL_BLUE};
@define-color magenta ${PILL_MAGENTA};
@define-color cyan ${PILL_CYAN};
@define-color orange ${PILL_ORANGE};

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
  generate >"$output_file"
  echo "Generated: $output_file"
else
  generate
fi

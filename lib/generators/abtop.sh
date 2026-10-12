#!/usr/bin/env bash
# Generate an abtop theme from theme.yml or palette.yml
# Usage: abtop.sh <theme.yml|palette.yml> [output-file]
#
# abtop reads btop's theme format, but paints the keys in its own roles:
# graph_text is most label text, proc_misc marks a thinking session, and the
# cpu and process gradients color context-window and quota fill by severity.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../theme.sh"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <theme.yml|palette.yml> [output-file]"
  exit 1
fi

input_file="$1"
output_file="${2:-}"

eval "$(load_colors "$input_file")"

DIAG_ERROR="${EXTENDED_DIAGNOSTIC_ERROR:-$BASE08}"
DIAG_WARNING="${EXTENDED_DIAGNOSTIC_WARNING:-$BASE09}"
DIAG_OK="${EXTENDED_DIAGNOSTIC_OK:-$BASE0B}"
UI_ACCENT="${EXTENDED_UI_ACCENT:-$BASE0D}"
UI_SELECTION="${EXTENDED_UI_SELECTION:-$BASE02}"
UI_BORDER="${EXTENDED_UI_BORDER:-$BASE01}"

generate() {
  cat <<EOF
# ${THEME_NAME} - abtop theme
# Generated from theme.yml
# Author: ${THEME_AUTHOR}

theme[main_bg]="$(to_upper "$BASE00")"
theme[main_fg]="$(to_upper "$BASE05")"

# Panel titles
theme[title]="$(to_upper "$BASE0C")"

# Key hints, executing sessions, Bash calls
theme[hi_fg]="$(to_upper "$UI_ACCENT")"

theme[selected_bg]="$(to_upper "$UI_SELECTION")"
theme[selected_fg]="$(to_upper "$BASE06")"
theme[inactive_fg]="$(to_upper "$BASE03")"

# Labels and secondary text throughout
theme[graph_text]="$(to_upper "$BASE04")"

# Unfilled meter cells
theme[meter_bg]="$(to_upper "$BASE03")"

# Thinking sessions, Edit calls, open ports
theme[proc_misc]="$(to_upper "$DIAG_OK")"

# Session ids, Read calls, MCP profiles
theme[session_id]="$(to_upper "$BASE0A")"

# Rate-limited sessions and status messages
theme[status_fg]="$(to_upper "$DIAG_ERROR")"
theme[warning_fg]="$(to_upper "$DIAG_WARNING")"

theme[cpu_box]="$(to_upper "$UI_BORDER")"
theme[mem_box]="$(to_upper "$UI_BORDER")"
theme[net_box]="$(to_upper "$UI_BORDER")"
theme[proc_box]="$(to_upper "$UI_BORDER")"
theme[div_line]="$(to_upper "$UI_BORDER")"

# Session badge per agent CLI
theme[agent_claude]="$(to_upper "$BASE09")"
theme[agent_codex]="$(to_upper "$BASE0D")"
theme[agent_opencode]="$(to_upper "$BASE0B")"

# Context, quota and token-rate meters, by severity
theme[cpu_start]="$(to_upper "$DIAG_OK")"
theme[cpu_mid]="$(to_upper "$DIAG_WARNING")"
theme[cpu_end]="$(to_upper "$DIAG_ERROR")"

# Each session's context use, waiting sessions, port conflicts
theme[process_start]="$(to_upper "$DIAG_OK")"
theme[process_mid]="$(to_upper "$DIAG_WARNING")"
theme[process_end]="$(to_upper "$DIAG_ERROR")"

# Input tokens
theme[free_start]="$(to_upper "$DIAG_OK")"
theme[free_mid]="$(to_upper "$BASE0C")"
theme[free_end]="$(to_upper "$BASE06")"

# Output tokens and per-project fill
theme[used_start]="$(to_upper "$DIAG_WARNING")"
theme[used_mid]="$(to_upper "$DIAG_ERROR")"
theme[used_end]="$(to_upper "$BASE0A")"

# Cache reads and writes
theme[cached_start]="$(to_upper "$BASE0A")"
theme[cached_mid]="$(to_upper "$DIAG_WARNING")"
theme[cached_end]="$(to_upper "$BASE06")"
EOF
}

if [[ -n "$output_file" ]]; then
  generate >"$output_file"
  echo "Generated: $output_file"
else
  generate
fi

#!/usr/bin/env bash
# Generate tmux config from theme.yml or palette.yml
# Usage: tmux.sh <theme.yml|palette.yml> [output-file]
#
# Enhanced generator using FULL color palette:
# - All 16 base16 colors
# - Extended palette fields when available (diagnostic_*, ui_*, git_*)
# - ANSI colors for semantic meaning (red=alert, green=success)
# - Special colors for consistency with terminal

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
DIAG_OK="${EXTENDED_DIAGNOSTIC_OK:-$BASE0B}"
UI_ACCENT="${EXTENDED_UI_ACCENT:-$BASE0D}"
UI_BORDER="${EXTENDED_UI_BORDER:-$BASE02}"
GIT_ADD="${EXTENDED_GIT_ADD:-$BASE0B}"

generate() {
  cat << EOF
# ${THEME_NAME} - tmux theme
# Generated from theme.yml
# Author: ${THEME_AUTHOR}
#
# Color mapping:
#   Background tones: base00 (main), base01 (panels), base02 (selection)
#   Foreground tones: base03 (muted), base04 (dim), base05 (normal), base06 (bright), base07 (brightest)
#   Accents: base08 (red), base09 (orange), base0A (yellow), base0B (green),
#            base0C (cyan), base0D (blue), base0E (magenta), base0F (brown)
#   Extended: diagnostic_error, diagnostic_warning, ui_accent, git_add (when available)

# ==============================================================================
# STATUS BAR
# ==============================================================================

# Main status bar style
# base00 = main background, base04 = dim foreground for status text
set-option -g status-style "fg=${BASE04},bg=${BASE00}"

# ==============================================================================
# WINDOW STATUS
# ==============================================================================

# Inactive window titles
# base04 = dim foreground, base00 = main background
set-window-option -g window-status-style "fg=${BASE04},bg=${BASE00}"

# Current/active window - use warning color for high visibility
# ANSI black for deeper contrast on current window
set-window-option -g window-status-current-style "fg=${DIAG_WARNING},bg=${ANSI_BLACK},bold"

# Last visited window - slightly brighter than inactive
# base05 = normal foreground, base01 = panel background
set-window-option -g window-status-last-style "fg=${BASE05},bg=${BASE01}"

# Activity alert - use error color to draw attention
set-window-option -g window-status-activity-style "fg=${DIAG_ERROR},bg=${BASE00}"

# Bell alert - inverted error color for maximum visibility
set-window-option -g window-status-bell-style "fg=${BASE00},bg=${DIAG_ERROR},bold"

# ==============================================================================
# PANE BORDERS
# ==============================================================================

# Inactive pane border - subtle, use UI border color
set-option -g pane-border-style "fg=${UI_BORDER}"

# Active pane border - use yellow (base0A) for visibility without being harsh
set-option -g pane-active-border-style "fg=${BASE0A}"

# Pane number display (prefix + q)
set-option -g display-panes-active-colour "${DIAG_WARNING}"
set-option -g display-panes-colour "${BASE03}"

# ==============================================================================
# MESSAGES
# ==============================================================================

# Message bar (e.g., "Reloaded config")
# base0A (yellow) foreground on base00 background - visible but not alarming
set-option -g message-style "fg=${BASE0A},bg=${BASE00}"

# Command mode (prefix + :)
# Same as message style for consistency
set-option -g message-command-style "fg=${BASE0A},bg=${BASE00}"

# ==============================================================================
# COPY MODE
# ==============================================================================

# Copy mode highlighting - use ok/success color for "selected/good" semantic
# base01 background to maintain readability
set-window-option -g mode-style "fg=${DIAG_OK},bg=${BASE01}"

# ==============================================================================
# CLOCK
# ==============================================================================

# Clock color (prefix + t) - use info/accent color
set-window-option -g clock-mode-colour "${UI_ACCENT}"

# ==============================================================================
# WINDOW STYLES (PANE BACKGROUNDS)
# ==============================================================================

# These affect the actual pane content background
# Using base00 for consistency with terminal background
set-window-option -g window-style "bg=${BASE00}"
set-window-option -g window-active-style "bg=${BASE00}"

# ==============================================================================
# STATUS BAR LAYOUT
# ==============================================================================

# Status bar position and length
set-option -g status-left-length 100
set-option -g status-right-length 100

# Status left: session name with icon
# Use git_add/ok color for session icon and name (green = good/active)
set-option -g status-left " #[fg=${GIT_ADD}]  #S  "

# Window status separator
set-window-option -g window-status-separator "  "

# Window status format (backslash separators)
set-window-option -g window-status-format "\\\\   #W   /"
set-window-option -g window-status-current-format "\\\\   #W   /"

# Status right: clock and date
# base04 for muted clock/date text
set-option -g status-right "#[fg=${BASE04}]%I:%M%p  %m.%d.%Y "

# Pane border format: index, command, path
# UI accent for command, base0A (yellow) for path
set-option -g pane-border-format "  #[align=left,fg=${BASE03}](#{pane_index})  #[fg=${UI_ACCENT},align=centre]  #{pane_current_command}  #[fg=${BASE0A},align=right]  #{pane_current_path}  "

# vim: set ft=tmux tw=0:
EOF
}

if [[ -n "$output_file" ]]; then
  generate > "$output_file"
  echo "Generated: $output_file"
else
  generate
fi

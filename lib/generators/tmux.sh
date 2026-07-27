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
DIAG_INFO="${EXTENDED_DIAGNOSTIC_INFO:-$BASE0D}"
DIAG_OK="${EXTENDED_DIAGNOSTIC_OK:-$BASE0B}"
UI_ACCENT="${EXTENDED_UI_ACCENT:-$BASE0D}"
UI_SELECTION="${EXTENDED_UI_SELECTION:-$BASE02}"
UI_BORDER="${EXTENDED_UI_BORDER:-$BASE01}"
GIT_ADD="${EXTENDED_GIT_ADD:-$BASE0B}"

# Session list (status line 1). Entries are separated by whitespace and nothing
# else. Dividers were tried and dropped: padding and a bar are two separators
# doing one job, which flattens the spacing so proximity carries no information
# and the line only looks busier. Gestalt proximity groups on relative distance,
# so the gap between entries being wider than the gap inside a name is the whole
# mechanism — see docs/architecture/tmux-sessions.md in dotfiles.
SESSION_GAP="  "

# Conditionals wrap whole #[...] blocks rather than sitting inside one (no
# "fg=#{?...}") — tmux resolves a style at draw time and does not expand formats
# within it. Same idiom as pane-border-style below. Alert mirrors the window
# bell style: inverted rather than merely recoloured.
SESSION_ENTRY="#[range=session|#{session_id}]#{?session_alert,#[fg=${BASE00}]#[bg=${DIAG_ERROR}]#[bold],#[fg=${BASE04}]#[bg=${BASE00}]} #{session_name} #[nobold]#[norange]#[default]${SESSION_GAP}"
SESSION_ENTRY_CURRENT="#[range=session|#{session_id} list=focus]#[fg=${GIT_ADD}]#[bg=${BASE00}]#[bold] #{session_name} #[nobold]#[norange]#[list=on]#[default]${SESSION_GAP}"

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

# Last visited window - same as inactive (no special highlight)
set-window-option -g window-status-last-style "fg=${BASE04},bg=${BASE00}"

# Activity alert - use error color to draw attention
set-window-option -g window-status-activity-style "fg=${DIAG_ERROR},bg=${BASE00}"

# Bell alert - inverted error color for maximum visibility
set-window-option -g window-status-bell-style "fg=${BASE00},bg=${DIAG_ERROR},bold"

# ==============================================================================
# PANE BORDERS
# ==============================================================================

# Pane border line color. Normally UI border (inactive) / yellow (active); turns
# the theme's error red when the pane is running ssh — the host-side remote
# indicator, matching the red SSH badge in pane-border-format below. Set WITHOUT
# -F so tmux stores the format and re-evaluates it per pane at draw time (with -F
# it would resolve once at load and never track the pane's command).
set-option -g pane-border-style "#{?#{==:#{pane_current_command},ssh},fg=${DIAG_ERROR},fg=${UI_BORDER}}"
set-option -g pane-active-border-style "#{?#{==:#{pane_current_command},ssh},fg=${DIAG_ERROR} bold,fg=${BASE0A}}"

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
# UI selection background for visual consistency with other selection states
set-window-option -g mode-style "fg=${DIAG_OK},bg=${UI_SELECTION}"

# ==============================================================================
# CLOCK
# ==============================================================================

# Clock color (prefix + t) - use info color for informational display
set-window-option -g clock-mode-colour "${DIAG_INFO}"

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

# Status left: empty. The session name lives in the list on the line above, so
# naming it again here would say the same thing twice on one screen, and the
# window format opens with its own space, so a pad here would push line 2 one
# column right of line 1.
set-option -g status-left ""

# Window status: the same shape as the session list above, so the two lines read
# as one bar. Separation is whitespace only; the current window is told apart by
# colour and weight, which is preattentive and needs no reading.
set-window-option -g window-status-separator "${SESSION_GAP}"
set-window-option -g window-status-format " #W "
set-window-option -g window-status-current-format " #W "

# Status right: clock and date
# base04 for muted clock/date text
set-option -g status-right "#[fg=${BASE04}]%I:%M%p  %m.%d.%Y "

# Session list, drawn on the first status line above the window row. list=focus
# on the current session keeps it scrolled into view once the list outgrows the
# terminal, with < > markers on the ends.
# tmux's stock window row is relocated to the second line by \`tmux-sessions
# install-status\`, which dotfiles runs before sourcing this file.
set-option -g "status-format[0]" "#[align=left]#[list=on]#[list=left-marker]<#[list=right-marker]>#[list=on]#{S:${SESSION_ENTRY},${SESSION_ENTRY_CURRENT}}"

# Pane border format: index, command, path (normal) — or a red host badge when
# the pane is running ssh. Host-side remote indicator: the local tmux detects the
# ssh process via pane_current_command, so any SSH target lights up red (theme's
# diagnostic_error) with zero setup on the remote — bare servers work. The badge
# shows pane_title, which a dotfiles remote sets to "host:cwd" via an OSC 2 prompt
# hook (falling back to the local "ssh: <target>" label, or plain SSH). Style
# attributes are space-separated (not comma) so they don't collide with the
# #{?...} branch separator; the nested #{?#{pane_title}...} is brace-scoped so its
# commas are fine.
set-option -g pane-border-format "#{?#{==:#{pane_current_command},ssh},  #[align=left fg=${DIAG_ERROR} bold](#{pane_index})  #[align=centre fg=${DIAG_ERROR} bold] 󰢹 #{?#{pane_title},#{pane_title},SSH}  ,  #[align=left fg=${BASE03}](#{pane_index})  #[align=centre fg=${UI_ACCENT}]  #{pane_current_command}  #[align=right fg=${BASE0A}]  #{pane_current_path}  }"

# vim: set ft=tmux tw=0:
EOF
}

if [[ -n "$output_file" ]]; then
  generate > "$output_file"
  echo "Generated: $output_file"
else
  generate
fi

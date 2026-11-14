#!/usr/bin/env bash
# Generate delta (git diff pager) theme from theme.yml or palette.yml
# Usage: delta.sh <theme.yml|palette.yml> [output-file]
#
# Emits a git config fragment included from the user's gitconfig.
#
# Delta's own defaults tint changed lines almost imperceptibly — the stock
# "#002800" added-line background sits at 1.06:1 against a #1c1c1c terminal and
# the removed-line background is fractionally darker than the page. The change
# signal is then buried under whatever the syntax highlighter is doing on top.
# So rather than blend the accent by a fixed fraction, which lands somewhere
# different on every palette, solve for the fraction that hits a target contrast
# ratio against this theme's own background.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../theme.sh"
source "$SCRIPT_DIR/../contrast.sh"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <theme.yml|palette.yml> [output-file]"
  exit 1
fi

input_file="$1"
output_file="${2:-}"

eval "$(load_colors "$input_file")"

# A band divides the contrast of every foreground drawn on it by its own
# contrast with the background, so a comment at 2:1 on the page reads at 1:1 on
# a 2.2:1 emphasis band. The emphasis styles therefore carry a foreground of
# their own, the theme's text made legible on the band. The line styles keep
# `syntax`.

BG="${SPECIAL_BG:-$BASE00}"
# The foreground bat draws unstyled text in, which is what delta renders through.
TEXT="${SPECIAL_FG}"
RED="${EXTENDED_DIAGNOSTIC_ERROR:-$BASE08}"
GREEN="${EXTENDED_DIAGNOSTIC_OK:-$BASE0B}"

MINUS_BG="$(band "$RED" "$BG" 1.45)"
PLUS_BG="$(band "$GREEN" "$BG" 1.45)"
MINUS_EMPH_BG="$(band "$RED" "$BG" 2.2)"
PLUS_EMPH_BG="$(band "$GREEN" "$BG" 2.2)"
MINUS_EMPH_FG="$(legible "$TEXT" "$MINUS_EMPH_BG" 4.5)"
PLUS_EMPH_FG="$(legible "$TEXT" "$PLUS_EMPH_BG" 4.5)"

generate() {
  cat <<EOF
# ${THEME_NAME} - delta theme
# Generated from theme.yml — do not edit; run 'theme apply' to regenerate

[delta]
    # Tracks whatever bat theme is currently applied; theme rewrites
    # ~/.config/bat/themes/current.tmTheme and rebuilds the bat cache on apply.
    syntax-theme = current

    minus-style = syntax "${MINUS_BG}"
    minus-emph-style = "${MINUS_EMPH_FG}" "${MINUS_EMPH_BG}"
    plus-style = syntax "${PLUS_BG}"
    plus-emph-style = "${PLUS_EMPH_FG}" "${PLUS_EMPH_BG}"

    line-numbers-minus-style = "${RED}"
    line-numbers-plus-style = "${GREEN}"
    line-numbers-zero-style = "${BASE03}"
    line-numbers-left-style = "${BASE03}"
    line-numbers-right-style = "${BASE03}"

    file-style = "${BASE0D}" bold
    file-decoration-style = "${BASE03}" ul
    hunk-header-style = file line-number syntax
    hunk-header-decoration-style = "${BASE03}" box
    # Quoted because an unquoted '#' begins a comment in git config, which would
    # silently truncate this to empty and make delta abort on every invocation.
    blame-palette = "${BASE00} ${BASE01} ${BASE02}"
    merge-conflict-ours-diff-header-style = "${BASE0A}" bold
    merge-conflict-theirs-diff-header-style = "${BASE0A}" bold
EOF
}

if [[ -n "$output_file" ]]; then
  generate >"$output_file"
  echo "Generated: $output_file"
else
  generate
fi

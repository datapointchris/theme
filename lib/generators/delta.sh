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

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <theme.yml|palette.yml> [output-file]"
  exit 1
fi

input_file="$1"
output_file="${2:-}"

eval "$(load_colors "$input_file")"

# Blend accent toward bg until the result reaches target contrast against bg.
# Capped so a near-background accent can never produce an opaque slab.
band() {
  awk -v accent="${1#\#}" -v bg="${2#\#}" -v target="$3" '
    function chan(h, i) { return strtonum("0x" substr(h, i, 2)) }
    function lin(v,  c) { c = v / 255; return (c <= 0.03928) ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4 }
    function lum(r, g, b) { return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b) }
    function ratio(l1, l2) { return (l1 > l2) ? (l1 + 0.05) / (l2 + 0.05) : (l2 + 0.05) / (l1 + 0.05) }
    BEGIN {
      ar = chan(accent, 1); ag = chan(accent, 3); ab = chan(accent, 5)
      br = chan(bg, 1);     bg_ = chan(bg, 3);    bb = chan(bg, 5)
      base = lum(br, bg_, bb)
      best = 0.65
      for (f = 0.02; f <= 0.65; f += 0.01) {
        r = ar * f + br * (1 - f); g = ag * f + bg_ * (1 - f); b = ab * f + bb * (1 - f)
        if (ratio(lum(r, g, b), base) >= target) { best = f; break }
      }
      r = ar * best + br * (1 - best); g = ag * best + bg_ * (1 - best); b = ab * best + bb * (1 - best)
      printf "#%02x%02x%02x\n", int(r + 0.5), int(g + 0.5), int(b + 0.5)
    }'
}

# A band divides the contrast of every foreground drawn on it by its own
# contrast with the background, so a comment at 2:1 on the page reads at 1:1 on
# a 2.2:1 emphasis band. The emphasis styles therefore carry a foreground of
# their own: the theme's text pushed toward white or black until it reads at the
# target. The line styles keep `syntax`. The push goes toward whichever extreme
# contrasts more with the band. The two contrasts multiply to 21, so that one is
# never below 4.58:1 and the target is always reachable. Each candidate is
# rounded before it is measured, so the check is on the color actually emitted.
legible() {
  awk -v text="${1#\#}" -v surface="${2#\#}" -v target="$3" '
    function chan(h, i) { return strtonum("0x" substr(h, i, 2)) }
    function lin(v,  c) { c = v / 255; return (c <= 0.03928) ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4 }
    function lum(r, g, b) { return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b) }
    function ratio(l1, l2) { return (l1 > l2) ? (l1 + 0.05) / (l2 + 0.05) : (l2 + 0.05) / (l1 + 0.05) }
    BEGIN {
      tr = chan(text, 1); tg = chan(text, 3); tb = chan(text, 5)
      base = lum(chan(surface, 1), chan(surface, 3), chan(surface, 5))
      toward = (ratio(1, base) >= ratio(0, base)) ? 255 : 0
      r = toward; g = toward; b = toward
      for (f = 0; f < 1; f += 0.02) {
        cr = int(toward * f + tr * (1 - f) + 0.5)
        cg = int(toward * f + tg * (1 - f) + 0.5)
        cb = int(toward * f + tb * (1 - f) + 0.5)
        if (ratio(lum(cr, cg, cb), base) >= target) { r = cr; g = cg; b = cb; break }
      }
      printf "#%02x%02x%02x\n", r, g, b
    }'
}

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

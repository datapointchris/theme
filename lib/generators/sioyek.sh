#!/usr/bin/env bash
# Generate sioyek prefs block from theme.yml
# Usage: sioyek.sh <theme.yml> [output-file]
#
# Emits a marker-delimited managed block of sioyek prefs. The block is meant to
# be spliced into the user's prefs_user.config by apply_sioyek (see lib.sh) so
# that user-managed keys outside the markers are preserved.
#
# Sioyek has no `include` directive — config.cpp's deserializer only knows
# key=value lines. user_config_paths is a fixed per-platform list, so we can't
# point sioyek at a separate per-theme file. Splice-in-place is the only way.
#
# Color choices match what tmux/btop/neovim use from the same theme.yml:
#   BASE00 -> page background, page margin (custom + dark modes)
#   BASE05 -> page text
# Sioyek's custom color shader linearly maps PDF-white -> CUSTOM_BACKGROUND_COLOR
# and PDF-black -> CUSTOM_TEXT_COLOR (see pdf_view_opengl_widget.cpp line 2756).

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

# Convert "#rrggbb" to "0.NNNN 0.NNNN 0.NNNN" (sioyek wants float triples).
hex_to_rgb_floats() {
  local hex="${1#\#}"
  local r g b
  r=$((16#${hex:0:2}))
  g=$((16#${hex:2:2}))
  b=$((16#${hex:4:2}))
  awk -v r="$r" -v g="$g" -v b="$b" \
    'BEGIN { printf "%.4f %.4f %.4f", r/255, g/255, b/255 }'
}

BG_FLOATS="$(hex_to_rgb_floats "$BASE00")"
FG_FLOATS="$(hex_to_rgb_floats "$BASE05")"

generate() {
  cat <<EOF
# >>> theme tool (managed) - do not edit between markers <<<
# theme: ${THEME_SLUG}
# Custom color mode: PDF-white -> custom_background_color,
#                    PDF-black -> custom_text_color.
custom_background_color $BG_FLOATS
custom_text_color $FG_FLOATS
custom_color_mode_empty_background_color $BG_FLOATS
# Margin color when toggled into the built-in dark mode.
dark_mode_background_color $BG_FLOATS
# <<< theme tool (managed) <<<
EOF
}

if [[ -n "$output_file" ]]; then
  generate >"$output_file"
  echo "Generated: $output_file"
else
  generate
fi

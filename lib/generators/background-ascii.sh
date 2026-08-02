#!/usr/bin/env bash
# Generate themed ASCII art backgrounds using ascii-image-converter
# Usage: background-ascii.sh <theme.yml> <source-image> <output-file>
#
# Converts images to ASCII art with theme-colored background.
# Requires: ascii-image-converter (brew install TheZoraiz/ascii-image-converter/ascii-image-converter)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../theme.sh"

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <theme.yml> <source-image> <output-file>"
  echo ""
  echo "Converts source-image to ASCII art with theme colors."
  echo "Requires: ascii-image-converter"
  exit 1
fi

theme_file="$1"
source_image="$2"
output_file="$3"

if ! command -v ascii-image-converter &>/dev/null; then
  echo "Error: ascii-image-converter not found." >&2
  echo "Install with: brew install TheZoraiz/ascii-image-converter/ascii-image-converter" >&2
  exit 1
fi

if [[ ! -f "$source_image" ]]; then
  echo "Error: Source image not found: $source_image" >&2
  exit 1
fi

# Load theme colors
eval "$(load_colors "$theme_file")"

# Convert hex color to R,G,B format for ascii-image-converter
hex_to_rgb() {
  local hex="${1#\#}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  echo "$r,$g,$b"
}

bg_rgb=$(hex_to_rgb "$BASE00")

# -C colors each glyph from the source pixel underneath it, which also makes
# --font-color a no-op — passing both produced byte-identical output. Keep the
# per-glyph colour, since recoloring below maps it into the palette and a single
# flat font colour would throw the image away entirely.
# -s takes a directory; the filename is auto-generated as <basename>-ascii-art.png
temp_dir="/tmp/ascii_$$"
mkdir -p "$temp_dir"

ascii-image-converter "$source_image" \
  -C \
  -s "$temp_dir" \
  --save-bg "${bg_rgb},100" \
  --width 200 \
  --only-save \
  2>/dev/null

source_basename=$(basename "$source_image" | sed 's/\.[^.]*$//')
generated_file="$temp_dir/${source_basename}-ascii-art.png"

if [[ ! -f "$generated_file" ]]; then
  rm -rf "$temp_dir"
  echo "Error: ascii-image-converter failed to create output" >&2
  exit 1
fi

# --save-bg themes the ground but the glyphs keep the photo's colours, so the
# result only half-matched the theme. Hand it to the recolor generator, but not
# on the settings lowpoly and recolor use: ASCII output is mostly ground, so it
# arrives dark already (mean ~20 of 100) and the darkening pass crushes it to
# near-black. The trimmed palette lowers the glyphs instead.
bash "$SCRIPT_DIR/background-recolor.sh" "$theme_file" "$generated_file" "$output_file" \
  --palette dark --no-darken
rm -rf "$temp_dir"

if [[ ! -f "$output_file" ]]; then
  echo "Error: recolor failed to create output file" >&2
  exit 1
fi

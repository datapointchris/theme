#!/usr/bin/env bash
# Generate themed ASCII art wallpapers using ascii-image-converter
# Usage: wallpaper-ascii.sh <theme.yml> <source-image> <output-file>
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

# Get background and foreground RGB values
bg_rgb=$(hex_to_rgb "$BASE00")
fg_rgb=$(hex_to_rgb "$BASE05")

# Generate ASCII art with theme colors
# -C: use colors from image, --save-bg: set background color (RGBA, alpha is 0-100)
# -s takes a directory path, output filename is auto-generated as <basename>-ascii-art.png
temp_dir="/tmp/ascii_$$"
mkdir -p "$temp_dir"

ascii-image-converter "$source_image" \
  -C \
  -s "$temp_dir" \
  --save-bg "${bg_rgb},100" \
  --font-color "${fg_rgb}" \
  --width 200 \
  --only-save \
  2>/dev/null

# Find the generated file (format: <basename>-ascii-art.png)
source_basename=$(basename "$source_image" | sed 's/\.[^.]*$//')
generated_file="$temp_dir/${source_basename}-ascii-art.png"

# Move to final location
if [[ -f "$generated_file" ]]; then
  mv "$generated_file" "$output_file"
  rm -rf "$temp_dir"
else
  rm -rf "$temp_dir"
  echo "Error: ascii-image-converter failed to create output" >&2
  exit 1
fi

# Verify output
if [[ ! -f "$output_file" ]]; then
  echo "Error: Failed to create output file" >&2
  exit 1
fi

#!/usr/bin/env bash
# Generate ASCII text banner wallpapers using figlet + ImageMagick
# Usage: wallpaper-banner.sh <theme.yml> <output-file> [text]
#
# Creates ASCII art text banner with theme colors.
# Requires: figlet, ImageMagick (magick)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../theme.sh"

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <theme.yml> <output-file> [text]"
  echo ""
  echo "Creates ASCII banner with theme colors."
  echo "Default text: theme display name"
  echo "Requires: figlet, magick"
  exit 1
fi

theme_file="$1"
output_file="$2"
text="${3:-}"

if ! command -v figlet &>/dev/null; then
  echo "Error: figlet not found. Install with: brew install figlet" >&2
  exit 1
fi

if ! command -v magick &>/dev/null; then
  echo "Error: ImageMagick not found. Install with: brew install imagemagick" >&2
  exit 1
fi

# Load theme colors
eval "$(load_colors "$theme_file")"

# Get display name if text not specified
if [[ -z "$text" ]]; then
  text=$(yq -r '.meta.display_name // .meta.id // "THEME"' "$theme_file" 2>/dev/null || echo "THEME")
fi

# Pick a random font from good options
fonts=("big" "block" "banner3" "colossal" "slant" "standard" "doom" "epic")
font="${fonts[$((RANDOM % ${#fonts[@]}))]}"

# Generate figlet text
banner_text=$(figlet -f "$font" -w 200 "$text" 2>/dev/null || figlet "$text")

# Count lines and estimate dimensions
line_count=$(echo "$banner_text" | wc -l)
max_width=$(echo "$banner_text" | awk '{ if (length > max) max = length } END { print max }')

# Calculate image dimensions (rough estimate based on monospace chars)
char_width=14
char_height=24
padding=100
img_width=$(( max_width * char_width + padding * 2 ))
img_height=$(( line_count * char_height + padding * 2 ))

# Minimum dimensions for wallpaper
[[ $img_width -lt 1920 ]] && img_width=1920
[[ $img_height -lt 1080 ]] && img_height=1080

# Create temporary file for text
temp_text="/tmp/banner_text_$$.txt"
echo "$banner_text" > "$temp_text"

# Pick accent color for text
accent_colors=("$BASE0D" "$BASE0E" "$BASE0C" "$BASE09" "$BASE0B")
text_color="${accent_colors[$((RANDOM % ${#accent_colors[@]}))]}"

# Generate image with ImageMagick
magick -size "${img_width}x${img_height}" "xc:${BASE00}" \
  -gravity center \
  -font "Menlo" \
  -pointsize 20 \
  -fill "$text_color" \
  -annotate +0+0 "@${temp_text}" \
  "$output_file"

# Clean up
rm -f "$temp_text"

# Verify output
if [[ ! -f "$output_file" ]]; then
  echo "Error: Failed to create output file" >&2
  exit 1
fi

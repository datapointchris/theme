#!/usr/bin/env bash
# Generate a themed plasma background from theme.yml
# Usage: background-plasma.sh <theme.yml> <output-file> [width] [height]
#
# Requires: ImageMagick (convert command)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../theme.sh"

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <theme.yml> <output-file> [width] [height]"
  echo "Default: 3840x2160"
  exit 1
fi

input_file="$1"
output_file="$2"
width="${3:-3840}"
height="${4:-2160}"

eval "$(load_colors "$input_file")"

generate_plasma() {
  # Multi-colored nebula clouds using accent palette. Rendered at full target
  # resolution — this is slow at 4K (five plasma:fractal + blur passes), so
  # backgrounds are pre-generated into the cache (`theme pre-generate`) and apply
  # copies from there rather than generating on the fly.
  local colors=("$BASE0D" "$BASE0E" "$BASE0C" "$BASE09" "$BASE0B")

  # Generate base with first plasma
  convert -size "${width}x${height}" -seed $RANDOM plasma:fractal \
    -grayscale Rec709Luminance \
    -sigmoidal-contrast 12x50% \
    -solarize 50% \
    -blur 0x2 \
    +level-colors "${BASE00},${colors[0]}" \
    /tmp/plasma_base_$$.png

  # Layer additional plasma clouds with different seeds and colors
  for i in {1..4}; do
    local color="${colors[$i]}"
    local contrast=$((10 + RANDOM % 8))
    local solarize=$((35 + RANDOM % 35))

    convert -size "${width}x${height}" -seed $RANDOM plasma:fractal \
      -grayscale Rec709Luminance \
      -sigmoidal-contrast "${contrast}x50%" \
      -solarize "${solarize}%" \
      -blur 0x2 \
      +level-colors "${BASE00},${color}" \
      /tmp/plasma_layer_$$.png

    convert /tmp/plasma_base_$$.png /tmp/plasma_layer_$$.png \
      -compose lighten -composite /tmp/plasma_base_$$.png
  done

  mv /tmp/plasma_base_$$.png "$output_file"
  rm -f /tmp/plasma_layer_$$.png
}

generate_plasma

echo "Generated: $output_file (${width}x${height})"

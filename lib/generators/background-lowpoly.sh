#!/usr/bin/env bash
# Generate low-poly Delaunay triangulated backgrounds using triangle
# Usage: background-lowpoly.sh <theme.yml> <source-image> <output-file>
#
# Converts images to low-poly triangulated art with theme background.
# Requires: triangle (go install github.com/esimov/triangle/v2/cmd/triangle@latest)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../theme.sh"

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <theme.yml> <source-image> <output-file>"
  echo ""
  echo "Converts source-image to low-poly art with theme background."
  echo "Requires: triangle"
  exit 1
fi

theme_file="$1"
source_image="$2"
output_file="$3"

if ! command -v triangle &>/dev/null; then
  echo "Error: triangle not found." >&2
  echo "Install with: go install github.com/esimov/triangle/v2/cmd/triangle@latest" >&2
  exit 1
fi

if [[ ! -f "$source_image" ]]; then
  echo "Error: Source image not found: $source_image" >&2
  exit 1
fi

# Load theme colors
eval "$(load_colors "$theme_file")"

# Scale up source image to 4K for better quality
scaled_image="/tmp/lowpoly_scaled_$$.png"
magick "$source_image" -resize 3840x2160^ -gravity center -extent 3840x2160 "$scaled_image"

# Generate low-poly version with theme background
# -pts: number of points (more = more detail)
# -bg: background color for transparent areas
# -st: stroke width
# -wf: wireframe mode (0=filled, 1=with stroke, 2=stroke only)
triangle \
  -in "$scaled_image" \
  -out "$output_file" \
  -bg "$BASE00" \
  -pts 2500 \
  -st 0.5 \
  -wf 1 \
  -bl 2 \
  2>/dev/null

# Clean up
rm -f "$scaled_image"

# Verify output
if [[ ! -f "$output_file" ]]; then
  echo "Error: triangle failed to create output file" >&2
  exit 1
fi

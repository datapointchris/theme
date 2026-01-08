#!/usr/bin/env bash
# Generate themed wallpapers by recoloring source images using gowall
# Usage: wallpaper-gowall.sh <theme.yml> <source-image> <output-file>
#
# Recolors any image to match the theme's color palette using gowall.
# Requires: gowall (go install github.com/Achno/gowall@latest)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../theme.sh"

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <theme.yml> <source-image> <output-file>"
  echo ""
  echo "Recolors source-image to match theme colors."
  echo "Requires: gowall"
  exit 1
fi

theme_file="$1"
source_image="$2"
output_file="$3"

if ! command -v gowall &>/dev/null; then
  echo "Error: gowall not found. Install with: go install github.com/Achno/gowall@latest" >&2
  exit 1
fi

if [[ ! -f "$source_image" ]]; then
  echo "Error: Source image not found: $source_image" >&2
  exit 1
fi

# Load theme colors
eval "$(load_colors "$theme_file")"

# Extract theme ID for unique config name
theme_id=$(yq -r '.meta.id // "custom"' "$theme_file" 2>/dev/null || echo "custom")

# Create gowall config with theme colors
# Uses base16 palette + key ANSI colors for a rich palette
gowall_config_dir="$HOME/.config/gowall"
gowall_config="$gowall_config_dir/config.yml"
mkdir -p "$gowall_config_dir"

# Build color list from theme
# Include base16 colors and select ANSI colors for variety
colors=(
  "$BASE00"  # Background
  "$BASE01"  # Lighter bg
  "$BASE02"  # Selection bg
  "$BASE03"  # Comments
  "$BASE04"  # Dark fg
  "$BASE05"  # Default fg
  "$BASE06"  # Light fg
  "$BASE07"  # Lightest fg
  "$BASE08"  # Red
  "$BASE09"  # Orange
  "$BASE0A"  # Yellow
  "$BASE0B"  # Green
  "$BASE0C"  # Cyan
  "$BASE0D"  # Blue
  "$BASE0E"  # Purple
  "$BASE0F"  # Brown
)

# Generate YAML for the theme
# Check if theme already exists in config, if not add it
if [[ -f "$gowall_config" ]] && grep -q "name: \"theme-$theme_id\"" "$gowall_config" 2>/dev/null; then
  # Theme exists, use it
  :
else
  # Create or append theme to config
  if [[ ! -s "$gowall_config" ]]; then
    echo "themes:" > "$gowall_config"
  fi

  # Append the theme
  {
    echo "  - name: \"theme-$theme_id\""
    echo "    colors:"
    for color in "${colors[@]}"; do
      echo "      - \"$color\""
    done
  } >> "$gowall_config"
fi

# Run gowall to convert the image
gowall convert "$source_image" --output "$output_file" -t "theme-$theme_id" 2>/dev/null

# Verify output was created
if [[ ! -f "$output_file" ]]; then
  echo "Error: gowall failed to create output file" >&2
  exit 1
fi

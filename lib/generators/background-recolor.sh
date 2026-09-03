#!/usr/bin/env bash
# Generate themed backgrounds by recoloring source images using gowall
# Usage: background-recolor.sh <theme.yml> <source-image> <output-file>
#                             [--palette full|dark] [--no-darken]
#
# Recolors any image to match the theme's color palette using gowall.
# Requires: gowall (go install github.com/Achno/gowall@latest)
#
# The defaults are what recolor and lowpoly both want: the full palette, then a
# darkening pass. A photo's brightness survives recoloring — gowall maps each
# pixel to the nearest palette color, so a bright sky lands on the theme's
# foreground and stays a pale expanse. Backgrounds are seen through terminal
# transparency, where that washes out.
#
# ascii wants the opposite on both counts, hence the flags: its output is mostly
# ground, so it is already dark and darkening it further crushes it to black
# (measured: mean 20 -> 2). Instead it drops the palette's lightest entries so
# the glyphs themselves sit lower.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../theme.sh"

palette_variant="full"
darken=1
positional=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --palette)
      palette_variant="${2:-}"
      shift 2
      ;;
    --no-darken)
      darken=0
      shift
      ;;
    *)
      positional+=("$1")
      shift
      ;;
  esac
done

if [[ ${#positional[@]} -lt 3 ]]; then
  echo "Usage: $0 <theme.yml> <source-image> <output-file> [--palette full|dark] [--no-darken]"
  echo ""
  echo "Recolors source-image to match theme colors."
  echo "Requires: gowall"
  exit 1
fi

theme_file="${positional[0]}"
source_image="${positional[1]}"
output_file="${positional[2]}"

case "$palette_variant" in
  full | dark) ;;
  *)
    echo "Error: --palette must be full or dark, got: $palette_variant" >&2
    exit 1
    ;;
esac

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
theme_id=$(yq '.meta.id // "custom"' "$theme_file" 2>/dev/null || echo "custom")

# gowall's -t takes a path to a JSON theme as well as a name from its config, so
# each palette is written to the cache instead of appended to
# ~/.config/gowall/config.yml. That file is a tracked dotfile, so appending to it
# meant every theme apply dirtied the dotfiles repo, and entries accumulated
# forever — it was still carrying themes deleted months ago.
palette_dir="$HOME/.cache/theme/gowall"
mkdir -p "$palette_dir"

# Build color list from theme
colors=(
  "$BASE00" # Background
  "$BASE01" # Lighter bg
  "$BASE02" # Selection bg
  "$BASE03" # Comments
  "$BASE04" # Dark fg
  "$BASE08" # Red
  "$BASE09" # Orange
  "$BASE0B" # Green
  "$BASE0C" # Cyan
  "$BASE0D" # Blue
  "$BASE0E" # Purple
  "$BASE0F" # Brown
)
palette_name="theme-$theme_id-dark"

# The full palette adds the foreground tier and the lightest accent back. Those
# four are exactly what a bright region maps onto, so the dark variant is this
# same palette with its top end removed rather than a different set of hues.
# Removing more than this pushes bright areas onto a colored accent and tints
# the sky - salmon on a warm theme, lavender on a cool one.
if [[ "$palette_variant" == "full" ]]; then
  colors+=("$BASE05" "$BASE06" "$BASE07" "$BASE0A")
  palette_name="theme-$theme_id"
fi

# Rewritten on every run rather than reused when present. The old config-append
# skipped regeneration once a name existed, so editing a color in theme.yml
# never reached gowall and the wallpaper kept the palette from first use.
palette_file="$palette_dir/${palette_name}.json"
{
  printf '{ "name": "%s", "colors": [' "$palette_name"
  for i in "${!colors[@]}"; do
    [[ $i -gt 0 ]] && printf ', '
    printf '"%s"' "${colors[$i]}"
  done
  printf '] }\n'
} >"$palette_file"

gowall convert "$source_image" --output "$output_file" -t "$palette_file" 2>/dev/null

# Verify output was created
if [[ ! -f "$output_file" ]]; then
  echo "Error: gowall failed to create output file" >&2
  exit 1
fi

if [[ "$darken" -eq 1 ]]; then
  darkened="${output_file}.darkened.png"
  if magick "$output_file" -brightness-contrast -30x10 "$darkened" 2>/dev/null; then
    mv "$darkened" "$output_file"
  else
    rm -f "$darkened"
    echo "Warning: could not darken $output_file, leaving it as recolored" >&2
  fi
fi

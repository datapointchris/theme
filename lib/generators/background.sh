#!/usr/bin/env bash
# Generate themed backgrounds from theme.yml
# Usage: background.sh <theme.yml> <output-file> [style] [width] [height]
#
# Styles:
#   plasma     - Fractal plasma with theme colors (default)
#   geometric  - Random geometric shapes
#   hexagons   - Honeycomb pattern
#   circles    - Overlapping circles
#   swirl      - Vortex gradient
#   spotlight  - Soft centered glow
#   sphere     - Single centered 3D sphere
#   spheres    - Multiple 3D spheres
#
# Requires: ImageMagick (convert command)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../theme.sh"

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <theme.yml> <output-file> [style] [width] [height]"
  echo ""
  echo "Styles: plasma, geometric, hexagons, circles, swirl, spotlight, sphere, spheres"
  echo "Default: plasma at 3840x2160"
  exit 1
fi

input_file="$1"
output_file="$2"
style="${3:-plasma}"
width="${4:-3840}"
height="${5:-2160}"

eval "$(load_colors "$input_file")"

# Darken a hex color by a percentage
darken_color() {
  local hex="$1"
  local percent="${2:-20}"
  hex="${hex#\#}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  r=$((r * (100 - percent) / 100))
  g=$((g * (100 - percent) / 100))
  b=$((b * (100 - percent) / 100))
  printf "#%02x%02x%02x" "$r" "$g" "$b"
}

generate_plasma() {
  # Multi-colored nebula clouds using accent palette
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

generate_geometric() {
  # Rotated shapes with accent colors (same palette as circles)
  local colors=("$BASE0D" "$BASE0E" "$BASE0C" "$BASE09" "$BASE0B")
  local draw_commands=""

  for _ in {1..60}; do
    local color="${colors[$((RANDOM % ${#colors[@]}))]}"
    local color_alpha="${color}45"  # 27% opacity
    local cx=$((RANDOM % width))
    local cy=$((RANDOM % height))
    local size=$((RANDOM % 150 + 50))
    local angle=$((RANDOM % 360))

    local shape=$((RANDOM % 3))
    case $shape in
      0) # Rotated rectangle
        local hw=$((size / 2))
        local hh=$((size / 4))
        draw_commands+=" -fill '${color_alpha}' -draw 'translate $cx,$cy rotate $angle rectangle $((- hw)),$((- hh)) $hw,$hh'"
        ;;
      1) # Circle (rotation doesn't matter)
        draw_commands+=" -fill '${color_alpha}' -draw 'circle $cx,$cy $((cx + size/2)),$cy'"
        ;;
      2) # Rotated triangle
        local s=$((size / 2))
        draw_commands+=" -fill '${color_alpha}' -draw 'translate $cx,$cy rotate $angle polygon 0,$((- s)) $((s)),$s $((-s)),$s'"
        ;;
    esac
  done

  # Single convert call with all draws
  eval "convert -size '${width}x${height}' xc:'${BASE00}' $draw_commands '$output_file'"
}

generate_hexagons() {
  # Scattered hexagons of varying sizes and accent colors
  local colors=("$BASE0D" "$BASE0E" "$BASE0C" "$BASE09" "$BASE0B")
  local draw_commands=""

  for _ in {1..45}; do
    local color="${colors[$((RANDOM % ${#colors[@]}))]}"
    local color_alpha="${color}40"
    local cx=$((RANDOM % width))
    local cy=$((RANDOM % height))
    local size=$((RANDOM % 80 + 30))
    local angle=$((RANDOM % 60))

    # Hexagon points relative to center
    local s=$size
    local h=$((s * 866 / 1000))  # sqrt(3)/2 approximation
    draw_commands+=" -fill '${color_alpha}' -draw 'translate $cx,$cy rotate $angle polygon 0,$((-s)) $h,$((-s/2)) $h,$((s/2)) 0,$s $((-h)),$((s/2)) $((-h)),$((-s/2))'"
  done

  eval "convert -size '${width}x${height}' xc:'${BASE00}' $draw_commands '$output_file'"
}

generate_circles() {
  # Build all draw commands at once
  local colors=("$BASE0D" "$BASE0E" "$BASE0C" "$BASE09" "$BASE0B")
  local draw_commands=""

  for _ in {1..50}; do
    local color="${colors[$((RANDOM % ${#colors[@]}))]}"
    local color_alpha="${color}35"  # 21% opacity
    local x=$((RANDOM % width))
    local y=$((RANDOM % height))
    local radius=$((RANDOM % 100 + 30))
    draw_commands+=" -fill '${color_alpha}' -draw 'circle $x,$y $((x + radius)),$y'"
  done

  # Single convert call with all circles
  eval "convert -size '${width}x${height}' xc:'${BASE00}' $draw_commands '$output_file'"
}

generate_swirl() {
  # Vortex gradient using two accent colors
  convert -size "${width}x${height}" \
    \( gradient:"${BASE00}-${BASE0D}" \) \
    \( gradient:"${BASE00}-${BASE0E}" -rotate 90 \) \
    -compose multiply -composite \
    -swirl 180 \
    "$output_file"
}

generate_spotlight() {
  # Soft centered glow
  convert -size "${width}x${height}" xc:"${BASE00}" \
    \( -size 800x800 radial-gradient:"${BASE0D}90-none" \) \
    -gravity center -compose over -composite \
    -blur 0x20 \
    "$output_file"
}

generate_sphere() {
  # Single centered 3D sphere
  convert -size "${width}x${height}" xc:"${BASE00}" \
    \( -size 600x600 radial-gradient:"${BASE0D}-transparent" \) \
    -gravity center -compose over -composite \
    "$output_file"
}

generate_spheres() {
  # Multiple 3D spheres distributed across screen
  convert -size "${width}x${height}" xc:"${BASE00}" \
    \( -size 320x320 radial-gradient:"${BASE0D}-transparent" \) -gravity center -geometry -650-350 -compose over -composite \
    \( -size 280x280 radial-gradient:"${BASE0E}-transparent" \) -gravity center -geometry -350-400 -compose over -composite \
    \( -size 250x250 radial-gradient:"${BASE0C}-transparent" \) -gravity center -geometry -50-320 -compose over -composite \
    \( -size 300x300 radial-gradient:"${BASE0D}-transparent" \) -gravity center -geometry +300-380 -compose over -composite \
    \( -size 260x260 radial-gradient:"${BASE0E}-transparent" \) -gravity center -geometry +600-300 -compose over -composite \
    \( -size 350x350 radial-gradient:"${BASE0C}-transparent" \) -gravity center -geometry -700-50 -compose over -composite \
    \( -size 290x290 radial-gradient:"${BASE0D}-transparent" \) -gravity center -geometry -400+50 -compose over -composite \
    \( -size 270x270 radial-gradient:"${BASE0E}-transparent" \) -gravity center -geometry -100-50 -compose over -composite \
    \( -size 330x330 radial-gradient:"${BASE0C}-transparent" \) -gravity center -geometry +200+0 -compose over -composite \
    \( -size 240x240 radial-gradient:"${BASE0D}-transparent" \) -gravity center -geometry +550-50 -compose over -composite \
    \( -size 310x310 radial-gradient:"${BASE0E}-transparent" \) -gravity center -geometry +750+100 -compose over -composite \
    \( -size 280x280 radial-gradient:"${BASE0C}-transparent" \) -gravity center -geometry -600+250 -compose over -composite \
    \( -size 260x260 radial-gradient:"${BASE0D}-transparent" \) -gravity center -geometry -300+300 -compose over -composite \
    \( -size 300x300 radial-gradient:"${BASE0E}-transparent" \) -gravity center -geometry +50+250 -compose over -composite \
    \( -size 250x250 radial-gradient:"${BASE0C}-transparent" \) -gravity center -geometry +400+300 -compose over -composite \
    \( -size 290x290 radial-gradient:"${BASE0D}-transparent" \) -gravity center -geometry +700+350 -compose over -composite \
    \( -size 270x270 radial-gradient:"${BASE0E}-transparent" \) -gravity center -geometry -500+400 -compose over -composite \
    \( -size 320x320 radial-gradient:"${BASE0C}-transparent" \) -gravity center -geometry -150+380 -compose over -composite \
    \( -size 240x240 radial-gradient:"${BASE0D}-transparent" \) -gravity center -geometry +250+420 -compose over -composite \
    \( -size 280x280 radial-gradient:"${BASE0E}-transparent" \) -gravity center -geometry +550+400 -compose over -composite \
    "$output_file"
}

# Generate based on style
case "$style" in
  plasma)
    generate_plasma
    ;;
  geometric)
    generate_geometric
    ;;
  hexagons)
    generate_hexagons
    ;;
  circles)
    generate_circles
    ;;
  swirl)
    generate_swirl
    ;;
  spotlight)
    generate_spotlight
    ;;
  sphere)
    generate_sphere
    ;;
  spheres)
    generate_spheres
    ;;
  *)
    echo "Unknown style: $style"
    echo "Valid styles: plasma, geometric, hexagons, circles, swirl, spotlight, sphere, spheres"
    exit 1
    ;;
esac

echo "Generated: $output_file (${width}x${height}, style: $style)"

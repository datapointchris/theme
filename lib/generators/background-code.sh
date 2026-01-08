#!/usr/bin/env bash
# Generate code screenshot backgrounds using silicon
# Usage: background-code.sh <theme.yml> <output-file> [language]
#
# Creates syntax-highlighted code screenshots with theme background.
# Requires: silicon (brew install silicon)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_APP_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../theme.sh"

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <theme.yml> <output-file> [language]"
  echo ""
  echo "Languages: python, lua, bash (default: random)"
  echo "Uses sample code from demo/ folder."
  echo "Requires: silicon"
  exit 1
fi

theme_file="$1"
output_file="$2"
language="${3:-}"

if ! command -v silicon &>/dev/null; then
  echo "Error: silicon not found. Install with: brew install silicon" >&2
  exit 1
fi

# Load theme colors
eval "$(load_colors "$theme_file")"

# Map language to demo file
demo_dir="$THEME_APP_DIR/demo"
declare -A lang_files=(
  ["python"]="sample.py"
  ["lua"]="sample.lua"
  ["bash"]="sample.sh"
)

# Pick random language if not specified
if [[ -z "$language" ]]; then
  langs=("python" "lua" "bash")
  language="${langs[$((RANDOM % ${#langs[@]}))]}"
fi

source_file="$demo_dir/${lang_files[$language]:-sample.py}"
if [[ ! -f "$source_file" ]]; then
  echo "Error: Demo file not found: $source_file" >&2
  exit 1
fi

# Pick best matching silicon theme based on our theme
theme_id=$(yq -r '.meta.id // "default"' "$theme_file" 2>/dev/null || echo "default")
silicon_theme="base16"

# Map some known themes to silicon built-ins
case "$theme_id" in
  gruvbox*) silicon_theme="gruvbox-dark" ;;
  nord*) silicon_theme="Nord" ;;
  dracula*) silicon_theme="Dracula" ;;
  solarized-dark*) silicon_theme="Solarized (dark)" ;;
  solarized-light*) silicon_theme="Solarized (light)" ;;
  one-dark*|onedark*) silicon_theme="TwoDark" ;;
  github-dark*) silicon_theme="GitHub" ;;
esac

# Generate code screenshot with theme background
silicon "$source_file" \
  --output "$output_file" \
  --background "$BASE00" \
  --theme "$silicon_theme" \
  --pad-horiz 80 \
  --pad-vert 100 \
  --shadow-blur-radius 0 \
  --no-window-controls \
  2>/dev/null

# Verify output
if [[ ! -f "$output_file" ]]; then
  echo "Error: silicon failed to create output file" >&2
  exit 1
fi

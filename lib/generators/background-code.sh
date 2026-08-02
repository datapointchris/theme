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

# silicon's --theme takes a .tmTheme path as well as a built-in name, and every
# theme already generates one for bat, so the code render uses the theme's own
# colors rather than whichever built-in came closest. This previously defaulted
# to silicon's "base16", which renders every token at the background colour: the
# output was a blank canvas for every theme that missed the built-in mapping,
# and silicon still exited 0.
silicon_theme="$(dirname "$theme_file")/bat.tmTheme"
if [[ ! -f "$silicon_theme" ]]; then
  echo "Error: no bat.tmTheme beside $theme_file — run lib/generate-all.sh first" >&2
  exit 1
fi

silicon "$source_file" \
  --output "$output_file" \
  --background "$BASE00" \
  --theme "$silicon_theme" \
  --pad-horiz 80 \
  --pad-vert 100 \
  --shadow-blur-radius 0 \
  --no-window-controls

if [[ ! -f "$output_file" ]]; then
  echo "Error: silicon failed to create output file" >&2
  exit 1
fi

# silicon reports success on a render that produced nothing, so the only
# reliable check is the pixels: a wallpaper of one flat colour is a failure.
if [[ "$(magick "$output_file" -format %k info: 2>/dev/null || echo 2)" -lt 2 ]]; then
  echo "Error: silicon rendered a blank image from $silicon_theme" >&2
  exit 1
fi

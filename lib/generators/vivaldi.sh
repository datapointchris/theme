#!/usr/bin/env bash
# Generate a Vivaldi theme object from theme.yml
# Usage: vivaldi.sh <theme.yml> [output-file]
#
# The object is one entry of Vivaldi's `vivaldi.themes.user` pref, the same
# shape a theme archive's settings.json carries. `theme apply` upserts it into
# the profile's Preferences; see lib/vivaldi-preferences.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../theme.sh"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <theme.yml> [output-file]"
  exit 1
fi

input_file="$1"
output_file="${2:-}"

eval "$(load_colors "$input_file")"

UI_ACCENT="${EXTENDED_UI_ACCENT:-$BASE0D}"
UI_SELECTION="${EXTENDED_UI_SELECTION:-$BASE02}"

# Vivaldi derives every shade, hover and contrast text from these five, so the
# palette's own intermediate slots have nowhere to go.
#
# Vivaldi paints its accent across the whole toolbar row and the active tab, so
# the accent takes the selection shade that firefox-based.sh gives a selected
# tab. The loud UI accent goes to highlight, which marks focus and selection.
generate() {
  jq -n \
    --arg id "theme-${THEME_SLUG}" \
    --arg name "$THEME_NAME" \
    --arg bg "$SPECIAL_BG" \
    --arg fg "$SPECIAL_FG" \
    --arg window "$BASE01" \
    --arg accent "$UI_SELECTION" \
    --arg highlight "$UI_ACCENT" \
    '{
      engineVersion: 1,
      version: 1,
      id: $id,
      url: "",
      name: $name,
      accentFromPage: false,
      accentOnWindow: false,
      accentSaturationLimit: 1,
      backgroundImage: "",
      backgroundPosition: "stretch",
      backgroundSource: "",
      radius: 4,
      colorAccentBg: $accent,
      colorBg: $bg,
      colorFg: $fg,
      colorHighlightBg: $highlight,
      colorWindowBg: $window,
      contrast: 0,
      preferSystemAccent: false,
      alpha: 1,
      blur: 0,
      transparencyTabs: false,
      transparencyTabBar: false
    }'
}

if [[ -n "$output_file" ]]; then
  generate >"$output_file"
  echo "Generated: $output_file"
else
  generate
fi

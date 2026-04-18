#!/usr/bin/env bash
# Generate Ghostty custom CSS from theme.yml
# Usage: ghostty-css.sh <theme.yml> [output-file]
#
# Outputs tab-styling CSS for gtk-custom-css. Colors pulled from base16 palette
# for cross-theme consistency. Font is hardcoded — font is a separate concern
# from theming (managed by `font apply`, not `theme apply`).
# Applied via: gtk-custom-css = themes/current.css (in main ghostty config)

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

generate() {
  cat << EOF
/* ${THEME_NAME} - Ghostty tab CSS
 * Generated from theme.yml
 *
 * Widget tree (ghostty-org/ghostty discussions #5806, #9477):
 *   tabbar > tabbox > tabboxchild > tab > label
 * Selected state is tab:selected (libadwaita pseudo-class, not :checked).
 * Base16 mapping: BASE00 = bg, BASE01 = lifted bg, BASE04 = muted fg, BASE05 = fg.
 */

/* Tab strip background — blend into terminal */
tabbar,
tabbar tabbox {
  background-color: ${BASE00};
  border: none;
  box-shadow: none;
  margin-top: 2px;
}

/* No borders — let libadwaita handle separators adaptively */
tabbar tabbox tabboxchild {
  margin: 0 2px;
}

/* Tab base — tight vertical padding to compress strip height */
tabbar tabbox tab {
  background-color: ${BASE00};
  padding: 2px 14px;
  margin: 0;
}

/* Inactive tab label — muted */
tabbar tabbox tab label,
tabbar tabbox tab .title {
  font-family: "Comic Mono Nerd Font";
  font-size: 13pt;
  color: ${BASE04};
  font-weight: normal;
}

/* Active tab — lifted background + foreground-color text */
tabbar tabbox tab:selected {
  background-color: ${BASE01};
}

tabbar tabbox tab:selected label,
tabbar tabbox tab:selected .title {
  color: ${BASE05};
}
EOF
}

if [[ -n "$output_file" ]]; then
  generate > "$output_file"
  echo "Generated: $output_file"
else
  generate
fi

#!/usr/bin/env bash
# Generate aerc email client styleset from theme.yml
# Usage: aerc.sh <theme.yml> [output-file]
#
# aerc's built-in styling leans on the terminal's bright ANSI slots and fills
# whole rows with them, which reads as bright boxes and unreadable pairings on
# most palettes. Accents here are foreground-only; the only backgrounds used are
# the theme's own low base16 surfaces, so selection and chrome stay quiet.
#
# Applied to: ~/.config/aerc/stylesets/current

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

DIAG_ERROR="${EXTENDED_DIAGNOSTIC_ERROR:-$BASE08}"
DIAG_WARNING="${EXTENDED_DIAGNOSTIC_WARNING:-$BASE0A}"
DIAG_OK="${EXTENDED_DIAGNOSTIC_OK:-$BASE0B}"
DIAG_INFO="${EXTENDED_DIAGNOSTIC_INFO:-$BASE0D}"
UI_ACCENT="${EXTENDED_UI_ACCENT:-$BASE0D}"
UI_BORDER="${EXTENDED_UI_BORDER:-$BASE02}"
UI_SELECTION="${EXTENDED_UI_SELECTION:-$BASE02}"

generate() {
  cat <<EOF
# ${THEME_NAME} - aerc styleset
# Generated from theme.yml
# Author: ${THEME_AUTHOR}

default.fg = ${BASE05}
default.bg = ${BASE00}

# Selection is a raised surface, not an inverted block: aerc's own default
# reverses the row, which turns any saturated accent into a full-width glare
*.selected.bg = ${UI_SELECTION}
*.selected.fg = ${BASE06}
*.selected.bold = true

border.fg = ${UI_BORDER}
border.bg = ${BASE00}

title.fg = ${BASE00}
title.bg = ${UI_ACCENT}
title.bold = true

header.fg = ${UI_ACCENT}
header.bold = true

statusline_default.fg = ${BASE04}
statusline_default.bg = ${BASE01}
statusline_error.fg = ${DIAG_ERROR}
statusline_error.bg = ${BASE01}
statusline_error.bold = true
statusline_success.fg = ${DIAG_OK}
statusline_success.bg = ${BASE01}

error.fg = ${DIAG_ERROR}
error.bold = true
warning.fg = ${DIAG_WARNING}
success.fg = ${DIAG_OK}

# Read mail recedes to the muted ink so unread carries the weight on its own
msglist_default.fg = ${BASE05}
msglist_read.fg = ${BASE04}
msglist_unread.fg = ${BASE06}
msglist_unread.bold = true
msglist_answered.fg = ${BASE0C}
msglist_forwarded.fg = ${BASE0C}
msglist_flagged.fg = ${DIAG_ERROR}
msglist_deleted.fg = ${BASE03}
msglist_marked.fg = ${BASE09}
msglist_marked.bold = true
msglist_result.fg = ${DIAG_WARNING}
msglist_result.bold = true
msglist_gutter.fg = ${UI_BORDER}
msglist_pill.fg = ${BASE00}
msglist_pill.bg = ${UI_ACCENT}

# Thread prefixes are structure, not content — keep them below the subject line
msglist_thread_context.fg = ${BASE04}
msglist_thread_folded.fg = ${BASE0C}
msglist_thread_orphan.fg = ${BASE03}

dirlist_default.fg = ${BASE04}
dirlist_unread.fg = ${BASE06}
dirlist_unread.bold = true
dirlist_recent.fg = ${DIAG_OK}

tab.fg = ${BASE04}
tab.bg = ${BASE01}
tab.selected.fg = ${BASE00}
tab.selected.bg = ${UI_ACCENT}
tab.selected.bold = true

selector_default.fg = ${BASE05}
selector_focused.fg = ${BASE00}
selector_focused.bg = ${UI_ACCENT}
selector_chooser.fg = ${UI_ACCENT}
selector_chooser.bold = true

completion_default.fg = ${BASE05}
completion_default.bg = ${BASE01}
completion_description.fg = ${BASE03}
completion_gutter.bg = ${BASE01}
completion_pill.bg = ${UI_BORDER}

part_switcher.fg = ${BASE04}
part_switcher.bg = ${BASE01}
part_filename.fg = ${BASE0C}
part_mimetype.fg = ${BASE03}

# Underlined so a link stays identifiable where OSC 8 is stripped in transit
url.fg = ${DIAG_INFO}
url.underline = true
signature.fg = ${BASE03}
spinner.fg = ${UI_ACCENT}
stack.bg = ${BASE00}

# Quote depth cycles through the palette so nested replies stay separable
quote_1.fg = ${BASE0C}
quote_2.fg = ${BASE0B}
quote_3.fg = ${BASE0E}
quote_4.fg = ${BASE09}
quote_x.fg = ${BASE03}

diff_meta.fg = ${BASE05}
diff_meta.bold = true
diff_chunk.fg = ${BASE0C}
diff_chunk_func.fg = ${BASE0E}
diff_add.fg = ${EXTENDED_GIT_ADD:-$BASE0B}
diff_del.fg = ${EXTENDED_GIT_DELETE:-$BASE08}
EOF
}

if [[ -n "$output_file" ]]; then
  generate >"$output_file"
  echo "Generated: $output_file"
else
  generate
fi

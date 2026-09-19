#!/usr/bin/env bash
# Generate a glamour style for glow from theme.yml
# Usage: glow.sh <theme.yml> [output-file]
#
# glamour's built-in styles color everything with xterm-256 indices of 16 and
# up, or with fixed hex. Only indices 0-15 follow the terminal palette, so under
# the built-ins no text color changes with the theme. This style carries the
# theme's own colors instead.
#
# Prose renders in true color. Code blocks do not: glow leaves glamour's chroma
# formatter at terminal256, so each syntax color below reaches the screen as its
# nearest xterm-256 entry.
#
# The layout follows glamour's own dark style. Markup colors follow bat's markup
# scopes, and code colors come from resolve_syntax_colors, so a markdown file
# reads the same under `bat` and `glow`.

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
resolve_syntax_colors

GIT_ADD="${EXTENDED_GIT_ADD:-$BASE0B}"
GIT_DELETE="${EXTENDED_GIT_DELETE:-$BASE08}"

# No chroma "background". It would be painted per token, quantized to 256 colors
# and ragged at every line end, and glamour never paints the block's own
# background once chroma is set. Code sits on the terminal background, as in bat.
generate() {
  cat <<EOF
{
  "document": {
    "block_prefix": "\n",
    "block_suffix": "\n",
    "color": "${SPECIAL_FG}",
    "margin": 2
  },
  "block_quote": {
    "indent": 1,
    "indent_token": "│ ",
    "color": "${SYNTAX_COMMENT}",
    "italic": true
  },
  "paragraph": {},
  "list": {
    "level_indent": 2
  },
  "heading": {
    "block_suffix": "\n",
    "color": "${BASE0D}",
    "bold": true
  },
  "h1": {
    "prefix": " ",
    "suffix": " ",
    "color": "${SPECIAL_BG}",
    "background_color": "${BASE0D}",
    "bold": true
  },
  "h2": {
    "prefix": "## "
  },
  "h3": {
    "prefix": "### "
  },
  "h4": {
    "prefix": "#### "
  },
  "h5": {
    "prefix": "##### "
  },
  "h6": {
    "prefix": "###### ",
    "bold": false
  },
  "text": {},
  "strikethrough": {
    "crossed_out": true
  },
  "emph": {
    "italic": true
  },
  "strong": {
    "bold": true
  },
  "hr": {
    "color": "${BASE03}",
    "format": "\n--------\n"
  },
  "item": {
    "block_prefix": "• "
  },
  "enumeration": {
    "block_prefix": ". "
  },
  "task": {
    "ticked": "[✓] ",
    "unticked": "[ ] "
  },
  "link": {
    "color": "${BASE0C}",
    "underline": true
  },
  "link_text": {
    "color": "${BASE0C}",
    "bold": true
  },
  "image": {
    "color": "${BASE0E}",
    "underline": true
  },
  "image_text": {
    "color": "${BASE04}",
    "format": "Image: {{.text}} →"
  },
  "code": {
    "prefix": " ",
    "suffix": " ",
    "color": "${SYNTAX_STRING}",
    "background_color": "${BASE01}"
  },
  "code_block": {
    "color": "${SPECIAL_FG}",
    "margin": 2,
    "chroma": {
      "text": {
        "color": "${SPECIAL_FG}"
      },
      "error": {
        "color": "${SPECIAL_FG}",
        "background_color": "${BASE08}"
      },
      "comment": {
        "color": "${SYNTAX_COMMENT}",
        "italic": true
      },
      "comment_preproc": {
        "color": "${SYNTAX_KEYWORD}"
      },
      "keyword": {
        "color": "${SYNTAX_KEYWORD}"
      },
      "keyword_reserved": {
        "color": "${SYNTAX_KEYWORD}"
      },
      "keyword_namespace": {
        "color": "${SYNTAX_KEYWORD}"
      },
      "keyword_type": {
        "color": "${SYNTAX_TYPE}"
      },
      "operator": {
        "color": "${SYNTAX_OPERATOR}"
      },
      "punctuation": {
        "color": "${SYNTAX_PUNCTUATION}"
      },
      "name": {
        "color": "${SYNTAX_VARIABLE}"
      },
      "name_builtin": {
        "color": "${SYNTAX_FUNCTION}"
      },
      "name_tag": {
        "color": "${SYNTAX_TAG}"
      },
      "name_attribute": {
        "color": "${SYNTAX_ATTRIBUTE}"
      },
      "name_class": {
        "color": "${SYNTAX_TYPE}"
      },
      "name_constant": {
        "color": "${SYNTAX_CONSTANT}"
      },
      "name_decorator": {
        "color": "${BASE0E}"
      },
      "name_exception": {
        "color": "${SYNTAX_TYPE}"
      },
      "name_function": {
        "color": "${SYNTAX_FUNCTION}"
      },
      "literal_number": {
        "color": "${SYNTAX_NUMBER}"
      },
      "literal_string": {
        "color": "${SYNTAX_STRING}"
      },
      "literal_string_escape": {
        "color": "${BASE0C}"
      },
      "generic_deleted": {
        "color": "${GIT_DELETE}"
      },
      "generic_emph": {
        "italic": true
      },
      "generic_inserted": {
        "color": "${GIT_ADD}"
      },
      "generic_strong": {
        "bold": true
      },
      "generic_subheading": {
        "color": "${BASE0C}"
      }
    }
  },
  "table": {},
  "definition_list": {},
  "definition_term": {},
  "definition_description": {
    "block_prefix": "\n🠶 "
  },
  "html_block": {},
  "html_span": {}
}
EOF
}

if [[ -n "$output_file" ]]; then
  generate >"$output_file"
  echo "Generated: $output_file"
else
  generate
fi

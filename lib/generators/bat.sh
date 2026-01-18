#!/usr/bin/env bash
# Generate TextMate .tmTheme for bat syntax highlighter from theme.yml
# Usage: bat.sh <theme.yml> [output-file]
#
# Generates a TextMate theme file that bat can use for syntax highlighting.
# Apply by copying to ~/.config/bat/themes/current.tmTheme and running:
#   bat cache --build
#
# Bat config should have: --theme=current

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../theme.sh"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <theme.yml> [output-file]"
  exit 1
fi

input_file="$1"
output_file="${2:-}"

# Load colors
eval "$(load_colors "$input_file")"

# Define syntax colors with fallbacks to base16
# These prefer extended.syntax_* values from theme.yml which match Neovim colors
SYNTAX_COMMENT="${EXTENDED_SYNTAX_COMMENT:-$BASE03}"
SYNTAX_STRING="${EXTENDED_SYNTAX_STRING:-$BASE0B}"
SYNTAX_NUMBER="${EXTENDED_SYNTAX_NUMBER:-$BASE09}"
SYNTAX_CONSTANT="${EXTENDED_SYNTAX_CONSTANT:-$BASE09}"
SYNTAX_VARIABLE="${EXTENDED_SYNTAX_VARIABLE:-$BASE08}"
SYNTAX_PARAMETER="${EXTENDED_SYNTAX_PARAMETER:-$SPECIAL_FG}"
SYNTAX_FUNCTION="${EXTENDED_SYNTAX_FUNCTION:-$BASE0D}"
SYNTAX_KEYWORD="${EXTENDED_SYNTAX_KEYWORD:-$BASE0E}"
SYNTAX_TYPE="${EXTENDED_SYNTAX_TYPE:-$BASE0A}"
SYNTAX_OPERATOR="${EXTENDED_SYNTAX_OPERATOR:-$SPECIAL_FG}"
SYNTAX_PUNCTUATION="${EXTENDED_SYNTAX_PUNCTUATION:-$BASE04}"
SYNTAX_TAG="${EXTENDED_SYNTAX_TAG:-$BASE08}"
SYNTAX_ATTRIBUTE="${EXTENDED_SYNTAX_ATTRIBUTE:-$BASE0A}"

# Git/diff colors with fallbacks
GIT_ADD="${EXTENDED_GIT_ADD:-$BASE0B}"
GIT_DELETE="${EXTENDED_GIT_DELETE:-$BASE08}"
GIT_CHANGE="${EXTENDED_GIT_CHANGE:-$BASE0A}"

generate() {
  cat << 'HEADER'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
HEADER

  cat << EOF
	<key>name</key>
	<string>${THEME_NAME}</string>
	<key>author</key>
	<string>${THEME_AUTHOR:-Generated from theme.yml}</string>
	<key>comment</key>
	<string>Generated for bat syntax highlighter</string>
	<key>semanticClass</key>
	<string>theme.${THEME_VARIANT:-dark}.${THEME_SLUG:-custom}</string>
	<key>colorSpaceName</key>
	<string>sRGB</string>
	<key>settings</key>
	<array>
		<!-- Global settings -->
		<dict>
			<key>settings</key>
			<dict>
				<key>background</key>
				<string>${SPECIAL_BG}</string>
				<key>foreground</key>
				<string>${SPECIAL_FG}</string>
				<key>caret</key>
				<string>${SPECIAL_CURSOR}</string>
				<key>selection</key>
				<string>${SPECIAL_SELECTION_BG}</string>
				<key>selectionForeground</key>
				<string>${SPECIAL_SELECTION_FG}</string>
				<key>lineHighlight</key>
				<string>${BASE01}</string>
				<key>gutterBackground</key>
				<string>${SPECIAL_BG}</string>
				<key>gutterForeground</key>
				<string>${BASE03}</string>
				<key>findHighlight</key>
				<string>${BASE0A}</string>
				<key>findHighlightForeground</key>
				<string>${SPECIAL_BG}</string>
				<key>guide</key>
				<string>${BASE02}</string>
				<key>activeGuide</key>
				<string>${BASE03}</string>
				<key>bracketsForeground</key>
				<string>${BASE0C}</string>
				<key>bracketsOptions</key>
				<string>underline</string>
				<key>bracketContentsForeground</key>
				<string>${BASE0C}</string>
				<key>bracketContentsOptions</key>
				<string>underline</string>
			</dict>
		</dict>

		<!-- Comments -->
		<dict>
			<key>name</key>
			<string>Comment</string>
			<key>scope</key>
			<string>comment, punctuation.definition.comment</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_COMMENT}</string>
				<key>fontStyle</key>
				<string>italic</string>
			</dict>
		</dict>

		<!-- Strings -->
		<dict>
			<key>name</key>
			<string>String</string>
			<key>scope</key>
			<string>string, string.quoted</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_STRING}</string>
			</dict>
		</dict>

		<!-- String interpolation -->
		<dict>
			<key>name</key>
			<string>String Interpolation</string>
			<key>scope</key>
			<string>constant.character.escape, string.interpolated, punctuation.section.embedded</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${BASE0C}</string>
			</dict>
		</dict>

		<!-- Numbers -->
		<dict>
			<key>name</key>
			<string>Number</string>
			<key>scope</key>
			<string>constant.numeric</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_NUMBER}</string>
			</dict>
		</dict>

		<!-- Constants -->
		<dict>
			<key>name</key>
			<string>Built-in constant</string>
			<key>scope</key>
			<string>constant.language</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_CONSTANT}</string>
			</dict>
		</dict>

		<!-- User-defined constants -->
		<dict>
			<key>name</key>
			<string>User-defined constant</string>
			<key>scope</key>
			<string>constant.character, constant.other</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${BASE0C}</string>
			</dict>
		</dict>

		<!-- Variables -->
		<dict>
			<key>name</key>
			<string>Variable</string>
			<key>scope</key>
			<string>variable</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_VARIABLE}</string>
			</dict>
		</dict>

		<!-- Parameters -->
		<dict>
			<key>name</key>
			<string>Function parameter</string>
			<key>scope</key>
			<string>variable.parameter</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_PARAMETER}</string>
			</dict>
		</dict>

		<!-- Keywords -->
		<dict>
			<key>name</key>
			<string>Keyword</string>
			<key>scope</key>
			<string>keyword</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_KEYWORD}</string>
			</dict>
		</dict>

		<!-- Control keywords -->
		<dict>
			<key>name</key>
			<string>Control keyword</string>
			<key>scope</key>
			<string>keyword.control</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_KEYWORD}</string>
			</dict>
		</dict>

		<!-- Operators -->
		<dict>
			<key>name</key>
			<string>Operator</string>
			<key>scope</key>
			<string>keyword.operator</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_OPERATOR}</string>
			</dict>
		</dict>

		<!-- Storage -->
		<dict>
			<key>name</key>
			<string>Storage</string>
			<key>scope</key>
			<string>storage</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_KEYWORD}</string>
			</dict>
		</dict>

		<!-- Storage type -->
		<dict>
			<key>name</key>
			<string>Storage type</string>
			<key>scope</key>
			<string>storage.type</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_TYPE}</string>
			</dict>
		</dict>

		<!-- Class name -->
		<dict>
			<key>name</key>
			<string>Class name</string>
			<key>scope</key>
			<string>entity.name.class, entity.name.type.class</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_TYPE}</string>
			</dict>
		</dict>

		<!-- Inherited class -->
		<dict>
			<key>name</key>
			<string>Inherited class</string>
			<key>scope</key>
			<string>entity.other.inherited-class</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_TYPE}</string>
			</dict>
		</dict>

		<!-- Function name -->
		<dict>
			<key>name</key>
			<string>Function name</string>
			<key>scope</key>
			<string>entity.name.function</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_FUNCTION}</string>
			</dict>
		</dict>

		<!-- Function call -->
		<dict>
			<key>name</key>
			<string>Function call</string>
			<key>scope</key>
			<string>variable.function, support.function</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_FUNCTION}</string>
			</dict>
		</dict>

		<!-- Built-in functions -->
		<dict>
			<key>name</key>
			<string>Library function</string>
			<key>scope</key>
			<string>support.function</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_FUNCTION}</string>
			</dict>
		</dict>

		<!-- Type -->
		<dict>
			<key>name</key>
			<string>Type</string>
			<key>scope</key>
			<string>entity.name.type, support.type</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_TYPE}</string>
			</dict>
		</dict>

		<!-- Built-in types -->
		<dict>
			<key>name</key>
			<string>Built-in type</string>
			<key>scope</key>
			<string>support.type.builtin</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_TYPE}</string>
			</dict>
		</dict>

		<!-- Tag name (HTML/XML) -->
		<dict>
			<key>name</key>
			<string>Tag name</string>
			<key>scope</key>
			<string>entity.name.tag</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_TAG}</string>
			</dict>
		</dict>

		<!-- Tag attribute -->
		<dict>
			<key>name</key>
			<string>Tag attribute</string>
			<key>scope</key>
			<string>entity.other.attribute-name</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_ATTRIBUTE}</string>
			</dict>
		</dict>

		<!-- Punctuation -->
		<dict>
			<key>name</key>
			<string>Punctuation</string>
			<key>scope</key>
			<string>punctuation</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_PUNCTUATION}</string>
			</dict>
		</dict>

		<!-- Punctuation - definition -->
		<dict>
			<key>name</key>
			<string>Punctuation definition</string>
			<key>scope</key>
			<string>punctuation.definition.tag, punctuation.definition.string</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_PUNCTUATION}</string>
			</dict>
		</dict>

		<!-- Support -->
		<dict>
			<key>name</key>
			<string>Library class</string>
			<key>scope</key>
			<string>support.class</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_TYPE}</string>
			</dict>
		</dict>

		<!-- Library constant -->
		<dict>
			<key>name</key>
			<string>Library constant</string>
			<key>scope</key>
			<string>support.constant</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_CONSTANT}</string>
			</dict>
		</dict>

		<!-- Invalid -->
		<dict>
			<key>name</key>
			<string>Invalid</string>
			<key>scope</key>
			<string>invalid</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SPECIAL_FG}</string>
				<key>background</key>
				<string>${BASE08}</string>
			</dict>
		</dict>

		<!-- Invalid deprecated -->
		<dict>
			<key>name</key>
			<string>Invalid deprecated</string>
			<key>scope</key>
			<string>invalid.deprecated</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SPECIAL_FG}</string>
				<key>background</key>
				<string>${BASE0E}</string>
			</dict>
		</dict>

		<!-- Diff: inserted -->
		<dict>
			<key>name</key>
			<string>Diff inserted</string>
			<key>scope</key>
			<string>markup.inserted, meta.diff.header.to-file</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${GIT_ADD}</string>
			</dict>
		</dict>

		<!-- Diff: deleted -->
		<dict>
			<key>name</key>
			<string>Diff deleted</string>
			<key>scope</key>
			<string>markup.deleted, meta.diff.header.from-file</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${GIT_DELETE}</string>
			</dict>
		</dict>

		<!-- Diff: changed -->
		<dict>
			<key>name</key>
			<string>Diff changed</string>
			<key>scope</key>
			<string>markup.changed</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${GIT_CHANGE}</string>
			</dict>
		</dict>

		<!-- Diff: range -->
		<dict>
			<key>name</key>
			<string>Diff range</string>
			<key>scope</key>
			<string>meta.diff.range, meta.diff.index</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${BASE0C}</string>
			</dict>
		</dict>

		<!-- Markup: heading -->
		<dict>
			<key>name</key>
			<string>Markup heading</string>
			<key>scope</key>
			<string>markup.heading, punctuation.definition.heading</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${BASE0D}</string>
				<key>fontStyle</key>
				<string>bold</string>
			</dict>
		</dict>

		<!-- Markup: bold -->
		<dict>
			<key>name</key>
			<string>Markup bold</string>
			<key>scope</key>
			<string>markup.bold</string>
			<key>settings</key>
			<dict>
				<key>fontStyle</key>
				<string>bold</string>
			</dict>
		</dict>

		<!-- Markup: italic -->
		<dict>
			<key>name</key>
			<string>Markup italic</string>
			<key>scope</key>
			<string>markup.italic</string>
			<key>settings</key>
			<dict>
				<key>fontStyle</key>
				<string>italic</string>
			</dict>
		</dict>

		<!-- Markup: underline -->
		<dict>
			<key>name</key>
			<string>Markup underline</string>
			<key>scope</key>
			<string>markup.underline</string>
			<key>settings</key>
			<dict>
				<key>fontStyle</key>
				<string>underline</string>
			</dict>
		</dict>

		<!-- Markup: link -->
		<dict>
			<key>name</key>
			<string>Markup link</string>
			<key>scope</key>
			<string>markup.underline.link, string.other.link</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${BASE0D}</string>
			</dict>
		</dict>

		<!-- Markup: list -->
		<dict>
			<key>name</key>
			<string>Markup list</string>
			<key>scope</key>
			<string>markup.list, punctuation.definition.list</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_TAG}</string>
			</dict>
		</dict>

		<!-- Markup: quote -->
		<dict>
			<key>name</key>
			<string>Markup quote</string>
			<key>scope</key>
			<string>markup.quote</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_COMMENT}</string>
				<key>fontStyle</key>
				<string>italic</string>
			</dict>
		</dict>

		<!-- Markup: raw/code -->
		<dict>
			<key>name</key>
			<string>Markup raw</string>
			<key>scope</key>
			<string>markup.raw, markup.inline.raw</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_STRING}</string>
			</dict>
		</dict>

		<!-- JSON keys -->
		<dict>
			<key>name</key>
			<string>JSON key</string>
			<key>scope</key>
			<string>meta.structure.dictionary.key.json string.quoted</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${BASE0D}</string>
			</dict>
		</dict>

		<!-- YAML keys -->
		<dict>
			<key>name</key>
			<string>YAML key</string>
			<key>scope</key>
			<string>entity.name.tag.yaml</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${BASE0D}</string>
			</dict>
		</dict>

		<!-- CSS selectors -->
		<dict>
			<key>name</key>
			<string>CSS selector</string>
			<key>scope</key>
			<string>entity.name.tag.css, entity.other.attribute-name.class.css, entity.other.attribute-name.id.css</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${BASE0A}</string>
			</dict>
		</dict>

		<!-- CSS properties -->
		<dict>
			<key>name</key>
			<string>CSS property</string>
			<key>scope</key>
			<string>support.type.property-name.css</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${BASE0D}</string>
			</dict>
		</dict>

		<!-- CSS values -->
		<dict>
			<key>name</key>
			<string>CSS value</string>
			<key>scope</key>
			<string>support.constant.property-value.css</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${BASE09}</string>
			</dict>
		</dict>

		<!-- Regex -->
		<dict>
			<key>name</key>
			<string>Regular expression</string>
			<key>scope</key>
			<string>string.regexp</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${BASE0C}</string>
			</dict>
		</dict>

		<!-- Namespace -->
		<dict>
			<key>name</key>
			<string>Namespace</string>
			<key>scope</key>
			<string>entity.name.namespace, entity.name.module</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${BASE0A}</string>
			</dict>
		</dict>

		<!-- Decorator/annotation -->
		<dict>
			<key>name</key>
			<string>Decorator</string>
			<key>scope</key>
			<string>meta.decorator, meta.annotation</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${BASE0E}</string>
			</dict>
		</dict>

		<!-- Shell: variable -->
		<dict>
			<key>name</key>
			<string>Shell variable</string>
			<key>scope</key>
			<string>variable.other.normal.shell, variable.other.positional.shell, variable.other.bracket.shell, variable.other.special.shell</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_VARIABLE}</string>
			</dict>
		</dict>

		<!-- Shell: command -->
		<dict>
			<key>name</key>
			<string>Shell command</string>
			<key>scope</key>
			<string>support.function.builtin.shell</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>${SYNTAX_FUNCTION}</string>
			</dict>
		</dict>

	</array>
	<key>uuid</key>
	<string>$(uuidgen 2>/dev/null || echo "00000000-0000-0000-0000-000000000000")</string>
</dict>
</plist>
EOF
}

if [[ -n "$output_file" ]]; then
  generate > "$output_file"
  echo "Generated: $output_file"
else
  generate
fi

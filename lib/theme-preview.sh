#!/usr/bin/env bash
# Theme preview for fzf - displays colors using ANSI 24-bit escape codes
# Usage: theme-preview.sh <theme-directory>

set -euo pipefail

theme_dir="$1"
theme_file="$theme_dir/theme.yml"

if [[ ! -f "$theme_file" ]]; then
  echo "Theme file not found: $theme_file"
  exit 1
fi

# Preview width (characters)
WIDTH=56

# Read every value in a SINGLE yq pass. fzf re-runs this preview on each
# keystroke while navigating the picker, so spawning ~50 separate yq
# subprocesses (each ~0.1s of interpreter startup) made the pane lag for
# seconds per theme. One jq program emitting all key=value lines keeps it
# instant. Keys never contain '=', so IFS='=' splits cleanly into name/value.
declare -A T
while IFS='=' read -r key value; do
  T["$key"]="$value"
done < <(yq -r '[
  "name="               + (.meta.display_name // "Unknown"),
  "author="             + (.meta.author // "Unknown"),
  "variant="            + (.meta.variant // "dark"),
  "neovim_cs="          + (.meta.neovim_colorscheme_name // .meta.id // "unknown"),
  "theme_bg="           + (.special.background // "#1a1a1a"),
  "theme_fg="           + (.special.foreground // "#ffffff"),
  "theme_cursor="       + (.special.cursor // "#ffffff"),
  "theme_selection_bg=" + (.special.selection_bg // "#444444"),
  "theme_border="       + (.special.border // "#555555"),
  "black="              + (.ansi.black // "#000000"),
  "red="                + (.ansi.red // "#ff0000"),
  "green="              + (.ansi.green // "#00ff00"),
  "yellow="             + (.ansi.yellow // "#ffff00"),
  "blue="               + (.ansi.blue // "#0000ff"),
  "magenta="            + (.ansi.magenta // "#ff00ff"),
  "cyan="               + (.ansi.cyan // "#00ffff"),
  "white="              + (.ansi.white // "#ffffff"),
  "bright_black="       + (.ansi.bright_black // "#808080"),
  "bright_red="         + (.ansi.bright_red // "#ff8080"),
  "bright_green="       + (.ansi.bright_green // "#80ff80"),
  "bright_yellow="      + (.ansi.bright_yellow // "#ffff80"),
  "bright_blue="        + (.ansi.bright_blue // "#8080ff"),
  "bright_magenta="     + (.ansi.bright_magenta // "#ff80ff"),
  "bright_cyan="        + (.ansi.bright_cyan // "#80ffff"),
  "bright_white="       + (.ansi.bright_white // "#ffffff"),
  "base00="             + (.base16.base00 // "#000000"),
  "base01="             + (.base16.base01 // "#111111"),
  "base02="             + (.base16.base02 // "#222222"),
  "base03="             + (.base16.base03 // "#333333"),
  "base04="             + (.base16.base04 // "#444444"),
  "base05="             + (.base16.base05 // "#555555"),
  "base06="             + (.base16.base06 // "#666666"),
  "base07="             + (.base16.base07 // "#777777"),
  "base08="             + (.base16.base08 // "#ff0000"),
  "base09="             + (.base16.base09 // "#ff8000"),
  "base0A="             + (.base16.base0A // "#ffff00"),
  "base0B="             + (.base16.base0B // "#00ff00"),
  "base0C="             + (.base16.base0C // "#00ffff"),
  "base0D="             + (.base16.base0D // "#0080ff"),
  "base0E="             + (.base16.base0E // "#ff00ff"),
  "base0F="             + (.base16.base0F // "#804000"),
  "syntax_comment="     + (.extended.syntax_comment // .ansi.bright_black // "#808080"),
  "syntax_string="      + (.extended.syntax_string // .ansi.green // "#00ff00"),
  "syntax_keyword="     + (.extended.syntax_keyword // .ansi.magenta // "#ff00ff"),
  "syntax_function="    + (.extended.syntax_function // .ansi.blue // "#0000ff"),
  "syntax_number="      + (.extended.syntax_number // .ansi.cyan // "#00ffff"),
  "syntax_type="        + (.extended.syntax_type // .ansi.yellow // "#ffff00"),
  "syntax_operator="    + (.extended.syntax_operator // .ansi.yellow // "#ffff00"),
  "git_add="            + (.extended.git_add // .ansi.green // "#00ff00"),
  "git_change="         + (.extended.git_change // .ansi.yellow // "#ffff00"),
  "git_delete="         + (.extended.git_delete // .ansi.red // "#ff0000"),
  "diag_error="         + (.extended.diagnostic_error // .ansi.red // "#ff0000"),
  "diag_warning="       + (.extended.diagnostic_warning // .ansi.yellow // "#ffff00"),
  "diag_info="          + (.extended.diagnostic_info // .ansi.blue // "#0000ff"),
  "diag_hint="          + (.extended.diagnostic_hint // .ansi.cyan // "#00ffff")
] | .[]' "$theme_file")

name="${T[name]}"
author="${T[author]}"
variant="${T[variant]}"
neovim_cs="${T[neovim_cs]}"

theme_bg="${T[theme_bg]}"
theme_fg="${T[theme_fg]}"
theme_cursor="${T[theme_cursor]}"
theme_selection_bg="${T[theme_selection_bg]}"
theme_border="${T[theme_border]}"

black="${T[black]}"
red="${T[red]}"
green="${T[green]}"
yellow="${T[yellow]}"
blue="${T[blue]}"
magenta="${T[magenta]}"
cyan="${T[cyan]}"
white="${T[white]}"

bright_black="${T[bright_black]}"
bright_red="${T[bright_red]}"
bright_green="${T[bright_green]}"
bright_yellow="${T[bright_yellow]}"
bright_blue="${T[bright_blue]}"
bright_magenta="${T[bright_magenta]}"
bright_cyan="${T[bright_cyan]}"
bright_white="${T[bright_white]}"

base00="${T[base00]}"
base01="${T[base01]}"
base02="${T[base02]}"
base03="${T[base03]}"
base04="${T[base04]}"
base05="${T[base05]}"
base06="${T[base06]}"
base07="${T[base07]}"
base08="${T[base08]}"
base09="${T[base09]}"
base0A="${T[base0A]}"
base0B="${T[base0B]}"
base0C="${T[base0C]}"
base0D="${T[base0D]}"
base0E="${T[base0E]}"
base0F="${T[base0F]}"

syntax_comment="${T[syntax_comment]}"
syntax_string="${T[syntax_string]}"
syntax_keyword="${T[syntax_keyword]}"
syntax_function="${T[syntax_function]}"
syntax_number="${T[syntax_number]}"
syntax_type="${T[syntax_type]}"
syntax_operator="${T[syntax_operator]}"

git_add="${T[git_add]}"
git_change="${T[git_change]}"
git_delete="${T[git_delete]}"
diag_error="${T[diag_error]}"
diag_warning="${T[diag_warning]}"
diag_info="${T[diag_info]}"
diag_hint="${T[diag_hint]}"

# ANSI escape helpers
reset=$'\033[0m'
bold=$'\033[1m'

# Convert hex to ANSI - fg with theme bg
c() {
  local hex="${1#\#}"
  local bg_hex="${theme_bg#\#}"
  printf '\033[38;2;%d;%d;%d;48;2;%d;%d;%dm' \
    "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}" \
    "0x${bg_hex:0:2}" "0x${bg_hex:2:2}" "0x${bg_hex:4:2}"
}

# Background only
bg() {
  local hex="${1#\#}"
  printf '\033[48;2;%d;%d;%dm' "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

# Pre-compute common color combos (fg color on theme bg)
C_FG="$(c "$theme_fg")"
C_DIM="$(c "$base03")"
C_KW="$(c "$syntax_keyword")"
C_FN="$(c "$syntax_function")"
C_TY="$(c "$syntax_type")"
C_ST="$(c "$syntax_string")"
C_NU="$(c "$syntax_number")"
C_CM="$(c "$syntax_comment")"
C_OP="$(c "$syntax_operator")"
C_ERR="$(c "$diag_error")"
C_WRN="$(c "$diag_warning")"
C_INF="$(c "$diag_info")"
C_HNT="$(c "$diag_hint")"
C_ADD="$(c "$git_add")"
C_CHG="$(c "$git_change")"
C_DEL="$(c "$git_delete")"
BG="$(bg "$theme_bg")"

# Print line with theme background, padded to WIDTH
p() {
  local text="$1"
  # Print: bg + text + padding + reset
  printf '%s' "$BG"
  printf '%s' "$text"
  # Pad with spaces (crude but works - just print extra spaces)
  printf '%*s' $((WIDTH - ${#text} + 40)) ""
  printf '%s\n' "$reset"
}

# Print a color swatch block
s() {
  printf '%s  %s' "$(bg "$1")" "$BG"
}

# Output all lines
p ""
p "${C_FG}${bold} $name${reset}${BG}"
p "${C_DIM} Author: $author"
p "${C_DIM} Variant: $variant | Neovim: $neovim_cs"
p ""
p "${C_FG}${bold} Special${reset}${BG}"
p " $(s "$theme_bg")${C_DIM}bg $(s "$theme_fg")${C_DIM}fg $(s "$theme_cursor")${C_DIM}cur $(s "$theme_selection_bg")${C_DIM}sel $(s "$theme_border")${C_DIM}bdr"
p ""
p "${C_FG}${bold} ANSI Normal${reset}${BG}"
p " $(s "$black")$(s "$red")$(s "$green")$(s "$yellow")$(s "$blue")$(s "$magenta")$(s "$cyan")$(s "$white")${C_DIM} 0-7"
p ""
p "${C_FG}${bold} ANSI Bright${reset}${BG}"
p " $(s "$bright_black")$(s "$bright_red")$(s "$bright_green")$(s "$bright_yellow")$(s "$bright_blue")$(s "$bright_magenta")$(s "$bright_cyan")$(s "$bright_white")${C_DIM} 8-15"
p ""
p "${C_FG}${bold} Base16${reset}${BG}"
p " $(s "$base00")$(s "$base01")$(s "$base02")$(s "$base03")$(s "$base04")$(s "$base05")$(s "$base06")$(s "$base07")${C_DIM} 00-07"
p " $(s "$base08")$(s "$base09")$(s "$base0A")$(s "$base0B")$(s "$base0C")$(s "$base0D")$(s "$base0E")$(s "$base0F")${C_DIM} 08-0F"
p ""
p "${C_FG}${bold} Syntax${reset}${BG}"
p " ${C_KW}keyword ${C_FN}func ${C_TY}Type ${C_ST}\"str\" ${C_NU}42 ${C_CM}# comment"
p ""
p "${C_FG}${bold} Diagnostics${reset}${BG} ${C_ERR}err ${C_WRN}warn ${C_INF}info ${C_HNT}hint"
p "${C_FG}${bold} Git${reset}${BG}         ${C_ADD}+add ${C_CHG}~chg ${C_DEL}-del"
p ""
p "${C_FG}${bold} Code Sample${reset}${BG}"
p "${C_CM}  # Configuration module"
p "${C_KW}  from ${C_TY}typing ${C_KW}import ${C_TY}Dict"
p ""
p "${C_KW}  class ${C_TY}Config${C_FG}:"
p "${C_ST}      \"\"\"App config.\"\"\""
p "${C_FG}      VERSION ${C_OP}= ${C_ST}\"1.0\""
p ""
p "${C_KW}      def ${C_FN}__init__${C_FG}(self, name):"
p "${C_FG}          self.name ${C_OP}= ${C_FG}name"
p "${C_FG}          self.count ${C_OP}= ${C_NU}42"
p ""
p "${C_KW}      def ${C_FN}validate${C_FG}(self):"
p "${C_KW}          return ${C_FG}self.count ${C_OP}> ${C_NU}0"
p ""

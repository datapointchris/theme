#!/usr/bin/env bash
# theme.sh - Functions for reading theme.yml files
# Sources theme colors into shell variables for use by generators

set -euo pipefail

# The variable contract every generator consumes after
# `eval "$(load_colors ...)"`. Named, never assigned: `export` on its own leaves
# a name unset, so `set -u` still catches a generator that runs without the
# eval, while static analysis can see these are produced here for consumers
# elsewhere — rather than reading them as typos of the lowercase locals below,
# or as dead names in this file.
export \
  ANSI_BLACK \
  ANSI_BLUE \
  ANSI_BRIGHT_BLACK \
  ANSI_BRIGHT_BLUE \
  ANSI_BRIGHT_CYAN \
  ANSI_BRIGHT_GREEN \
  ANSI_BRIGHT_MAGENTA \
  ANSI_BRIGHT_RED \
  ANSI_BRIGHT_WHITE \
  ANSI_BRIGHT_YELLOW \
  ANSI_CYAN \
  ANSI_GREEN \
  ANSI_MAGENTA \
  ANSI_RED \
  ANSI_WHITE \
  ANSI_YELLOW \
  SPECIAL_BG \
  SPECIAL_BORDER \
  SPECIAL_CURSOR \
  SPECIAL_CURSOR_TEXT \
  SPECIAL_FG \
  SPECIAL_PANEL \
  SPECIAL_SELECTION_BG \
  SPECIAL_SELECTION_FG \
  THEME_AUTHOR \
  THEME_NAME \
  THEME_SLUG \
  THEME_SOURCE \
  THEME_VARIANT

# Read a value from theme.yml using yq
# Usage: theme_get <key> <theme_file>
theme_get() {
  local key="$1"
  local file="$2"
  yq "$key // \"\"" "$file"
}

# Load all theme colors into shell variables
# Usage: eval "$(load_theme theme.yml)"
# Outputs same variable names as palette.sh for compatibility with generators
load_theme() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo "Error: Theme file not found: $file" >&2
    return 1
  fi

  # One yq process for the whole file.
  #
  # This was one `theme_get` — one yq spawn — per key, about eighty per theme.
  # yq itself takes 30ms, so the reads were nothing and the process spawns were
  # everything: five seconds per load on the Intel machines, paid once by every
  # generator, which is 600 loads in a full regeneration. Adding a key here costs
  # nothing now; adding one as a separate call cost another spawn.
  local raw
  if ! raw=$(yq -r '
    [
      ["THEME_NAME", .meta.display_name],
      ["THEME_AUTHOR", .meta.author],
      ["THEME_VARIANT", .meta.variant],
      ["THEME_SOURCE", .meta.derived_from],
      ["THEME_SLUG", .meta.id],
      ["BASE00", .base16.base00],
      ["BASE01", .base16.base01],
      ["BASE02", .base16.base02],
      ["BASE03", .base16.base03],
      ["BASE04", .base16.base04],
      ["BASE05", .base16.base05],
      ["BASE06", .base16.base06],
      ["BASE07", .base16.base07],
      ["BASE08", .base16.base08],
      ["BASE09", .base16.base09],
      ["BASE0A", .base16.base0A],
      ["BASE0B", .base16.base0B],
      ["BASE0C", .base16.base0C],
      ["BASE0D", .base16.base0D],
      ["BASE0E", .base16.base0E],
      ["BASE0F", .base16.base0F],
      ["ansi_black", .ansi.black],
      ["ansi_red", .ansi.red],
      ["ansi_green", .ansi.green],
      ["ansi_yellow", .ansi.yellow],
      ["ansi_blue", .ansi.blue],
      ["ansi_magenta", .ansi.magenta],
      ["ansi_cyan", .ansi.cyan],
      ["ansi_white", .ansi.white],
      ["bright_black", .ansi.bright_black],
      ["bright_red", .ansi.bright_red],
      ["bright_green", .ansi.bright_green],
      ["bright_yellow", .ansi.bright_yellow],
      ["bright_blue", .ansi.bright_blue],
      ["bright_magenta", .ansi.bright_magenta],
      ["bright_cyan", .ansi.bright_cyan],
      ["bright_white", .ansi.bright_white],
      ["bg", .special.background],
      ["fg", .special.foreground],
      ["cursor", .special.cursor],
      ["cursor_text", .special.cursor_text],
      ["sel_bg", .special.selection_bg],
      ["sel_fg", .special.selection_fg],
      ["border", .special.border],
      ["panel", .special.panel]
    ]
    + ((.extended // {}) | to_entries | map(["EXTENDED_" + (.key | upcase), .value]))
    | map([.[0], (.[1] // "")]) | .[] | @tsv
  ' "$file" 2>&1); then
    echo "Error: could not read theme file: $file" >&2
    echo "$raw" >&2
    return 1
  fi

  local -A field=()
  local key value
  while IFS=$'\t' read -r key value; do
    [[ -n "$key" ]] && field["$key"]="$value"
  done <<<"$raw"

  # Metadata (from meta section)
  echo "THEME_NAME=\"${field[THEME_NAME]}\""
  echo "THEME_AUTHOR=\"${field[THEME_AUTHOR]}\""
  echo "THEME_VARIANT=\"${field[THEME_VARIANT]}\""
  echo "THEME_SOURCE=\"${field[THEME_SOURCE]}\""
  echo "THEME_SLUG=\"${field[THEME_SLUG]}\""

  # Base16 palette. Emitted before everything below, because the fallbacks are
  # literal "$BASE08" strings that the caller's eval resolves in order.
  local slot
  for slot in BASE00 BASE01 BASE02 BASE03 BASE04 BASE05 BASE06 BASE07 \
    BASE08 BASE09 BASE0A BASE0B BASE0C BASE0D BASE0E BASE0F; do
    echo "$slot=\"${field[$slot]}\""
  done

  # ANSI colors (same structure as palette.yml)
  local ansi_black ansi_red ansi_green ansi_yellow ansi_blue ansi_magenta ansi_cyan ansi_white
  ansi_black="${field[ansi_black]}"
  ansi_red="${field[ansi_red]}"
  ansi_green="${field[ansi_green]}"
  ansi_yellow="${field[ansi_yellow]}"
  ansi_blue="${field[ansi_blue]}"
  ansi_magenta="${field[ansi_magenta]}"
  ansi_cyan="${field[ansi_cyan]}"
  ansi_white="${field[ansi_white]}"

  echo "ANSI_BLACK=\"${ansi_black:-\$BASE00}\""
  echo "ANSI_RED=\"${ansi_red:-\$BASE08}\""
  echo "ANSI_GREEN=\"${ansi_green:-\$BASE0B}\""
  echo "ANSI_YELLOW=\"${ansi_yellow:-\$BASE0A}\""
  echo "ANSI_BLUE=\"${ansi_blue:-\$BASE0D}\""
  echo "ANSI_MAGENTA=\"${ansi_magenta:-\$BASE0E}\""
  echo "ANSI_CYAN=\"${ansi_cyan:-\$BASE0C}\""
  echo "ANSI_WHITE=\"${ansi_white:-\$BASE05}\""

  # Bright ANSI colors
  local bright_black bright_red bright_green bright_yellow bright_blue bright_magenta bright_cyan bright_white
  bright_black="${field[bright_black]}"
  bright_red="${field[bright_red]}"
  bright_green="${field[bright_green]}"
  bright_yellow="${field[bright_yellow]}"
  bright_blue="${field[bright_blue]}"
  bright_magenta="${field[bright_magenta]}"
  bright_cyan="${field[bright_cyan]}"
  bright_white="${field[bright_white]}"

  echo "ANSI_BRIGHT_BLACK=\"${bright_black:-\$BASE03}\""
  echo "ANSI_BRIGHT_RED=\"${bright_red:-\$BASE08}\""
  echo "ANSI_BRIGHT_GREEN=\"${bright_green:-\$BASE0B}\""
  echo "ANSI_BRIGHT_YELLOW=\"${bright_yellow:-\$BASE0A}\""
  echo "ANSI_BRIGHT_BLUE=\"${bright_blue:-\$BASE0D}\""
  echo "ANSI_BRIGHT_MAGENTA=\"${bright_magenta:-\$BASE0E}\""
  echo "ANSI_BRIGHT_CYAN=\"${bright_cyan:-\$BASE0C}\""
  echo "ANSI_BRIGHT_WHITE=\"${bright_white:-\$BASE07}\""

  # Special colors (with fallbacks)
  local bg fg cursor cursor_text sel_bg sel_fg border panel
  bg="${field[bg]}"
  fg="${field[fg]}"
  cursor="${field[cursor]}"
  cursor_text="${field[cursor_text]}"
  sel_bg="${field[sel_bg]}"
  sel_fg="${field[sel_fg]}"
  border="${field[border]}"
  panel="${field[panel]}"

  echo "SPECIAL_BG=\"${bg:-\$BASE00}\""
  echo "SPECIAL_FG=\"${fg:-\$BASE05}\""
  echo "SPECIAL_CURSOR=\"${cursor:-\$BASE05}\""
  echo "SPECIAL_CURSOR_TEXT=\"${cursor_text:-\$BASE00}\""
  echo "SPECIAL_SELECTION_BG=\"${sel_bg:-\$BASE02}\""
  echo "SPECIAL_SELECTION_FG=\"${sel_fg:-\$BASE05}\""
  echo "SPECIAL_BORDER=\"${border:-\$BASE03}\""
  echo "SPECIAL_PANEL=\"${panel:-\$BASE01}\""

  # Extended colors, optional and read by name by individual generators. Already
  # upcased and prefixed by the yq pass above; sorted here only so the emitted
  # block is stable to read, since nothing consumes them in order.
  local extended_key
  while read -r extended_key; do
    [[ -n "$extended_key" ]] || continue
    echo "${extended_key}=\"${field[$extended_key]}\""
  done < <(printf '%s\n' "${!field[@]}" | grep '^EXTENDED_' | sort)
}

# Load colors from theme.yml (alias for load_theme)
load_colors() {
  load_theme "$1"
}

# Convert color to uppercase (for btop)
to_upper() {
  echo "$1" | tr '[:lower:]' '[:upper:]'
}

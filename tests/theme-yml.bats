#!/usr/bin/env bats
# theme.yml -> shell variable contract.
#
# lib/theme.sh is the only thing that reads theme.yml, and every generator
# consumes what it emits via `eval "$(load_colors ...)"`. So this file asserts on
# the variables after the eval, not on the text of the assignments: the fallbacks
# are written as literal "$BASE08" strings that only become colours when the eval
# runs, and a generator sees the resolved value.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  use_fixture_themes_dir
  # theme.sh stands alone — no lib.sh, no storage.sh. Generators source only
  # this, which is why it must not grow a dependency on them.
  # shellcheck source=../lib/theme.sh
  source "$THEME_ROOT/lib/theme.sh"
  FIXTURE=$(make_fixture_theme fixture-dark "Fixture Dark")
}

@test "theme_get reads a value" {
  run theme_get '.meta.id' "$FIXTURE"
  assert_success
  assert_output "fixture-dark"
}

@test "theme_get returns empty for a missing key, never the string null" {
  # The load-bearing half of theme_get's `// ""`. Bare yq prints "null" for an
  # absent key, and "null" is a non-empty string — so every `${value:-fallback}`
  # below would keep it and generators would write `color = null` into real app
  # configs rather than falling back to a base16 slot.
  run theme_get '.special.cursor' "$FIXTURE"
  assert_success
  assert_output ""
}

@test "load_theme fails on a missing file" {
  run load_theme "$THEMES_DIR/nope/theme.yml"
  assert_failure
  assert_output --partial "Theme file not found"
}

@test "metadata comes from the meta block" {
  eval "$(load_theme "$FIXTURE")"
  assert_equal "$THEME_SLUG" "fixture-dark"
  assert_equal "$THEME_NAME" "Fixture Dark"
  assert_equal "$THEME_AUTHOR" "Fixture Author"
  assert_equal "$THEME_VARIANT" "dark"
  assert_equal "$THEME_SOURCE" "fixture"
}

@test "base16 slots pass through unchanged" {
  eval "$(load_theme "$FIXTURE")"
  assert_equal "$BASE00" "#000000"
  assert_equal "$BASE08" "#080808"
  assert_equal "$BASE0D" "#0d0d0d"
  assert_equal "$BASE0F" "#0f0f0f"
}

@test "ANSI colors fall back to their base16 slots by hue" {
  # The fallback map is the reason a palette is transcribed by hue rather than by
  # role: a theme with no ansi block gets its red from base08, so putting a green
  # in base08 to match some upstream "keywords" role would make the terminal's
  # red green.
  eval "$(load_theme "$FIXTURE")"
  assert_equal "$ANSI_BLACK" "#000000"   # base00
  assert_equal "$ANSI_RED" "#080808"     # base08
  assert_equal "$ANSI_GREEN" "#0b0b0b"   # base0B
  assert_equal "$ANSI_YELLOW" "#0a0a0a"  # base0A
  assert_equal "$ANSI_BLUE" "#0d0d0d"    # base0D
  assert_equal "$ANSI_MAGENTA" "#0e0e0e" # base0E
  assert_equal "$ANSI_CYAN" "#0c0c0c"    # base0C
  assert_equal "$ANSI_WHITE" "#050505"   # base05
}

@test "bright ANSI colors fall back with black and white shifted, the rest shared" {
  # Only bright_black and bright_white differ from their normal counterparts
  # (base03 and base07 rather than base00 and base05). Everything else falls back
  # to the same slot as its normal variant, so a theme with no ansi block has no
  # visible bright/normal distinction beyond those two.
  eval "$(load_theme "$FIXTURE")"
  assert_equal "$ANSI_BRIGHT_BLACK" "#030303" # base03, not base00
  assert_equal "$ANSI_BRIGHT_WHITE" "#070707" # base07, not base05
  assert_equal "$ANSI_BRIGHT_RED" "$ANSI_RED"
  assert_equal "$ANSI_BRIGHT_GREEN" "$ANSI_GREEN"
  assert_equal "$ANSI_BRIGHT_BLUE" "$ANSI_BLUE"
}

@test "an explicit ansi block wins over the fallback" {
  cat >>"$FIXTURE" <<'YAML'
ansi:
  red: "#ff0000"
  bright_black: "#444444"
YAML
  eval "$(load_theme "$FIXTURE")"
  assert_equal "$ANSI_RED" "#ff0000"
  assert_equal "$ANSI_BRIGHT_BLACK" "#444444"
  # An ansi block that names only some colours still falls back for the rest.
  assert_equal "$ANSI_GREEN" "#0b0b0b"
}

@test "special colors fall back to their base16 slots" {
  eval "$(load_theme "$FIXTURE")"
  assert_equal "$SPECIAL_BG" "#000000"           # base00
  assert_equal "$SPECIAL_FG" "#050505"           # base05
  assert_equal "$SPECIAL_CURSOR" "#050505"       # base05
  assert_equal "$SPECIAL_CURSOR_TEXT" "#000000"  # base00
  assert_equal "$SPECIAL_SELECTION_BG" "#020202" # base02
  assert_equal "$SPECIAL_SELECTION_FG" "#050505" # base05
  assert_equal "$SPECIAL_BORDER" "#030303"       # base03
  assert_equal "$SPECIAL_PANEL" "#010101"        # base01
}

@test "an explicit special block wins over the fallback" {
  cat >>"$FIXTURE" <<'YAML'
special:
  background: "#123456"
  cursor: "#abcdef"
YAML
  eval "$(load_theme "$FIXTURE")"
  assert_equal "$SPECIAL_BG" "#123456"
  assert_equal "$SPECIAL_CURSOR" "#abcdef"
  assert_equal "$SPECIAL_FG" "#050505"
}

@test "extended keys become EXTENDED_ variables, uppercased" {
  # Generators read a fixed set of these by name, so the casing rule is a
  # contract: ui_accent in the yaml is EXTENDED_UI_ACCENT in the generator, and
  # real themes carry keys like bg0_h and _nc that must survive it intact.
  cat >>"$FIXTURE" <<'YAML'
extended:
  ui_accent: "#aa00aa"
  bg0_h: "#111111"
  _nc: "#222222"
YAML
  eval "$(load_theme "$FIXTURE")"
  assert_equal "$EXTENDED_UI_ACCENT" "#aa00aa"
  assert_equal "$EXTENDED_BG0_H" "#111111"
  assert_equal "$EXTENDED__NC" "#222222"
}

@test "a theme with no extended block emits no EXTENDED_ variables" {
  # Not cosmetic: generators test these with ${EXTENDED_X:-fallback}, so an
  # EXTENDED_X assigned to the empty string is a different thing from an absent
  # one only because of the colon. Emitting nothing keeps both readings correct.
  run pipeline "load_theme '$FIXTURE' | grep -c EXTENDED_ || true"
  assert_success
  assert_output "0"
}

@test "load_colors is load_theme" {
  # Generators call load_colors; the name predates theme.yml and is still what
  # every one of them uses.
  local via_alias via_direct
  via_alias=$(load_colors "$FIXTURE")
  via_direct=$(load_theme "$FIXTURE")
  assert_equal "$via_alias" "$via_direct"
}

@test "to_upper uppercases a hex colour for btop" {
  run to_upper "#a3be8c"
  assert_success
  assert_output "#A3BE8C"
}

@test "every real theme.yml loads without error" {
  # The integration end of this file, and the cheapest guard against a hand-edited
  # theme.yml with a broken key: load_theme is the single reader every generator
  # goes through, so a theme that fails here produces broken configs for 20 apps.
  local theme_file
  for theme_file in "$THEME_ROOT"/themes/*/theme.yml; do
    run pipeline "eval \"\$(load_theme '$theme_file')\"; echo \"\$SPECIAL_BG\""
    assert_success
    assert_output --regexp '^#[0-9a-fA-F]{6}$'
  done
}

#!/usr/bin/env bats
# Installing a theme into Vivaldi's Preferences.
#
# The file is the user's whole browser profile, rewritten in place, so an apply
# must change nothing but the theme: their own themes and every other pref
# survive, a reapplied theme is replaced rather than duplicated, and ours is
# selected under both OS-schedule slots as well as `current`.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  source_theme_libs

  vivaldi="$BATS_TEST_TMPDIR/vivaldi"
  mkdir -p "$vivaldi/Default"
  printf '{"profile":{"info_cache":{"Default":{}}}}' >"$vivaldi/Local State"
  printf '{"browser":{"has_seen_welcome_page":true},"vivaldi":{"theme":{"schedule":{"o_s":{"light":"Vivaldi1","dark":"Vivaldi2"}}},"themes":{"user":[{"id":"mine","name":"Mine"}]}}}' \
    >"$vivaldi/Default/Preferences"
  printf '{"id":"theme-a","name":"A"}' >"$BATS_TEST_TMPDIR/a.json"
  printf '{"id":"theme-b","name":"B"}' >"$BATS_TEST_TMPDIR/b.json"
}

@test "an install keeps the user's themes and prefs and selects the theme" {
  vivaldi_install_theme "$vivaldi" "$BATS_TEST_TMPDIR/a.json"
  vivaldi_install_theme "$vivaldi" "$BATS_TEST_TMPDIR/b.json"
  vivaldi_install_theme "$vivaldi" "$BATS_TEST_TMPDIR/b.json"

  run jq -c '[.vivaldi.themes.user[].id], .vivaldi.themes.current, .vivaldi.theme.schedule.o_s, .browser' \
    "$vivaldi/Default/Preferences"
  assert_output '["mine","theme-a","theme-b"]
"theme-b"
{"light":"theme-b","dark":"theme-b"}
{"has_seen_welcome_page":true}'
}

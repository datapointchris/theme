#!/usr/bin/env bats
# A whole `theme apply`: every app the platform themes receives the theme.
#
# apply_theme_to_apps is the path a user reaches on every apply, and each app
# step reports only applied or skipped. The per-app installs are pinned in
# apply-install.bats. What this file pins is the dispatch: which apps a
# platform runs, and that each one lands the theme rather than skipping.
#
# The reloads that reach a live session (tmux, hyprctl, signals to running
# bars) are in reload_apps, which the CLI calls separately, so nothing here
# touches the machine. bat and delta are stubbed so the result does not depend
# on whether the machine running the suite has them.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  source_theme_libs
  use_fixture_themes_dir

  stub_command bat
  stub_command delta
  set_background_mode none

  make_fixture_theme alpha-dark "Alpha Dark" generated >/dev/null
  local artifact
  for artifact in ghostty.conf kitty.conf tmux.conf btop.theme abtop.theme tui-theme.json \
    flavor.toml userChrome.css bat.tmTheme delta.conf sioyek.config hyprland.lua \
    waybar.css hyprlock.conf dunst.conf rofi.rasi; do
    printf 'generated for alpha-dark\n' >"$THEMES_DIR/alpha-dark/$artifact"
  done
  printf '{"id":"alpha-dark","name":"Alpha Dark"}\n' >"$THEMES_DIR/alpha-dark/vivaldi.json"

  # A Firefox profile, so the browser step has somewhere to install.
  source "$THEME_ROOT/lib/browser-profiles.sh"
  firefox_profile="$BATS_TEST_TMPDIR/firefox-profile"
  mkdir -p "$firefox_profile" "$(dirname "$(get_profiles_ini firefox)")"
  printf '[Profile0]\nPath=%s\nDefault=1\n' "$firefox_profile" >"$(get_profiles_ini firefox)"
}

# Each path holds the fixture artifact, reached through its pointer.
assert_installed() {
  local path
  for path in "$@"; do
    [[ "$(cat "$HOME/.config/$path" 2>/dev/null)" == "generated for alpha-dark" ]] \
      || fail "$path does not hold alpha-dark"
  done
}

@test "an apply on a plain Linux machine themes every cross-platform app" {
  PLATFORM=linux run pipeline "apply_theme_to_apps alpha-dark 2>/dev/null"
  assert_success
  assert_line "APPLIED:tmux btop abtop tui-theme yazi browsers bat delta sioyek"
  assert_line "SKIPPED:none"

  assert_equal "$(get_current_theme)" "alpha-dark"
  assert_installed tmux/themes/current.conf btop/themes/current.theme \
    abtop/themes/current.theme tui-theme/current.json yazi/flavors/current.yazi/flavor.toml \
    bat/themes/current.tmTheme delta/current.gitconfig
  assert_equal "$(cat "$firefox_profile/chrome/userChrome.css")" "generated for alpha-dark"
}

@test "an apply on Arch also themes the terminals, the desktop and Vivaldi" {
  local vivaldi
  vivaldi=$(vivaldi_user_data_dir)
  mkdir -p "$vivaldi/Default"
  printf '{"profile":{"info_cache":{"Default":{}}}}' >"$vivaldi/Local State"
  printf '{}' >"$vivaldi/Default/Preferences"

  PLATFORM=arch run pipeline "apply_theme_to_apps alpha-dark 2>/dev/null"
  assert_success
  assert_line "APPLIED:ghostty kitty tmux btop abtop tui-theme yazi browsers vivaldi bat delta sioyek hyprland waybar hyprlock dunst rofi"
  assert_line "SKIPPED:none"

  assert_equal "$(get_current_theme)" "alpha-dark"
  assert_installed ghostty/themes/current.conf kitty/themes/current-theme.conf \
    hypr/themes/current.lua waybar/themes/current.css hypr/themes/hyprlock.conf \
    rofi/themes/current.rasi dunst/dunstrc.d/99-theme.conf
  assert_equal "$(jq -r '.vivaldi.themes.current' "$vivaldi/Default/Preferences")" "alpha-dark"
}

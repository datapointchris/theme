#!/usr/bin/env bats
# Where an applied theme lands, and what `current` is.
#
# Every consumer names `current`, and `current` is now a symlink to a file carrying
# the theme's own id rather than a copy overwritten on every apply. Both halves are
# load-bearing and neither is obvious from a call site, so they are pinned here.
#
# The pointer keeps its name because an app that can only `source` a path needs one
# that does not move, and because the apps resolving a theme *by name* read their
# config from a symlink into the dotfiles repo — writing the name there would write
# through into that checkout, which is how the gowall palettes dirtied it for months.
#
# The install half is testable even though the apply path as a whole is not: what
# reaches the live machine is the *reload* (hyprctl, pkill borders, tmux
# source-file), and those are stubbed. Everything below writes only under a sandbox
# HOME.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  source_theme_libs
  use_fixture_themes_dir

  make_fixture_theme alpha-dark "Alpha Dark" generated >/dev/null
  make_fixture_theme beta-light "Beta Light" plugin >/dev/null
}

# The apply functions read a generated artifact rather than theme.yml, and
# make_fixture_theme writes only the source. Content is a marker so an assertion
# can tell a resolved pointer from a stale copy.
give_artifact() {
  local id="$1" artifact="$2"
  printf 'generated for %s\n' "$id" >"$THEMES_DIR/$id/$artifact"
}

@test "an artifact installs under the theme id" {
  give_artifact alpha-dark ghostty.conf

  run apply_ghostty alpha-dark
  assert_success
  assert [ -f "$HOME/.config/ghostty/themes/alpha-dark.conf" ]
}

@test "current is a symlink at the installed name, not a copy" {
  give_artifact alpha-dark ghostty.conf
  apply_ghostty alpha-dark

  assert [ -L "$HOME/.config/ghostty/themes/current.conf" ]
  run readlink "$HOME/.config/ghostty/themes/current.conf"
  assert_output "alpha-dark.conf"
}

@test "the link is relative, so the directory survives being moved or exported" {
  give_artifact alpha-dark ghostty.conf
  apply_ghostty alpha-dark

  run readlink "$HOME/.config/ghostty/themes/current.conf"
  refute_output --partial "/"
}

@test "a current left as a real file by the copy scheme becomes a link" {
  # The migration path off every machine that ever ran the previous version.
  # Without the unlink, ln leaves the stale copy in place and the apply is a silent
  # no-op — the theme changes and nothing on screen does.
  mkdir -p "$HOME/.config/ghostty/themes"
  echo "stale" >"$HOME/.config/ghostty/themes/current.conf"
  give_artifact alpha-dark ghostty.conf

  apply_ghostty alpha-dark

  assert [ -L "$HOME/.config/ghostty/themes/current.conf" ]
  run cat "$HOME/.config/ghostty/themes/current.conf"
  assert_output --partial "generated for alpha-dark"
}

@test "applying a second theme leaves the first installed" {
  # The point of naming the payload: every theme applied stays selectable, which is
  # what the app's own theme picker needs and what makes an exported config say
  # which theme it is running.
  give_artifact alpha-dark ghostty.conf
  give_artifact beta-light ghostty.conf
  apply_ghostty alpha-dark

  apply_ghostty beta-light

  assert [ -f "$HOME/.config/ghostty/themes/alpha-dark.conf" ]
  run readlink "$HOME/.config/ghostty/themes/current.conf"
  assert_output "beta-light.conf"
}

@test "yazi installs a flavor directory and links current.yazi at it" {
  give_artifact alpha-dark flavor.toml

  run apply_yazi alpha-dark
  assert_success
  assert [ -f "$HOME/.config/yazi/flavors/alpha-dark.yazi/flavor.toml" ]
  assert [ -L "$HOME/.config/yazi/flavors/current.yazi" ]
}

@test "a current.yazi left as a real directory is replaced, not linked into" {
  # ln -sfn onto a real directory creates the link *inside* it, which would leave
  # the stale flavor.toml in place and a nested current.yazi nobody reads.
  mkdir -p "$HOME/.config/yazi/flavors/current.yazi"
  echo "stale" >"$HOME/.config/yazi/flavors/current.yazi/flavor.toml"
  give_artifact alpha-dark flavor.toml

  apply_yazi alpha-dark

  assert [ -L "$HOME/.config/yazi/flavors/current.yazi" ]
  run cat "$HOME/.config/yazi/flavors/current.yazi/flavor.toml"
  assert_output --partial "generated for alpha-dark"
}

@test "yazi's theme.toml is written here, because yazi refuses to start without its flavor" {
  give_artifact alpha-dark flavor.toml

  apply_yazi alpha-dark

  run cat "$HOME/.config/yazi/theme.toml"
  assert_output --partial 'dark = "current"'
}

@test "a symlinked theme.toml is never written through" {
  # That path was dotfiles-managed until dotfiles stopped shipping it. A machine on
  # an older checkout still has the link, and writing through it edits the repo.
  give_artifact alpha-dark flavor.toml
  mkdir -p "$HOME/.config/yazi"
  echo "owned elsewhere" >"$BATS_TEST_TMPDIR/managed.toml"
  ln -s "$BATS_TEST_TMPDIR/managed.toml" "$HOME/.config/yazi/theme.toml"

  apply_yazi alpha-dark

  run cat "$BATS_TEST_TMPDIR/managed.toml"
  assert_output "owned elsewhere"
}

@test "hyprland and hyprlock share a themes directory without colliding" {
  stub_command hyprctl
  give_artifact alpha-dark hyprland.conf
  give_artifact alpha-dark hyprlock.conf

  apply_hyprland alpha-dark
  apply_hyprlock alpha-dark

  assert [ -f "$HOME/.config/hypr/themes/alpha-dark.conf" ]
  assert [ -f "$HOME/.config/hypr/themes/alpha-dark-hyprlock.conf" ]
  run readlink "$HOME/.config/hypr/themes/hyprlock.conf"
  assert_output "alpha-dark-hyprlock.conf"
}

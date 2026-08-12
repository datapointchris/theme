#!/usr/bin/env bats
# What an apply says when it could not do the whole job.
#
# An apply is nearly all successes, so the failure worth engineering for is the one
# that produces no output at all: a plugin theme whose Neovim colorscheme was never
# installed changes the terminal and leaves the editor alone, and every tick on
# screen still says the apply worked.
#
# The channel matters as much as the message. `apply_theme_to_apps` calls every
# `apply_*` with stderr redirected to /dev/null, so a warning written there during
# an apply is discarded — which is why warnings are collected and printed by the
# caller instead.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  source_theme_libs
  use_fixture_themes_dir

  # The check is skipped outright where there is no Neovim to be wrong about.
  stub_command nvim
}

plugin_theme() {
  local id="$1" plugin="$2" colorscheme="$3"
  local file
  file=$(make_fixture_theme "$id" "$id" plugin)
  yq -i ".meta.plugin = \"$plugin\" | .meta.neovim_colorscheme_name = \"$colorscheme\"" "$file"
}

installed_colorscheme() {
  mkdir -p "$HOME/.config/nvim/colors"
  touch "$HOME/.config/nvim/colors/$1.lua"
}

@test "a plugin colorscheme that is not installed is warned about, by name" {
  plugin_theme oceanic upstream/oceanic-next OceanicNext

  check_neovim_colorscheme oceanic

  assert [ "${#APPLY_WARNINGS[@]}" -eq 1 ]
  assert_regex "${APPLY_WARNINGS[0]}" "OceanicNext"
  assert_regex "${APPLY_WARNINGS[0]}" "upstream/oceanic-next"
}

@test "an installed colorscheme raises nothing" {
  plugin_theme oceanic upstream/oceanic-next OceanicNext
  installed_colorscheme OceanicNext

  check_neovim_colorscheme oceanic

  assert [ "${#APPLY_WARNINGS[@]}" -eq 0 ]
}

@test "a colorscheme is found wherever a plugin manager put it" {
  # lazy.nvim and vim.pack use different layouts, and the check looks for the file
  # `:colorscheme` actually needs rather than for either manager's directory.
  plugin_theme oceanic upstream/oceanic-next OceanicNext
  mkdir -p "$HOME/.local/share/nvim/lazy/oceanic-next/colors"
  touch "$HOME/.local/share/nvim/lazy/oceanic-next/colors/OceanicNext.lua"

  check_neovim_colorscheme oceanic

  assert [ "${#APPLY_WARNINGS[@]}" -eq 0 ]
}

@test "a theme with no plugin is never warned about" {
  # Either generated here or built into Neovim, and neither can be missing —
  # retrobox is the second case and would otherwise warn on every apply.
  make_fixture_theme retrobox "Retrobox" plugin >/dev/null

  check_neovim_colorscheme retrobox

  assert [ "${#APPLY_WARNINGS[@]}" -eq 0 ]
}

@test "the warning says the editor keeps its old colours when there is no fallback" {
  plugin_theme oceanic upstream/oceanic-next OceanicNext

  check_neovim_colorscheme oceanic

  assert_regex "${APPLY_WARNINGS[0]}" "no generated fallback"
}

@test "the warning names the fallback when the theme ships one" {
  # The fallback is deliberately not named after the colorscheme it stands in
  # for, so a warning that only said "falling back" would leave the reader with
  # nothing to type.
  plugin_theme oceanic upstream/oceanic-next OceanicNext
  mkdir -p "$THEMES_DIR/oceanic/neovim/colors"
  touch "$THEMES_DIR/oceanic/neovim/colors/theme-oceanic.lua"

  check_neovim_colorscheme oceanic

  assert_regex "${APPLY_WARNINGS[0]}" "theme-oceanic"
}

@test "an empty neovim directory is not mistaken for a fallback" {
  # The directory is created by the generator before it writes anything, so the
  # colorscheme file is what says the fallback is really there.
  plugin_theme oceanic upstream/oceanic-next OceanicNext
  mkdir -p "$THEMES_DIR/oceanic/neovim/colors"

  check_neovim_colorscheme oceanic

  assert_regex "${APPLY_WARNINGS[0]}" "no generated fallback"
}

@test "nothing is checked when there is no neovim on the machine" {
  # The stub is what makes the rest of this file testable; without one, a warning
  # would name an editor the user does not have.
  rm -f "$BATS_TEST_TMPDIR/stubs/nvim"
  plugin_theme oceanic upstream/oceanic-next OceanicNext

  PATH="$BATS_TEST_TMPDIR/stubs" check_neovim_colorscheme oceanic

  assert [ "${#APPLY_WARNINGS[@]}" -eq 0 ]
}

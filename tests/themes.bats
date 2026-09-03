#!/usr/bin/env bats
# Theme discovery, name resolution and the current-theme state file.
#
# themes/ is the single source of truth — there is no index — so every one of
# these functions is a directory scan, and all of them run against a fixture
# THEMES_DIR rather than the repo's real themes, whose count and names move.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  source_theme_libs
  use_fixture_themes_dir

  make_fixture_theme alpha-dark "Alpha Dark" generated >/dev/null
  make_fixture_theme beta-light "Beta Light" plugin >/dev/null
  make_fixture_theme OceanicNext "Oceanic Next" plugin >/dev/null
}

@test "get_theme_names lists the theme directories" {
  run get_theme_names
  assert_success
  assert_line "alpha-dark"
  assert_line "beta-light"
  assert_line "OceanicNext"
  assert_equal "${#lines[@]}" 3
}

@test "get_theme_names fails when the themes directory is gone" {
  rm -rf "$THEMES_DIR"
  run get_theme_names
  assert_failure
  assert_output --partial "Themes directory not found"
}

@test "count_themes counts directories with no surrounding whitespace" {
  # `wc -l | xargs` rather than `wc -l`: the trim matters because the count is
  # interpolated straight into "Available Themes (N total)".
  run count_themes
  assert_success
  assert_output "3"
}

@test "a directory without a theme.yml still lists but resolves to nothing" {
  # An incomplete theme directory — a half-finished addition, or a checkout with
  # the yml missing — is visible to the listing and invisible to every reader.
  mkdir -p "$THEMES_DIR/no-yml"
  run get_theme_names
  assert_line "no-yml"

  run get_theme_by_name no-yml
  assert_failure
}

@test "get_theme_by_name returns the theme.yml contents" {
  run get_theme_by_name alpha-dark
  assert_success
  assert_output --partial 'id: "alpha-dark"'
}

@test "get_theme_by_name matches case-insensitively" {
  # OceanicNext is the real precedent: its directory is camel case because the
  # Neovim colorscheme is, so anything a user types is the wrong case.
  run get_theme_by_name oceanicnext
  assert_success
  assert_output --partial 'id: "OceanicNext"'
}

@test "get_theme_mapping reads a meta field" {
  run get_theme_mapping alpha-dark neovim_colorscheme_source
  assert_success
  assert_output "generated"
}

@test "get_theme_mapping returns empty for an absent meta field" {
  run get_theme_mapping alpha-dark plugin
  assert_success
  assert_output ""
}

@test "get_theme_mapping fails for an unknown theme" {
  run get_theme_mapping nonexistent variant
  assert_failure
}

@test "theme_name_to_canonical passes an exact directory name through" {
  run theme_name_to_canonical alpha-dark
  assert_success
  assert_output "alpha-dark"
}

@test "theme_name_to_canonical resolves a case variant to the directory name" {
  # Must not shortcut on `[[ -d "$THEMES_DIR/$input" ]]`: macOS is
  # case-insensitive, so that test says yes for any spelling and the user's
  # spelling then reaches the state file and the gist-synced history under an id
  # the Arch box cannot resolve. Passes trivially on Linux; on macOS it is the
  # whole reason resolution matches against the listing instead.
  run theme_name_to_canonical oceanicnext
  assert_success
  assert_output "OceanicNext"
}

@test "theme_name_to_canonical resolves a display name to the directory name" {
  # What makes `theme apply "Beta Light"` work, and why the picker can pass its
  # own label back in.
  run theme_name_to_canonical "beta light"
  assert_success
  assert_output "beta-light"
}

@test "theme_name_to_canonical echoes an unknown name back unchanged" {
  # Deliberate, and the quiet failure mode to know about: resolution never
  # errors, so callers find out only when get_theme_path returns empty.
  run theme_name_to_canonical "not-a-theme"
  assert_success
  assert_output "not-a-theme"
}

@test "get_theme_path resolves through canonicalization" {
  run get_theme_path "beta light"
  assert_success
  assert_output "$THEMES_DIR/beta-light"
}

@test "get_theme_path is empty for an unknown theme" {
  run get_theme_path "not-a-theme"
  assert_success
  assert_output ""
}

@test "get_library_path is get_theme_path" {
  # Kept for the apply path, which still calls the old name.
  run get_library_path alpha-dark
  assert_output "$THEMES_DIR/alpha-dark"
}

@test "get_theme_display_info labels a generated theme" {
  run get_theme_display_info alpha-dark
  assert_success
  assert_output "Alpha Dark (Generated)"
}

@test "get_theme_display_info labels a plugin theme" {
  run get_theme_display_info beta-light
  assert_success
  assert_output "Beta Light (Neovim Plugin)"
}

@test "get_theme_display_info falls back to the id when display_name is absent" {
  yq -i 'del(.meta.display_name)' "$THEMES_DIR/alpha-dark/theme.yml"
  run get_theme_display_info alpha-dark
  assert_success
  assert_output "alpha-dark (Generated)"
}

@test "get_theme_display_info adds no label for an unrecognized source" {
  # Only "generated" and "plugin" are labeled. A typo in the field is therefore
  # invisible here, and equally invisible to Neovim's picker, which reads the
  # same field.
  yq -i '.meta.neovim_colorscheme_source = "typo"' "$THEMES_DIR/alpha-dark/theme.yml"
  run get_theme_display_info alpha-dark
  assert_success
  assert_output "Alpha Dark"
}

@test "get_theme_display_info echoes the id for a theme with no theme.yml" {
  run get_theme_display_info missing-theme
  assert_success
  assert_output "missing-theme"
}

@test "current theme round-trips through the state file" {
  set_current_theme alpha-dark
  run get_current_theme
  assert_success
  assert_output "alpha-dark"
}

@test "get_current_theme is empty before anything is applied" {
  run get_current_theme
  assert_success
  assert_output ""
}

@test "the current-theme file stays in production even in development mode" {
  # The coupling to Neovim: it watches ~/.local/state/theme/current with a libuv
  # fs_event. THEME_STATE_DIR moves to .dev-data under THEME_ENV=development, and
  # if the current-theme file moved with it, dev-mode applies would stop reaching
  # the editor — hence the separate THEME_LIVE_DIR.
  run bash -c "HOME='$HOME' THEME_ENV=development bash -c 'source \"$THEME_ROOT/lib/lib.sh\"; echo \"\$CURRENT_THEME_FILE\"; echo \"\$THEME_STATE_DIR\"'"
  assert_success
  assert_line --index 0 "$HOME/.local/state/theme/current"
  assert_line --index 1 "$THEME_ROOT/.dev-data"
}

@test "list_themes_with_status marks the current theme" {
  set_current_theme beta-light
  run list_themes_with_status
  assert_success
  assert_line "● Beta Light (Neovim Plugin) (current)"
  assert_line "  Alpha Dark (Generated)"
}

@test "every theme directory in the repo has a theme.yml" {
  # The repo-level invariant behind all of the above: a directory under themes/
  # without a theme.yml is listed by the CLI and unreadable by everything else.
  local dir
  for dir in "$THEME_ROOT"/themes/*/; do
    [[ -f "$dir/theme.yml" ]] || fail "$dir has no theme.yml"
  done
}

@test "no two themes in the repo share a display name" {
  # Display names are one of the three things theme_name_to_canonical resolves,
  # and a duplicate makes `theme apply "<name>"` silently pick whichever
  # directory the glob reaches first. -N suppresses yq's inter-document "---",
  # which otherwise counts as a value here.
  run pipeline "yq -N -r '.meta.display_name' $THEME_ROOT/themes/*/theme.yml | sort | uniq -d"
  assert_success
  assert_output ""
}

@test "no theme id in the repo differs from its directory name" {
  # meta.id is what history, the state file and Neovim all key on, while the
  # directory is what the listing scan produces. A theme where they disagree
  # applies fine and records its history under the other name.
  local dir id
  for dir in "$THEME_ROOT"/themes/*/; do
    id=$(yq -r '.meta.id' "$dir/theme.yml")
    assert_equal "$id" "$(basename "$dir")"
  done
}

#!/usr/bin/env bats
# Which background styles are in the rotation, and where source images come from.
#
# Two config files under ~/.config/theme, both line-oriented: background-mode
# holds the enabled styles, background-sources.conf holds path references rather
# than copies, so adding a directory tracks whatever is in it later.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  source_theme_libs
}

#==============================================================================
# MODES
#==============================================================================

@test "the mode defaults to all before anything is configured" {
  # "all" is a sentinel, not an expansion: nothing enumerates the styles until
  # asked, so a style added to BACKGROUND_GENERATED_STYLES is enabled for anyone
  # who never customized their mode.
  run get_background_mode
  assert_success
  assert_output "all"
}

@test "an empty mode file reads as all" {
  mkdir -p "$(dirname "$BACKGROUND_MODE_FILE")"
  : >"$BACKGROUND_MODE_FILE"
  run get_background_mode
  assert_output "all"
}

@test "list_available_background_modes names the generated styles and the transforms" {
  # The generated styles are prefixed and the source transforms are not, which is
  # the distinction is_background_type_enabled parses back out of a background id.
  run list_available_background_modes
  assert_line "generated:plasma"
  assert_line "recolor"
  assert_line "ascii"
  assert_line "lowpoly"
}

@test "set_background_mode replaces the whole list" {
  set_background_mode recolor ascii
  run get_background_mode
  assert_line --index 0 "recolor"
  assert_line --index 1 "ascii"
  assert_equal "${#lines[@]}" 2

  set_background_mode lowpoly
  run get_background_mode
  assert_output "lowpoly"
}

@test "set_background_mode all writes the sentinel rather than every style" {
  set_background_mode recolor
  set_background_mode all
  run get_background_mode
  assert_output "all"
}

@test "add_background_mode is a no-op while the mode is all" {
  run add_background_mode recolor
  assert_success
  assert_output --partial "Already set to 'all'"
  run get_background_mode
  assert_output "all"
}

@test "add_background_mode appends, and refuses a duplicate" {
  set_background_mode recolor
  run add_background_mode ascii
  assert_output "Added: ascii"

  run add_background_mode ascii
  assert_output "Mode already enabled: ascii"

  run get_background_mode
  assert_equal "${#lines[@]}" 2
}

@test "removing a mode from all expands the list minus that one" {
  # The only place the sentinel is expanded, and it has to be: there is no way to
  # express "everything except ascii" as a sentinel.
  set_background_mode all
  run remove_background_mode ascii
  assert_output --partial "expanded from 'all'"

  run get_background_mode
  assert_line "generated:plasma"
  assert_line "recolor"
  assert_line "lowpoly"
  refute_line "ascii"
}

@test "remove_background_mode reports a mode that was not enabled" {
  set_background_mode recolor
  run remove_background_mode ascii
  assert_output "Mode not enabled: ascii"
  run get_background_mode
  assert_output "recolor"
}

@test "remove_background_mode can empty the list, which reads back as all" {
  # Worth knowing rather than guessing at: removing the last mode does not
  # disable backgrounds, it re-enables everything, because an empty file is
  # indistinguishable from an unconfigured one.
  set_background_mode recolor
  remove_background_mode recolor
  run get_background_mode
  assert_output "all"
}

@test "is_background_type_enabled accepts everything under all" {
  run is_background_type_enabled "generated:plasma"
  assert_success
  run is_background_type_enabled "recolor:/pics/one.jpg"
  assert_success
}

@test "is_background_type_enabled matches a generated style exactly or by category" {
  set_background_mode "generated:plasma"
  run is_background_type_enabled "generated:plasma"
  assert_success

  set_background_mode generated
  run is_background_type_enabled "generated:plasma"
  assert_success

  set_background_mode recolor
  run is_background_type_enabled "generated:plasma"
  assert_failure
}

@test "is_background_type_enabled reads the transform out of a source background id" {
  # A source background id is "<transform>:<path>", so the enablement check keys
  # on the prefix and the path is irrelevant to it.
  set_background_mode ascii
  run is_background_type_enabled "ascii:/pics/one.jpg"
  assert_success
  run is_background_type_enabled "recolor:/pics/one.jpg"
  assert_failure
}

@test "get_enabled_generated_styles expands all and the generated category" {
  run get_enabled_generated_styles
  assert_output "plasma"

  set_background_mode generated
  run get_enabled_generated_styles
  assert_output "plasma"

  set_background_mode "generated:plasma"
  run get_enabled_generated_styles
  assert_output "plasma"

  set_background_mode recolor
  run get_enabled_generated_styles
  assert_output ""
}

@test "is_source_type_enabled and is_recolor_enabled follow the mode" {
  run is_recolor_enabled
  assert_success

  set_background_mode ascii
  run is_recolor_enabled
  assert_failure
  run is_source_type_enabled ascii
  assert_success
  run is_source_type_enabled lowpoly
  assert_failure
}

#==============================================================================
# SOURCES
#==============================================================================

@test "add_background_source rejects a path that does not exist" {
  run add_background_source "$BATS_TEST_TMPDIR/nope.jpg"
  assert_failure
  assert_output --partial "Path not found"
}

@test "add_background_source rejects a file that is not an image" {
  echo "text" >"$BATS_TEST_TMPDIR/notes.txt"
  run add_background_source "$BATS_TEST_TMPDIR/notes.txt"
  assert_failure
  assert_output --partial "Not an image file"
}

@test "add_background_source stores a file as an absolute path with a file: prefix" {
  # Paths, not copies — so the entry has to be absolute, since it is resolved
  # from whatever directory a later rotation happens to run in.
  make_test_image "$BATS_TEST_TMPDIR/pics/one.png"
  cd "$BATS_TEST_TMPDIR/pics"
  run add_background_source "one.png"
  assert_success
  assert_output --partial "Added file:"

  run list_background_source_entries
  assert_output "file:$BATS_TEST_TMPDIR/pics/one.png"
}

@test "add_background_source stores a directory with a dir: prefix and an image count" {
  make_test_image "$BATS_TEST_TMPDIR/pics/one.png"
  make_test_image "$BATS_TEST_TMPDIR/pics/two.png"
  echo "not an image" >"$BATS_TEST_TMPDIR/pics/readme.txt"

  run add_background_source "$BATS_TEST_TMPDIR/pics"
  assert_success
  assert_output --partial "(2 images)"

  run list_background_source_entries
  assert_output "dir:$BATS_TEST_TMPDIR/pics"
}

@test "add_background_source refuses to add the same entry twice" {
  make_test_image "$BATS_TEST_TMPDIR/pics/one.png"
  add_background_source "$BATS_TEST_TMPDIR/pics/one.png"
  run add_background_source "$BATS_TEST_TMPDIR/pics/one.png"
  assert_success
  assert_output --partial "already added"

  run list_background_source_entries
  assert_equal "${#lines[@]}" 1
}

@test "add_background_source distinguishes a path from one it is a prefix of" {
  # Was a substring test, so adding ~/pics while ~/pics-old was already listed
  # reported "already added" and silently dropped an entire wallpaper directory.
  mkdir -p "$BATS_TEST_TMPDIR/pics-old" "$BATS_TEST_TMPDIR/pics"
  add_background_source "$BATS_TEST_TMPDIR/pics-old"
  run add_background_source "$BATS_TEST_TMPDIR/pics"
  assert_success
  assert_output --partial "Added directory:"

  run list_background_source_entries
  assert_equal "${#lines[@]}" 2
}

@test "removing a full entry leaves an entry it is a prefix of alone" {
  mkdir -p "$BATS_TEST_TMPDIR/pics-old" "$BATS_TEST_TMPDIR/pics"
  add_background_source "$BATS_TEST_TMPDIR/pics"
  add_background_source "$BATS_TEST_TMPDIR/pics-old"

  run remove_background_source "dir:$BATS_TEST_TMPDIR/pics"
  assert_success

  run list_background_source_entries
  assert_output "dir:$BATS_TEST_TMPDIR/pics-old"
}

@test "a directory source is expanded at read time, not at add time" {
  # The reason sources are stored as paths: images dropped into a watched
  # directory afterwards are picked up without touching the config.
  make_test_image "$BATS_TEST_TMPDIR/pics/one.png"
  add_background_source "$BATS_TEST_TMPDIR/pics"

  run get_all_background_images
  assert_equal "${#lines[@]}" 1

  make_test_image "$BATS_TEST_TMPDIR/pics/two.jpg"
  run get_all_background_images
  assert_equal "${#lines[@]}" 2
}

@test "get_all_background_images skips a file entry whose file has gone" {
  make_test_image "$BATS_TEST_TMPDIR/pics/one.png"
  add_background_source "$BATS_TEST_TMPDIR/pics/one.png"
  rm "$BATS_TEST_TMPDIR/pics/one.png"

  run get_all_background_images
  assert_output ""
}

@test "get_all_background_images ignores blank and commented lines" {
  mkdir -p "$(dirname "$BACKGROUND_SOURCES_FILE")"
  printf '# a comment\n\n' >"$BACKGROUND_SOURCES_FILE"
  run get_all_background_images
  assert_success
  assert_output ""
}

@test "get_all_background_images is empty with no sources file" {
  run get_all_background_images
  assert_success
  assert_output ""
}

@test "remove_background_source accepts the full entry or a path fragment" {
  make_test_image "$BATS_TEST_TMPDIR/pics/one.png"
  make_test_image "$BATS_TEST_TMPDIR/pics/two.png"
  add_background_source "$BATS_TEST_TMPDIR/pics/one.png"
  add_background_source "$BATS_TEST_TMPDIR/pics/two.png"

  run remove_background_source "file:$BATS_TEST_TMPDIR/pics/one.png"
  assert_success
  run remove_background_source "two.png"
  assert_success

  run list_background_source_entries
  assert_output ""
}

@test "remove_background_source fails on an unknown path and with no sources" {
  run remove_background_source "/pics/absent.png"
  assert_failure
  assert_output --partial "No sources configured"

  make_test_image "$BATS_TEST_TMPDIR/pics/one.png"
  add_background_source "$BATS_TEST_TMPDIR/pics/one.png"
  run remove_background_source "/pics/absent.png"
  assert_failure
  assert_output --partial "Source not found"
}

@test "verify_background_sources fails when an entry is broken" {
  make_test_image "$BATS_TEST_TMPDIR/pics/one.png"
  add_background_source "$BATS_TEST_TMPDIR/pics/one.png"
  run verify_background_sources
  assert_success
  assert_output --partial "Valid: 1, Broken: 0"

  rm "$BATS_TEST_TMPDIR/pics/one.png"
  run verify_background_sources
  assert_failure
  assert_output --partial "Valid: 0, Broken: 1"
}

@test "verify_background_sources flags an entry with an unrecognized prefix" {
  mkdir -p "$(dirname "$BACKGROUND_SOURCES_FILE")"
  echo "http:/pics/one.png" >"$BACKGROUND_SOURCES_FILE"
  run verify_background_sources
  assert_failure
  assert_output --partial "unknown type"
}

@test "clean_background_sources drops broken entries and keeps comments" {
  make_test_image "$BATS_TEST_TMPDIR/pics/kept.png"
  add_background_source "$BATS_TEST_TMPDIR/pics/kept.png"
  make_test_image "$BATS_TEST_TMPDIR/pics/gone.png"
  add_background_source "$BATS_TEST_TMPDIR/pics/gone.png"
  rm "$BATS_TEST_TMPDIR/pics/gone.png"
  echo "# hand-written note" >>"$BACKGROUND_SOURCES_FILE"

  run clean_background_sources
  assert_success
  assert_output --partial "Cleaned 1 broken entries"

  run list_background_source_entries
  assert_line "file:$BATS_TEST_TMPDIR/pics/kept.png"
  assert_line "# hand-written note"
  assert_equal "${#lines[@]}" 2
}

@test "clean_background_sources is a no-op with nothing configured" {
  run clean_background_sources
  assert_success
  assert_output "No sources configured."
}

#!/usr/bin/env bats
# `theme <verb> --help`, at every level of the command tree.
#
# The verbs carrying free text read it as "$*", so a --help reaching one becomes
# the message rather than a request for help: `theme reject --help` hides the
# current theme with "--help" as the reason, `like`/`dislike`/`note` write a
# history record saying the same, and `theme random --help` applies a random
# theme. main() answers the flag before dispatch for that reason.
#
# The verb list is read out of the help screen rather than written here, so a
# command added to the table is covered without a new test.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  source_theme_libs

  # A verb that acts needs something to act on, or it exits early on "no theme
  # applied" and the test passes without exercising the guard.
  mkdir -p "$THEME_LIVE_DIR"
  echo "gruvbox-dark-hard" >"$CURRENT_THEME_FILE"
}

# Commands and Subcommands both sit between those two headers on the plain
# help screen, which is the branch a sandboxed HOME gets.
help_screen_verbs() {
  "$THEME_ROOT/bin/theme" help \
    | sed -n '/^Commands$/,/^Examples$/p' \
    | awk '/^  [a-z]/ { print $1 }'
}

assert_no_history() {
  [[ ! -s "$THEME_HISTORY_FILE" ]] || {
    echo "history written by a help request:" >&2
    cat "$THEME_HISTORY_FILE" >&2
    return 1
  }
}

@test "the help screen lists every verb the tables carry" {
  run help_screen_verbs
  assert_success
  assert_line "reject"
  assert_line "random"
  assert_line "background"
  assert_line "sync"
}

@test "every verb on the help screen answers --help without acting" {
  local verb
  while read -r verb; do
    run "$THEME_ROOT/bin/theme" "$verb" --help
    [[ "$status" -eq 0 ]] || fail "theme $verb --help exited $status: $output"
    [[ -n "$output" ]] || fail "theme $verb --help printed nothing"
    assert_no_history
  done < <(help_screen_verbs)
}

@test "every verb answers -h the same way" {
  local verb
  while read -r verb; do
    run "$THEME_ROOT/bin/theme" "$verb" -h
    [[ "$status" -eq 0 ]] || fail "theme $verb -h exited $status: $output"
    assert_no_history
  done < <(help_screen_verbs)
}

@test "a flat verb gets its own synopsis, not the whole screen" {
  run "$THEME_ROOT/bin/theme" reject --help
  assert_success
  assert_line "Usage: theme reject <message>"
  assert_line "  Mark current theme as rejected (avoids rediscovery)"
  refute_line "Theme Management"
}

@test "an alias resolves to the verb it stands for" {
  run "$THEME_ROOT/bin/theme" rand --help
  assert_success
  assert_line "Usage: theme random"
}

@test "a verb owning a help tree gets its own screen" {
  run "$THEME_ROOT/bin/theme" background --help
  assert_success
  assert_output --partial "Background Management"
}

@test "a nested subcommand keeps its own help" {
  run "$THEME_ROOT/bin/theme" background mode --help
  assert_success
  assert_output --partial "Background Mode Settings"
}

@test "an unknown verb falls back to the full screen" {
  run "$THEME_ROOT/bin/theme" nonsense --help
  assert_success
  assert_output --partial "Theme Management"
}

@test "theme help still renders both sections and the examples" {
  run "$THEME_ROOT/bin/theme" help
  assert_success
  assert_line "Commands"
  assert_line "Subcommands"
  assert_line "Examples"
  assert_line "  reject <message>     Mark current theme as rejected (avoids rediscovery)"
}

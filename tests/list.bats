#!/usr/bin/env bats
# `theme list --status`, the one listing keyed on lifecycle state.
#
# Rejection is the only state a theme carries, and it is recorded in the history
# rather than on disk. The three values partition every theme: it is available or
# it is rejected, and `all` is both.
#
# These drive bin/theme as a subprocess, because the surface under test is the
# command line rather than a library function. THEMES_DIR is derived from lib.sh's
# own location and no environment variable moves it, so a subprocess reads the
# repo's real themes — every assertion here names a theme it rejected itself, or
# compares two counts taken the same way, so adding a theme cannot move one.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  source_theme_libs

  # sed rather than `head -1`, which closes the pipe and takes the producing
  # loop down with SIGPIPE under pipefail.
  REJECTED_ID=$(get_theme_names | sed -n '1p')
  REJECTED_NAME=$(get_theme_display_info "$REJECTED_ID")
  add_history_record "2025-01-01T00:00:00Z" "$REJECTED_ID" reject "fixture reason"
}

# A theme line carries the marker and a name. The detail line a rejected theme
# carries is indented four spaces, so it is not one.
count_listed() {
  "$THEME_ROOT/bin/theme" list --status "$1" 2>/dev/null \
    | awk '/^(● |  [^ ])/ { n++ } END { print n + 0 }'
}

@test "--status rejected lists a rejected theme, with the reason it was rejected" {
  run "$THEME_ROOT/bin/theme" list --status rejected
  assert_success
  assert_output --partial "$REJECTED_NAME"
  assert_output --partial "rejected 2025-01-01: fixture reason"
}

@test "--status all lists a rejected theme beside the available ones" {
  run "$THEME_ROOT/bin/theme" list --status all
  assert_success
  assert_output --partial "$REJECTED_NAME"
}

@test "the default narrows to available and hides a rejected theme" {
  run "$THEME_ROOT/bin/theme" list
  assert_success
  refute_output --partial "fixture reason"
}

@test "the narrowed default names the flag that widens it, on stderr" {
  run bash -c "'$THEME_ROOT/bin/theme' list 2>&1 >/dev/null"
  assert_success
  assert_output --partial "Rejected themes are hidden: theme list --status all"

  run bash -c "'$THEME_ROOT/bin/theme' list 2>/dev/null"
  assert_success
  refute_output --partial "--status all"
}

@test "available and rejected partition all" {
  local available rejected all
  available=$(count_listed available)
  rejected=$(count_listed rejected)
  all=$(count_listed all)

  [[ "$rejected" -gt 0 ]] || fail "nothing was rejected, so the partition proves nothing"
  [[ $((available + rejected)) -eq "$all" ]] \
    || fail "available ($available) + rejected ($rejected) != all ($all)"
}

@test "the header count matches the themes actually listed" {
  local status
  for status in available rejected all; do
    local header listed
    header=$("$THEME_ROOT/bin/theme" list --status "$status" 2>/dev/null \
      | sed -n '1s/^Themes (\([0-9][0-9]*\) .*/\1/p')
    listed=$(count_listed "$status")
    [[ "$header" == "$listed" ]] \
      || fail "--status $status header says $header, listed $listed"
  done
}

@test "a state is not a verb" {
  run "$THEME_ROOT/bin/theme" rejected
  assert_failure
  assert_output --partial "Commands"
}

@test "--status refuses a value outside the enum" {
  run "$THEME_ROOT/bin/theme" list --status closed
  assert_failure
  assert_output --partial "unknown status: closed"
}

@test "list refuses an option it does not have" {
  run "$THEME_ROOT/bin/theme" list --all
  assert_failure
  assert_output --partial "unknown option: --all"
}

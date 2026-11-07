#!/usr/bin/env bats
# The verbs that open an fzf picker, run where nobody can answer one.
#
# These drive bin/theme as a subprocess with stdin from /dev/null, which is
# what a script or a timer hands it. Each picker verb has a form taking the
# theme as an argument, and that form is the one a script uses.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  source_theme_libs

  # sed rather than `head -1`, which closes the pipe and takes the producing
  # loop down with SIGPIPE under pipefail.
  REJECTED_ID=$(get_theme_names | sed -n '1p')
  add_history_record "2025-01-01T00:00:00Z" "$REJECTED_ID" reject "fixture reason"
}

@test "a picker verb without a terminal exits 2 instead of waiting" {
  local verb
  for verb in change info unreject; do
    run "$THEME_ROOT/bin/theme" "$verb" </dev/null
    [[ "$status" -eq 2 ]] || fail "theme $verb exited $status, expected 2"
  done
}

@test "unreject with a theme restores it without a picker" {
  run "$THEME_ROOT/bin/theme" unreject "$REJECTED_ID" </dev/null
  assert_success
  run is_theme_rejected "$REJECTED_ID"
  assert_failure
}

#!/usr/bin/env bats
# When the schedule changes the theme: the hold each kind of apply earns, and the presence check.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  source_theme_libs
  source "$THEME_ROOT/lib/schedule.sh"
  stub_command_with_output uname testbox
}

# A logind whose display session is 2 and carries the given hints.
stub_session() {
  cat >"$BATS_TEST_TMPDIR/stubs/loginctl" <<EOF
#!/usr/bin/env bash
case "\$1" in
  show-user) echo 2 ;;
  show-session) printf '%s\n' $* ;;
esac
EOF
  chmod +x "$BATS_TEST_TMPDIR/stubs/loginctl"
}

@test "a hand apply holds the next change 12 hours, a scheduled one 6, and only this machine's count" {
  # No trigger is how every apply before the schedule reads, and it was applied by hand.
  add_history_record "2026-01-01T00:00:00Z" sora apply
  add_apply_record "2026-01-01T01:00:00Z" nord schedule otherbox
  run pipeline "schedule_last_apply | jq -r '.due'"
  assert_output "$((1767225600 + 12 * 3600))"

  add_apply_record "2026-01-01T02:00:00Z" kanagawa schedule
  run pipeline "schedule_last_apply | jq -r '.due'"
  assert_output "$((1767232800 + 6 * 3600))"
}

@test "a due change waits while the session is idle or locked, and goes ahead while it is active" {
  export PLATFORM=arch
  add_apply_record "2026-01-01T00:00:00Z" sora schedule
  local due=$((1767225600 + 6 * 3600))

  run pipeline "schedule_decide $((due - 60)) | cut -f1"
  assert_output "waiting"

  stub_session IdleHint=yes LockedHint=no
  run pipeline "schedule_decide $due | cut -f1"
  assert_output "away"

  stub_session IdleHint=no LockedHint=yes
  run pipeline "schedule_decide $due | cut -f1"
  assert_output "away"

  stub_session IdleHint=no LockedHint=no
  run pipeline "schedule_decide $due | cut -f1"
  assert_output "due"
}

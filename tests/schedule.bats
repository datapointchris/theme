#!/usr/bin/env bats
# When the schedule changes the theme: the turn each kind of apply leads to, and the presence check.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  source_theme_libs
  source "$THEME_ROOT/lib/schedule.sh"
  stub_command_with_output uname testbox
  # Turns are local hours. A POSIX zone needs no tzdata: 02:00 local is 07:00Z.
  export TZ=EST5
}

# Epoch seconds at an hour of 2026-01-01 UTC, past 24 into the next day.
utc_hour() {
  echo $((1767225600 + $1 * 3600))
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

@test "the next turn follows a scheduled apply, waits out a hand apply's hold, and skips a missed window" {
  # No trigger is how every apply before the schedule reads, and it was applied by hand.
  add_history_record "2026-01-01T00:00:00Z" sora apply
  # Counted, another machine's apply at 02:30 local would lead to the 06:00 turn.
  add_apply_record "2026-01-01T07:30:00Z" nord schedule otherbox
  # 19:00 local plus the 12-hour hold is 07:00, so the 10:00 turn.
  run schedule_next_turn "$(utc_hour 0)"
  assert_output "$(utc_hour 15)"

  add_apply_record "2026-01-01T15:10:00Z" kanagawa schedule
  run schedule_next_turn "$(utc_hour 15)"
  assert_output "$(utc_hour 19)"

  # Away until 15:30 local, past the 14:00 turn's hour, so the 18:00 turn.
  run schedule_next_turn "$(($(utc_hour 20) + 1800))"
  assert_output "$(utc_hour 23)"
}

@test "a due change waits while the session is idle or locked, and goes ahead while it is active" {
  export PLATFORM=arch
  add_apply_record "2026-01-01T15:10:00Z" sora schedule
  local due
  due=$(utc_hour 19)

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

#!/usr/bin/env bats
# Terminal opacity.
#
# Every app gets its own small config file that its main config includes, rather
# than the tool editing the main config: an include is idempotent, so nothing has
# to parse and rewrite a file the user also edits.
#
# The reload paths are stubbed. Unstubbed, set_opacity reaches the developer's
# live tmux server and waybar — a test may not restyle the machine it runs on.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  source_theme_libs

  stub_command tmux 1    # "no server running", so nothing is sourced into one
  stub_command pgrep 1   # waybar not running
  stub_command killall 0 # never reached while pgrep says no
  stub_command cmd.exe 1 # not WSL, so the Windows Terminal write is skipped
}

@test "opacity reads as fully opaque before anything is set" {
  run get_current_opacity
  assert_success
  assert_output "1.0"
}

@test "ghostty opacity round-trips through its own include file" {
  set_ghostty_opacity 0.85
  run get_ghostty_opacity
  assert_output "0.85"
  run cat "$GHOSTTY_OPACITY_FILE"
  assert_output "background-opacity = 0.85"
}

@test "kitty opacity round-trips, in kitty's own syntax" {
  # Same value, different file format — kitty uses whitespace where ghostty uses
  # an equals sign, so the two setters are not interchangeable.
  set_kitty_opacity 0.85
  run get_kitty_opacity
  assert_output "0.85"
  run cat "$KITTY_OPACITY_FILE"
  assert_output "background_opacity 0.85"
}

@test "waybar opacity is stored in a comment it can be read back out of" {
  # CSS has nowhere to keep a scalar, so the value is round-tripped through a
  # comment and only used to build the alpha() call below it.
  set_waybar_opacity 0.90
  run get_waybar_opacity
  assert_output "0.90"
  run cat "$WAYBAR_OPACITY_FILE"
  assert_output --partial "alpha(@bg, 0.90)"
}

@test "windows terminal opacity is stored as an integer percentage" {
  set_windows_terminal_opacity 0.85 || true
  run jq -r '.opacity' "$WINDOWS_TERMINAL_OPACITY_FILE"
  assert_output "85"
  run get_windows_terminal_opacity
  assert_output "0.85"
}

@test "get_current_opacity prefers ghostty, then kitty, then windows terminal" {
  set_kitty_opacity 0.70
  run get_current_opacity
  assert_output "0.70"

  set_ghostty_opacity 0.60
  run get_current_opacity
  assert_output "0.60"
}

@test "set_opacity converts a percentage and writes every app" {
  run set_opacity 85
  assert_success
  assert_output --partial "0.85"

  assert_equal "$(get_ghostty_opacity)" "0.85"
  assert_equal "$(get_kitty_opacity)" "0.85"
  assert_equal "$(get_waybar_opacity)" "0.85"
}

@test "set_opacity rejects anything that is not a percentage" {
  local bad
  for bad in "" abc 101 -5 0.5 50.5; do
    run set_opacity "$bad"
    assert_failure
    assert_output --partial "must be a number between 0 and 100"
  done
}

@test "set_opacity accepts the endpoints" {
  run set_opacity 0
  assert_success
  assert_equal "$(get_ghostty_opacity)" "0.00"

  run set_opacity 100
  assert_success
  assert_equal "$(get_ghostty_opacity)" "1.00"
}

@test "set_opacity leaves windows-terminal out of the applied list off WSL" {
  # The list names what actually changed. _apply_windows_terminal_opacity needs a
  # Windows user from cmd.exe and a settings.json under /mnt/c, so it reports
  # failure everywhere else and the caller drops it.
  run set_opacity 85
  assert_output --partial "ghostty"
  assert_output --partial "kitty"
  assert_output --partial "tmux"
  assert_output --partial "waybar"
  refute_output --partial "windows-terminal"
}

@test "change_opacity steps from the current value" {
  set_opacity 90
  run change_opacity -0.05
  assert_success
  assert_output --partial "0.85"
  assert_equal "$(get_ghostty_opacity)" "0.85"
}

@test "change_opacity clamps to the 0.5 to 1.0 band" {
  # A terminal below half opacity is unreadable over most wallpapers, so the step
  # command refuses to go there even though set_opacity will.
  set_opacity 55
  run change_opacity -0.20
  assert_output --partial "0.50"
  assert_equal "$(get_ghostty_opacity)" "0.50"

  set_opacity 98
  run change_opacity 0.10
  assert_output --partial "1.00"
  assert_equal "$(get_ghostty_opacity)" "1.00"
}

@test "tmux gets a transparent override below full opacity and none at full" {
  # tmux cannot be translucent itself; it has to stop painting its own background
  # so the terminal's shows through. At full opacity the theme owns the colour
  # again, so the override has to come back out.
  set_tmux_opacity 0.85
  run cat "$TMUX_OPACITY_FILE"
  assert_output --partial "bg=default"

  set_tmux_opacity 1.0
  run cat "$TMUX_OPACITY_FILE"
  refute_output --partial "bg=default"
}

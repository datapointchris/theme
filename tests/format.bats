#!/usr/bin/env bats
# Duration formatting for the stats footer.
#
# Both functions take seconds and answer in one unit pair, because they are read
# in a fixed-width footer next to a theme name — not because precision is
# unavailable.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  source_theme_libs
}

@test "format_duration uses seconds below a minute" {
  run format_duration 0
  assert_output "0s"
  run format_duration 59
  assert_output "59s"
}

@test "format_duration uses whole minutes below an hour" {
  # Truncates rather than rounds, at every boundary.
  run format_duration 60
  assert_output "1m"
  run format_duration 119
  assert_output "1m"
  run format_duration 3599
  assert_output "59m"
}

@test "format_duration adds minutes to hours only when there are any" {
  run format_duration 3600
  assert_output "1h"
  run format_duration 3660
  assert_output "1h 1m"
  run format_duration 86399
  assert_output "23h 59m"
}

@test "format_duration adds hours to days only when there are any" {
  run format_duration 86400
  assert_output "1d"
  run format_duration 90000
  assert_output "1d 1h"
  run format_duration 8640000
  assert_output "100d"
}

@test "format_duration handles the usage totals it is actually given" {
  # calculate_usage_time sums seconds across a theme's whole history, so the
  # numbers reaching this are large.
  run format_duration 1234567
  assert_output "14d 6h"
}

@test "format_relative collapses anything under an hour to just now" {
  run format_relative 0
  assert_output "just now"
  run format_relative 3599
  assert_output "just now"
}

@test "format_relative counts hours then days" {
  run format_relative 3600
  assert_output "1h ago"
  run format_relative 86399
  assert_output "23h ago"
  run format_relative 86400
  assert_output "1d ago"
  run format_relative 864000
  assert_output "10d ago"
}

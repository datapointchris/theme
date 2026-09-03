#!/usr/bin/env bats
# What `theme random` draws from, and how the draw is weighted.
#
# Two properties carry the whole design. Every available theme is reachable on
# any draw, and a rejected theme is reachable on none. Anything that narrows the
# draw to a subset — the lowest apply count, the newest arrival — reads as a
# broken shuffle: the tool keeps returning the same few themes and the rest of
# the library is unreachable until that subset changes.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  source_theme_libs
  use_fixture_themes_dir
}

# Weights are measured against the clock, so the recent end of a fixture has to
# be written relative to now. The distant end does not: any timestamp older than
# THEME_RECENCY_CAP_DAYS clamps to the cap and stays put.
#
# Takes a signed day offset, because one test needs a timestamp in the future.
at_days_offset() {
  date -u -d "$1 days" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
    || date -u -v "${1}d" +%Y-%m-%dT%H:%M:%SZ
}

@test "list_themes_not_rejected drops a rejected theme" {
  make_fixture_theme keeper >/dev/null
  make_fixture_theme dropped >/dev/null
  add_history_record "2025-01-01T00:00:00Z" dropped reject "too bright"

  run list_themes_not_rejected
  assert_output "keeper"
}

@test "list_themes_not_rejected restores a theme whose last action is unreject" {
  make_fixture_theme restored >/dev/null
  add_history_record "2025-01-01T00:00:00Z" restored reject "too bright"
  add_history_record "2025-02-01T00:00:00Z" restored unreject

  run list_themes_not_rejected
  assert_output "restored"
}

@test "list_themes_not_rejected lists everything when nothing is rejected" {
  make_fixture_theme one >/dev/null
  make_fixture_theme two >/dev/null

  run list_themes_not_rejected
  assert_line "one"
  assert_line "two"
}

@test "compute_theme_weights gives a never-applied theme the capped weight" {
  run pipeline "echo unseen | compute_theme_weights"
  assert_output "unseen	$((1 + THEME_RECENCY_CAP_DAYS / THEME_RECENCY_SCALE_DAYS))"
}

@test "compute_theme_weights weighs a long-unused theme above a recent one" {
  add_history_record "2020-01-01T00:00:00Z" stale apply
  add_history_record "$(at_days_offset 0)" fresh apply

  local stale_weight fresh_weight
  stale_weight=$(echo stale | compute_theme_weights | cut -f2)
  fresh_weight=$(echo fresh | compute_theme_weights | cut -f2)

  run awk -v a="$stale_weight" -v b="$fresh_weight" 'BEGIN { print (a > b) ? "yes" : "no" }'
  assert_output "yes"
}

@test "compute_theme_weights caps a theme unused far longer than the ceiling" {
  add_history_record "2020-01-01T00:00:00Z" ancient apply

  run pipeline "echo ancient | compute_theme_weights"
  assert_output "ancient	$((1 + THEME_RECENCY_CAP_DAYS / THEME_RECENCY_SCALE_DAYS))"
}

@test "compute_theme_weights floors a future-dated apply at the minimum weight" {
  # Another machine with a skewed clock dates an apply ahead of now, which
  # subtracts to a negative age and would otherwise weigh below every peer.
  add_history_record "$(at_days_offset +30)" skewed apply

  run pipeline "echo skewed | compute_theme_weights"
  assert_output "skewed	1"
}

@test "compute_theme_weights emits a line per theme read from stdin" {
  run pipeline "printf '%s\n' alpha beta gamma | compute_theme_weights | cut -f1"
  assert_line --index 0 "alpha"
  assert_line --index 1 "beta"
  assert_line --index 2 "gamma"
}

@test "weighted_random_choice returns the only candidate" {
  run pipeline "printf 'solo\t1\n' | weighted_random_choice"
  assert_output "solo"
}

@test "weighted_random_choice fails on empty input" {
  run pipeline "printf '' | weighted_random_choice"
  assert_failure
}

@test "weighted_random_choice never returns a zero-weight candidate" {
  for _ in $(seq 20); do
    run pipeline "printf 'live\t1\nzero\t0\n' | weighted_random_choice"
    assert_output "live"
  done
}

@test "weighted_random_choice reaches every candidate" {
  # Also pins the seeding: awk's bare srand() takes the clock in whole seconds,
  # so a loop this fast would return one name 40 times and leave two of the
  # three unreached.
  local drawn
  drawn=$(for _ in $(seq 40); do
    printf 'one\t1\ntwo\t1\nthree\t1\n' | weighted_random_choice
  done | sort -u | wc -l)

  assert_equal "$drawn" 3
}

@test "weighted_random_choice favors the heavier candidate" {
  local heavy=0
  for _ in $(seq 40); do
    [[ "$(printf 'heavy\t9\nlight\t1\n' | weighted_random_choice)" == "heavy" ]] && heavy=$((heavy + 1))
  done

  # 9:1 over 40 draws; a fair sampler clears half by a margin no seed explains.
  run awk -v n="$heavy" 'BEGIN { print (n > 20) ? "yes" : "no" }'
  assert_output "yes"
}

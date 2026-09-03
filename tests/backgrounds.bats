#!/usr/bin/env bats
# Background history: a second JSONL log, keyed by background *and* theme.
#
# The pairing is the whole design. A wallpaper that works under a dark palette
# can be unusable under a light one, so likes, dislikes and rejections are all
# scoped to the theme they were expressed under, and the rotation weights are
# computed per theme from that.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  source_theme_libs
  use_fixture_themes_dir
}

@test "log_background_action records the background alongside the theme" {
  log_background_action apply "recolor:/pics/one.jpg" gruvbox
  run jq -c '{background, theme, action}' "$BACKGROUND_HISTORY_FILE"
  assert_output '{"background":"recolor:/pics/one.jpg","theme":"gruvbox","action":"apply"}'
}

@test "log_background_action defaults the theme to the current one" {
  set_current_theme everforest
  log_background_action apply "generated:plasma"
  run jq -r '.theme' "$BACKGROUND_HISTORY_FILE"
  assert_output "everforest"
}

@test "log_background_action reads the live current-theme file, not the dev one" {
  # The current-theme file stays in THEME_LIVE_DIR even in development mode,
  # because Neovim watches it. This read used to go to "$THEME_STATE_DIR/current"
  # instead, which in dev mode is a different, stale file — so dev-mode
  # background records were attributed to whatever theme was current the last
  # time dev mode ran.
  set_current_theme everforest
  mkdir -p "$THEME_ROOT/.dev-data"

  run bash -c "HOME='$HOME' THEME_ENV=development bash -c '
    source \"$THEME_ROOT/lib/lib.sh\"
    BACKGROUND_HISTORY_FILE=\"$BATS_TEST_TMPDIR/dev-bg.jsonl\"
    log_background_action apply \"generated:plasma\"
    jq -r .theme \"\$BACKGROUND_HISTORY_FILE\"'"
  assert_success
  assert_output "everforest"
}

@test "log_background_action falls back to unknown with no current theme" {
  log_background_action apply "generated:plasma"
  run jq -r '.theme' "$BACKGROUND_HISTORY_FILE"
  assert_output "unknown"
}

@test "log_background_action requires an action" {
  run log_background_action ""
  assert_failure
  assert_output --partial "action required"
}

@test "get_background_history is an empty array before anything is logged" {
  rm -f "$BACKGROUND_HISTORY_FILE"
  run get_background_history
  assert_output "[]"
}

@test "get_background_history_for_theme filters to one theme" {
  add_background_record "2025-01-01T00:00:00Z" "generated:plasma" gruvbox apply
  add_background_record "2025-01-02T00:00:00Z" "generated:plasma" nord apply

  run pipeline "get_background_history_for_theme gruvbox | jq 'length'"
  assert_output "1"
}

@test "get_background_stats aggregates across every theme by default" {
  add_background_record "2025-01-01T00:00:00Z" "generated:plasma" gruvbox apply
  add_background_record "2025-01-02T00:00:00Z" "generated:plasma" nord apply
  add_background_record "2025-01-03T00:00:00Z" "generated:plasma" nord like
  add_background_record "2025-01-04T00:00:00Z" "generated:plasma" nord dislike
  add_background_record "2025-01-05T00:00:00Z" "generated:plasma" nord note "washed out"

  run pipeline "get_background_stats 'generated:plasma' | jq -c '{theme,applies,likes,dislikes,score,notes}'"
  assert_output '{"theme":"all","applies":2,"likes":1,"dislikes":1,"score":0,"notes":["washed out"]}'
}

@test "get_background_stats scopes to one theme when given one" {
  # The reason a background is not simply liked or disliked: the same image
  # scores differently under different palettes.
  add_background_record "2025-01-01T00:00:00Z" "generated:plasma" gruvbox like
  add_background_record "2025-01-02T00:00:00Z" "generated:plasma" nord dislike

  run pipeline "get_background_stats 'generated:plasma' gruvbox | jq -c '{theme,likes,dislikes,score}'"
  assert_output '{"theme":"gruvbox","likes":1,"dislikes":0,"score":1}'
}

@test "get_background_stats requires a background id" {
  run get_background_stats ""
  assert_failure
  assert_output --partial "background ID required"
}

@test "a background rejected under one theme stays available under another" {
  add_background_record "2025-01-01T00:00:00Z" "recolor:/pics/one.jpg" gruvbox reject "too warm"

  run is_background_rejected "recolor:/pics/one.jpg" gruvbox
  assert_success

  run is_background_rejected "recolor:/pics/one.jpg" nord
  assert_failure
}

@test "unrejecting a background brings it back for that theme" {
  add_background_record "2025-01-01T00:00:00Z" "recolor:/pics/one.jpg" gruvbox reject "too warm"
  add_background_record "2025-01-02T00:00:00Z" "recolor:/pics/one.jpg" gruvbox unreject

  run is_background_rejected "recolor:/pics/one.jpg" gruvbox
  assert_failure
}

@test "is_background_rejected is false with no background history" {
  rm -f "$BACKGROUND_HISTORY_FILE"
  run is_background_rejected "generated:plasma" gruvbox
  assert_failure
}

@test "list_rejected_backgrounds and get_rejected_background_ids agree" {
  add_background_record "2025-01-01T00:00:00Z" "recolor:/pics/one.jpg" gruvbox reject "too warm"
  add_background_record "2025-01-02T00:00:00Z" "recolor:/pics/two.jpg" gruvbox reject "too busy"
  add_background_record "2025-01-03T00:00:00Z" "recolor:/pics/two.jpg" gruvbox unreject
  add_background_record "2025-01-04T00:00:00Z" "recolor:/pics/three.jpg" nord reject "wrong theme"

  run pipeline "list_rejected_backgrounds gruvbox | jq -r '.background'"
  assert_output "recolor:/pics/one.jpg"

  run get_rejected_background_ids gruvbox
  assert_output "recolor:/pics/one.jpg"
}

@test "get_background_rankings orders by score then applies" {
  add_background_record "2025-01-01T00:00:00Z" "bg:liked" gruvbox apply
  add_background_record "2025-01-02T00:00:00Z" "bg:liked" gruvbox like
  add_background_record "2025-01-03T00:00:00Z" "bg:neutral" gruvbox apply
  add_background_record "2025-01-04T00:00:00Z" "bg:disliked" gruvbox apply
  add_background_record "2025-01-05T00:00:00Z" "bg:disliked" gruvbox dislike

  run pipeline "get_background_rankings gruvbox | jq -r '.background'"
  assert_line --index 0 "bg:liked"
  assert_line --index 1 "bg:neutral"
  assert_line --index 2 "bg:disliked"
}

@test "get_background_rankings with no theme ranks across all of them" {
  add_background_record "2025-01-01T00:00:00Z" "bg:one" gruvbox apply
  add_background_record "2025-01-02T00:00:00Z" "bg:two" nord apply

  run pipeline "get_background_rankings | jq -r '.background' | sort"
  assert_line --index 0 "bg:one"
  assert_line --index 1 "bg:two"
}

@test "get_background_apply_counts counts applies only" {
  add_background_record "2025-01-01T00:00:00Z" "bg:one" gruvbox apply
  add_background_record "2025-01-02T00:00:00Z" "bg:one" gruvbox apply
  add_background_record "2025-01-03T00:00:00Z" "bg:one" gruvbox like

  run get_background_apply_counts gruvbox
  assert_output "bg:one	2"
}

@test "get_recent_backgrounds returns applies newest first, honoring the limit" {
  add_background_record "2025-01-01T00:00:00Z" "bg:one" gruvbox apply
  add_background_record "2025-01-02T00:00:00Z" "bg:two" gruvbox apply
  add_background_record "2025-01-03T00:00:00Z" "bg:three" gruvbox apply

  # Emits a stream of objects rather than one array — `limit(n; .[])` produces
  # values, not a collection — so a reader pipes it through jq again rather than
  # indexing it.
  run pipeline "get_recent_backgrounds 2 gruvbox | jq -r '.background'"
  assert_line --index 0 "bg:three"
  assert_line --index 1 "bg:two"
  assert_equal "${#lines[@]}" 2
}

#==============================================================================
# ROTATION WEIGHTS
#==============================================================================

@test "compute_background_weights is empty with no history" {
  rm -f "$BACKGROUND_HISTORY_FILE"
  run compute_background_weights gruvbox
  assert_output "{}"
}

@test "compute_background_weights ranks liked above neutral above disliked" {
  # The rotation is weighted, not filtered: a disliked background keeps a small
  # chance rather than disappearing, so a snap judgment is recoverable.
  add_background_record "2025-01-01T00:00:00Z" "bg:liked" gruvbox like
  add_background_record "2025-01-02T00:00:00Z" "bg:neutral" gruvbox note "seen it"
  add_background_record "2025-01-03T00:00:00Z" "bg:disliked" gruvbox dislike

  run pipeline "compute_background_weights gruvbox | jq -c '[.\"bg:liked\" > .\"bg:neutral\", .\"bg:neutral\" > .\"bg:disliked\", .\"bg:disliked\" > 0]'"
  assert_output "[true,true,true]"
}

@test "compute_background_weights damps a frequently applied background" {
  # The variety term. Two backgrounds with identical ratings diverge on how often
  # they have already been shown.
  add_background_record "2025-01-01T00:00:00Z" "bg:fresh" gruvbox apply
  add_background_record "2025-01-02T00:00:00Z" "bg:worn" gruvbox apply
  add_background_record "2025-01-03T00:00:00Z" "bg:worn" gruvbox apply
  add_background_record "2025-01-04T00:00:00Z" "bg:worn" gruvbox apply

  run pipeline "compute_background_weights gruvbox | jq -r '.\"bg:fresh\" > .\"bg:worn\"'"
  assert_output "true"
}

@test "compute_background_weights floors the preference term at 0.1" {
  # Five dislikes take the preference term negative, and a negative weight would
  # invert the weighted pick rather than merely deprioritizing it.
  local i
  for i in 1 2 3 4 5 6 7 8; do
    add_background_record "2025-01-0${i}T00:00:00Z" "bg:hated" gruvbox dislike
  done

  run pipeline "compute_background_weights gruvbox | jq -r '.\"bg:hated\" == 0.1'"
  assert_output "true"
}

@test "compute_background_weights scopes to the theme asked for" {
  add_background_record "2025-01-01T00:00:00Z" "bg:one" gruvbox apply
  add_background_record "2025-01-02T00:00:00Z" "bg:two" nord apply

  run pipeline "compute_background_weights gruvbox | jq -r 'keys | join(\",\")'"
  assert_output "bg:one"
}

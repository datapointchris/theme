#!/usr/bin/env bats
# The JSONL history: what gets written, and what the readers make of it.
#
# One file records every action on every machine and is merged across them
# through a gist, so the read path carries a normalizer that repairs names
# recorded by older versions. That normalizer is the most intricate jq in the
# repo and the reason this file leans on it heavily: it runs on every read, and
# a mistake in it silently re-splits a theme's stats rather than erroring.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  source_theme_libs
  use_fixture_themes_dir
}

#==============================================================================
# WRITING
#==============================================================================

@test "log_action writes one JSON object per call" {
  log_action apply gruvbox
  log_action like gruvbox "great contrast"

  run wc -l <"$THEME_HISTORY_FILE"
  assert_output "2"

  run jq -r -s '.[0] | keys | join(",")' "$THEME_HISTORY_FILE"
  assert_output "action,machine,platform,theme,ts"
}

@test "log_action omits the message key rather than writing an empty one" {
  # Two record shapes, not one with a blank field. Readers test for the key's
  # presence — get_background_stats collects `.message // empty` — so an empty
  # string would show up as a note with no text.
  log_action apply gruvbox
  run jq -r 'has("message")' "$THEME_HISTORY_FILE"
  assert_output "false"

  : >"$THEME_HISTORY_FILE"
  log_action like gruvbox "nice"
  run jq -r '.message' "$THEME_HISTORY_FILE"
  assert_output "nice"
}

@test "log_action records the platform and machine of the writing host" {
  # What makes one shared history readable per machine after a gist merge.
  PLATFORM=arch log_action apply gruvbox
  run jq -r '.platform' "$THEME_HISTORY_FILE"
  assert_output "arch"
  run jq -r '.machine | length > 0' "$THEME_HISTORY_FILE"
  assert_output "true"
}

@test "log_action writes a UTC timestamp jq can parse" {
  # calculate_usage_time subtracts these with fromdateiso8601, which accepts only
  # the Z form — a local-offset timestamp would make every duration wrong.
  log_action apply gruvbox
  run jq -r '.ts | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$")' "$THEME_HISTORY_FILE"
  assert_output "true"
}

@test "log_action requires an action" {
  run log_action ""
  assert_failure
  assert_output --partial "action required"
}

@test "log_action creates the state directory if it is missing" {
  rm -rf "$THEME_STATE_DIR"
  log_action apply gruvbox
  assert_equal "$(wc -l <"$THEME_HISTORY_FILE" | xargs)" "1"
}

#==============================================================================
# NORMALIZATION ON READ
#==============================================================================

@test "get_history returns an empty array with no history" {
  rm -f "$THEME_HISTORY_FILE"
  run get_history
  assert_success
  assert_output "[]"
}

@test "get_history sorts by timestamp regardless of write order" {
  add_history_record "2025-03-01T00:00:00Z" gruvbox apply
  add_history_record "2025-01-01T00:00:00Z" nord apply
  add_history_record "2025-02-01T00:00:00Z" everforest apply

  run pipeline "get_history | jq -r '.[].theme'"
  assert_line --index 0 "nord"
  assert_line --index 1 "everforest"
  assert_line --index 2 "gruvbox"
}

@test "get_history renames the themes that were recorded under display names" {
  # Three themes were logged by display name before ids were used consistently.
  # Without this their likes and hours sit in a bucket no current theme matches.
  add_history_record "2025-01-01T00:00:00Z" "Nordic" apply
  add_history_record "2025-01-02T00:00:00Z" "Oceanic Next" apply
  add_history_record "2025-01-03T00:00:00Z" "Retrobox" apply

  run pipeline "get_history | jq -r '.[].theme'"
  assert_line --index 0 "nordic"
  assert_line --index 1 "oceanic-next"
  assert_line --index 2 "retrobox"
}

@test "get_history collapses the archlinux platform label to arch" {
  add_history_record "2025-01-01T00:00:00Z" gruvbox apply "" "archlinux"
  run pipeline "get_history | jq -r '.[].platform'"
  assert_output "arch"
}

@test "get_history canonicalizes machine names to one label per physical box" {
  # Four spellings of two machines. The legacy format was platform-host, so the
  # platform prefix is stripped; case is folded because the hostname was recorded
  # as both Macmini and macmini; and a host recorded as empty or "unknown" falls
  # back to the platform, since the Arch box is the only Arch machine.
  add_history_record "2025-01-01T00:00:00Z" gruvbox apply "" macos "macos-Macmini"
  add_history_record "2025-01-02T00:00:00Z" gruvbox apply "" macos "Macmini"
  add_history_record "2025-01-03T00:00:00Z" gruvbox apply "" arch "arch-"
  add_history_record "2025-01-04T00:00:00Z" gruvbox apply "" arch "archlinux-unknown"

  run pipeline "get_history | jq -r '.[].machine'"
  assert_line --index 0 "macmini"
  assert_line --index 1 "macmini"
  assert_line --index 2 "archlinux"
  assert_line --index 3 "archlinux"
}

@test "get_history leaves a record with no machine field alone" {
  # The oldest records predate the field. They read back as null rather than
  # being dropped or guessed at, which is why get_theme_stats collects
  # `.machine // "unknown"`.
  add_history_record "2025-01-01T00:00:00Z" gruvbox apply
  jq -c 'del(.machine)' "$THEME_HISTORY_FILE" >"$THEME_HISTORY_FILE.tmp"
  mv "$THEME_HISTORY_FILE.tmp" "$THEME_HISTORY_FILE"

  run pipeline "get_history | jq -r '.[].machine'"
  assert_output "null"
}

@test "normalization is idempotent" {
  # There is no migration and no version marker — the filter runs on every read
  # and again on every sync merge, so normalizing already-normalized records has
  # to be a no-op or the two sides of a merge would never converge.
  add_history_record "2025-01-01T00:00:00Z" "Nordic" apply "" "archlinux" "macos-Macmini"

  local once twice
  once=$(get_history)
  echo "$once" | jq -c '.[]' >"$THEME_HISTORY_FILE"
  twice=$(get_history)
  assert_equal "$once" "$twice"
}

@test "get_history_raw emits one compact object per line" {
  # The line-oriented form the sync merge feeds back into a JSONL file.
  add_history_record "2025-01-01T00:00:00Z" gruvbox apply
  add_history_record "2025-01-02T00:00:00Z" nord apply

  run get_history_raw
  assert_equal "${#lines[@]}" 2
  assert_line --index 0 --partial '"theme":"gruvbox"'
}

#==============================================================================
# STATS
#==============================================================================

@test "get_theme_stats counts each action type and nets the score" {
  add_history_record "2025-01-01T00:00:00Z" gruvbox apply
  add_history_record "2025-01-02T00:00:00Z" gruvbox apply
  add_history_record "2025-01-03T00:00:00Z" gruvbox like
  add_history_record "2025-01-04T00:00:00Z" gruvbox like
  add_history_record "2025-01-05T00:00:00Z" gruvbox dislike
  add_history_record "2025-01-06T00:00:00Z" gruvbox note "the comment"
  add_history_record "2025-01-07T00:00:00Z" nord apply

  run pipeline "get_theme_stats gruvbox | jq -c '{applies,likes,dislikes,notes,score,total_actions,last_used}'"
  assert_output '{"applies":2,"likes":2,"dislikes":1,"notes":1,"score":1,"total_actions":6,"last_used":"2025-01-02T00:00:00Z"}'
}

@test "get_theme_stats reports last_used as never for a theme only ever rated" {
  add_history_record "2025-01-01T00:00:00Z" gruvbox like
  run pipeline "get_theme_stats gruvbox | jq -r '.last_used'"
  assert_output "never"
}

@test "get_theme_stats lists the platforms and machines a theme was used on" {
  add_history_record "2025-01-01T00:00:00Z" gruvbox apply "" macos macmini
  add_history_record "2025-01-02T00:00:00Z" gruvbox apply "" arch archlinux
  run pipeline "get_theme_stats gruvbox | jq -c '[.platforms, .machines]'"
  assert_output '[["arch","macos"],["archlinux","macmini"]]'
}

@test "get_theme_stats requires a theme name" {
  run get_theme_stats ""
  assert_failure
  assert_output --partial "theme name required"
}

@test "calculate_usage_time credits each apply until the next one" {
  # The apply log is a timeline, not a set of independent events: a theme's hours
  # are the gaps between its apply and whatever replaced it.
  add_history_record "2025-01-01T00:00:00Z" gruvbox apply
  add_history_record "2025-01-01T01:00:00Z" nord apply
  add_history_record "2025-01-01T03:00:00Z" gruvbox apply
  add_history_record "2025-01-01T04:00:00Z" everforest apply

  run pipeline "calculate_usage_time '' | jq -c '{gruvbox,nord}'"
  assert_output '{"gruvbox":7200,"nord":7200}'
}

@test "calculate_usage_time leaves the final apply uncounted unless it is current" {
  # Otherwise the last theme ever applied would keep accruing hours forever on
  # every machine that read the merged history.
  add_history_record "2025-01-01T00:00:00Z" gruvbox apply
  add_history_record "2025-01-01T01:00:00Z" nord apply

  run pipeline "calculate_usage_time '' | jq -r 'has(\"nord\")'"
  assert_output "false"
}

@test "calculate_usage_time counts the current theme up to now" {
  add_history_record "2025-01-01T00:00:00Z" gruvbox apply
  add_history_record "2025-01-01T01:00:00Z" nord apply

  # A timestamp in the past, so the open-ended duration is bounded below rather
  # than pinned to a clock the test cannot control.
  run pipeline "calculate_usage_time nord | jq -r '.nord > 3600'"
  assert_output "true"
}

@test "calculate_usage_time accepts a timestamp with a UTC offset" {
  # Records written by an older version carried +00:00 rather than Z, and
  # fromdateiso8601 rejects the offset form outright — hence the parse_ts shim.
  add_history_record "2025-01-01T00:00:00+00:00" gruvbox apply
  add_history_record "2025-01-01T02:00:00Z" nord apply

  run pipeline "calculate_usage_time '' | jq -r '.gruvbox'"
  assert_output "7200"
}

#==============================================================================
# RANKINGS
#==============================================================================

@test "get_rankings orders by score, breaking ties on most recent apply" {
  add_history_record "2025-01-01T00:00:00Z" low apply
  add_history_record "2025-01-02T00:00:00Z" tied-old apply
  add_history_record "2025-01-02T00:00:00Z" tied-old like
  add_history_record "2025-01-03T00:00:00Z" tied-new apply
  add_history_record "2025-01-03T00:00:00Z" tied-new like

  run pipeline "get_rankings | jq -r '.theme'"
  assert_line --index 0 "tied-new"
  assert_line --index 1 "tied-old"
  assert_line --index 2 "low"
}

@test "get_rankings drops a rejected theme and restores an unrejected one" {
  # Last write wins, so a theme can come back. The Telescope picker in Neovim
  # reads the same reject/unreject pairs out of this file.
  add_history_record "2025-01-01T00:00:00Z" kept apply
  add_history_record "2025-01-02T00:00:00Z" gone apply
  add_history_record "2025-01-03T00:00:00Z" gone reject "too bright"
  add_history_record "2025-01-04T00:00:00Z" back apply
  add_history_record "2025-01-05T00:00:00Z" back reject "changed my mind"
  add_history_record "2025-01-06T00:00:00Z" back unreject

  run pipeline "get_rankings | jq -r '.theme' | sort"
  assert_line --index 0 "back"
  assert_line --index 1 "kept"
  assert_equal "${#lines[@]}" 2
}

@test "get_theme_rank_positions places a theme in both rankings" {
  make_fixture_theme first "First" >/dev/null
  make_fixture_theme second "Second" >/dev/null

  add_history_record "2025-01-01T00:00:00Z" first apply
  add_history_record "2025-01-01T02:00:00Z" second apply
  add_history_record "2025-01-01T03:00:00Z" first apply
  add_history_record "2025-01-01T04:00:00Z" second apply
  add_history_record "2025-01-02T00:00:00Z" second like

  # BY LIKES ranks on score, so second leads; BY HOURS ranks on accrued usage,
  # where first holds two hours against second's one.
  run pipeline "get_theme_rank_positions second | jq -c ."
  assert_output '{"total":2,"likes_pos":1,"hours_pos":2}'
}

@test "get_theme_rank_positions ignores history for themes no longer installed" {
  # History outlives themes — a deleted theme keeps its records, and counting it
  # would report "3 of 12" against a list of 11.
  make_fixture_theme installed "Installed" >/dev/null
  add_history_record "2025-01-01T00:00:00Z" installed apply
  add_history_record "2025-01-02T00:00:00Z" deleted-long-ago apply

  run pipeline "get_theme_rank_positions installed | jq -r '.total'"
  assert_output "1"
}

#==============================================================================
# REJECTION
#==============================================================================

@test "reject_theme then is_theme_rejected, and unreject reverses it" {
  reject_theme gruvbox "too bright"
  run is_theme_rejected gruvbox
  assert_success

  unreject_theme gruvbox
  run is_theme_rejected gruvbox
  assert_failure
}

@test "is_theme_rejected is false for a theme with no reject history" {
  log_action apply gruvbox
  run is_theme_rejected gruvbox
  assert_failure
}

@test "is_theme_rejected is false with no history file at all" {
  rm -f "$THEME_HISTORY_FILE"
  run is_theme_rejected gruvbox
  assert_failure
}

@test "reject_theme requires a theme and records a default reason" {
  run reject_theme ""
  assert_failure
  assert_output --partial "theme name required"

  reject_theme gruvbox
  run jq -r 'select(.action == "reject") | .message' "$THEME_HISTORY_FILE"
  assert_output "No reason provided"
}

@test "get_rejected_theme_info returns the most recent rejection" {
  add_history_record "2025-01-01T00:00:00Z" gruvbox reject "first reason"
  add_history_record "2025-01-02T00:00:00Z" gruvbox unreject
  add_history_record "2025-01-03T00:00:00Z" gruvbox reject "second reason"

  run pipeline "get_rejected_theme_info gruvbox | jq -r '.message'"
  assert_output "second reason"
}

@test "get_rejected_theme_info returns an empty object for a theme never rejected" {
  log_action apply gruvbox
  run get_rejected_theme_info gruvbox
  assert_output "{}"
}

@test "list_rejected_themes reports only the currently rejected, newest first" {
  add_history_record "2025-01-01T00:00:00Z" older reject "reason one"
  add_history_record "2025-01-02T00:00:00Z" newer reject "reason two"
  add_history_record "2025-01-03T00:00:00Z" restored reject "reason three"
  add_history_record "2025-01-04T00:00:00Z" restored unreject

  run pipeline "list_rejected_themes | jq -r '.theme'"
  assert_line --index 0 "newer"
  assert_line --index 1 "older"
  assert_equal "${#lines[@]}" 2
}

#==============================================================================
# COUNTS AND VALIDATION
#==============================================================================

@test "the counting helpers agree with the records written" {
  add_history_record "2025-01-01T00:00:00Z" gruvbox apply
  add_history_record "2025-01-02T00:00:00Z" gruvbox apply
  add_history_record "2025-01-03T00:00:00Z" nord like

  run count_total_actions
  assert_output "3"

  run count_themes_tracked
  assert_output "2"

  run list_tracked_themes
  assert_line --index 0 "gruvbox"
  assert_line --index 1 "nord"

  run get_all_apply_counts
  assert_output --partial "gruvbox"
  assert_output --partial "2"
}

@test "get_all_apply_counts omits a theme that was never applied" {
  add_history_record "2025-01-01T00:00:00Z" only-liked like
  run get_all_apply_counts
  assert_output ""
}

@test "validate_history_file accepts an absent, empty and populated history" {
  rm -f "$THEME_HISTORY_FILE"
  run validate_history_file
  assert_success

  # The state init_storage leaves on a fresh machine. `jq -e` exits 4 on empty
  # input, so this case has to be handled before jq sees the file at all.
  : >"$THEME_HISTORY_FILE"
  run validate_history_file
  assert_success

  log_action apply gruvbox
  run validate_history_file
  assert_success
}

@test "validate_history_file rejects a corrupt history" {
  echo "not json at all" >"$THEME_HISTORY_FILE"
  run validate_history_file
  assert_failure
  assert_output --partial "Invalid JSON"
}

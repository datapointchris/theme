#!/usr/bin/env bats
# The merge rule, which is the whole reason the gist holds one file per machine.
#
# A union merge cannot express a deletion. Every machine may assert every row, so
# a row removed on one machine is restored by the next machine to sync from a
# copy that still holds it. One writer per file makes a removal an ordinary edit.
#
# Nothing here reaches the network: _sync_merge_histories takes the remote files'
# contents as a string, which is exactly what sync_pull assembles from them.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  source_theme_libs
  source "$THEME_ROOT/lib/sync.sh"
}

record() {
  local ts="$1" machine="$2" theme="$3" action="$4"
  printf '{"ts":"%s","platform":"arch","machine":"%s","theme":"%s","action":"%s"}' \
    "$ts" "$machine" "$theme" "$action"
}

@test "a row this machine deleted stays deleted when another machine still has it" {
  # The failure the split exists to prevent. Under a union merge the peer's copy
  # re-asserts the row on every sync, forever.
  add_history_record "2025-01-01T00:00:00Z" gruvbox apply "" arch archlinux

  local peer_file
  peer_file="$(record 2025-01-02T00:00:00Z macmini nord apply)
$(record 2025-01-03T00:00:00Z macmini gruvbox reject)"

  # The peer's file does not carry the deleted row, because this machine wrote it
  # and this machine is the only writer of its own file.
  run _sync_merge_histories "$THEME_HISTORY_FILE" archlinux "$peer_file"
  assert_success
  assert_equal "${#lines[@]}" 3

  # Now delete it locally and merge again. Nothing puts it back.
  : >"$THEME_HISTORY_FILE"
  run _sync_merge_histories "$THEME_HISTORY_FILE" archlinux "$peer_file"
  assert_success
  assert_equal "${#lines[@]}" 2
  refute_output --partial '"theme":"gruvbox","action":"apply"'
}

@test "a row another machine deleted disappears from here too" {
  # The mirror case. The peer's file is authoritative for the peer, so dropping a
  # row from it removes the row here even though the local copy still holds it.
  add_history_record "2025-01-01T00:00:00Z" gruvbox apply "" arch archlinux
  add_history_record "2025-01-02T00:00:00Z" nord apply "" macos macmini

  run _sync_merge_histories "$THEME_HISTORY_FILE" archlinux "$(record 2025-01-05T00:00:00Z macmini kanagawa apply)"
  assert_success
  assert_equal "${#lines[@]}" 2
  refute_output --partial '"theme":"nord"'
  assert_output --partial '"theme":"kanagawa"'
}

@test "this machine's own rows come from local, never from its remote file" {
  # sync_pull skips this machine's own file for exactly this reason. A row
  # written since the last push lives only in the local file, and a merge that
  # preferred the remote would drop it.
  add_history_record "2025-01-09T00:00:00Z" gruvbox apply "" arch archlinux

  run _sync_merge_histories "$THEME_HISTORY_FILE" archlinux ""
  assert_success
  assert_equal "${#lines[@]}" 1
  assert_output --partial '"theme":"gruvbox"'
}

@test "a row in a peer's file claiming this machine is ignored" {
  # Ownership is by machine field, not by which file carried it, so a stale peer
  # cannot speak for this machine.
  : >"$THEME_HISTORY_FILE"

  run _sync_merge_histories "$THEME_HISTORY_FILE" archlinux "$(record 2025-01-02T00:00:00Z archlinux gruvbox reject)"
  assert_success
  assert_output ""
}

@test "the merge normalizes before deciding whose row it is" {
  # A legacy record spells this machine "macos-Macmini". Without normalization it
  # would look like a peer's row and be dropped from the local side.
  add_history_record "2025-01-01T00:00:00Z" gruvbox apply "" macos "macos-Macmini"

  run _sync_merge_histories "$THEME_HISTORY_FILE" macmini ""
  assert_success
  assert_equal "${#lines[@]}" 1
  assert_output --partial '"machine":"macmini"'
}

@test "the merged output is sorted by timestamp and free of duplicates" {
  add_history_record "2025-01-05T00:00:00Z" gruvbox apply "" arch archlinux

  local peer
  peer="$(record 2025-01-01T00:00:00Z macmini nord apply)
$(record 2025-01-01T00:00:00Z macmini nord apply)"

  run _sync_merge_histories "$THEME_HISTORY_FILE" archlinux "$peer"
  assert_success
  assert_equal "${#lines[@]}" 2
  assert_line --index 0 --partial '2025-01-01'
  assert_line --index 1 --partial '2025-01-05'
}

@test "the pre-split history.jsonl is not one of the per-machine files" {
  # A machine on an older release still writes the whole merged set to that name.
  # Reading it back would restore the union this replaces.
  run grep -E '^history-.+\.jsonl$' <<<"history.jsonl"
  assert_failure

  run grep -E '^history-.+\.jsonl$' <<<"history-archlinux.jsonl"
  assert_success
}

@test "the filename carries this machine's id" {
  run _sync_history_filename
  assert_success
  assert_output "history-$(_storage_get_machine_id).jsonl"
}

@test "_sync_own_records emits only this machine's rows, sorted" {
  add_history_record "2025-01-03T00:00:00Z" gruvbox apply "" arch archlinux
  add_history_record "2025-01-01T00:00:00Z" nord apply "" macos macmini
  add_history_record "2025-01-02T00:00:00Z" kanagawa apply "" arch archlinux

  run _sync_own_records archlinux
  assert_success
  assert_equal "${#lines[@]}" 2
  assert_line --index 0 --partial '"theme":"kanagawa"'
  assert_line --index 1 --partial '"theme":"gruvbox"'
}

#!/usr/bin/env bats
# `theme current show --json`, the read another program calls under a deadline
# of about a second. `theme current` pulls the history gist first, so this read
# is the one that must never reach gh.
#
# It drives bin/theme as a subprocess, which reads the repo's real themes. The
# theme it applies is taken from the listing, so adding a theme cannot move it.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  source_theme_libs
}

@test "theme current show --json prints the current id without a sync" {
  local id
  id=$(get_theme_names | sed -n '1p')
  mkdir -p "$THEME_LIVE_DIR"
  echo "$id" >"$CURRENT_THEME_FILE"

  # Enabled with a gist id, which is what sends `theme current` to gh.
  printf '{"enabled": true, "gist_id": "fixture"}\n' >"$THEME_STATE_DIR/sync-state.json"
  printf '#!/usr/bin/env bash\ntouch "%s"\nexit 1\n' "$BATS_TEST_TMPDIR/gh-called" >"$BATS_TEST_TMPDIR/stubs/gh"
  chmod +x "$BATS_TEST_TMPDIR/stubs/gh"

  run "$THEME_ROOT/bin/theme" current show --json
  assert_success
  assert_equal "$(jq -r .id <<<"$output")" "$id"
  [[ ! -e "$BATS_TEST_TMPDIR/gh-called" ]] || fail "theme current show --json called gh"

  # The keys the schema requires are the keys printed, so neither drifts alone.
  jq -e --slurpfile schema "$THEME_ROOT/schemas/current-show.schema.json" \
    '(keys | sort) == ($schema[0].required | sort)' <<<"$output" >/dev/null \
    || fail "printed keys differ from the schema's required keys: $output"
}

#!/usr/bin/env bats
# `scripts/check-plugin-drift.sh --since`, resolved to the UTC instant GitHub's
# commits API takes as `until`.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  DRIFT="$BATS_TEST_DIRNAME/../scripts/check-plugin-drift.sh"
  # A copy without the guard runs the whole drift check against GitHub on source.
  grep -qF "if [[ \"\${BASH_SOURCE[0]}\" == \"\${0}\" ]]; then" "$DRIFT" \
    || fail "check-plugin-drift.sh has no BASH_SOURCE guard, so sourcing it would run the check"
  export TZ=America/New_York
  source "$DRIFT"
  NOW=$(date -d 2026-10-18T14:00:00Z +%s)
}

@test "--since resolves each form to its instant and refuses a value naming none" {
  while read -r text expected; do
    echo "# --since $text"
    run since_instant "$text" "$NOW"
    if [[ "$expected" == refused ]]; then
      assert_failure 2
    else
      assert_success
      assert_output "$expected"
    fi
  done <<'EOF'
30s 2026-10-18T13:59:30Z
10m 2026-10-18T13:50:00Z
12h 2026-10-18T02:00:00Z
7d 2026-10-11T14:00:00Z
2w 2026-10-04T14:00:00Z
2026-10-01 2026-10-01T04:00:00Z
2026-10-01T09:00:00-04:00 2026-10-01T13:00:00Z
6mo refused
1y refused
2026-10-01T09:00 refused
2026-02-30 refused
tuesday refused
2999-01-01 refused
EOF
}

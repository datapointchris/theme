#!/usr/bin/env bash
# Test all themes for hangs/errors
# Runs each theme apply with timeout to identify problematic themes
#
# Usage: ./scripts/test-all-themes.sh [timeout_seconds]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default timeout of 30 seconds per theme
TIMEOUT_SECS="${1:-30}"

# Source libs for list_themes
source "$THEME_APP_DIR/lib/lib.sh"

# Results tracking
PASS=()
FAIL=()
TIMEOUT_THEMES=()

echo "Testing all themes with ${TIMEOUT_SECS}s timeout..."
echo "=================================================="
echo ""

# Get all themes
mapfile -t THEMES < <(list_themes)
TOTAL=${#THEMES[@]}

for i in "${!THEMES[@]}"; do
  theme="${THEMES[$i]}"
  idx=$((i + 1))

  printf "[%2d/%2d] %-30s " "$idx" "$TOTAL" "$theme"

  # Run theme apply with timeout
  start_time=$(date +%s.%N)

  if timeout "$TIMEOUT_SECS" bash -c "
    source '$THEME_APP_DIR/lib/lib.sh'
    source '$THEME_APP_DIR/lib/storage.sh'
    apply_theme_to_apps '$theme' >/dev/null 2>&1
  " 2>/dev/null; then
    end_time=$(date +%s.%N)
    elapsed=$(echo "$end_time - $start_time" | bc)
    printf "✓ (%.1fs)\n" "$elapsed"
    PASS+=("$theme")
  else
    exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
      printf "⏰ TIMEOUT (>${TIMEOUT_SECS}s)\n"
      TIMEOUT_THEMES+=("$theme")
    else
      end_time=$(date +%s.%N)
      elapsed=$(echo "$end_time - $start_time" | bc)
      printf "✗ error=%d (%.1fs)\n" "$exit_code" "$elapsed"
      FAIL+=("$theme")
    fi
  fi
done

echo ""
echo "=================================================="
echo "Results:"
echo "  Passed:   ${#PASS[@]}/$TOTAL"
echo "  Failed:   ${#FAIL[@]}/$TOTAL"
echo "  Timeout:  ${#TIMEOUT_THEMES[@]}/$TOTAL"

if [[ ${#FAIL[@]} -gt 0 ]]; then
  echo ""
  echo "Failed themes:"
  for t in "${FAIL[@]}"; do
    echo "  - $t"
  done
fi

if [[ ${#TIMEOUT_THEMES[@]} -gt 0 ]]; then
  echo ""
  echo "Timeout themes:"
  for t in "${TIMEOUT_THEMES[@]}"; do
    echo "  - $t"
  done
fi

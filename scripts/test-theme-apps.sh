#!/usr/bin/env bash
# Test individual app applies for a specific theme
# Helps identify which app is causing hangs
#
# Usage: ./scripts/test-theme-apps.sh <theme> [timeout_seconds]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

THEME="${1:-}"
TIMEOUT_SECS="${2:-10}"

if [[ -z "$THEME" ]]; then
  echo "Usage: $0 <theme> [timeout_seconds]"
  exit 1
fi

source "$THEME_APP_DIR/lib/lib.sh"

echo "Testing apps for theme: $THEME"
echo "Timeout: ${TIMEOUT_SECS}s per app"
echo "========================================"
echo ""

# Apps to test (macOS)
APPS=(ghostty kitty borders wallpaper tmux btop)

for app in "${APPS[@]}"; do
  printf "  %-12s " "$app"

  start_time=$(date +%s.%N)

  if timeout "$TIMEOUT_SECS" bash -c "
    source '$THEME_APP_DIR/lib/lib.sh'
    apply_$app '$THEME'
  " 2>/dev/null; then
    end_time=$(date +%s.%N)
    elapsed=$(echo "$end_time - $start_time" | bc)
    printf "✓ (%.2fs)\n" "$elapsed"
  else
    exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
      printf "⏰ TIMEOUT (>${TIMEOUT_SECS}s)\n"
    else
      end_time=$(date +%s.%N)
      elapsed=$(echo "$end_time - $start_time" | bc)
      printf "✗ error=%d (%.2fs)\n" "$exit_code" "$elapsed"
    fi
  fi
done

echo ""
echo "Testing reload_tmux..."
printf "  %-12s " "reload_tmux"
if timeout 5 bash -c "
  source '$THEME_APP_DIR/lib/lib.sh'
  reload_tmux
" 2>/dev/null; then
  printf "✓\n"
else
  printf "✗\n"
fi

echo ""
echo "Testing log_action..."
printf "  %-12s " "log_action"
if timeout 5 bash -c "
  source '$THEME_APP_DIR/lib/storage.sh'
  log_action 'test' 'test-theme' 'test message'
" 2>/dev/null; then
  printf "✓\n"
else
  printf "✗\n"
fi

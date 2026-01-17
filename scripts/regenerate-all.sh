#!/usr/bin/env bash
# Regenerate all app configs for all themes in parallel
#
# Usage: ./scripts/regenerate-all.sh [--themes <pattern>] [--generators <pattern>]
#
# Examples:
#   ./scripts/regenerate-all.sh                          # All themes, all generators
#   ./scripts/regenerate-all.sh --themes "everforest*"   # Only everforest themes
#   ./scripts/regenerate-all.sh --generators ghostty     # Only ghostty generator

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GENERATORS_DIR="$THEME_DIR/lib/generators"
THEMES_DIR="$THEME_DIR/themes"

# Check for GNU parallel
if ! command -v parallel &>/dev/null; then
  echo "Error: GNU parallel is required but not installed."
  echo "Install with: brew install parallel"
  exit 1
fi

# Generator -> output filename mapping
declare -A GENERATOR_OUTPUT=(
  [ghostty]="ghostty.conf"
  [kitty]="kitty.conf"
  [alacritty]="alacritty.toml"
  [tmux]="tmux.conf"
  [btop]="btop.theme"
  [borders]="bordersrc"
  [hyprland]="hyprland.conf"
  [hyprlock]="hyprlock.conf"
  [waybar]="waybar.css"
  [rofi]="rofi.rasi"
  [dunst]="dunst.conf"
  [mako]="mako.conf"
  [walker]="walker.css"
  [swayosd]="swayosd.css"
  [windows-terminal]="windows-terminal.json"
  [icons]="icons.theme"
  [hyprland-picker]="hyprland-picker.css"
  [chromium]="chromium.theme"
)

# Parse arguments
THEME_PATTERN=""
GENERATOR_PATTERN=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --themes)
      THEME_PATTERN="$2"
      shift 2
      ;;
    --generators)
      GENERATOR_PATTERN="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--themes <pattern>] [--generators <pattern>]"
      echo ""
      echo "Options:"
      echo "  --themes <pattern>      Only process themes matching pattern (glob)"
      echo "  --generators <pattern>  Only run generators matching pattern (glob)"
      echo ""
      echo "Available generators:"
      printf "  %s\n" "${!GENERATOR_OUTPUT[@]}" | sort
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Collect themes
themes=()
for theme_dir in "$THEMES_DIR"/*/; do
  theme=$(basename "$theme_dir")
  # shellcheck disable=SC2053  # Intentional glob matching for pattern filter
  if [[ -f "$theme_dir/theme.yml" ]]; then
    if [[ -z "$THEME_PATTERN" ]]; then
      themes+=("$theme")
    elif [[ "$theme" == $THEME_PATTERN ]]; then
      themes+=("$theme")
    fi
  fi
done

# Collect generators
generators=()
# shellcheck disable=SC2053  # Intentional glob matching for pattern filter
for gen in "${!GENERATOR_OUTPUT[@]}"; do
  if [[ -z "$GENERATOR_PATTERN" ]]; then
    generators+=("$gen")
  elif [[ "$gen" == $GENERATOR_PATTERN ]]; then
    generators+=("$gen")
  fi
done

# Count totals
total_themes=${#themes[@]}
total_generators=${#generators[@]}
total_jobs=$((total_themes * total_generators))

if [[ $total_jobs -eq 0 ]]; then
  echo "No matching themes or generators found."
  exit 1
fi

echo "Regenerating configs..."
echo "  Themes: $total_themes"
echo "  Generators: $total_generators"
echo "  Total jobs: $total_jobs"
echo ""

# Create temp files
job_list=$(mktemp)
results_dir=$(mktemp -d)
trap 'rm -f "$job_list"; rm -rf "$results_dir"' EXIT

# Build job list: script|input|output|theme|gen|results_dir|total
for theme in "${themes[@]}"; do
  theme_yml="$THEMES_DIR/$theme/theme.yml"
  for gen in "${generators[@]}"; do
    output_file="$THEMES_DIR/$theme/${GENERATOR_OUTPUT[$gen]}"
    generator_script="$GENERATORS_DIR/${gen}.sh"
    if [[ -f "$generator_script" ]]; then
      echo "$generator_script|$theme_yml|$output_file|$theme|$gen|$results_dir|$total_jobs"
    fi
  done
done > "$job_list"

actual_jobs=$(wc -l < "$job_list" | tr -d ' ')

# Use all available cores
cores=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

echo "Running $actual_jobs jobs with $cores parallel workers..."
echo ""

# Job runner function
run_job() {
  IFS='|' read -r script input output theme gen results_dir total <<< "$1"
  result_file="$results_dir/${theme}__${gen}"

  job_start=$EPOCHREALTIME

  if "$script" "$input" "$output" >/dev/null 2>&1; then
    job_end=$EPOCHREALTIME
    elapsed=$(awk "BEGIN {printf \"%.2f\", $job_end - $job_start}")
    echo "ok|$elapsed" > "$result_file"
    done=$(find "$results_dir" -maxdepth 1 -type f | wc -l | tr -d ' ')
    pct=$((done * 100 / total))
    printf "✓ %-30s %-18s %6.2fs  [%d/%d %3d%%]\n" "$theme" "$gen" "$elapsed" "$done" "$total" "$pct"
  else
    job_end=$EPOCHREALTIME
    elapsed=$(awk "BEGIN {printf \"%.2f\", $job_end - $job_start}")
    echo "fail|$elapsed" > "$result_file"
    done=$(find "$results_dir" -maxdepth 1 -type f | wc -l | tr -d ' ')
    pct=$((done * 100 / total))
    printf "✗ %-30s %-18s %6.2fs  [%d/%d %3d%%] FAILED\n" "$theme" "$gen" "$elapsed" "$done" "$total" "$pct"
  fi
}
export -f run_job

started=$(date +%s.%N)

# Run with GNU parallel
parallel --jobs "$cores" run_job < "$job_list"

ended=$(date +%s.%N)
total_elapsed=$(awk "BEGIN {printf \"%.2f\", $ended - $started}")

# Count results and collect timing stats
success=0
failed=0
failed_list=()
declare -A generator_times
declare -A theme_times

for result_file in "$results_dir"/*; do
  [[ -f "$result_file" ]] || continue
  name=$(basename "$result_file")
  theme="${name%__*}"
  gen="${name#*__}"

  IFS='|' read -r status elapsed < "$result_file"

  if [[ "$status" == "ok" ]]; then
    ((++success))
  else
    ((++failed))
    failed_list+=("$theme/$gen")
  fi

  # Accumulate times per generator
  current_gen_time="${generator_times[$gen]:-0}"
  generator_times[$gen]=$(awk "BEGIN {printf \"%.2f\", $current_gen_time + $elapsed}")

  # Accumulate times per theme
  current_theme_time="${theme_times[$theme]:-0}"
  theme_times[$theme]=$(awk "BEGIN {printf \"%.2f\", $current_theme_time + $elapsed}")
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "  ✓ Success: %d\n" "$success"
printf "  ✗ Failed:  %d\n" "$failed"
printf "  Total time: %.2fs (wall clock with %d parallel workers)\n" "$total_elapsed" "$cores"
echo ""

echo "TIME PER GENERATOR (cumulative across all themes):"
echo "──────────────────────────────────────────────────"
for gen in $(echo "${!generator_times[@]}" | tr ' ' '\n' | sort); do
  printf "  %-20s %8.2fs\n" "$gen" "${generator_times[$gen]}"
done | sort -t$'\t' -k2 -rn | head -20
echo ""

echo "TIME PER THEME (cumulative across all generators):"
echo "──────────────────────────────────────────────────"
for theme in $(echo "${!theme_times[@]}" | tr ' ' '\n' | sort); do
  printf "  %-30s %8.2fs\n" "$theme" "${theme_times[$theme]}"
done | sort -t$'\t' -k2 -rn | head -20
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $failed -gt 0 ]]; then
  echo ""
  echo "FAILED JOBS:"
  for f in "${failed_list[@]}"; do
    echo "  - $f"
  done
  exit 1
fi

#!/usr/bin/env bash
# Check whether plugin themes still match the upstream colorschemes they claim
# to mirror. Development tooling, not part of the theme CLI — it is only worth
# running once or twice a year, or after adding a plugin theme.
#
# Usage: scripts/check-plugin-drift.sh [theme-id ...]
#        scripts/check-plugin-drift.sh --since 2026-01-18   # history mode
#
# A plugin theme's theme.yml is a hand transcription of that plugin's palette,
# taken once and never re-read. Two things go wrong: upstream changes a colour
# after we transcribed it, or the transcription was wrong to begin with. This
# checks for both, and the second turns out to be the common one.
#
# Do NOT baseline against lazy-lock.json. It pins the plugin, but the pin moves
# every time :Lazy update runs, so a comparison against it reports nothing.
# Baseline against the date theme.yml was last written instead.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$THEME_DIR"

for tool in gh yq rg; do
  command -v "$tool" >/dev/null || { echo "Error: $tool is required" >&2; exit 1; }
done

since=""
themes=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --since) since="$2"; shift 2 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) themes+=("$1"); shift ;;
  esac
done

if [[ ${#themes[@]} -eq 0 ]]; then
  while IFS= read -r t; do
    [[ -n "$t" ]] && themes+=("$t")
  done < <(
    yq -r 'select(.meta.neovim_colorscheme_source == "plugin") | [.meta.id] | @tsv' themes/*/theme.yml | sort
  )
fi

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# Upstream repos that ship terminal configs, and where. This is the only
# per-plugin knowledge in here, and it buys the exact check: their file is
# generated from the same palette the colorscheme uses, so comparing it to ours
# settles the question without parsing any Lua. Themes absent from this list
# fall back to the history check, which only says "look at this", not "this is
# wrong". Path takes {variant}; empty value means the repo ships nothing usable.
declare -A UPSTREAM_TERMINAL=(
  [EdenEast/nightfox.nvim]="extra/{variant}/{variant}.ghostty"
  [Aejkatappaja/cendre]="extras/ghostty/{variant}"
  [Aejkatappaja/sora]="extras/ghostty/{variant}"
  [rebelot/kanagawa.nvim]="extras/alacritty/kanagawa_{variant}.toml"
  [craftzdog/solarized-osaka.nvim]="extras/alacritty/solarized_osaka_{variant}.toml"
)
# The upstream file is named for its own variant, which is not always our id.
declare -A VARIANT_OF=(
  [nightfox]="nightfox" [terafox]="terafox"
  [cendre]="cendre" [cendre-medium]="cendre-medium" [cendre-soft]="cendre-soft"
  [sora]="sora"
  [kanagawa]="wave"
  [solarized-osaka]="dark"
)

colors_of() { { rg -o "#?\b[0-9a-fA-F]{6}\b" "$1" || true; } | tr -d '#' | tr 'A-F' 'a-f' | sort -u; }

exact=0; flagged=0; skipped=0

for id in "${themes[@]}"; do
  yml="themes/$id/theme.yml"
  [[ -f "$yml" ]] || { echo "  ?  $id — no theme.yml"; continue; }
  repo=$(yq -r '.meta.plugin // ""' "$yml")
  [[ -n "$repo" && "$repo" != "null" ]] || { printf "  -  %-22s no upstream plugin (built-in)\n" "$id"; ((++skipped)); continue; }

  path_tpl="${UPSTREAM_TERMINAL[$repo]:-}"
  variant="${VARIANT_OF[$id]:-$id}"

  if [[ -n "$path_tpl" ]]; then
    path="${path_tpl//\{variant\}/$variant}"
    if gh api "repos/$repo/contents/$path" --jq '.content' 2>/dev/null | base64 -d > "$tmp/up" && [[ -s "$tmp/up" ]]; then
      # Compare colour sets, not lines: upstream ships whatever terminal format
      # it likes, and ours is generated. A colour we lack that upstream has is
      # usually an extended slot beyond the 16 ANSI, so report both directions.
      only_up=$(comm -23 <(colors_of "$tmp/up") <(colors_of "themes/$id/ghostty.conf") | tr '\n' ' ')
      only_ours=$(comm -13 <(colors_of "$tmp/up") <(colors_of "themes/$id/ghostty.conf") | tr '\n' ' ')
      # Only "ours" matters. A colour upstream has and we do not is almost
      # always an extended slot past the 16 ANSI (nightfox ships palette 16),
      # which we deliberately do not generate. A colour *we* have that upstream
      # does not means the transcription invented a value.
      if [[ -z "$only_ours" ]]; then
        printf "  ok %-22s matches %s" "$id" "$path"
        [[ -n "$only_up" ]] && printf "  (upstream extras not generated: %s)" "$only_up"
        printf "\n"
        ((++exact))
      else
        printf "  !! %-22s has colours upstream does not: %s\n" "$id" "$only_ours"
        printf "     compare against %s\n" "$path"
        ((++flagged))
      fi
      continue
    fi
  fi

  # No shipped terminal config: fall back to asking whether upstream touched
  # anything palette-shaped since we wrote our copy.
  base="${since:-$(git log -1 --format=%ad --date=short -- "$yml")T00:00:00Z}"
  [[ "$base" == *T* ]] || base="${base}T00:00:00Z"
  sha=$(gh api "repos/$repo/commits?until=$base&per_page=1" --jq '.[0].sha' 2>/dev/null || true)
  if [[ -z "$sha" ]]; then
    printf "  ?  %-22s could not resolve a baseline commit in %s\n" "$id" "$repo"
    ((++skipped)); continue
  fi
  line=$(gh api "repos/$repo/compare/${sha}...HEAD" --jq '"\(.ahead_by)|\([.files[].filename] | join(" "))"' 2>/dev/null || echo "?|")
  ahead="${line%%|*}"
  all_rel=$(echo "${line#*|}" | tr ' ' '\n' | { rg -i "palette|colou?rs?/|extras?/" || true; })
  # A repo hosting several colorschemes (flexoki ships one file per variant)
  # would otherwise flag every theme it publishes whenever any one changes. If a
  # changed file names this variant that is the signal; if only other variants
  # moved, this theme is unaffected.
  mine=$(printf '%s' "$all_rel" | { rg -F "$variant" || true; })

  if [[ -z "$all_rel" ]]; then
    printf "  ok %-22s %s commits upstream since %s, none touching a palette\n" "$id" "$ahead" "${base%%T*}"
    ((++exact))
  elif [[ -z "$mine" ]]; then
    printf "  ok %-22s upstream changed only other variants\n" "$id"
    ((++exact))
  else
    printf "  !! %-22s palette files changed upstream since %s\n" "$id" "${base%%T*}"
    printf "     %s\n" "$(printf '%s' "$mine" | head -4 | tr '\n' ' ')"
    ((++flagged))
  fi
done

echo ""
echo "  $exact clean, $flagged to review, $skipped skipped"
[[ $flagged -eq 0 ]]

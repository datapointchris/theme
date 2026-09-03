#!/usr/bin/env bash
# Find British spellings anywhere in the repo, including the places the
# pre-commit hook cannot reach. Development tooling, not part of the theme CLI —
# worth running before a release and after transcribing a new plugin palette.
#
# Usage: scripts/check-spelling.sh [--list-settled]
#
# The hook runs codespell with its default word regex, which keeps a hyphenated
# or digit-suffixed token whole. `display-panes-colour` and `grey1` therefore
# exit 0 there, and an rg pattern anchored on \b misses both for the same reason
# — there is no word boundary between a letter and a digit. This widens the
# token regex to letters only, so `-`, `_` and digits all split, and adds -H so
# the dot-prefixed files codespell otherwise refuses to open are read too.
#
# Widening the regex is what makes the settled list below necessary: a British
# spelling that is genuinely correct now surfaces on every run, so each one is
# declared here with its reason rather than being re-argued each time.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$THEME_DIR"

for tool in codespell rg git; do
  command -v "$tool" >/dev/null || {
    echo "Error: $tool is required" >&2
    exit 1
  }
done

# A finding is settled when its source line matches one of these. Keyed on the
# line rather than the word, because the same word is correct in one place and
# wrong three lines later.
declare -A SETTLED=(
  ["display-panes-colour|display-panes-active-colour|clock-mode-colour|(^|[^a-zA-Z])-colour([^a-zA-Z]|$)"]="tmux's own option names, and the -colour suffix where the comments name it"
  ["align=centre"]="tmux's style parser accepts no other spelling; the generated sites are filtered earlier by .codespellrc's ignore-regex, so these are the prose ones"
  ["grey[0-9]"]="everforest's own palette slot names, quoted where a value was transcribed"
  ["(^|[^A-Za-z])(EDE|CAF|DAA|caf)([^A-Za-z]|$)"]="hex fragments, read as words once the token regex splits on digits"
  ["theme_get's"]="a possessive of the function name, split at the underscore"
  ["\`[a-z*-]*(colour|centre|grey|behaviour|artefact|licence)[a-z0-9-]*\`"]="a backticked citation of the spelling under discussion, not a use of it"
)

list_settled=0
[[ ${1:-} == "--list-settled" ]] && list_settled=1

# A finding is attributed to the first pattern that matches it, and bash gives no
# order to an associative array's keys. Sorting makes the per-pattern counts the
# same on every run, so a change in them means the tree changed.
mapfile -t SETTLED_ORDER < <(printf '%s\n' "${!SETTLED[@]}" | sort)

echo "Scanning $(git ls-files | wc -l) tracked files"
echo ""

findings=$(git ls-files | tr '\n' '\0' \
  | xargs -0 -r codespell --builtin 'clear,rare,en-GB_to_en-US' -H --regex "[a-zA-Z']+" 2>/dev/null || true)

settled=0
review=0
declare -A settled_by

while IFS= read -r finding; do
  [[ -z "$finding" ]] && continue
  file=${finding%%:*}
  rest=${finding#*:}
  lineno=${rest%%:*}
  [[ -f "$file" ]] || continue
  src=$(sed -n "${lineno}p" "$file")

  matched=""
  for pattern in "${SETTLED_ORDER[@]}"; do
    if printf '%s' "$src" | rg -q "$pattern"; then
      matched="$pattern"
      break
    fi
  done

  if [[ -n "$matched" ]]; then
    ((++settled))
    settled_by["$matched"]=$((${settled_by["$matched"]:-0} + 1))
    [[ $list_settled -eq 1 ]] && printf "  -- %s\n" "$finding"
  else
    ((++review))
    printf "  !! %s\n" "$finding"
    printf "     %s\n" "$(printf '%s' "$src" | sed -E 's/^[[:space:]]+//')"
  fi
done <<<"$findings"

if [[ $list_settled -eq 1 || $review -gt 0 ]]; then
  echo ""
fi
echo "  Settled:"
for pattern in "${SETTLED_ORDER[@]}"; do
  printf "    %3d  %s\n" "${settled_by["$pattern"]:-0}" "${SETTLED[$pattern]}"
done

echo ""
if [[ $review -eq 0 ]]; then
  echo "  $settled settled, nothing to review"
else
  echo "  $settled settled, $review to review"
fi

[[ $review -eq 0 ]]

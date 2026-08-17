#!/usr/bin/env bash
# Shared helpers. Sourced by every test file.

THEME_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
export THEME_ROOT

# Points every path the libraries derive at a sandbox, and MUST run before any
# library is sourced. lib.sh and storage.sh both read HOME and THEME_ENV at
# *source* time to decide where state lives, so overriding them afterwards moves
# only the paths that happen to be recomputed later.
#
# THEME_ENV is the one that bites. .envrc sets it to "development" via direnv, so
# a suite inheriting a developer's shell writes its history into the repo's
# .dev-data — passing, while editing the state a later manual run reads back.
# PLATFORM is cleared for the same reason: it short-circuits detect_platform, so
# an exported one would decide what the platform tests are testing.
isolate_theme_state() {
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
  unset THEME_ENV PLATFORM

  # Overriding HOME does not isolate anything that reads an XDG variable, because
  # a developer's shell exports them as absolute paths. The Neovim colorscheme
  # check was the first library code to read one, and it answered against the real
  # ~/.local/share/nvim — so a test asserting "this colorscheme is not installed"
  # passed or failed on which plugins the machine running the suite happened to
  # have. Pointed at the sandbox rather than unset, so the fallbacks are not what
  # gets exercised.
  export XDG_CONFIG_HOME="$HOME/.config"
  export XDG_DATA_HOME="$HOME/.local/share"
  export XDG_STATE_HOME="$HOME/.local/state"
  export XDG_CACHE_HOME="$HOME/.cache"

  # bin/theme resolves bashselfupdate through this one, and an exported absolute
  # path reaches the developer's real installation — which checks a remote for a
  # release on every command a test runs.
  export XDG_LIB_HOME="$HOME/.local/lib"

  # First on PATH so stub_command can shadow anything the libraries shell out
  # to. Prepended once, here, rather than per stub, which would stack a copy of
  # PATH for every stub a test installs.
  mkdir -p "$BATS_TEST_TMPDIR/stubs"
  export PATH="$BATS_TEST_TMPDIR/stubs:$PATH"
}

# Sources the libraries the way bin/theme does. lib.sh pulls in storage.sh
# itself; the redundant second source is deliberate, mirroring the CLI so the
# suite exercises the same load order and the source guard stays covered.
source_theme_libs() {
  source "$THEME_ROOT/lib/lib.sh"
  source "$THEME_ROOT/lib/storage.sh"
}

# Redirects theme lookup at a sandbox directory. THEMES_DIR is computed from
# lib.sh's own location, so without this every listing test reads the repo's 25
# real themes and its assertions move whenever a theme is added.
use_fixture_themes_dir() {
  THEMES_DIR="$BATS_TEST_TMPDIR/themes"
  mkdir -p "$THEMES_DIR"
}

# Writes a theme.yml carrying meta and base16 only, so the ANSI and special
# fallbacks in load_theme are what gets exercised. Each base16 slot holds the
# colour that names its own index — base0D is #0d0d0d — which is what lets a
# fallback assertion read as the slot it fell back to.
#
# Usage: make_fixture_theme <id> [display_name] [colorscheme_source]
make_fixture_theme() {
  local id="$1" display_name="${2:-$1}" source_type="${3:-generated}"
  local dir="$THEMES_DIR/$id"
  mkdir -p "$dir"

  {
    echo "meta:"
    echo "  id: \"$id\""
    echo "  display_name: \"$display_name\""
    echo "  neovim_colorscheme_name: \"$id\""
    echo "  neovim_colorscheme_source: \"$source_type\""
    echo "  variant: \"dark\""
    echo "  author: \"Fixture Author\""
    echo "  derived_from: \"fixture\""
    echo "base16:"
    local slot
    for slot in 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F; do
      printf '  base%s: "#%s%s%s"\n' "$slot" "${slot,,}" "${slot,,}" "${slot,,}"
    done
  } >"$dir/theme.yml"

  echo "$dir/theme.yml"
}

# Appends one history record. Timestamps are arguments, never generated: the
# ranking and usage-time functions sort and subtract on .ts, so a suite calling
# `date` would assert against a moving target.
#
# printf rather than jq. Escaping is not the concern it would be for real input —
# every value here is a literal the test chose — and a suite this size wrote
# enough records that one jq process per line was a large fraction of its
# runtime. The record shape mirrors log_action, which is tested against jq.
#
# Usage: add_history_record <ts> <theme> <action> [message] [platform] [machine]
add_history_record() {
  local ts="$1" theme="$2" action="$3" message="${4:-}" platform="${5:-macos}" machine="${6:-testbox}"
  mkdir -p "$(dirname "$THEME_HISTORY_FILE")"

  if [[ -n "$message" ]]; then
    printf '{"ts":"%s","platform":"%s","machine":"%s","theme":"%s","action":"%s","message":"%s"}\n' \
      "$ts" "$platform" "$machine" "$theme" "$action" "$message" >>"$THEME_HISTORY_FILE"
  else
    printf '{"ts":"%s","platform":"%s","machine":"%s","theme":"%s","action":"%s"}\n' \
      "$ts" "$platform" "$machine" "$theme" "$action" >>"$THEME_HISTORY_FILE"
  fi
}

# Usage: add_background_record <ts> <background> <theme> <action> [message]
add_background_record() {
  local ts="$1" background="$2" theme="$3" action="$4" message="${5:-}"
  mkdir -p "$(dirname "$BACKGROUND_HISTORY_FILE")"

  if [[ -n "$message" ]]; then
    printf '{"ts":"%s","platform":"macos","machine":"testbox","theme":"%s","background":"%s","action":"%s","message":"%s"}\n' \
      "$ts" "$theme" "$background" "$action" "$message" >>"$BACKGROUND_HISTORY_FILE"
  else
    printf '{"ts":"%s","platform":"macos","machine":"testbox","theme":"%s","background":"%s","action":"%s"}\n' \
      "$ts" "$theme" "$background" "$action" >>"$BACKGROUND_HISTORY_FILE"
  fi
}

# Runs a pipeline in the shell the test is already in, so `run` can capture it.
#
# bats' `run` takes a command, not a pipeline, and the usual way around that is
# `run bash -c "source ../lib/lib.sh; foo | jq ..."` — which spawns a shell and
# re-sources the libraries for every assertion. At ~0.15s each that was most of
# this suite's runtime, and it re-derived state the test had already set up.
#
# Usage: run pipeline "get_history | jq -r '.[].theme'"
pipeline() {
  eval "$*"
}

# Writes a real 1x1 PNG. add_background_source asks `file --mime-type` rather
# than trusting the extension, so an empty file with a .png name is rejected —
# and a base64 blob keeps the suite off ImageMagick, which the runner has no
# reason to carry.
#
# The bytes are a PNG whatever the name says. That is deliberate where a test
# needs a .jpg: the mime check accepts any image/*, and the directory scan
# matches on extension alone, so one blob covers both.
make_test_image() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  base64 -d >"$path" <<'PNG'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFAAH/q842iQAAAABJRU5ErkJggg==
PNG
}

# Shadows a command with a no-op that exits with the given status.
#
# Needed because the opacity and reload paths shell out to live services: an
# unstubbed `tmux source-file` reaches the developer's own tmux server and
# restyles their panes from the sandbox file, and `killall -SIGUSR2 waybar`
# reloads their bar. A test may not touch the machine it runs on.
#
# Usage: stub_command <name> [exit_code]
stub_command() {
  local name="$1" exit_code="${2:-0}"
  printf '#!/usr/bin/env bash\nexit %s\n' "$exit_code" >"$BATS_TEST_TMPDIR/stubs/$name"
  chmod +x "$BATS_TEST_TMPDIR/stubs/$name"
}

# Shadows a command with one printing fixed output, so a function reading the
# machine's identity can be tested against a value instead of against whichever
# machine the suite happens to run on.
#
# Usage: stub_command_with_output <name> <stdout> [exit_code]
stub_command_with_output() {
  local name="$1" output="$2" exit_code="${3:-0}"
  {
    echo '#!/usr/bin/env bash'
    printf 'printf %%s\\\\n %q\n' "$output"
    printf 'exit %s\n' "$exit_code"
  } >"$BATS_TEST_TMPDIR/stubs/$name"
  chmod +x "$BATS_TEST_TMPDIR/stubs/$name"
}

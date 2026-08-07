#!/usr/bin/env bats
# The generator registry, and the invariants that keep an app from falling out of
# it unnoticed.
#
# Generated configs are committed artifacts, so nothing fails at the moment a
# generator stops running — the stale file is still there, still valid, still the
# previous palette. Every check here is aimed at that: a generator missing from
# the map, a map entry with no script, a theme missing an artifact its siblings
# have.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  use_fixture_themes_dir

  GENERATE_ALL="$THEME_ROOT/lib/generate-all.sh"
  GENERATORS_DIR="$THEME_ROOT/lib/generators"
  declare -gA MAP_ARTIFACT=()
  declare -gA ARTIFACT_COUNT=()
  load_generator_map

  # Generators deliberately outside generate-all.sh, each for its own reason:
  # the background ones are driven per-apply by the rotation with a source image
  # and an output path, and vscode is run by hand. Named here so a *new*
  # generator cannot join them silently.
  UNWIRED_GENERATORS=" background-ascii background-lowpoly background-plasma background-recolor vscode "
}

# The map is read textually rather than by sourcing, because generate-all.sh runs
# its work at source time. The quotes this depends on are the same quotes that
# keep shfmt from rewriting the subscripts.
#
# One grep for both halves, and one call per test: the earlier version ran a
# fresh grep per key, which is 48 processes for the artifact checks alone.
load_generator_map() {
  MAP_ARTIFACT=()
  local key artifact
  while IFS=$'\t' read -r key artifact; do
    MAP_ARTIFACT["$key"]="$artifact"
  done < <(grep -oE '^\s*\["[^"]+"\]="[^"]+"' "$GENERATE_ALL" \
    | sed -E 's/^\s*\["([^"]+)"\]="([^"]+)"$/\1\t\2/')
}

map_keys() {
  printf '%s\n' "${!MAP_ARTIFACT[@]}"
}

# Every distinct filename across every theme directory, and how many themes carry
# it. Built with globs rather than `find -exec basename` — 25 themes times 24
# artifacts is 600 process spawns, which was most of this file's runtime.
count_theme_artifacts() {
  ARTIFACT_COUNT=()
  # Files only. neovim/ is a directory and the one artifact themes legitimately
  # differ on — only generated themes carry it.
  local path name
  for path in "$THEME_ROOT"/themes/*/*; do
    [[ -f "$path" ]] || continue
    name="${path##*/}"
    ARTIFACT_COUNT["$name"]=$((${ARTIFACT_COUNT["$name"]:-0} + 1))
  done
}

@test "no generator script is missing from the map" {
  local script name
  for script in "$GENERATORS_DIR"/*.sh; do
    name=$(basename "$script" .sh)
    [[ "$UNWIRED_GENERATORS" == *" $name "* ]] && continue
    map_keys | grep -qxF "$name" \
      || fail "$name.sh has no GENERATOR_OUTPUT entry, so generate-all.sh never runs it"
  done
}

@test "no map entry is missing its generator script" {
  local name
  while read -r name; do
    [[ -f "$GENERATORS_DIR/$name.sh" ]] \
      || fail "GENERATOR_OUTPUT names '$name' but $GENERATORS_DIR/$name.sh does not exist"
  done < <(map_keys)
}

@test "no map subscript contains a space" {
  # The regression pin. shfmt reads an unquoted subscript as arithmetic and
  # rewrote [ghostty-css] to [ghostty - css] — still a legal associative key, so
  # bash was happy, and the generator path became "ghostty - css.sh", which does
  # not exist. Four generators stopped running for a month while every run
  # reported success.
  run grep -nE '^\s*\[[^]]* [^]]*\]=' "$GENERATE_ALL"
  assert_failure
}

@test "every hyphenated generator is in the map under its real name" {
  # The four that were lost, named explicitly: a subscript-mangling regression
  # only ever affects hyphenated keys, and these are all of them.
  local name
  for name in ghostty-css windows-terminal firefox-based hyprland-picker; do
    map_keys | grep -qxF "$name" || fail "$name is not in GENERATOR_OUTPUT"
  done
}

@test "a mapped generator with no script is a hard error, not a skipped job" {
  # What should have happened when the subscripts were mangled. Asserted through
  # the script rather than by reading it, since the guard is the behaviour.
  local sandbox="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$sandbox/lib/generators" "$sandbox/themes/only"
  cp "$GENERATE_ALL" "$sandbox/lib/generate-all.sh"
  cp "$GENERATORS_DIR"/tmux.sh "$sandbox/lib/generators/"
  cp "$THEME_ROOT/lib/theme.sh" "$sandbox/lib/"
  make_fixture_theme only "Only" >/dev/null
  cp "$THEMES_DIR/only/theme.yml" "$sandbox/themes/only/"

  # tmux is present, so the failure can only come from the other mapped entries.
  run "$sandbox/lib/generate-all.sh"
  assert_failure
  assert_output --partial "is in GENERATOR_OUTPUT but"
}

@test "generate-all --help lists the generators it knows about" {
  # The documented way to find out what will run, so it has to enumerate the map
  # rather than the directory.
  run "$GENERATE_ALL" --help
  assert_success
  assert_output --partial "ghostty-css"
  assert_output --partial "firefox-based"
}

@test "generate-all rejects an unknown option" {
  run "$GENERATE_ALL" --nope
  assert_failure
  assert_output --partial "Unknown option"
}

@test "generate-all fails rather than doing nothing when a filter matches no theme" {
  run "$GENERATE_ALL" --themes "no-such-theme-*"
  assert_failure
  assert_output --partial "No matching themes or generators found."
}

#==============================================================================
# GENERATOR OUTPUT
#==============================================================================

@test "every committed artifact matches what its generator produces today" {
  # Two failure modes in one check, both of which have happened here.
  #
  # A generator improvement does not reach a theme until that theme is
  # regenerated, and the committed file stays valid-looking in the meantime — so
  # a mismatch means the artifacts are stale and generate-all.sh needs running.
  #
  # A generator that is not deterministic also cannot match, which is how the bat
  # generator's per-run uuidgen was found: it rewrote all 25 tmTheme files on
  # every regeneration, training the reader to skip the one file a real palette
  # change would have appeared in.
  #
  # One theme, not all 25: a generator that has moved on shows up on the first
  # theme it is run against, and 600 invocations is not a pre-commit hook. The
  # full sweep is generate-all.sh followed by `git status`.
  local sample_theme
  sample_theme=$(basename "$(find "$THEME_ROOT/themes" -mindepth 1 -maxdepth 1 -type d | sort | head -1)")
  local theme_yml="$THEME_ROOT/themes/$sample_theme/theme.yml"

  local gen artifact
  for gen in "${!MAP_ARTIFACT[@]}"; do
    artifact="${MAP_ARTIFACT[$gen]}"

    run "$GENERATORS_DIR/$gen.sh" "$theme_yml" "$BATS_TEST_TMPDIR/$artifact"
    assert_success

    run diff "$THEME_ROOT/themes/$sample_theme/$artifact" "$BATS_TEST_TMPDIR/$artifact"
    assert_success
  done
}

@test "the bat theme's uuid is derived from the theme, not minted per run" {
  # It was `uuidgen`, which is unique per *run* — the property bat does not need
  # and the one that made all 25 committed tmTheme files churn on every
  # regeneration. Determinism is covered above; this is the other half, that two
  # themes still do not collide.
  local first second
  first=$(make_fixture_theme uuid-one "Uuid One")
  second=$(make_fixture_theme uuid-two "Uuid Two")

  "$GENERATORS_DIR/bat.sh" "$first" "$BATS_TEST_TMPDIR/one.tmTheme" >/dev/null
  "$GENERATORS_DIR/bat.sh" "$second" "$BATS_TEST_TMPDIR/two.tmTheme" >/dev/null

  local uuid_one uuid_two
  uuid_one=$(grep -A1 '<key>uuid</key>' "$BATS_TEST_TMPDIR/one.tmTheme" | tail -1)
  uuid_two=$(grep -A1 '<key>uuid</key>' "$BATS_TEST_TMPDIR/two.tmTheme" | tail -1)
  assert_not_equal "$uuid_one" "$uuid_two"
  assert_regex "$uuid_one" '<string>[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}</string>'
}

@test "a generator carries the theme's own colours into its output" {
  # The fixture's base00 is #000000 and its foreground falls back to base05,
  # #050505 — values no real theme has, so finding them proves the output came
  # from this theme.yml rather than from a default baked into the generator.
  local theme_yml
  theme_yml=$(make_fixture_theme fixture-dark "Fixture Dark")

  run "$GENERATORS_DIR/ghostty.sh" "$theme_yml" "$BATS_TEST_TMPDIR/ghostty.conf"
  assert_success

  run cat "$BATS_TEST_TMPDIR/ghostty.conf"
  assert_output --partial "#000000"
  assert_output --partial "#050505"
}

@test "a generator fails on a theme.yml that is not there" {
  run "$GENERATORS_DIR/ghostty.sh" "$THEMES_DIR/absent/theme.yml" "$BATS_TEST_TMPDIR/out.conf"
  assert_failure
}

#==============================================================================
# REPO-WIDE ARTIFACT UNIFORMITY
#==============================================================================

@test "every theme carries the same artifact set" {
  # The check that catches both halves of the same problem: a new theme built
  # while a generator was missing from the map, and a stale file left behind by a
  # format migration. neovim/ is the one legitimate difference — only generated
  # themes have it, and being a directory it is not counted here.
  count_theme_artifacts

  local total="${ARTIFACT_COUNT["theme.yml"]}"
  [[ "$total" -gt 1 ]] || fail "found $total themes — the glob has gone stale"

  local artifact
  for artifact in "${!ARTIFACT_COUNT[@]}"; do
    assert_equal "$artifact:${ARTIFACT_COUNT[$artifact]}" "$artifact:$total"
  done
}

@test "every artifact a theme carries is one some generator produces" {
  # The inverse of the uniformity check above, which cannot see a file that is
  # present in *every* theme and generated by nothing — mako.ini survived a
  # rename in eight themes exactly that way.
  count_theme_artifacts

  local produced=" theme.yml ${MAP_ARTIFACT[*]} "

  local artifact
  for artifact in "${!ARTIFACT_COUNT[@]}"; do
    [[ "$produced" == *" $artifact "* ]] \
      || fail "themes carry '$artifact' but no generator in the map produces it"
  done
}

@test "every app artifact the CLI reports on is one a generator produces" {
  # THEME_APP_ARTIFACTS is what `theme current` lists. A generator added without
  # a row there stays invisible even though apply is deploying it, so the two
  # lists have to name the same set.
  source "$THEME_ROOT/lib/lib.sh"

  local produced=" neovim ${MAP_ARTIFACT[*]} "

  local row artifact
  for row in "${THEME_APP_ARTIFACTS[@]}"; do
    artifact="${row%%:*}"
    [[ "$produced" == *" $artifact "* ]] \
      || fail "THEME_APP_ARTIFACTS lists '$artifact', which no generator produces"
  done
}

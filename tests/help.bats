#!/usr/bin/env bats
# `theme <verb> --help`, at every level of the command tree.
#
# The verbs carrying free text read it as "$*", so a --help reaching one becomes
# the message rather than a request for help: `theme reject --help` hides the
# current theme with "--help" as the reason, `like`/`dislike`/`note` write a
# history record saying the same, and `theme random --help` applies a random
# theme. main() answers the flag before dispatch for that reason.
#
# The verb list is read out of the help screen rather than written here, so a
# command added to the table is covered without a new test.
#
# The same screens are the command tree that every command a hint, an error or
# an example prints is walked against, so renaming a command fails here rather
# than sending a reader to "unknown command".

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  source_theme_libs

  # A verb that acts needs something to act on, or it exits early on "no theme
  # applied" and the test passes without exercising the guard.
  mkdir -p "$THEME_LIVE_DIR"
  echo "gruvbox" >"$CURRENT_THEME_FILE"
}

# Commands and Subcommands both sit between those two headers on the plain
# help screen, which is the branch a sandboxed HOME gets.
help_screen_verbs() {
  "$THEME_ROOT/bin/theme" help \
    | sed -n '/^Commands$/,/^Examples$/p' \
    | awk '/^  [a-z]/ { print $1 }'
}

assert_no_history() {
  [[ ! -s "$THEME_HISTORY_FILE" ]] || {
    echo "history written by a help request:" >&2
    cat "$THEME_HISTORY_FILE" >&2
    return 1
  }
}

@test "the help screen lists every verb the tables carry" {
  run help_screen_verbs
  assert_success
  assert_line "reject"
  assert_line "random"
  assert_line "background"
  assert_line "sync"
}

@test "every verb on the help screen answers --help without acting" {
  local verb
  while read -r verb; do
    run "$THEME_ROOT/bin/theme" "$verb" --help
    [[ "$status" -eq 0 ]] || fail "theme $verb --help exited $status: $output"
    [[ -n "$output" ]] || fail "theme $verb --help printed nothing"
    assert_no_history
  done < <(help_screen_verbs)
}

@test "every verb answers -h the same way" {
  local verb
  while read -r verb; do
    run "$THEME_ROOT/bin/theme" "$verb" -h
    [[ "$status" -eq 0 ]] || fail "theme $verb -h exited $status: $output"
    assert_no_history
  done < <(help_screen_verbs)
}

@test "a flat verb gets its own synopsis, not the whole screen" {
  local full
  full=$("$THEME_ROOT/bin/theme" help 2>&1)
  run "$THEME_ROOT/bin/theme" reject --help
  assert_success
  [[ -n "$output" && "$output" != "$full" ]] || fail "reject --help printed the full screen"
}

@test "bare theme is a request for help, not a usage error" {
  run "$THEME_ROOT/bin/theme"
  assert_success
}

# Prints "<command path>|leaf" or "<command path>|node" for every command under
# the path given, read from that path's help screen. A screen lists what runs
# under Commands and what has a screen of its own under Subcommands. Only a
# Subcommands entry is asked for its help, because a leaf below the first word
# takes --help as an argument and runs.
command_tree() {
  local prefix="$1" name kind
  local -a words=()
  [[ -n "$prefix" ]] && read -ra words <<<"$prefix"
  while read -r name kind; do
    echo "${prefix:+$prefix }$name|$kind"
    if [[ "$kind" == node ]]; then
      command_tree "${prefix:+$prefix }$name"
    fi
  done < <(
    "$THEME_ROOT/bin/theme" ${words[@]+"${words[@]}"} --help \
      | awk '/^[A-Z]/ { section = $0; next }
             /^  [a-z]/ && section == "Commands" { print $1, "leaf" }
             /^  [a-z]/ && section == "Subcommands" { print $1, "node" }'
  )
}

# Every `theme ...` the source prints for a person to run, as
# "<file>:<line> <words>". Prose says "the theme name" and "with theme colors",
# so a command is recognized by what leads into it: a label ending in a colon,
# "see" or "or", an opening single quote, print_cyan, or an example line's indent.
printed_commands() {
  local re='(Usage: |Run: |[^A-Za-z][a-z]+: |print_cyan "|'"'"'|[^a-z]see |[^a-z]or |^[[:space:]]+|echo "[[:space:]]+)theme(( [a-z][a-z-]*)+)'
  local line file rest lineno text
  while IFS= read -r line; do
    file=${line%%:*}
    rest=${line#*:}
    lineno=${rest%%:*}
    text=${rest#*:}
    [[ "$text" =~ ^[[:space:]]*# ]] && continue
    while [[ "$text" =~ $re ]]; do
      echo "${file#"$THEME_ROOT"/}:$lineno${BASH_REMATCH[2]}"
      text=${text#*"${BASH_REMATCH[0]}"}
    done
  done < <(grep -HnE 'theme [a-z]' "$THEME_ROOT/bin/theme" "$THEME_ROOT"/lib/*.sh \
    "$THEME_ROOT"/lib/generators/*.sh "$THEME_ROOT"/scripts/*.sh)
}

@test "every command a hint or help screen prints is in the command tree" {
  # help is the one verb no screen lists, because it is the screen.
  local tree
  tree=$'\nhelp|leaf\n'"$(command_tree "")"$'\n'

  local location words path word walked=0 missing=""
  local -a parts
  while read -r location words; do
    walked=$((walked + 1))
    read -ra parts <<<"$words"
    path=""
    for word in "${parts[@]}"; do
      path="${path:+$path }$word"
      [[ "$tree" == *$'\n'"$path|leaf"$'\n'* ]] && break
      if [[ "$tree" != *$'\n'"$path|node"$'\n'* ]]; then
        missing+="$location: theme $words"$'\n'
        break
      fi
    done
  done < <(printed_commands)

  [[ -z "$missing" ]] || fail "printed commands missing from the command tree:"$'\n'"$missing"
  ((walked > 40)) || fail "found only $walked printed commands; the markers stopped matching"
}

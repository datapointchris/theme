#!/usr/bin/env bats
# Platform detection, and the label contract between detection and dispatch.
#
# This file exists because the two halves disagreed. lib.sh and storage.sh each
# defined detect_platform; storage.sh emitted "arch" for the Arch box and lib.sh
# emitted "archlinux", so whichever was sourced last decided what every platform
# comparison in lib.sh was compared against. bin/theme sourced storage.sh second
# and took "arch", while scripts/test-all-themes.sh sources only lib.sh and took
# the other — and on Arch that meant apply_theme_to_apps silently skipped
# Hyprland, Waybar, Hyprlock, Dunst, Rofi, ghostty, kitty and the wallpaper, with
# no error and nothing in the skipped list. macOS returns "macos" from both
# definitions, which is why it survived for months on the machine it was used on.

load "$HOME/.local/lib/bats-support/load.bash"
load "$HOME/.local/lib/bats-assert/load.bash"

setup() {
  load "$BATS_TEST_DIRNAME/helpers.bash"
  isolate_theme_state
  source_theme_libs
}

@test "PLATFORM overrides detection" {
  # The seam the rest of the suite leans on: there is no way to fake
  # /etc/arch-release from a test, so every platform-dependent assertion sets
  # PLATFORM instead.
  PLATFORM=arch run detect_platform
  assert_success
  assert_output "arch"
}

@test "detects the host it is running on" {
  run detect_platform
  assert_success
  if [[ "$OSTYPE" == darwin* ]]; then
    assert_output "macos"
  else
    refute_output ""
  fi
}

@test "only one library defines detect_platform" {
  # The regression pin. A second definition anywhere in lib/ reintroduces the
  # shadowing, and the winner depends on source order rather than on anything a
  # reader can see at the call site.
  run pipeline "grep -c '^detect_platform() {' $THEME_ROOT/lib/*.sh | grep -v ':0$'"
  assert_success
  assert_output "$THEME_ROOT/lib/storage.sh:1"
}

@test "sourcing lib.sh alone gives the same detect_platform as the CLI" {
  # scripts/test-all-themes.sh sources only lib.sh. Before the fix it therefore
  # ran against a different platform vocabulary than bin/theme.
  local alone both
  alone=$(bash -c "PLATFORM= source '$THEME_ROOT/lib/lib.sh'; detect_platform")
  both=$(bash -c "PLATFORM= source '$THEME_ROOT/lib/lib.sh'; source '$THEME_ROOT/lib/storage.sh'; detect_platform")
  assert_equal "$alone" "$both"
}

@test "every platform label lib.sh compares against is one detect_platform can emit" {
  # A label detect_platform never produces is a dead branch, and every branch
  # here guards an app being applied — so a dead one is an app that silently
  # stops being themed. Both comparison forms are checked: `"$platform" == "x"`
  # and the case arms in set_desktop_wallpaper.
  local emitted=" macos wsl arch linux unknown "
  local label found=0

  while read -r label; do
    [[ -n "$label" ]] || continue
    found=$((found + 1))
    [[ "$emitted" == *" $label "* ]] \
      || fail "lib.sh dispatches on '$label', which detect_platform never emits"
  done < <(
    {
      grep -oE 'platform" == "[a-z]+"' "$THEME_ROOT/lib/lib.sh" | grep -oE '[a-z]+"$'
      grep -oE '^    [a-z]+\)$' "$THEME_ROOT/lib/lib.sh" | tr -d ' '
    } | tr -d '")' | sort -u
  )

  # Guards the extraction itself: a refactor that renames the local or reindents
  # the case would otherwise leave this test passing over zero labels.
  [[ "$found" -ge 3 ]] || fail "found only $found platform labels — the extraction has gone stale"
}

@test "the storage source guard makes a second source a no-op" {
  # lib.sh sources storage.sh, and bin/theme sources both. Without the guard the
  # tail of storage.sh re-runs init_storage on every source.
  run bash -c "source '$THEME_ROOT/lib/storage.sh'; source '$THEME_ROOT/lib/storage.sh'; echo \"\$_THEME_STORAGE_SOURCED\""
  assert_success
  assert_output "1"
}

@test "the machine id lowercases the hostname and drops the domain" {
  # Prefixing the platform (the old "platform-host" format) both duplicated the
  # platform field and split one machine's records whenever the platform label
  # drifted or the hostname case changed — hence bare, and hence lowercased.
  stub_command_with_output uname "MacMini.local"
  run _storage_get_machine_id
  assert_success
  assert_output "macmini"
}

@test "the machine id falls back to unknown when the hostname is empty" {
  # Not hypothetical: the Arch box recorded an empty hostname for a while, which
  # is why the history normalizer has an "unknown" branch to merge back.
  stub_command_with_output uname ""
  run _storage_get_machine_id
  assert_success
  assert_output "unknown"
}

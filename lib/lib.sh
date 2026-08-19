#!/usr/bin/env bash
# Theme library - core functions for theme management
# Applies themes directly from themes/ directory

set -euo pipefail

THEME_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
THEME_APP_DIR="$(cd "$THEME_LIB_DIR/.." && pwd)"

# Sourced here rather than left to the caller, so this file is self-sufficient
# and there is one definition of detect_platform in play. Both files used to
# define it and they disagreed about Arch's label — storage.sh emits "arch",
# this file emitted "archlinux" — so whichever was sourced last decided what
# every platform comparison below compared against. bin/theme took storage.sh's
# answer while scripts/test-all-themes.sh, which sources only this file, took
# the other, and on Arch that silently skipped Hyprland, Waybar, ghostty, kitty
# and the wallpaper. storage.sh also owns THEME_STATE_DIR and the history paths.
source "$THEME_LIB_DIR/storage.sh"

# Always production, unlike THEME_STATE_DIR: apps watch this directory, so dev
# mode must not point them at .dev-data.
THEME_LIVE_DIR="$HOME/.local/state/theme"

# Configuration - themes/ is the single source of truth
THEMES_DIR="$THEME_APP_DIR/themes"

# Live files - always in production so apps respond to changes
CURRENT_THEME_FILE="$THEME_LIVE_DIR/current"

# artifact:label pairs used to report which apps a theme carries configs for.
# Add a row here when adding a generator, or the app stays invisible to
# `theme current` even though `theme apply` is happily deploying it.
THEME_APP_ARTIFACTS=(
  "ghostty.conf:Ghostty"
  "kitty.conf:Kitty"
  "alacritty.toml:Alacritty"
  "tmux.conf:tmux"
  "btop.theme:btop"
  "bat.tmTheme:bat"
  "delta.conf:delta"
  "flavor.toml:yazi"
  "sioyek.config:sioyek"
  "userChrome.css:Firefox-based"
  "chromium.theme:Chromium"
  "bordersrc:JankyBorders"
  "hyprland.conf:Hyprland"
  "hyprlock.conf:Hyprlock"
  "waybar.css:Waybar"
  "walker.css:Walker"
  "swayosd.css:SwayOSD"
  "rofi.rasi:Rofi"
  "dunst.conf:Dunst"
  "mako.conf:Mako"
  "icons.theme:Icons"
  "windows-terminal.json:WindowsTerminal"
  "neovim:Neovim(generated)"
)

#==============================================================================
# THEME ACCESS - scans themes/ directory
#==============================================================================

# List all theme directory names (the canonical names)
get_theme_names() {
  if [[ ! -d "$THEMES_DIR" ]]; then
    echo "Error: Themes directory not found: $THEMES_DIR" >&2
    return 1
  fi

  for dir in "$THEMES_DIR"/*/; do
    [[ -d "$dir" ]] && basename "$dir"
  done
}

# Get theme data from theme.yml
get_theme_by_name() {
  local name="$1"
  local theme_file="$THEMES_DIR/$name/theme.yml"

  if [[ ! -f "$theme_file" ]]; then
    # Try case-insensitive match
    for dir in "$THEMES_DIR"/*/; do
      local dir_name
      dir_name=$(basename "$dir")
      if [[ "${dir_name,,}" == "${name,,}" ]]; then
        theme_file="$THEMES_DIR/$dir_name/theme.yml"
        break
      fi
    done
  fi

  if [[ -f "$theme_file" ]]; then
    cat "$theme_file"
  else
    return 1
  fi
}

# Get a specific mapping from theme.yml meta section
get_theme_mapping() {
  local name="$1"
  local app="$2"
  local theme_file="$THEMES_DIR/$name/theme.yml"

  if [[ ! -f "$theme_file" ]]; then
    return 1
  fi

  APP="$app" yq ".meta.$app // \"\"" "$theme_file"
}

# Convert input to canonical theme directory name
theme_name_to_canonical() {
  local input="$1"

  # Exact match against the listing, not `[[ -d "$THEMES_DIR/$input" ]]`. macOS
  # is case-insensitive, so the -d test accepted "Gruvbox-Dark-Hard" as already
  # canonical and returned the user's spelling — which then reached the state
  # file and history.jsonl. History is gist-synced, so the Arch box received
  # entries under an id it cannot resolve, and stats split one theme across two
  # names. That is the damage normalize_theme in storage.sh exists to undo.
  for dir in "$THEMES_DIR"/*/; do
    local exact_name
    exact_name=$(basename "$dir")
    if [[ "$exact_name" == "$input" ]]; then
      echo "$exact_name"
      return
    fi
  done

  # Try case-insensitive match
  for dir in "$THEMES_DIR"/*/; do
    local dir_name
    dir_name=$(basename "$dir")
    if [[ "${dir_name,,}" == "${input,,}" ]]; then
      echo "$dir_name"
      return
    fi
  done

  # Try matching against meta.display_name in theme.yml files
  for dir in "$THEMES_DIR"/*/; do
    local theme_file="$dir/theme.yml"
    if [[ -f "$theme_file" ]]; then
      local meta_name
      meta_name=$(yq '.meta.display_name // ""' "$theme_file" 2>/dev/null || echo "")
      if [[ "${meta_name,,}" == "${input,,}" ]]; then
        basename "$dir"
        return
      fi
    fi
  done

  # Return input as-is if no match
  echo "$input"
}

#==============================================================================
# THEME LISTING
#==============================================================================

list_themes() {
  get_theme_names
}

# The set `theme random` draws from. `theme reject` promises a theme is out of
# rotation, and rejection lives in the history rather than on disk, so a listing
# taken from the themes directory alone still offers every rejected theme.
list_themes_not_rejected() {
  local rejected
  rejected=$(get_rejected_theme_ids)

  if [[ -z "$rejected" ]]; then
    get_theme_names
    return
  fi

  declare -A rejected_map
  while IFS= read -r theme; do
    [[ -n "$theme" ]] && rejected_map["$theme"]=1
  done <<<"$rejected"

  local theme
  while IFS= read -r theme; do
    [[ -n "${rejected_map[$theme]:-}" ]] && continue
    echo "$theme"
  done < <(get_theme_names)
}

get_theme_display_info() {
  local theme="$1"
  local theme_file="$THEMES_DIR/$theme/theme.yml"

  if [[ ! -f "$theme_file" ]]; then
    echo "$theme"
    return
  fi

  local display_name source_type
  display_name=$(yq '.meta.display_name // ""' "$theme_file" 2>/dev/null)
  source_type=$(yq '.meta.neovim_colorscheme_source // ""' "$theme_file" 2>/dev/null)

  if [[ -z "$display_name" ]]; then
    display_name="$theme"
  fi

  local source_label=""
  case "$source_type" in
    generated) source_label=" (Generated)" ;;
    plugin) source_label=" (Neovim Plugin)" ;;
  esac

  echo "${display_name}${source_label}"
}

list_themes_with_status() {
  local current
  current=$(get_current_theme 2>/dev/null || echo "")

  while IFS= read -r theme; do
    local display_info
    display_info=$(get_theme_display_info "$theme")
    if [[ "$theme" == "$current" ]]; then
      echo "● $display_info (current)"
    else
      echo "  $display_info"
    fi
  done < <(get_theme_names)
}

count_themes() {
  get_theme_names | wc -l | xargs
}

#==============================================================================
# CURRENT THEME
#==============================================================================

get_current_theme() {
  if [[ -f "$CURRENT_THEME_FILE" ]]; then
    cat "$CURRENT_THEME_FILE"
  else
    echo ""
  fi
}

set_current_theme() {
  local theme="$1"
  mkdir -p "$(dirname "$CURRENT_THEME_FILE")"
  echo "$theme" >"$CURRENT_THEME_FILE"
}

#==============================================================================
# APP HANDLERS - Direct application from themes/ directory
#==============================================================================

# Get the theme directory path
get_theme_path() {
  local theme="$1"
  local canonical
  canonical=$(theme_name_to_canonical "$theme")

  local path="$THEMES_DIR/$canonical"
  if [[ -d "$path" ]]; then
    echo "$path"
  else
    echo ""
  fi
}

# Alias for backward compatibility
get_library_path() {
  get_theme_path "$@"
}

# Install one artifact under the theme's own name and repoint `current` at it.
#
# `current` stays the name every consumer holds, for two reasons that pull the same
# way. An app that can only `source` or `@import` a path needs one that does not
# move. And an app that resolves a theme *by name* reads its config from a symlink
# into the dotfiles repo, so writing the name there would write through the link
# into the checkout — which is exactly how the gowall palettes dirtied dotfiles for
# months. The link reconciles both: the payload carries the theme id, so a machine
# says which theme it is running, and every theme ever applied stays beside the
# others instead of overwriting one file forever.
#
# Nothing is pruned. These directories are also where a user's own themes live, and
# an installer that deletes what it does not recognise is worse than a few stale
# kilobytes.
install_themed_artifact() {
  local source="$1" dir="$2" named="$3" pointer="$4"

  mkdir -p "$dir" || return 1
  cp "$source" "$dir/$named" || return 1

  # The copy-based scheme this replaces left `current` as a real file, and `ln`
  # onto a real directory links *inside* it rather than replacing it.
  [[ -L "$dir/$pointer" ]] || rm -rf "${dir:?}/${pointer:?}"
  ln -sfn "$named" "$dir/$pointer"
}

# Warnings raised during an apply, printed together at the end.
#
# Every apply_* call in apply_theme_to_apps runs with stderr redirected to
# /dev/null, deliberately — that is what keeps cp and reload noise off the screen.
# So anything written to stderr during an apply is discarded, and a warning nobody
# can see is worse than no warning, because a quiet run reads as a correct one.
# This array is the channel that survives the redirect.
APPLY_WARNINGS=()

apply_warn() {
  APPLY_WARNINGS+=("$1")
}

# Whether there is a controlling terminal to write progress to.
#
# `[[ -w /dev/tty ]]` is the obvious test and the wrong one: it reads the device
# node's permission bits, which are writable whether or not this process has a
# terminal attached. So the guard passed and the very next redirect failed, and
# `theme apply` from cron, a script or an agent session printed
# "/dev/tty: No such device or address" and reported the background step failed.
# Opening it is the only thing that answers the question.
tty_writable() {
  { : >/dev/tty; } 2>/dev/null
}

# Whether Neovim could resolve this colorscheme by name.
#
# `:colorscheme <name>` needs a `colors/<name>.{lua,vim}` somewhere on the
# runtimepath, so that file is what gets looked for rather than asking a particular
# plugin manager where it keeps things — lazy.nvim installs under `nvim/lazy/`,
# vim.pack under `nvim/site/pack/`, and a migration between them must not silently
# turn this check into "always fine".
neovim_colorscheme_available() {
  local name="$1"
  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"

  # Tested rather than globbed: these two carry no metacharacter, so `nullglob`
  # would not drop them when they do not exist — they would stay in the array as
  # literal words and the check would answer "found" on every machine.
  local candidate
  for candidate in "$config_home/nvim/colors/$name.lua" "$config_home/nvim/colors/$name.vim"; do
    if [[ -f "$candidate" ]]; then
      return 0
    fi
  done

  local restore
  restore=$(shopt -p nullglob globstar)
  shopt -s nullglob globstar
  local found=("$data_home"/nvim/**/colors/"$name".lua "$data_home"/nvim/**/colors/"$name".vim)
  eval "$restore"

  [[ ${#found[@]} -gt 0 ]]
}

# Warn when Neovim cannot honour the theme being applied.
#
# A plugin theme names a colorscheme this tool does not ship. On a machine that
# never installed it — no network, a locked-down box, a plugin sync that has not
# run — the terminal changes colour and the editor does not, with nothing on screen
# saying so. That silence is the whole reason this exists; a fallback that nobody
# is told about is indistinguishable from the theme having applied.
#
# Only plugin themes are checked. A theme with no `plugin` is either generated here
# or built into Neovim (retrobox), and neither of those can be missing.
check_neovim_colorscheme() {
  local theme="$1"
  local theme_file="$THEMES_DIR/$theme/theme.yml"

  [[ -f "$theme_file" ]] || return 0
  command -v nvim &>/dev/null || return 0

  local plugin
  plugin=$(yq '.meta.plugin // ""' "$theme_file" 2>/dev/null)
  [[ -n "$plugin" ]] || return 0

  local colorscheme
  colorscheme=$(yq '.meta.neovim_colorscheme_name // ""' "$theme_file" 2>/dev/null)
  [[ -n "$colorscheme" ]] || return 0

  neovim_colorscheme_available "$colorscheme" && return 0

  local id
  id=$(yq '.meta.id // ""' "$theme_file" 2>/dev/null)
  [[ -n "$id" ]] || id="$theme"

  # Named, not just announced: the fallback is only useful to someone who can
  # type it, and it is deliberately not the name the theme advertises.
  local fallback="theme-$id"
  if [[ -f "$THEMES_DIR/$theme/neovim/colors/$fallback.lua" ]]; then
    apply_warn "Neovim colorscheme '$colorscheme' is not installed ($plugin) — falling back to '$fallback', generated from this palette rather than tuned by the theme's author."
  else
    apply_warn "Neovim colorscheme '$colorscheme' is not installed ($plugin) and this theme ships no generated fallback — the editor keeps its previous colours."
  fi
}

# Apply Ghostty theme
# Installs as themes/<id>.conf with themes/current.conf pointing at it
apply_ghostty() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/ghostty.conf" ]]; then
    return 1
  fi

  local ghostty_theme_dir="$HOME/.config/ghostty/themes"

  install_themed_artifact "$lib_path/ghostty.conf" "$ghostty_theme_dir" "$theme.conf" "current.conf" || return 1

  # Referenced from main ghostty config via: gtk-custom-css = themes/current.css
  if [[ -f "$lib_path/ghostty.css" ]]; then
    install_themed_artifact "$lib_path/ghostty.css" "$ghostty_theme_dir" "$theme.css" "current.css" || return 1
  fi

  return 0
}

# Apply Kitty theme (Arch)
apply_kitty() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/kitty.conf" ]]; then
    return 1
  fi

  local kitty_theme_dir="$HOME/.config/kitty/themes"

  # `current-theme.conf` is kitty's own convention — its theme kitten writes
  # exactly that path — so the pointer keeps kitty's spelling rather than ours.
  install_themed_artifact "$lib_path/kitty.conf" "$kitty_theme_dir" "$theme.conf" "current-theme.conf" || return 1

  # Kitty auto-reloads when config changes
  return 0
}

# Apply tmux theme
apply_tmux() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/tmux.conf" ]]; then
    return 1
  fi

  local tmux_theme_dir="$HOME/.config/tmux/themes"

  install_themed_artifact "$lib_path/tmux.conf" "$tmux_theme_dir" "$theme.conf" "current.conf" || return 1

  return 0
}

# Apply btop theme
apply_btop() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/btop.theme" ]]; then
    return 1
  fi

  local btop_theme_dir="$HOME/.config/btop/themes"

  install_themed_artifact "$lib_path/btop.theme" "$btop_theme_dir" "$theme.theme" "current.theme" || return 1

  # Update btop config to use current theme
  local btop_config="$HOME/.config/btop/btop.conf"
  if [[ -f "$btop_config" ]]; then
    if grep -q "^color_theme" "$btop_config"; then
      sed -i 's|^color_theme.*|color_theme = "current"|' "$btop_config"
    fi
  fi

  return 0
}

# Apply JankyBorders theme (macOS)
apply_borders() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/bordersrc" ]]; then
    return 1
  fi

  local borders_theme_dir="$HOME/.config/borders/themes"

  install_themed_artifact "$lib_path/bordersrc" "$borders_theme_dir" "$theme" "current" || return 1
  chmod +x "$borders_theme_dir/$theme"

  # Restart borders if running
  if pgrep -x "borders" &>/dev/null; then
    pkill -x "borders" 2>/dev/null || true
    sleep 0.5
    "$HOME/.config/borders/bordersrc" >/dev/null 2>&1 &
    disown
  fi

  return 0
}

# Apply yazi theme (all platforms)
# Uses flavor system: copies to ~/.config/yazi/flavors/current.yazi/flavor.toml
apply_yazi() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/flavor.toml" ]]; then
    return 1
  fi

  local yazi_dir="$HOME/.config/yazi"
  local flavors_dir="$yazi_dir/flavors"

  # A flavor is a directory rather than a file, so this is the one case
  # install_themed_artifact cannot serve.
  mkdir -p "$flavors_dir/$theme.yazi" || return 1
  cp "$lib_path/flavor.toml" "$flavors_dir/$theme.yazi/flavor.toml" || return 1

  [[ -L "$flavors_dir/current.yazi" ]] || rm -rf "$flavors_dir/current.yazi"
  ln -sfn "$theme.yazi" "$flavors_dir/current.yazi" || return 1

  # yazi names its flavor in theme.toml and *refuses to start* when the named one
  # is absent, so the pointer belongs to whoever knows a theme has been applied —
  # this tool — and not to a config repo that ships it unconditionally. A machine
  # with no theme.toml falls back to yazi's built-in theme and starts clean, which
  # is what makes a fresh install work.
  #
  # Never through a symlink: that path was dotfiles-managed until dotfiles stopped
  # shipping it, and writing through one is how the gowall palettes dirtied that
  # repo for months. An old checkout still declaring it keeps its own file.
  if [[ ! -L "$yazi_dir/theme.toml" ]]; then
    printf '[flavor]\ndark = "current"\nlight = "current"\n' >"$yazi_dir/theme.toml" || return 1
  fi

  return 0
}

# Apply aerc email client theme (all platforms)
# aerc.conf pins styleset-name to "current", so the filename is the contract
apply_aerc() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/aerc.styleset" ]]; then
    return 1
  fi

  local aerc_styleset_dir="$HOME/.config/aerc/stylesets"

  install_themed_artifact "$lib_path/aerc.styleset" "$aerc_styleset_dir" "$theme" "current" || return 1

  return 0
}

# Apply Firefox-based browser theme (all platforms)
# Copies userChrome.css to detected browser profiles
apply_firefox_based() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/userChrome.css" ]]; then
    return 1
  fi

  # Source browser profiles discovery
  local browser_profiles_lib="$THEME_LIB_DIR/browser-profiles.sh"
  if [[ ! -f "$browser_profiles_lib" ]]; then
    return 1
  fi
  source "$browser_profiles_lib"

  local applied=0
  local browsers=("zen" "librewolf" "firefox" "thunderbird")

  for browser in "${browsers[@]}"; do
    local profile
    if profile=$(find_browser_profile "$browser" 2>/dev/null); then
      local chrome_dir="$profile/chrome"
      mkdir -p "$chrome_dir"
      cp "$lib_path/userChrome.css" "$chrome_dir/userChrome.css"
      applied=$((applied + 1))
    fi
  done

  if [[ $applied -eq 0 ]]; then
    return 1
  fi

  return 0
}

# Apply sioyek PDF viewer theme (all platforms)
# Splices a marker-delimited managed block into the user's prefs_user.config.
#
# Sioyek has no `include` directive (config.cpp deserializer is key=value only)
# and user_config_paths is a fixed per-platform list, so we have to write into
# the single prefs_user.config file directly. The managed-block pattern keeps
# user-added prefs (use_system_theme, startup_commands, etc.) outside the block
# untouched. Target path is the XDG location, which sioyek supports on both
# Linux and macOS (main.cpp:234-236 explicitly handcrafts an XDG path on mac).
apply_sioyek() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/sioyek.config" ]]; then
    return 1
  fi

  local sioyek_config_dir="$HOME/.config/sioyek"
  local target="$sioyek_config_dir/prefs_user.config"
  mkdir -p "$sioyek_config_dir"

  local block
  block=$(<"$lib_path/sioyek.config")

  if [[ ! -f "$target" ]]; then
    printf '%s\n' "$block" >"$target"
    return 0
  fi

  if grep -q "^# >>> theme tool" "$target"; then
    awk -v block="$block" '
      /^# >>> theme tool .managed./ { print block; in_block=1; next }
      /^# <<< theme tool .managed./ && in_block { in_block=0; next }
      !in_block { print }
    ' "$target" >"$target.tmp" && mv "$target.tmp" "$target"
  else
    printf '\n%s\n' "$block" >>"$target"
  fi

  return 0
}

# Apply bat syntax highlighter theme (all platforms)
# Copies .tmTheme to bat themes dir and rebuilds cache
apply_bat() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/bat.tmTheme" ]]; then
    return 1
  fi

  # Check if bat is installed
  if ! command -v bat &>/dev/null; then
    return 1
  fi

  local bat_themes_dir="$HOME/.config/bat/themes"

  # bat registers a theme under its filename stem, and delta selects out of the
  # same cache by that stem — so `current.tmTheme` has to keep existing or delta
  # silently drops to its bundled default. The link satisfies that while the named
  # copy makes every applied theme selectable as `bat --theme=<id>`.
  install_themed_artifact "$lib_path/bat.tmTheme" "$bat_themes_dir" "$theme.tmTheme" "current.tmTheme" || return 1

  # Rebuild bat cache to register the updated theme
  bat cache --build >/dev/null 2>&1 || true

  return 0
}

# Apply delta git pager theme (all platforms)
# Writes a git config fragment included from the user's gitconfig
apply_delta() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/delta.conf" ]]; then
    return 1
  fi

  # bat is a hard dependency, not a nicety: the generated fragment selects the
  # syntax theme by the name bat registers, and delta warns on every single diff
  # if that cache was never built.
  if ! command -v delta &>/dev/null || ! command -v bat &>/dev/null; then
    return 1
  fi

  local delta_config_dir="$HOME/.config/delta"

  install_themed_artifact "$lib_path/delta.conf" "$delta_config_dir" "$theme.gitconfig" "current.gitconfig" || return 1

  return 0
}

#==============================================================================
# OPACITY MANAGEMENT
#==============================================================================

# Opacity config directories (separate from main config, included via config-file directive)
GHOSTTY_OPACITY_DIR="$HOME/.config/ghostty/opacity"
GHOSTTY_OPACITY_FILE="$GHOSTTY_OPACITY_DIR/current.conf"
KITTY_OPACITY_DIR="$HOME/.config/kitty/opacity"
KITTY_OPACITY_FILE="$KITTY_OPACITY_DIR/current.conf"
WINDOWS_TERMINAL_OPACITY_FILE="$HOME/.config/windows-terminal/opacity.json"
TMUX_OPACITY_FILE="$HOME/.config/tmux/opacity.conf"
WAYBAR_OPACITY_DIR="$HOME/.config/waybar/opacity"
WAYBAR_OPACITY_FILE="$WAYBAR_OPACITY_DIR/current.css"

# Get current opacity from ghostty opacity config
get_ghostty_opacity() {
  if [[ -f "$GHOSTTY_OPACITY_FILE" ]]; then
    grep -E "^background-opacity\s*=" "$GHOSTTY_OPACITY_FILE" 2>/dev/null | sed 's/.*=\s*//' | tr -d ' ' || echo "1.0"
  else
    echo "1.0"
  fi
}

# Set ghostty opacity
set_ghostty_opacity() {
  local opacity="$1"
  mkdir -p "$GHOSTTY_OPACITY_DIR"
  echo "background-opacity = $opacity" >"$GHOSTTY_OPACITY_FILE"
}

# Get current opacity from kitty opacity config
get_kitty_opacity() {
  if [[ -f "$KITTY_OPACITY_FILE" ]]; then
    grep -E "^background_opacity\s+" "$KITTY_OPACITY_FILE" 2>/dev/null | awk '{print $2}' || echo "1.0"
  else
    echo "1.0"
  fi
}

# Set kitty opacity
set_kitty_opacity() {
  local opacity="$1"
  mkdir -p "$KITTY_OPACITY_DIR"
  echo "background_opacity $opacity" >"$KITTY_OPACITY_FILE"
}

# Get current opacity from windows terminal opacity config
get_windows_terminal_opacity() {
  if [[ -f "$WINDOWS_TERMINAL_OPACITY_FILE" ]]; then
    local pct
    pct=$(jq -r '.opacity // 100' "$WINDOWS_TERMINAL_OPACITY_FILE" 2>/dev/null)
    awk "BEGIN {printf \"%.2f\", $pct / 100}"
  else
    echo "1.0"
  fi
}

# Set windows terminal opacity (stores as 0-100 integer)
set_windows_terminal_opacity() {
  local opacity="$1"
  local pct
  pct=$(awk "BEGIN {printf \"%.0f\", $opacity * 100}")
  mkdir -p "$(dirname "$WINDOWS_TERMINAL_OPACITY_FILE")"
  echo "{\"opacity\": $pct}" >"$WINDOWS_TERMINAL_OPACITY_FILE"

  _apply_windows_terminal_opacity "$pct"
}

# Apply opacity directly to Windows Terminal settings.json
_apply_windows_terminal_opacity() {
  local opacity_pct="$1"

  local windows_user wt_settings=""
  windows_user=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
  [[ -z "$windows_user" ]] && return 1

  for path in "/mnt/c/Users/$windows_user/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json" \
    "/mnt/c/Users/$windows_user/AppData/Local/Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState/settings.json" \
    "/mnt/c/Users/$windows_user/AppData/Local/Microsoft/Windows Terminal/settings.json"; do
    [[ -f "$path" ]] && wt_settings="$path" && break
  done
  [[ -z "$wt_settings" ]] && return 1

  cp "$wt_settings" "${wt_settings}.backup"

  if [[ "$opacity_pct" == "100" ]]; then
    jq 'del(.profiles.defaults.opacity) | .profiles.list = [.profiles.list[] | del(.opacity)]' \
      "$wt_settings" >"${wt_settings}.tmp" && mv "${wt_settings}.tmp" "$wt_settings"
  else
    jq --argjson opacity "$opacity_pct" \
      '.profiles.defaults.opacity = $opacity | .profiles.list = [.profiles.list[] | .opacity = $opacity]' \
      "$wt_settings" >"${wt_settings}.tmp" && mv "${wt_settings}.tmp" "$wt_settings"
  fi
}

# Set tmux opacity (uses 'default' bg when < 1.0, otherwise uses theme bg)
set_tmux_opacity() {
  local opacity="$1"
  local tmux_dir
  tmux_dir="$(dirname "$TMUX_OPACITY_FILE")"
  mkdir -p "$tmux_dir"

  if awk "BEGIN {exit !($opacity < 1.0)}"; then
    # Transparent - use default background
    cat >"$TMUX_OPACITY_FILE" <<'EOF'
# Transparent background (inherits from terminal)
set -g window-style 'bg=default'
set -g window-active-style 'bg=default'
EOF
  else
    # Opaque - use theme background (empty file, theme controls bg)
    cat >"$TMUX_OPACITY_FILE" <<'EOF'
# Opaque background (uses theme colors)
# No overrides needed - theme controls background
EOF
  fi

  # Reload tmux if running
  if command -v tmux &>/dev/null && tmux list-sessions &>/dev/null; then
    tmux source-file "$TMUX_OPACITY_FILE" 2>/dev/null || true
  fi
}

# Get current opacity from waybar opacity config
get_waybar_opacity() {
  if [[ -f "$WAYBAR_OPACITY_FILE" ]]; then
    grep -E "^/\* opacity:" "$WAYBAR_OPACITY_FILE" 2>/dev/null | sed 's|.* opacity: \([0-9.]*\).*|\1|' || echo "1.0"
  else
    echo "1.0"
  fi
}

# Set waybar opacity
set_waybar_opacity() {
  local opacity="$1"
  mkdir -p "$WAYBAR_OPACITY_DIR"
  cat >"$WAYBAR_OPACITY_FILE" <<EOF
/* Waybar opacity - managed by theme tool */
/* opacity: $opacity */
@define-color waybar-bg alpha(@bg, $opacity);
EOF

  # Reload waybar if running
  if pgrep -x waybar &>/dev/null; then
    killall -SIGUSR2 waybar 2>/dev/null || true
  fi
}

# Get current opacity (from first available terminal)
get_current_opacity() {
  local opacity

  if [[ -f "$GHOSTTY_OPACITY_FILE" ]]; then
    opacity=$(get_ghostty_opacity)
  elif [[ -f "$KITTY_OPACITY_FILE" ]]; then
    opacity=$(get_kitty_opacity)
  elif [[ -f "$WINDOWS_TERMINAL_OPACITY_FILE" ]]; then
    opacity=$(get_windows_terminal_opacity)
  else
    opacity="1.0"
  fi

  echo "$opacity"
}

# Change opacity by delta (e.g., 0.05 or -0.05)
change_opacity() {
  local delta="$1"
  local current
  current=$(get_current_opacity)

  # Calculate new opacity using awk for floating point
  local new_opacity
  new_opacity=$(awk "BEGIN {printf \"%.2f\", $current + $delta}")

  # Clamp between 0.5 and 1.0
  if awk "BEGIN {exit !($new_opacity < 0.5)}"; then
    new_opacity="0.50"
  elif awk "BEGIN {exit !($new_opacity > 1.0)}"; then
    new_opacity="1.00"
  fi

  # Apply to all terminals and waybar
  local applied=()

  set_ghostty_opacity "$new_opacity" && applied+=("ghostty")
  set_kitty_opacity "$new_opacity" && applied+=("kitty")
  set_windows_terminal_opacity "$new_opacity" && applied+=("windows-terminal")
  set_tmux_opacity "$new_opacity" && applied+=("tmux")
  set_waybar_opacity "$new_opacity" && applied+=("waybar")

  echo "$current → $new_opacity (${applied[*]})"
}

# Set opacity to an absolute value (0-100)
set_opacity() {
  local value="$1"

  # Validate input is a number between 0 and 100
  if ! [[ "$value" =~ ^[0-9]+$ ]] || [[ "$value" -lt 0 ]] || [[ "$value" -gt 100 ]]; then
    echo "Error: opacity must be a number between 0 and 100" >&2
    return 1
  fi

  local current
  current=$(get_current_opacity)

  # Convert 0-100 to 0.00-1.00
  local new_opacity
  new_opacity=$(awk "BEGIN {printf \"%.2f\", $value / 100}")

  # Apply to all terminals and waybar
  local applied=()

  set_ghostty_opacity "$new_opacity" && applied+=("ghostty")
  set_kitty_opacity "$new_opacity" && applied+=("kitty")
  set_windows_terminal_opacity "$new_opacity" && applied+=("windows-terminal")
  set_tmux_opacity "$new_opacity" && applied+=("tmux")
  set_waybar_opacity "$new_opacity" && applied+=("waybar")

  echo "$current → $new_opacity (${applied[*]})"
}

# Background cache directory
BACKGROUND_CACHE_DIR="${BACKGROUND_CACHE_DIR:-$HOME/.cache/theme/backgrounds}"

# Where the wallpaper handed to the compositor is rendered. Regenerable and
# deleted a minute later — the timestamp in the name exists only to defeat
# macOS's wallpaper cache — so it is cache, not data. It used to be written to
# ~/.local/share/theme, which is the installed git checkout, so every apply left
# an untracked PNG in that repo's `git status`. The stable
# ~/.local/share/theme/background.png is deliberate and stays: hyprpaper.conf in
# dotfiles names that exact path for its restart fallback.
BACKGROUND_RENDER_DIR="${BACKGROUND_RENDER_DIR:-$HOME/.cache/theme/current}"

# Background sources config file (path references, not copies)
BACKGROUND_SOURCES_FILE="${BACKGROUND_SOURCES_FILE:-$HOME/.config/theme/background-sources.conf}"

# Current background tracking - always in production so background actually changes
BACKGROUND_CURRENT_FILE="$THEME_LIVE_DIR/background-current"

# Mode setting (which background types to include in rotation)
BACKGROUND_MODE_FILE="${BACKGROUND_MODE_FILE:-$HOME/.config/theme/background-mode}"

# Default background resolution
BACKGROUND_WIDTH=3840
BACKGROUND_HEIGHT=2160

# All available generated styles (no source image needed)
BACKGROUND_GENERATED_STYLES=("plasma")

# Source-based transform types (need source images like recolor)
BACKGROUND_SOURCE_TYPES=("recolor" "ascii" "lowpoly")

#==============================================================================
# BACKGROUND MODE MANAGEMENT
#==============================================================================

# List all available background modes/styles
list_available_background_modes() {
  for style in "${BACKGROUND_GENERATED_STYLES[@]}"; do
    echo "generated:$style"
  done
  for type in "${BACKGROUND_SOURCE_TYPES[@]}"; do
    echo "$type"
  done
}

# Get current background mode settings
# Returns: list of enabled modes, one per line, or "all" if not set
get_background_mode() {
  if [[ ! -f "$BACKGROUND_MODE_FILE" ]]; then
    echo "all"
    return
  fi

  local content
  content=$(cat "$BACKGROUND_MODE_FILE")

  if [[ -z "$content" ]]; then
    echo "all"
    return
  fi

  echo "$content"
}

# Set background mode to specific types
# Args: type1 [type2 ...]
# Special values: "all" enables everything
set_background_mode() {
  mkdir -p "$(dirname "$BACKGROUND_MODE_FILE")"

  if [[ "$1" == "all" ]]; then
    echo "all" >"$BACKGROUND_MODE_FILE"
    return
  fi

  : >"$BACKGROUND_MODE_FILE"
  for mode in "$@"; do
    echo "$mode" >>"$BACKGROUND_MODE_FILE"
  done
}

# Add a mode to current settings
add_background_mode() {
  local mode="$1"
  local current
  current=$(get_background_mode)

  if [[ "$current" == "all" ]]; then
    echo "Already set to 'all' - all modes enabled"
    return
  fi

  if echo "$current" | grep -qxF "$mode"; then
    echo "Mode already enabled: $mode"
    return
  fi

  mkdir -p "$(dirname "$BACKGROUND_MODE_FILE")"
  echo "$mode" >>"$BACKGROUND_MODE_FILE"
  echo "Added: $mode"
}

# Remove a mode from current settings
remove_background_mode() {
  local mode="$1"
  local current
  current=$(get_background_mode)

  if [[ "$current" == "all" ]]; then
    # Switch from "all" to explicit list minus the removed mode
    : >"$BACKGROUND_MODE_FILE"
    while IFS= read -r available; do
      [[ "$available" != "$mode" ]] && echo "$available" >>"$BACKGROUND_MODE_FILE"
    done < <(list_available_background_modes)
    echo "Removed: $mode (expanded from 'all')"
    return
  fi

  if ! echo "$current" | grep -qxF "$mode"; then
    echo "Mode not enabled: $mode"
    return
  fi

  { grep -vxF "$mode" "$BACKGROUND_MODE_FILE" || true; } >"${BACKGROUND_MODE_FILE}.tmp"
  mv "${BACKGROUND_MODE_FILE}.tmp" "$BACKGROUND_MODE_FILE"
  echo "Removed: $mode"
}

# Check if a background type is enabled by current mode
# Args: background_id (e.g., "generated:plasma" or "recolor:/path/to/file.jpg")
# Returns: 0 if enabled, 1 if not
is_background_type_enabled() {
  local background_id="$1"
  local current_mode
  current_mode=$(get_background_mode)

  if [[ "$current_mode" == "all" ]]; then
    return 0
  fi

  local bg_type="${background_id%%:*}"
  local bg_value="${background_id#*:}"

  if [[ "$bg_type" == "generated" ]]; then
    # Check exact match (generated:plasma) or category match (generated)
    if echo "$current_mode" | grep -qxF "generated:$bg_value"; then
      return 0
    fi
    if echo "$current_mode" | grep -qxF "generated"; then
      return 0
    fi
  else
    # Source-based types: recolor, ascii, lowpoly
    if echo "$current_mode" | grep -qxF "$bg_type"; then
      return 0
    fi
  fi

  return 1
}

# Check if a source-based type is enabled (recolor, ascii, lowpoly)
is_source_type_enabled() {
  local type="$1"
  local current_mode
  current_mode=$(get_background_mode)

  [[ "$current_mode" == "all" ]] && return 0
  echo "$current_mode" | grep -qxF "$type"
}

# Get list of enabled generated styles based on current mode
get_enabled_generated_styles() {
  local current_mode
  current_mode=$(get_background_mode)

  if [[ "$current_mode" == "all" ]]; then
    printf '%s\n' "${BACKGROUND_GENERATED_STYLES[@]}"
    return
  fi

  # Check for category "generated" (all generated styles)
  if echo "$current_mode" | grep -qxF "generated"; then
    printf '%s\n' "${BACKGROUND_GENERATED_STYLES[@]}"
    return
  fi

  # Check individual generated:style entries
  for style in "${BACKGROUND_GENERATED_STYLES[@]}"; do
    if echo "$current_mode" | grep -qxF "generated:$style"; then
      echo "$style"
    fi
  done
}

# Check if recolor mode is enabled
is_recolor_enabled() {
  local current_mode
  current_mode=$(get_background_mode)

  [[ "$current_mode" == "all" ]] && return 0
  echo "$current_mode" | grep -qxF "recolor"
}

#==============================================================================
# BACKGROUND SOURCE MANAGEMENT (path-based, no copying)
#==============================================================================

# Add a source path (file or directory) for background recoloring
# Stores path reference in background-sources.conf (no copying)
add_background_source() {
  local source_path="$1"

  if [[ ! -e "$source_path" ]]; then
    echo "Error: Path not found: $source_path" >&2
    return 1
  fi

  # Get absolute path
  local abs_path
  abs_path=$(cd "$(dirname "$source_path")" && pwd)/$(basename "$source_path")

  mkdir -p "$(dirname "$BACKGROUND_SOURCES_FILE")"

  if [[ -d "$abs_path" ]]; then
    # Directory source
    local prefix="dir:"
    local entry="${prefix}${abs_path}"

    # -x, so the match is the whole line. Without it this is a substring test:
    # adding ~/pics while ~/pics-old was already a source reported "already
    # added" and silently dropped the new directory.
    if [[ -f "$BACKGROUND_SOURCES_FILE" ]] && grep -qxF "$entry" "$BACKGROUND_SOURCES_FILE" 2>/dev/null; then
      echo "Directory already added: $abs_path"
      return 0
    fi

    # Count images in directory
    local count
    count=$(find "$abs_path" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | wc -l | xargs)

    echo "$entry" >>"$BACKGROUND_SOURCES_FILE"
    echo "Added directory: $abs_path ($count images)"
  else
    # Single file
    local mime
    mime=$(file --mime-type -b "$abs_path" 2>/dev/null || echo "")
    if [[ ! "$mime" =~ ^image/ ]]; then
      echo "Error: Not an image file: $abs_path" >&2
      return 1
    fi

    local entry="file:${abs_path}"

    # -x for the same reason as the directory branch above: one.png must not
    # match an already-listed one.png.bak.
    if [[ -f "$BACKGROUND_SOURCES_FILE" ]] && grep -qxF "$entry" "$BACKGROUND_SOURCES_FILE" 2>/dev/null; then
      echo "File already added: $abs_path"
      return 0
    fi

    echo "$entry" >>"$BACKGROUND_SOURCES_FILE"
    echo "Added file: $abs_path"
  fi
}

# List configured background sources (the config entries, not expanded images)
list_background_source_entries() {
  if [[ ! -f "$BACKGROUND_SOURCES_FILE" ]]; then
    return 0
  fi
  cat "$BACKGROUND_SOURCES_FILE"
}

# Expand all sources to actual image files (scans directories at runtime)
get_all_background_images() {
  if [[ ! -f "$BACKGROUND_SOURCES_FILE" ]]; then
    return 0
  fi

  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    [[ "$entry" =~ ^# ]] && continue

    local type="${entry%%:*}"
    local path="${entry#*:}"

    case "$type" in
      file)
        if [[ -f "$path" ]] && [[ -r "$path" ]]; then
          echo "$path"
        fi
        ;;
      dir)
        if [[ -d "$path" ]]; then
          find "$path" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null
        fi
        ;;
    esac
  done <"$BACKGROUND_SOURCES_FILE"
}

# Remove a background source entry
remove_background_source() {
  local input="$1"

  if [[ ! -f "$BACKGROUND_SOURCES_FILE" ]]; then
    echo "Error: No sources configured" >&2
    return 1
  fi

  # A full entry removes exactly that line. Anything else falls through to the
  # fragment match below, which is deliberately loose — but only once the exact
  # reading has been ruled out, so removing "dir:~/pics" cannot also take
  # "dir:~/pics-old" with it.
  if grep -qxF "$input" "$BACKGROUND_SOURCES_FILE" 2>/dev/null; then
    { grep -vxF "$input" "$BACKGROUND_SOURCES_FILE" || true; } >"${BACKGROUND_SOURCES_FILE}.tmp"
    mv "${BACKGROUND_SOURCES_FILE}.tmp" "$BACKGROUND_SOURCES_FILE"
    echo "Removed: $input"
    return 0
  fi

  # Try matching path without prefix
  local match
  match=$(grep -E "(file:|dir:).*${input}" "$BACKGROUND_SOURCES_FILE" 2>/dev/null | head -1 || true)
  if [[ -n "$match" ]]; then
    { grep -vF "$match" "$BACKGROUND_SOURCES_FILE" || true; } >"${BACKGROUND_SOURCES_FILE}.tmp"
    mv "${BACKGROUND_SOURCES_FILE}.tmp" "$BACKGROUND_SOURCES_FILE"
    echo "Removed: $match"
    return 0
  fi

  echo "Error: Source not found: $input" >&2
  return 1
}

# Verify all source paths exist and are readable
verify_background_sources() {
  if [[ ! -f "$BACKGROUND_SOURCES_FILE" ]]; then
    echo "No sources configured."
    return 0
  fi

  local valid=0
  local broken=0

  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    [[ "$entry" =~ ^# ]] && continue

    local type="${entry%%:*}"
    local path="${entry#*:}"

    case "$type" in
      file)
        if [[ -f "$path" ]] && [[ -r "$path" ]]; then
          echo "  ✓ $entry"
          valid=$((valid + 1))
        else
          echo "  ✗ $entry (missing or unreadable)"
          broken=$((broken + 1))
        fi
        ;;
      dir)
        if [[ -d "$path" ]]; then
          local count
          count=$(find "$path" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | wc -l | xargs)
          echo "  ✓ $entry ($count images)"
          valid=$((valid + 1))
        else
          echo "  ✗ $entry (directory not found)"
          broken=$((broken + 1))
        fi
        ;;
      *)
        echo "  ? $entry (unknown type)"
        broken=$((broken + 1))
        ;;
    esac
  done <"$BACKGROUND_SOURCES_FILE"

  echo ""
  echo "Valid: $valid, Broken: $broken"
  [[ $broken -eq 0 ]]
}

# Remove broken source entries
clean_background_sources() {
  if [[ ! -f "$BACKGROUND_SOURCES_FILE" ]]; then
    echo "No sources configured."
    return 0
  fi

  local cleaned=0
  local temp_file="${BACKGROUND_SOURCES_FILE}.tmp"
  : >"$temp_file"

  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    [[ "$entry" =~ ^# ]] && {
      echo "$entry" >>"$temp_file"
      continue
    }

    local type="${entry%%:*}"
    local path="${entry#*:}"
    local keep=true

    case "$type" in
      file)
        if [[ ! -f "$path" ]] || [[ ! -r "$path" ]]; then
          echo "Removing: $entry (file missing)"
          keep=false
          cleaned=$((cleaned + 1))
        fi
        ;;
      dir)
        if [[ ! -d "$path" ]]; then
          echo "Removing: $entry (directory missing)"
          keep=false
          cleaned=$((cleaned + 1))
        fi
        ;;
    esac

    [[ "$keep" == "true" ]] && echo "$entry" >>"$temp_file"
  done <"$BACKGROUND_SOURCES_FILE"

  mv "$temp_file" "$BACKGROUND_SOURCES_FILE"
  echo ""
  echo "Cleaned $cleaned broken entries."
}

# Get a random source image (scans directories at runtime)
get_random_background_source() {
  local images=()

  while IFS= read -r img; do
    [[ -n "$img" ]] && images+=("$img")
  done < <(get_all_background_images)

  if [[ ${#images[@]} -eq 0 ]]; then
    return 1
  fi

  echo "${images[$((RANDOM % ${#images[@]}))]}"
}

# Get current background info
get_current_background() {
  if [[ -f "$BACKGROUND_CURRENT_FILE" ]]; then
    cat "$BACKGROUND_CURRENT_FILE"
  fi
}

# Set current background
set_current_background() {
  local background_id="$1"
  mkdir -p "$(dirname "$BACKGROUND_CURRENT_FILE")"
  echo "$background_id" >"$BACKGROUND_CURRENT_FILE"
}

# Set desktop wallpaper (platform-specific dispatcher)
set_desktop_wallpaper() {
  local background_file="$1"
  local platform
  platform=$(detect_platform)

  case "$platform" in
    macos)
      set_desktop_wallpaper_macos "$background_file"
      ;;
    arch)
      set_desktop_wallpaper_hyprland "$background_file"
      ;;
    wsl)
      set_desktop_wallpaper_wsl "$background_file"
      ;;
    *)
      echo "Warning: Background not supported on platform: $platform" >&2
      return 1
      ;;
  esac
}

# macOS: Set wallpaper via Finder AppleScript
set_desktop_wallpaper_macos() {
  local background_file="$1"

  # Over ssh there is no reachable GUI session, so the Finder AppleScript blocks
  # forever — there is no desktop to set from a remote shell. Skip it. Use :- so
  # this is safe under `set -u` when SSH_CONNECTION is unset (the local case).
  if [[ -n "${SSH_CONNECTION:-}" ]]; then
    return 0
  fi

  # Even locally the call can hang on a first-run macOS automation-permission
  # prompt (Terminal controlling Finder). Cap it with a timeout so a theme apply
  # or `theme random` always completes; the wallpaper simply stays unchanged until
  # permission is granted in System Settings > Privacy & Security > Automation.
  if ! timeout 10 osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$background_file\"" 2>/dev/null; then
    echo "Warning: could not set wallpaper (grant your terminal Automation access to Finder to enable it)" >&2
    return 1
  fi
}

# Arch/Hyprland: Set wallpaper via hyprpaper IPC
set_desktop_wallpaper_hyprland() {
  local background_file="$1"

  if ! pgrep -x hyprpaper &>/dev/null; then
    echo "Warning: hyprpaper not running" >&2
    return 1
  fi

  # Set wallpaper via IPC (hyprpaper 0.8+ only supports 'wallpaper' request)
  # Format: [monitor],[path],[fit_mode] - empty monitor = all monitors
  hyprctl hyprpaper wallpaper ",$background_file" 2>/dev/null || return 1

  # Also update stable path for hyprpaper config fallback on restart
  local stable_path="$HOME/.local/share/theme/background.png"
  cp "$background_file" "$stable_path" 2>/dev/null || true
}

# WSL: Set Windows wallpaper via PowerShell (experimental, may fail on restricted systems)
set_desktop_wallpaper_wsl() {
  local background_file="$1"

  # Get Windows username (may differ from Linux username)
  local win_user
  # shellcheck disable=SC2016  # $env:USERNAME is a PowerShell variable, not shell
  win_user=$(powershell.exe -NoProfile -Command 'Write-Host -NoNewline $env:USERNAME' 2>/dev/null | tr -d '\r')

  if [[ -z "$win_user" ]]; then
    echo "Warning: Could not determine Windows username" >&2
    return 1
  fi

  # Copy to Windows-accessible location
  local win_dir="/mnt/c/Users/$win_user/Pictures/theme"
  mkdir -p "$win_dir" 2>/dev/null || {
    echo "Warning: Could not create Windows directory: $win_dir" >&2
    return 1
  }

  local win_file="$win_dir/background.png"
  cp "$background_file" "$win_file" 2>/dev/null || {
    echo "Warning: Could not copy background to Windows path" >&2
    return 1
  }

  # Convert to Windows path format
  local win_path="C:\\Users\\$win_user\\Pictures\\theme\\background.png"

  # Set via PowerShell using SystemParametersInfo
  powershell.exe -NoProfile -Command "
    Add-Type -TypeDefinition '
    using System.Runtime.InteropServices;
    public class Wallpaper {
      public const int SPI_SETDESKWALLPAPER = 0x0014;
      public const int SPIF_UPDATEINIFILE = 0x01;
      public const int SPIF_SENDCHANGE = 0x02;
      [DllImport(\"user32.dll\", CharSet=CharSet.Auto)]
      static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
      public static void Set(string path) {
        SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, path, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
      }
    }';
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -Value '10'
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -Value '0'
    [Wallpaper]::Set('$win_path')
  " 2>/dev/null || {
    echo "Warning: PowerShell wallpaper command failed (may be restricted)" >&2
    return 1
  }
}

# Apply background
# Returns: background_id (e.g., "generated:plasma" or "recolor:/path/to/image.jpg")
# Render one background. Every mode maps to generators/background-<mode>.sh;
# the only difference is that a generated style is drawn from the palette alone
# and takes a target size, while a source type transforms an image it is handed.
# Args: theme.yml, theme_id, bg_type, bg_value, output_file
render_background() {
  local theme_yml="$1" theme_id="$2" bg_type="$3" bg_value="$4" output_file="$5"
  local generators_dir
  generators_dir="$(dirname "${BASH_SOURCE[0]}")/generators"

  if [[ "$bg_type" == "generated" ]]; then
    # Full-resolution renders are slow, so `theme pre-generate` fills a cache and
    # apply copies from it; a miss falls through to rendering on the spot.
    local cache_file="$BACKGROUND_CACHE_DIR/$theme_id/${bg_value}.png"
    if [[ -f "$cache_file" ]]; then
      cp "$cache_file" "$output_file"
      return 0
    fi
    local generator="$generators_dir/background-${bg_value}.sh"
    [[ -f "$generator" ]] || {
      echo "Error: no generator for style: $bg_value" >&2
      return 1
    }
    bash "$generator" "$theme_yml" "$output_file" "$BACKGROUND_WIDTH" "$BACKGROUND_HEIGHT" >/dev/null 2>&1
    return $?
  fi

  local generator="$generators_dir/background-${bg_type}.sh"
  [[ -f "$generator" ]] || {
    echo "Error: unknown background type: $bg_type" >&2
    return 1
  }
  bash "$generator" "$theme_yml" "$bg_value" "$output_file" >/dev/null 2>&1
}

apply_background() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/theme.yml" ]]; then
    return 1
  fi

  local background_dir="$BACKGROUND_RENDER_DIR"
  mkdir -p "$background_dir"

  # Use unique filename to bypass macOS background cache
  local timestamp
  timestamp=$(date +%s)
  local background_file="$background_dir/background-${timestamp}.png"

  # Clean up old background files
  find "$background_dir" -name 'background-*.png' -mmin +1 -delete 2>/dev/null || true

  # Build list of available backgrounds based on mode settings
  local available=()

  # Add enabled generated styles
  while IFS= read -r style; do
    [[ -n "$style" ]] && available+=("generated:$style")
  done < <(get_enabled_generated_styles)

  # Add source-based types if enabled and source images exist
  for source_type in "${BACKGROUND_SOURCE_TYPES[@]}"; do
    if is_source_type_enabled "$source_type"; then
      while IFS= read -r img; do
        [[ -n "$img" ]] && available+=("${source_type}:$img")
      done < <(get_all_background_images)
    fi
  done

  if [[ ${#available[@]} -eq 0 ]]; then
    echo "Error: No backgrounds available (check mode settings)" >&2
    return 1
  fi

  # Pick random from available
  local selected="${available[$((RANDOM % ${#available[@]}))]}"
  local bg_type="${selected%%:*}"
  local bg_value="${selected#*:}"
  local background_id="$selected"

  # Progress to the terminal (this function's stdout is captured by the caller).
  # A cache hit copies in ~0s; an on-the-fly render at 4K can take a while, so the
  # live style name + elapsed time make it obvious the apply is working, not hung.
  local gen_start=$SECONDS
  if tty_writable; then
    printf '  Background: %s (%s) ... ' "$bg_value" "$bg_type" >/dev/tty
  fi

  render_background "$lib_path/theme.yml" "$theme" "$bg_type" "$bg_value" "$background_file" || return 1

  if tty_writable; then
    printf 'done (%ds)\n' "$((SECONDS - gen_start))" >/dev/tty
  fi

  # Set as desktop background (platform-specific)
  set_desktop_wallpaper "$background_file" || return 1

  # Track current background
  set_current_background "$background_id"

  # Output the selected style for status display
  if [[ "$bg_type" == "generated" ]]; then
    echo "$bg_value"
  else
    echo "$bg_type ($(basename "$bg_value"))"
  fi
  return 0
}

# Rotate background without changing theme
# Selects a different background than current, applies it
# Args: [rejected_list] [weights_json]
#   rejected_list: newline-separated list of rejected background IDs
#   weights_json: JSON object mapping background ID to weight (default 1.0)
rotate_background() {
  local rejected_list="${1:-}"
  local weights_json="${2:-}"

  local theme
  theme=$(get_current_theme)

  if [[ -z "$theme" ]]; then
    echo "Error: No theme currently applied" >&2
    return 1
  fi

  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/theme.yml" ]]; then
    echo "Error: Theme not found: $theme" >&2
    return 1
  fi

  local background_dir="$BACKGROUND_RENDER_DIR"
  mkdir -p "$background_dir"

  local timestamp
  timestamp=$(date +%s)
  local background_file="$background_dir/background-${timestamp}.png"

  find "$background_dir" -name 'background-*.png' -mmin +1 -delete 2>/dev/null || true

  # Build list of available backgrounds, excluding current and rejected
  local current_background
  current_background=$(get_current_background)

  # Convert rejected list to associative array for O(1) lookup
  declare -A rejected_map
  if [[ -n "$rejected_list" ]]; then
    while IFS= read -r bg; do
      [[ -n "$bg" ]] && rejected_map["$bg"]=1
    done <<<"$rejected_list"
  fi

  local available=()

  # Add enabled generated styles (respects mode setting)
  while IFS= read -r style; do
    [[ -z "$style" ]] && continue
    local bg_id="generated:$style"
    # Skip current and rejected
    [[ "$bg_id" == "$current_background" ]] && continue
    [[ -n "${rejected_map[$bg_id]:-}" ]] && continue
    available+=("$bg_id")
  done < <(get_enabled_generated_styles)

  # Add source-based types if enabled and source images exist
  for source_type in "${BACKGROUND_SOURCE_TYPES[@]}"; do
    if is_source_type_enabled "$source_type"; then
      while IFS= read -r img; do
        [[ -z "$img" ]] && continue
        local bg_id="${source_type}:$img"
        [[ "$bg_id" == "$current_background" ]] && continue
        [[ -n "${rejected_map[$bg_id]:-}" ]] && continue
        available+=("$bg_id")
      done < <(get_all_background_images)
    fi
  done

  if [[ ${#available[@]} -eq 0 ]]; then
    echo "Error: No alternative backgrounds available" >&2
    return 1
  fi

  # One jq for the whole list. A lookup per background costs a process per
  # image, and a configured source directory is mostly images.
  local weights_arg="${weights_json:-}"
  [[ -z "$weights_arg" ]] && weights_arg='{}'

  local selected
  selected=$(printf '%s\n' "${available[@]}" \
    | jq -R -s -r --argjson weights "$weights_arg" '
      split("\n") | map(select(length > 0)) | .[] | "\(.)\t\($weights[.] // 1)"
    ' | weighted_random_choice)

  # Fallback if something went wrong with weighting
  [[ -z "$selected" ]] && selected="${available[0]}"

  local bg_type="${selected%%:*}"
  local bg_value="${selected#*:}"

  render_background "$lib_path/theme.yml" "$theme" "$bg_type" "$bg_value" "$background_file" || return 1

  set_desktop_wallpaper "$background_file" || return 1

  set_current_background "$selected"

  # Output for display
  if [[ "$bg_type" == "generated" ]]; then
    echo "$bg_value"
  else
    echo "$bg_type ($(basename "$bg_value"))"
  fi
  return 0
}

# Apply Hyprland theme (Arch)
apply_hyprland() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/hyprland.conf" ]]; then
    return 1
  fi

  local hypr_theme_dir="$HOME/.config/hypr/themes"

  install_themed_artifact "$lib_path/hyprland.conf" "$hypr_theme_dir" "$theme.conf" "current.conf" || return 1

  # Reload hyprland if running
  if command -v hyprctl &>/dev/null; then
    hyprctl reload 2>/dev/null || true
  fi

  return 0
}

# Apply waybar theme (Arch)
apply_waybar() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/waybar.css" ]]; then
    return 1
  fi

  local waybar_theme_dir="$HOME/.config/waybar/themes"

  install_themed_artifact "$lib_path/waybar.css" "$waybar_theme_dir" "$theme.css" "current.css" || return 1

  return 0
}

# Apply hyprlock theme (Arch)
apply_hyprlock() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/hyprlock.conf" ]]; then
    return 1
  fi

  local hyprlock_theme_dir="$HOME/.config/hypr/themes"

  # Suffixed, because hyprland and hyprlock share one themes directory and a bare
  # `<id>.conf` would collide with the window manager's.
  install_themed_artifact "$lib_path/hyprlock.conf" "$hyprlock_theme_dir" "$theme-hyprlock.conf" "hyprlock.conf" || return 1

  return 0
}

# Apply dunst theme (Arch)
# Uses drop-in directory: ~/.config/dunst/dunstrc.d/99-theme.conf
apply_dunst() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/dunst.conf" ]]; then
    return 1
  fi

  local dunst_dropin_dir="$HOME/.config/dunst/dunstrc.d"
  mkdir -p "$dunst_dropin_dir"

  cp "$lib_path/dunst.conf" "$dunst_dropin_dir/99-theme.conf"

  return 0
}

# Apply rofi theme (Arch)
apply_rofi() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/rofi.rasi" ]]; then
    return 1
  fi

  local rofi_theme_dir="$HOME/.config/rofi/themes"

  install_themed_artifact "$lib_path/rofi.rasi" "$rofi_theme_dir" "$theme.rasi" "current.rasi" || return 1

  return 0
}

# Apply Windows Terminal theme (WSL)
apply_windows_terminal() {
  local theme="$1"
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]] || [[ ! -f "$lib_path/windows-terminal.json" ]]; then
    return 1
  fi

  # Get Windows username from WSL
  local windows_user
  windows_user=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
  [[ -z "$windows_user" ]] && return 1

  # Find Windows Terminal settings.json
  local wt_settings=""
  local paths=(
    "/mnt/c/Users/$windows_user/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
    "/mnt/c/Users/$windows_user/AppData/Local/Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState/settings.json"
    "/mnt/c/Users/$windows_user/AppData/Local/Microsoft/Windows Terminal/settings.json"
  )

  for path in "${paths[@]}"; do
    if [[ -f "$path" ]]; then
      wt_settings="$path"
      break
    fi
  done

  [[ -z "$wt_settings" ]] && return 1

  # Read theme JSON and merge into settings
  local theme_json
  theme_json=$(cat "$lib_path/windows-terminal.json")
  local theme_name
  theme_name=$(echo "$theme_json" | jq -r '.name')

  # Backup settings
  cp "$wt_settings" "${wt_settings}.backup"

  # Remove existing scheme with same name and add new one
  jq --argjson scheme "$theme_json" \
    '.schemes = [.schemes[] | select(.name != $scheme.name)] + [$scheme]' \
    "$wt_settings" >"${wt_settings}.tmp" && mv "${wt_settings}.tmp" "$wt_settings"

  # Set as active colorScheme for defaults AND all profiles
  jq --arg theme "$theme_name" '
    .profiles.defaults.colorScheme = $theme |
    .profiles.list = [.profiles.list[] | .colorScheme = $theme]
  ' "$wt_settings" >"${wt_settings}.tmp" && mv "${wt_settings}.tmp" "$wt_settings"

  # Also apply opacity if configured (to all profiles)
  if [[ -f "$WINDOWS_TERMINAL_OPACITY_FILE" ]]; then
    local opacity_pct
    opacity_pct=$(jq -r '.opacity // 100' "$WINDOWS_TERMINAL_OPACITY_FILE" 2>/dev/null)
    if [[ -n "$opacity_pct" ]] && [[ "$opacity_pct" != "100" ]]; then
      jq --argjson opacity "$opacity_pct" '
        .profiles.defaults.opacity = $opacity |
        .profiles.list = [.profiles.list[] | .opacity = $opacity]
      ' "$wt_settings" >"${wt_settings}.tmp" && mv "${wt_settings}.tmp" "$wt_settings"
    fi
  fi

  return 0
}

#==============================================================================
# MAIN APPLY FUNCTION
#==============================================================================

# Apply theme to all available apps on current platform
apply_theme_to_apps() {
  local theme="$1"
  local platform
  platform=$(detect_platform)

  local applied=()
  local skipped=()

  APPLY_WARNINGS=()

  _print_app_status() {
    local app="$1"
    local success="$2"
    if [[ "$success" == "true" ]]; then
      echo "  ✓ $app" >&2
    else
      echo "  ✗ $app (error)" >&2
    fi
  }

  # Check if theme exists in library
  local lib_path
  lib_path=$(get_library_path "$theme")

  if [[ -z "$lib_path" ]]; then
    echo "Warning: Theme '$theme' not in library, limited app support" >&2
  fi

  # Ghostty (macOS and Arch)
  if [[ "$platform" == "macos" ]] || [[ "$platform" == "arch" ]]; then
    if apply_ghostty "$theme" 2>/dev/null; then
      applied+=("ghostty")
      _print_app_status "ghostty" "true"
    else
      skipped+=("ghostty")
      _print_app_status "ghostty" "false"
    fi
  fi

  # Kitty (macOS and Arch)
  if [[ "$platform" == "macos" ]] || [[ "$platform" == "arch" ]]; then
    if apply_kitty "$theme" 2>/dev/null; then
      applied+=("kitty")
      _print_app_status "kitty" "true"
    else
      skipped+=("kitty")
      _print_app_status "kitty" "false"
    fi
  fi

  # JankyBorders (macOS only)
  if [[ "$platform" == "macos" ]]; then
    if apply_borders "$theme" 2>/dev/null; then
      applied+=("borders")
      _print_app_status "borders" "true"
    else
      skipped+=("borders")
      _print_app_status "borders" "false"
    fi
  fi

  # Background (macOS, Arch, WSL)
  local background_id=""
  if [[ "$platform" == "macos" ]] || [[ "$platform" == "arch" ]] || [[ "$platform" == "wsl" ]]; then
    local background_style
    if background_style=$(apply_background "$theme" 2>/dev/null); then
      applied+=("background")
      _print_app_status "background ($background_style)" "true"
      background_id=$(get_current_background)
    else
      skipped+=("background")
      _print_app_status "background" "false"
    fi
  fi

  # Tmux (all platforms)
  if apply_tmux "$theme" 2>/dev/null; then
    applied+=("tmux")
    _print_app_status "tmux" "true"
  else
    skipped+=("tmux")
    _print_app_status "tmux" "false"
  fi

  # Btop (all platforms)
  if apply_btop "$theme" 2>/dev/null; then
    applied+=("btop")
    _print_app_status "btop" "true"
  else
    skipped+=("btop")
    _print_app_status "btop" "false"
  fi

  # Yazi (all platforms)
  if apply_yazi "$theme" 2>/dev/null; then
    applied+=("yazi")
    _print_app_status "yazi" "true"
  else
    skipped+=("yazi")
    _print_app_status "yazi" "false"
  fi

  # aerc email client (all platforms)
  if apply_aerc "$theme" 2>/dev/null; then
    applied+=("aerc")
    _print_app_status "aerc" "true"
  else
    skipped+=("aerc")
    _print_app_status "aerc" "false"
  fi

  # Firefox-based browsers (all platforms)
  if apply_firefox_based "$theme" 2>/dev/null; then
    applied+=("browsers")
    _print_app_status "browsers" "true"
  else
    skipped+=("browsers")
    _print_app_status "browsers" "false"
  fi

  # bat syntax highlighter (all platforms)
  if apply_bat "$theme" 2>/dev/null; then
    applied+=("bat")
    _print_app_status "bat" "true"
  else
    skipped+=("bat")
    _print_app_status "bat" "false"
  fi

  # delta git pager (all platforms) — must follow bat, whose cache it reads
  if apply_delta "$theme" 2>/dev/null; then
    applied+=("delta")
    _print_app_status "delta" "true"
  else
    skipped+=("delta")
    _print_app_status "delta" "false"
  fi

  # sioyek PDF viewer (all platforms)
  if apply_sioyek "$theme" 2>/dev/null; then
    applied+=("sioyek")
    _print_app_status "sioyek" "true"
  else
    skipped+=("sioyek")
    _print_app_status "sioyek" "false"
  fi

  # Hyprland (Arch only)
  if [[ "$platform" == "arch" ]]; then
    if apply_hyprland "$theme" 2>/dev/null; then
      applied+=("hyprland")
      _print_app_status "hyprland" "true"
    else
      skipped+=("hyprland")
      _print_app_status "hyprland" "false"
    fi

    if apply_waybar "$theme" 2>/dev/null; then
      applied+=("waybar")
      _print_app_status "waybar" "true"
    else
      skipped+=("waybar")
      _print_app_status "waybar" "false"
    fi

    if apply_hyprlock "$theme" 2>/dev/null; then
      applied+=("hyprlock")
      _print_app_status "hyprlock" "true"
    else
      skipped+=("hyprlock")
      _print_app_status "hyprlock" "false"
    fi

    if apply_dunst "$theme" 2>/dev/null; then
      applied+=("dunst")
      _print_app_status "dunst" "true"
    else
      skipped+=("dunst")
      _print_app_status "dunst" "false"
    fi

    if apply_rofi "$theme" 2>/dev/null; then
      applied+=("rofi")
      _print_app_status "rofi" "true"
    else
      skipped+=("rofi")
      _print_app_status "rofi" "false"
    fi
  fi

  # Windows Terminal (WSL only)
  if [[ "$platform" == "wsl" ]]; then
    if apply_windows_terminal "$theme" 2>/dev/null; then
      applied+=("windows-terminal")
      _print_app_status "windows-terminal" "true"
    else
      skipped+=("windows-terminal")
      _print_app_status "windows-terminal" "false"
    fi
  fi

  check_neovim_colorscheme "$theme"

  # Record current theme
  set_current_theme "$theme"

  # After the per-app ticks, so the last thing on screen is the thing that needs
  # doing rather than a wall of successes it would scroll past.
  if [[ ${#APPLY_WARNINGS[@]} -gt 0 ]]; then
    echo "" >&2
    echo "  ⚠  APPLIED WITH WARNINGS" >&2
    local warning
    for warning in "${APPLY_WARNINGS[@]}"; do
      echo "     $warning" >&2
    done
    echo "" >&2
  fi

  # Return results
  echo "APPLIED:${applied[*]:-none}"
  echo "SKIPPED:${skipped[*]:-none}"
  echo "BACKGROUND:${background_id:-none}"
}

#==============================================================================
# UTILITY FUNCTIONS
#==============================================================================

# Reads "<name>\t<weight>" lines on stdin and prints one name, chosen with
# probability proportional to its weight. Returns 1 on empty input.
#
# One awk over the whole list, seeded from $RANDOM. awk's bare srand() takes the
# clock in whole seconds, so two picks inside the same second return the same
# name — which a rotation driven by a keybinding hits routinely.
weighted_random_choice() {
  awk -F'\t' -v seed="${RANDOM}$$" '
    {
      name[NR] = $1
      weight[NR] = $2 + 0
      total += weight[NR]
    }
    END {
      if (NR == 0 || total <= 0) exit 1
      srand(seed)
      target = rand() * total
      for (i = 1; i <= NR; i++) {
        cumulative += weight[i]
        if (target <= cumulative) {
          print name[i]
          exit 0
        }
      }
      print name[NR]
    }
  '
}

format_duration() {
  local seconds="$1"

  if [[ "$seconds" -lt 60 ]]; then
    echo "${seconds}s"
  elif [[ "$seconds" -lt 3600 ]]; then
    local mins=$((seconds / 60))
    echo "${mins}m"
  elif [[ "$seconds" -lt 86400 ]]; then
    local hours=$((seconds / 3600))
    local mins=$(((seconds % 3600) / 60))
    if [[ "$mins" -gt 0 ]]; then
      echo "${hours}h ${mins}m"
    else
      echo "${hours}h"
    fi
  else
    local days=$((seconds / 86400))
    local hours=$(((seconds % 86400) / 3600))
    if [[ "$hours" -gt 0 ]]; then
      echo "${days}d ${hours}h"
    else
      echo "${days}d"
    fi
  fi
}

# Format an elapsed number of seconds as a coarse "ago" string for recency.
format_relative() {
  local seconds="$1"

  if [[ "$seconds" -lt 3600 ]]; then
    echo "just now"
  elif [[ "$seconds" -lt 86400 ]]; then
    echo "$((seconds / 3600))h ago"
  else
    echo "$((seconds / 86400))d ago"
  fi
}

reload_tmux() {
  if command -v tmux &>/dev/null && tmux list-sessions &>/dev/null 2>&1; then
    tmux source-file ~/.config/tmux/tmux.conf 2>/dev/null || true
    return 0
  fi
  return 1
}

reload_kitty() {
  if command -v pkill &>/dev/null; then
    pkill -USR1 kitty 2>/dev/null || true
    return 0
  fi
  return 1
}

reload_hyprland() {
  if command -v hyprctl &>/dev/null; then
    hyprctl reload 2>/dev/null || true
    return 0
  fi
  return 1
}

# Restart waybar instead of SIGUSR2 reload.
# Why: Waybar's in-process reload races with MPRIS/playerctl D-Bus signal
# callbacks, occasionally segfaulting in libplayerctl during teardown.
# A clean process restart sidesteps the race entirely.
reload_waybar() {
  if pgrep -x waybar &>/dev/null; then
    pkill -x waybar 2>/dev/null || true
    setsid waybar >/dev/null 2>&1 </dev/null &
    disown
    return 0
  fi
  return 1
}

reload_dunst() {
  if command -v killall &>/dev/null; then
    killall dunst 2>/dev/null || true
    # Dunst auto-restarts on next notification, or start it explicitly
    if command -v dunst &>/dev/null; then
      dunst &>/dev/null &
      disown
    fi
    return 0
  fi
  return 1
}

# Reload all applicable apps after theme apply
reload_apps() {
  local platform
  platform=$(detect_platform)
  local applied_apps="${1:-}"

  # tmux (all platforms)
  [[ "$applied_apps" == *"tmux"* ]] && reload_tmux

  # Platform-specific reloads
  if [[ "$platform" == "arch" ]]; then
    [[ "$applied_apps" == *"kitty"* ]] && reload_kitty
    [[ "$applied_apps" == *"hyprland"* ]] && reload_hyprland
    [[ "$applied_apps" == *"waybar"* ]] && reload_waybar
    [[ "$applied_apps" == *"dunst"* ]] && reload_dunst
    # btop requires manual restart
    # rofi loads theme on next launch
    # hyprlock loads theme on next lock
  fi
}

# Render the "About" block (theme.yml metadata) — the theme's identity. Shown
# in the full view. The compact picker preview omits it because the color
# swatch above already carries this same metadata rendered in-palette.
_render_theme_about() {
  local theme="$1"
  local theme_file="$THEMES_DIR/$theme/theme.yml"
  [[ -f "$theme_file" ]] || return 0

  # Single yq pass — key=value lines. Keys never contain '=', so IFS splits clean.
  local author variant derived nvim_name nvim_source plugin_repo
  while IFS='=' read -r key value; do
    case "$key" in
      author) author="$value" ;;
      variant) variant="$value" ;;
      derived) derived="$value" ;;
      nvim_name) nvim_name="$value" ;;
      nvim_source) nvim_source="$value" ;;
      plugin) plugin_repo="$value" ;;
    esac
  done < <(yq '[
    "author="      + (.meta.author // ""),
    "variant="     + (.meta.variant // ""),
    "derived="     + (.meta.derived_from // ""),
    "nvim_name="   + (.meta.neovim_colorscheme_name // .meta.id // ""),
    "nvim_source=" + (.meta.neovim_colorscheme_source // ""),
    "plugin="      + (.meta.plugin // "")
  ] | .[]' "$theme_file")

  echo "About:"
  [[ -n "$author" ]] && printf "  Author: %s\n" "$author"
  local variant_line="$variant"
  [[ -n "$derived" && "$derived" != "null" ]] && variant_line="${variant_line:+$variant_line · }from $derived"
  [[ -n "$variant_line" ]] && printf "  %s\n" "$variant_line"
  [[ -n "$nvim_name" ]] && printf "  Neovim: %s (%s)\n" "$nvim_name" "${nvim_source:-unknown}"
  [[ -n "$plugin_repo" && "$plugin_repo" != "null" ]] && printf "  Plugin: %s\n" "$plugin_repo"
  return 0
}

# Render this theme's action history (the log), oldest to newest.
# Args: $1 theme, $2 limit (0 = all; N = most recent N entries).
_render_theme_history() {
  local theme="$1" limit="$2"

  type -t get_history &>/dev/null || return 0

  local total
  total=$(get_history | jq --arg theme "$theme" '[.[] | select(.theme == $theme)] | length')
  [[ "$total" -eq 0 ]] && return 0

  local label="History"
  if [[ "$limit" -gt 0 && "$total" -gt "$limit" ]]; then
    label="Recent (last $limit of $total)"
  fi

  echo ""
  echo "$label:"
  get_history | jq -r --arg theme "$theme" --argjson limit "$limit" '
    ( map(select(.theme == $theme)) | sort_by(.ts) ) as $all |
    ( if $limit > 0 then $all[-$limit:] else $all end ) |
    .[] |
    .action as $act |
    .ts[0:10] as $date |
    .message as $msg |
    if $act == "apply" then "  \($date)  applied"
    elif $act == "like" then (if $msg then "  \($date)  liked: \($msg)" else "  \($date)  liked" end)
    elif $act == "dislike" then (if $msg then "  \($date)  disliked: \($msg)" else "  \($date)  disliked" end)
    elif $act == "note" then "  \($date)  note: \($msg)"
    elif $act == "reject" then "  \($date)  rejected: \($msg)"
    elif $act == "unreject" then "  \($date)  unrejected"
    else "  \($date)  \($act)"
    end
  ' 2>/dev/null
  return 0
}

# Print a rank line like "<prefix>likes #2 · hours #5 of 40", only if at least
# one position is known. $prefix is the complete label (e.g. "rank: ", "  Rank: ").
_render_theme_rank_line() {
  local prefix="$1" likes_pos="$2" hours_pos="$3" total="$4"
  [[ -z "$likes_pos" && -z "$hours_pos" ]] && return 0

  local line=""
  [[ -n "$likes_pos" ]] && line="likes #${likes_pos}"
  if [[ -n "$hours_pos" ]]; then
    [[ -n "$line" ]] && line="$line · "
    line="${line}hours #${hours_pos}"
  fi
  [[ -n "$total" ]] && line="$line of $total"
  printf "%s%s\n" "$prefix" "$line"
  return 0
}

# Render the stats footer — the numbers, shown last so they summarize after the
# description and history have set context.
_render_theme_stat_footer() {
  local theme="$1" format="$2"

  type -t get_theme_stats &>/dev/null || return 0
  local stats
  stats=$(get_theme_stats "$theme" 2>/dev/null)
  [[ -z "$stats" || "$stats" == "null" || "$stats" == "{}" ]] && return 0

  local total_actions
  total_actions=$(echo "$stats" | jq -r '.total_actions // 0')
  [[ "$total_actions" -eq 0 ]] && return 0

  local score likes dislikes notes applies platforms machines
  score=$(echo "$stats" | jq -r '.score // 0')
  likes=$(echo "$stats" | jq -r '.likes // 0')
  dislikes=$(echo "$stats" | jq -r '.dislikes // 0')
  notes=$(echo "$stats" | jq -r '.notes // 0')
  applies=$(echo "$stats" | jq -r '.applies // 0')
  platforms=$(echo "$stats" | jq -r '.platforms | join(", ") // "none"')
  machines=$(echo "$stats" | jq -r '.machines | join(", ") // "unknown"')

  # Attributed usage time via the same engine rank uses.
  local usage_seconds=0 usage_time="not used"
  if type -t calculate_usage_time &>/dev/null; then
    local current_theme usage_times
    current_theme=$(get_current_theme 2>/dev/null || echo "")
    usage_times=$(calculate_usage_time "$current_theme")
    usage_seconds=$(echo "$usage_times" | jq -r --arg theme "$theme" '.[$theme] // 0')
    [[ "$usage_seconds" -gt 0 ]] && usage_time=$(format_duration "$usage_seconds")
  fi

  # Recency from last apply. Computed in jq (with the same tz-aware parse as
  # calculate_usage_time) to stay portable across BSD/GNU date.
  local seconds_since=""
  seconds_since=$(get_history | jq -r --arg theme "$theme" '
    def parse_ts:
      if test("[+-][0-9]{2}:[0-9]{2}$") then
        gsub("[+-][0-9]{2}:[0-9]{2}$"; "Z") | fromdateiso8601
      else fromdateiso8601 end;
    (map(select(.theme == $theme and .action == "apply")) | max_by(.ts) | .ts) as $last |
    if $last == null then "" else ((now | floor) - ($last | parse_ts)) end
  ' 2>/dev/null)
  local recency=""
  [[ -n "$seconds_since" && "$seconds_since" != "null" ]] && recency=$(format_relative "$seconds_since")

  # Rank positions among available themes (likes list and hours list).
  local likes_pos="" hours_pos="" rank_total=""
  if type -t get_theme_rank_positions &>/dev/null; then
    local positions
    positions=$(get_theme_rank_positions "$theme" 2>/dev/null)
    if [[ -n "$positions" ]]; then
      likes_pos=$(echo "$positions" | jq -r '.likes_pos // empty')
      hours_pos=$(echo "$positions" | jq -r '.hours_pos // empty')
      rank_total=$(echo "$positions" | jq -r '.total // empty')
    fi
  fi

  echo ""
  if [[ "$format" == "full" ]]; then
    echo "Stats:"
    printf "  Score: %+d (%d likes, %d dislikes)\n" "$score" "$likes" "$dislikes"
    printf "  Usage time: %s\n" "$usage_time"
    [[ -n "$recency" ]] && printf "  Last used: %s\n" "$recency"
    _render_theme_rank_line "  Rank: " "$likes_pos" "$hours_pos" "$rank_total"
    printf "  Notes: %d\n" "$notes"
    printf "  Times applied: %d\n" "$applies"
    printf "  Platforms: %s\n" "$platforms"
    printf "  Machines: %s\n" "$machines"
  else
    printf "%+d · %d↑ %d↓" "$score" "$likes" "$dislikes"
    [[ "$usage_seconds" -gt 0 ]] && printf " · %s used" "$usage_time"
    echo ""
    printf "%d× applied" "$applies"
    [[ -n "$recency" ]] && printf " · last used %s" "$recency"
    echo ""
    _render_theme_rank_line "rank: " "$likes_pos" "$hours_pos" "$rank_total"
  fi
  return 0
}

# Render available app configs and the Neovim colorscheme wiring (full view).
_render_theme_configs() {
  local theme="$1"
  local theme_dir="$THEMES_DIR/$theme"
  local theme_file="$theme_dir/theme.yml"

  echo ""
  echo "App Configs:"
  local configs=""
  local entry artifact label
  for entry in "${THEME_APP_ARTIFACTS[@]}"; do
    artifact="${entry%%:*}"
    label="${entry#*:}"
    [[ -e "$theme_dir/$artifact" ]] && configs+="$label "
  done
  echo "  Available: ${configs:-none}"

  if [[ -f "$theme_file" ]]; then
    local nvim_name nvim_source plugin_repo
    nvim_name=$(yq '.meta.neovim_colorscheme_name // .meta.id' "$theme_file")
    nvim_source=$(yq '.meta.neovim_colorscheme_source // "unknown"' "$theme_file")
    plugin_repo=$(yq '.meta.plugin // ""' "$theme_file")
    echo "  Neovim colorscheme: $nvim_name ($nvim_source)"
    [[ -n "$plugin_repo" && "$plugin_repo" != "null" ]] && echo "  Plugin: $plugin_repo"
  fi
  return 0
}

# Display theme details. Order mirrors font: About (description) -> History
# (the log) -> Stats footer. The compact picker preview starts at the log
# because the color swatch above already carries the About block in-palette.
# Args: $1 theme id
#       $2 format ("full" for 'theme current', "compact" for the change picker)
display_theme_details() {
  local theme="$1"
  local format="${2:-full}"

  local display_info
  display_info=$(get_theme_display_info "$theme")

  if [[ "$format" == "full" ]]; then
    echo ""
    echo "Current Theme: $display_info"
    echo "           ID: $theme"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    _render_theme_about "$theme"
    _render_theme_history "$theme" 0
    _render_theme_stat_footer "$theme" "$format"
    _render_theme_configs "$theme"
    echo ""
  else
    _render_theme_history "$theme" 6
    _render_theme_stat_footer "$theme" "$format"
  fi
}

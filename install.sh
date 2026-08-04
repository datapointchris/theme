#!/usr/bin/env bash
set -euo pipefail

# Overridable so a fork can install itself, and so this script can be exercised
# against the commit under test rather than against whatever is on main. Same
# reasoning as bashselfupdate's own installer, which these mirror.
REPO_URL="${THEME_REPO_URL:-https://github.com/datapointchris/theme.git}"
INSTALL_DIR="${THEME_INSTALL_DIR:-$HOME/.local/share/theme}"
BIN_DIR="${THEME_BIN_DIR:-$HOME/.local/bin}"
BASHSELFUPDATE_REPO_URL="${BASHSELFUPDATE_REPO_URL:-https://github.com/datapointchris/bashselfupdate.git}"
BASHSELFUPDATE_INSTALL_URL="https://github.com/datapointchris/bashselfupdate"

info() { echo "[info] $*"; }
success() { echo "[ok] $*"; }
error() { echo "[error] $*" >&2; }

if ! command -v git &>/dev/null; then
  error "git is required but not installed"
  exit 1
fi

if ! command -v jq &>/dev/null; then
  error "jq is required but not installed"
  exit 1
fi

mkdir -p "$BIN_DIR"

# theme sources bashselfupdate for `theme update` and the daily notice.
#
# Cloned with git rather than piped from its install script over curl, because
# that is the one transport this installer already requires and the two are not
# equally available: a locked-down network can allow github.com over git while
# blocking raw.githubusercontent.com, which is exactly why dotfiles keeps a
# cache of install *scripts*. Adding a second transport would make theme
# uninstallable on a machine where it currently installs fine.
#
# Sourced from the fresh clone and then pointed at itself, so the tag comparator
# lives in one place. `git tag --sort=-v:refname` here would be the sort -V
# ordering the library exists to replace.
install_bashselfupdate() {
  local dir="${XDG_LIB_HOME:-$HOME/.local/lib}/bashselfupdate"

  if [[ ! -d "$dir/.git" ]]; then
    rm -rf "$dir"
    mkdir -p "$(dirname "$dir")"
    git clone --quiet "$BASHSELFUPDATE_REPO_URL" "$dir" || return 1
  fi

  # shellcheck source=/dev/null
  source "$dir/lib/version.sh"
  # shellcheck source=/dev/null
  source "$dir/lib/source.sh"
  # shellcheck source=/dev/null
  source "$dir/lib/update.sh"

  bashselfupdate_checkout_latest "$dir" >/dev/null
}

# Not fatal. theme works without it — only `theme update` and the daily notice
# need it, and bin/theme degrades to an actionable error and silence
# respectively. Failing the whole install here would make an unreachable
# github.com cost the user a working theme command for no reason.
info "Installing bashselfupdate..."
if install_bashselfupdate; then
  success "bashselfupdate installed"
else
  error "Could not install bashselfupdate — 'theme update' will not work until it is"
  error "  Install it separately: $BASHSELFUPDATE_INSTALL_URL"
fi

if [[ ! -d "$INSTALL_DIR/.git" ]]; then
  info "Installing theme..."
  if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
  fi
  if ! git clone --quiet "$REPO_URL" "$INSTALL_DIR"; then
    error "Failed to clone theme repository"
    exit 1
  fi
  success "theme cloned to $INSTALL_DIR"
fi

# Moving to the newest tag, not `git pull`. The previous version pulled, which
# fails outright once `theme update` has run: a plain `git checkout <tag>`
# leaves a detached HEAD, a detached HEAD has no upstream, and git answers with
# "You are not currently on a branch". Re-running the installer then meant
# reinstalling from scratch.
#
# checkout_latest rather than update: a fresh clone lands on main, which between
# releases is ahead of the newest tag, and update declines a checkout that is not
# sitting on one. It leaves the checkout on a branch and is idempotent, which is
# what makes re-running this script mean what everyone assumes it means.
if declare -F bashselfupdate_checkout_latest &>/dev/null; then
  if ! tag=$(bashselfupdate_checkout_latest "$INSTALL_DIR"); then
    error "Failed to move theme to its latest release"
    exit 1
  fi
  success "theme at $tag"
else
  # Without the library there is no comparator to pick the newest tag with, so
  # this tracks the branch instead. Reachable only when bashselfupdate could not
  # be installed above, which is also a machine where `theme update` was never
  # able to leave a detached HEAD — so pull still works here.
  if ! git -C "$INSTALL_DIR" pull --quiet; then
    error "Failed to update theme"
    exit 1
  fi
  success "theme updated from $(git -C "$INSTALL_DIR" rev-parse --abbrev-ref HEAD)"
fi

ln -sf "$INSTALL_DIR/bin/theme" "$BIN_DIR/theme"
success "theme installed: $BIN_DIR/theme"

if command -v theme &>/dev/null; then
  info "Run 'theme' to get started"
else
  info "Add $BIN_DIR to your PATH, then run 'theme'"
fi

#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/datapointchris/theme.git"
INSTALL_DIR="$HOME/.local/share/theme"
BIN_DIR="$HOME/.local/bin"

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

if [[ -d "$INSTALL_DIR/.git" ]]; then
  info "Updating existing installation..."
  if git -C "$INSTALL_DIR" pull --quiet; then
    success "theme updated"
  else
    error "Failed to update theme"
    exit 1
  fi
else
  info "Installing theme..."
  if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
  fi
  if git clone --quiet "$REPO_URL" "$INSTALL_DIR"; then
    success "theme cloned to $INSTALL_DIR"
  else
    error "Failed to clone theme repository"
    exit 1
  fi
fi

ln -sf "$INSTALL_DIR/bin/theme" "$BIN_DIR/theme"
success "theme installed: $BIN_DIR/theme"

if command -v theme &>/dev/null; then
  info "Run 'theme' to get started"
else
  info "Add $BIN_DIR to your PATH, then run 'theme'"
fi

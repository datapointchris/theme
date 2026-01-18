#!/usr/bin/env bash
# Generate userChrome.css for Firefox-based browsers from theme.yml
# Works with: Zen Browser, Librewolf, Firefox, Thunderbird
# Usage: firefox-based.sh <theme.yml> [output-file]
#
# Generates CSS custom properties for browser theming.
# Applied by copying to: <profile>/chrome/userChrome.css
#
# Note: Requires toolkit.legacyUserProfileCustomizations.stylesheets = true
# in about:config for the browser to load userChrome.css

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../theme.sh"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <theme.yml> [output-file]"
  exit 1
fi

input_file="$1"
output_file="${2:-}"

# Load colors
eval "$(load_colors "$input_file")"

generate() {
  cat << EOF
/* Theme: ${THEME_NAME} */
/* Generated from theme.yml - Firefox-based browsers */
/* Compatible with: Zen Browser, Librewolf, Firefox, Thunderbird */
/*
 * Setup: Enable in about:config:
 *   toolkit.legacyUserProfileCustomizations.stylesheets = true
 * Then restart browser to apply changes.
 */

@namespace url("http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul");
@namespace html url("http://www.w3.org/1999/xhtml");

/*==============================================================================
 * FIREFOX BUILT-IN CSS VARIABLES
 * These are stable APIs that Firefox exposes for theming
 *============================================================================*/

:root {
  /* Toolbar and chrome backgrounds */
  --toolbar-bgcolor: ${SPECIAL_BG} !important;
  --toolbar-color: ${SPECIAL_FG} !important;
  --lwt-accent-color: ${BASE01} !important;
  --lwt-text-color: ${SPECIAL_FG} !important;

  /* Tab colors */
  --tab-selected-bgcolor: ${SPECIAL_SELECTION_BG} !important;
  --tab-selected-textcolor: ${SPECIAL_FG} !important;
  --tab-line-color: ${BASE0D} !important;
  --tabs-border-color: ${SPECIAL_BORDER} !important;
  --tabpanel-background-color: ${SPECIAL_BG} !important;

  /* URL bar */
  --urlbar-box-bgcolor: ${BASE01} !important;
  --urlbar-box-text-color: ${SPECIAL_FG} !important;
  --urlbar-box-hover-bgcolor: ${BASE02} !important;
  --urlbar-box-active-bgcolor: ${BASE02} !important;
  --urlbar-box-focus-bgcolor: ${BASE01} !important;
  --autocomplete-popup-background: ${BASE01} !important;
  --autocomplete-popup-color: ${SPECIAL_FG} !important;
  --autocomplete-popup-highlight-background: ${SPECIAL_SELECTION_BG} !important;
  --autocomplete-popup-highlight-color: ${SPECIAL_FG} !important;

  /* Sidebar */
  --sidebar-background-color: ${SPECIAL_BG} !important;
  --sidebar-text-color: ${SPECIAL_FG} !important;
  --sidebar-border-color: ${SPECIAL_BORDER} !important;

  /* Panels and popups */
  --arrowpanel-background: ${BASE01} !important;
  --arrowpanel-color: ${SPECIAL_FG} !important;
  --arrowpanel-border-color: ${SPECIAL_BORDER} !important;
  --panel-separator-color: ${BASE02} !important;

  /* Focus and selection */
  --focus-outline-color: ${BASE0D} !important;
  --input-bgcolor: ${BASE01} !important;
  --input-color: ${SPECIAL_FG} !important;
  --input-border-color: ${SPECIAL_BORDER} !important;

  /* Buttons */
  --button-bgcolor: ${BASE01} !important;
  --button-color: ${SPECIAL_FG} !important;
  --button-hover-bgcolor: ${BASE02} !important;
  --button-active-bgcolor: ${BASE03} !important;
  --button-primary-bgcolor: ${BASE0D} !important;
  --button-primary-color: ${SPECIAL_BG} !important;
  --button-primary-hover-bgcolor: ${ANSI_BRIGHT_BLUE} !important;
  --button-primary-active-bgcolor: ${BASE0D} !important;

  /* Scrollbars (Firefox 64+) */
  scrollbar-color: ${BASE03} ${BASE01};

  /* Link colors */
  --lwt-toolbarbutton-icon-fill: ${SPECIAL_FG} !important;

  /* Lightweight theme colors */
  --lwt-toolbar-field-background-color: ${BASE01} !important;
  --lwt-toolbar-field-color: ${SPECIAL_FG} !important;
  --lwt-toolbar-field-border-color: ${SPECIAL_BORDER} !important;
  --lwt-toolbar-field-focus: ${BASE02} !important;
  --lwt-toolbar-field-highlight: ${SPECIAL_SELECTION_BG} !important;
  --lwt-toolbar-field-highlight-text: ${SPECIAL_FG} !important;

  /* Context menu */
  --menu-background-color: ${BASE01} !important;
  --menu-color: ${SPECIAL_FG} !important;
  --menuitem-hover-background-color: ${SPECIAL_SELECTION_BG} !important;

  /* Findbar */
  --toolbar-field-focus-background-color: ${BASE01} !important;
  --toolbar-field-focus-color: ${SPECIAL_FG} !important;
}

/*==============================================================================
 * ZEN BROWSER SPECIFIC VARIABLES
 * Zen extends Firefox with its own theming system
 *============================================================================*/

:root {
  /* Zen accent colors */
  --zen-primary-color: ${BASE0D} !important;
  --zen-accent-color: ${BASE0D} !important;
  --zen-colors-primary: ${BASE0D} !important;
  --zen-colors-secondary: ${BASE0E} !important;
  --zen-colors-tertiary: ${BASE0C} !important;

  /* Zen backgrounds */
  --zen-colors-bg: ${SPECIAL_BG} !important;
  --zen-colors-bg-secondary: ${BASE01} !important;
  --zen-themed-toolbar-bg: ${SPECIAL_BG} !important;

  /* Zen text colors */
  --zen-colors-text: ${SPECIAL_FG} !important;
  --zen-colors-text-secondary: ${BASE04} !important;

  /* Zen borders */
  --zen-colors-border: ${SPECIAL_BORDER} !important;
  --zen-dialog-background: ${BASE01} !important;
}

/*==============================================================================
 * THUNDERBIRD SPECIFIC
 * Email client specific overrides
 *============================================================================*/

/* Thunderbird message pane */
:root {
  --foldertree-background: ${SPECIAL_BG} !important;
  --folderpane-unread-count-background: ${BASE0D} !important;
  --thread-pane-background: ${SPECIAL_BG} !important;
  --messagepane-background-color: ${SPECIAL_BG} !important;
}

/*==============================================================================
 * ADDITIONAL ELEMENT COLORS
 * Direct styling for common elements (more fragile but fills gaps)
 *============================================================================*/

/* Window background for areas not covered by variables */
#main-window,
#navigator-toolbox,
#PersonalToolbar,
#toolbar-menubar {
  background-color: ${SPECIAL_BG} !important;
  color: ${SPECIAL_FG} !important;
}

/* Tab bar background */
#titlebar,
#TabsToolbar,
.tabbrowser-tabs {
  background-color: ${SPECIAL_BG} !important;
}

/* Inactive tabs */
.tabbrowser-tab:not([selected="true"]) {
  background-color: ${SPECIAL_BG} !important;
  color: ${BASE04} !important;
}

/* Active/selected tab */
.tabbrowser-tab[selected="true"] {
  background-color: ${SPECIAL_SELECTION_BG} !important;
  color: ${SPECIAL_FG} !important;
}

/* Tab hover state */
.tabbrowser-tab:hover:not([selected="true"]) {
  background-color: ${BASE01} !important;
}

/* New tab button */
#tabs-newtab-button,
.tabs-newtab-button {
  fill: ${SPECIAL_FG} !important;
}

/* URL bar */
#urlbar {
  background-color: ${BASE01} !important;
  color: ${SPECIAL_FG} !important;
  border-color: ${SPECIAL_BORDER} !important;
}

#urlbar:focus-within,
#urlbar[focused="true"] {
  background-color: ${BASE01} !important;
  border-color: ${BASE0D} !important;
}

/* URL bar results popup */
#urlbar-results,
.urlbarView {
  background-color: ${BASE01} !important;
  color: ${SPECIAL_FG} !important;
}

.urlbarView-row[selected] {
  background-color: ${SPECIAL_SELECTION_BG} !important;
}

/* Navigation buttons */
#nav-bar {
  background-color: ${SPECIAL_BG} !important;
}

/* Bookmark toolbar */
#PersonalToolbar {
  background-color: ${SPECIAL_BG} !important;
  border-color: ${SPECIAL_BORDER} !important;
}

.bookmark-item {
  color: ${SPECIAL_FG} !important;
}

/* Context menus */
menupopup,
menu,
menuitem {
  background-color: ${BASE01} !important;
  color: ${SPECIAL_FG} !important;
}

menuitem:hover,
menu:hover {
  background-color: ${SPECIAL_SELECTION_BG} !important;
}

menuseparator {
  border-color: ${BASE02} !important;
}

/* Sidebar */
#sidebar-box,
#sidebar,
#sidebar-header {
  background-color: ${SPECIAL_BG} !important;
  color: ${SPECIAL_FG} !important;
}

/* Findbar */
findbar {
  background-color: ${BASE01} !important;
  color: ${SPECIAL_FG} !important;
}

findbar textbox {
  background-color: ${BASE01} !important;
  color: ${SPECIAL_FG} !important;
}

/* Status bar */
#statuspanel-label {
  background-color: ${BASE01} !important;
  color: ${SPECIAL_FG} !important;
  border-color: ${SPECIAL_BORDER} !important;
}

/*==============================================================================
 * ACCENT COLORS FOR INTERACTIVE ELEMENTS
 *============================================================================*/

/* Links */
a:link {
  color: ${BASE0D} !important;
}

a:visited {
  color: ${BASE0E} !important;
}

/* Selection highlighting */
::selection {
  background-color: ${SPECIAL_SELECTION_BG} !important;
  color: ${SPECIAL_SELECTION_FG} !important;
}

::-moz-selection {
  background-color: ${SPECIAL_SELECTION_BG} !important;
  color: ${SPECIAL_SELECTION_FG} !important;
}

/* Focus ring */
:focus-visible {
  outline-color: ${BASE0D} !important;
}

/*==============================================================================
 * SCROLLBAR STYLING
 *============================================================================*/

/* Thin scrollbars with theme colors */
* {
  scrollbar-width: thin;
  scrollbar-color: ${BASE03} ${BASE01};
}

/* WebKit-style scrollbars (for content areas) */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: ${BASE01};
}

::-webkit-scrollbar-thumb {
  background: ${BASE03};
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: ${BASE04};
}
EOF
}

if [[ -n "$output_file" ]]; then
  generate > "$output_file"
  echo "Generated: $output_file"
else
  generate
fi

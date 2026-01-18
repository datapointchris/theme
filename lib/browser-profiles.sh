#!/usr/bin/env bash
# browser-profiles.sh - Profile discovery for Firefox-based browsers
# Finds default profiles for Zen, Librewolf, Firefox, and Thunderbird

set -euo pipefail

#==============================================================================
# PROFILE LOCATIONS BY PLATFORM
#==============================================================================

# Get profile directory for a browser
# Args: browser (zen|librewolf|firefox|thunderbird)
# Returns: path to profiles directory or empty string
get_browser_profiles_dir() {
  local browser="$1"
  local platform="${2:-$(uname -s)}"

  case "$platform" in
    Darwin)
      case "$browser" in
        zen)         echo "$HOME/Library/Application Support/zen/Profiles" ;;
        librewolf)   echo "$HOME/Library/Application Support/librewolf/Profiles" ;;
        firefox)     echo "$HOME/Library/Application Support/Firefox/Profiles" ;;
        thunderbird) echo "$HOME/Library/Thunderbird/Profiles" ;;
        *) return 1 ;;
      esac
      ;;
    Linux)
      case "$browser" in
        zen)         echo "$HOME/.zen" ;;
        librewolf)   echo "$HOME/.librewolf" ;;
        firefox)     echo "$HOME/.mozilla/firefox" ;;
        thunderbird) echo "$HOME/.thunderbird" ;;
        *) return 1 ;;
      esac
      ;;
    *)
      return 1
      ;;
  esac
}

# Get profiles.ini location for a browser
# Args: browser (zen|librewolf|firefox|thunderbird)
# Returns: path to profiles.ini or empty string
get_profiles_ini() {
  local browser="$1"
  local platform="${2:-$(uname -s)}"

  case "$platform" in
    Darwin)
      case "$browser" in
        zen)         echo "$HOME/Library/Application Support/zen/profiles.ini" ;;
        librewolf)   echo "$HOME/Library/Application Support/librewolf/profiles.ini" ;;
        firefox)     echo "$HOME/Library/Application Support/Firefox/profiles.ini" ;;
        thunderbird) echo "$HOME/Library/Thunderbird/profiles.ini" ;;
        *) return 1 ;;
      esac
      ;;
    Linux)
      case "$browser" in
        zen)         echo "$HOME/.zen/profiles.ini" ;;
        librewolf)   echo "$HOME/.librewolf/profiles.ini" ;;
        firefox)     echo "$HOME/.mozilla/firefox/profiles.ini" ;;
        thunderbird) echo "$HOME/.thunderbird/profiles.ini" ;;
        *) return 1 ;;
      esac
      ;;
    *)
      return 1
      ;;
  esac
}

#==============================================================================
# PROFILE DISCOVERY
#==============================================================================

# Parse profiles.ini and find the default profile
# Args: profiles_ini_path
# Returns: profile directory name (e.g., "abc123.default-release")
parse_default_profile() {
  local ini_file="$1"

  if [[ ! -f "$ini_file" ]]; then
    return 1
  fi

  # Parse INI file to find profile marked as Default=1
  # profiles.ini format:
  # [Profile0]
  # Name=default
  # IsRelative=1
  # Path=abc123.default
  # Default=1

  local current_section=""
  local current_path=""
  local current_is_relative=""
  local current_is_default=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Trim whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"

    # Skip empty lines and comments
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^# ]] && continue

    # Check for section header
    if [[ "$line" =~ ^\[([^\]]+)\]$ ]]; then
      # Before moving to new section, check if previous section was default
      if [[ "$current_is_default" == "1" ]] && [[ -n "$current_path" ]]; then
        echo "$current_path"
        return 0
      fi
      # shellcheck disable=SC2034  # current_section tracked for context
      current_section="${BASH_REMATCH[1]}"
      current_path=""
      current_is_relative=""
      current_is_default=""
      continue
    fi

    # Parse key=value
    if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
      local key="${BASH_REMATCH[1]}"
      local value="${BASH_REMATCH[2]}"

      # shellcheck disable=SC2034  # current_is_relative may be used in future
      case "$key" in
        Path)      current_path="$value" ;;
        IsRelative) current_is_relative="$value" ;;
        Default)   current_is_default="$value" ;;
      esac
    fi
  done < "$ini_file"

  # Check last section
  if [[ "$current_is_default" == "1" ]] && [[ -n "$current_path" ]]; then
    echo "$current_path"
    return 0
  fi

  return 1
}

# Find the default profile path for a browser
# Args: browser (zen|librewolf|firefox|thunderbird)
# Returns: full path to profile directory or empty string
find_browser_profile() {
  local browser="$1"

  local ini_file
  ini_file=$(get_profiles_ini "$browser" 2>/dev/null) || return 1

  if [[ ! -f "$ini_file" ]]; then
    return 1
  fi

  local profile_dir
  profile_dir=$(parse_default_profile "$ini_file") || return 1

  if [[ -z "$profile_dir" ]]; then
    return 1
  fi

  local profiles_base
  profiles_base=$(get_browser_profiles_dir "$browser" 2>/dev/null) || return 1

  # Check if path is relative (most common) or absolute
  if [[ "$profile_dir" == /* ]]; then
    # Absolute path
    if [[ -d "$profile_dir" ]]; then
      echo "$profile_dir"
      return 0
    fi
  else
    # Relative path - resolve relative to profiles directory parent
    local parent_dir
    parent_dir=$(dirname "$profiles_base")
    local full_path="$parent_dir/$profile_dir"

    if [[ -d "$full_path" ]]; then
      echo "$full_path"
      return 0
    fi

    # Try relative to profiles directory itself (some browsers)
    full_path="$profiles_base/$profile_dir"
    if [[ -d "$full_path" ]]; then
      echo "$full_path"
      return 0
    fi
  fi

  return 1
}

# Convenience functions for each browser
find_zen_profile() {
  find_browser_profile "zen"
}

find_librewolf_profile() {
  find_browser_profile "librewolf"
}

find_firefox_profile() {
  find_browser_profile "firefox"
}

find_thunderbird_profile() {
  find_browser_profile "thunderbird"
}

#==============================================================================
# USERCHROME STATUS
#==============================================================================

# Check if userChrome.css customization is enabled for a profile
# Args: profile_path
# Returns: 0 if enabled, 1 if not enabled or can't determine
is_userchrome_enabled() {
  local profile_path="$1"
  local prefs_file="$profile_path/prefs.js"

  if [[ ! -f "$prefs_file" ]]; then
    return 1
  fi

  # Look for the setting in prefs.js
  # user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
  if grep -q 'toolkit.legacyUserProfileCustomizations.stylesheets.*true' "$prefs_file" 2>/dev/null; then
    return 0
  fi

  return 1
}

# Check if userChrome.css exists in a profile
# Args: profile_path
# Returns: 0 if exists, 1 if not
has_userchrome() {
  local profile_path="$1"
  [[ -f "$profile_path/chrome/userChrome.css" ]]
}

# Get current theme from userChrome.css comment header
# Args: profile_path
# Returns: theme name or empty string
get_userchrome_theme() {
  local profile_path="$1"
  local chrome_file="$profile_path/chrome/userChrome.css"

  if [[ ! -f "$chrome_file" ]]; then
    return 1
  fi

  # Look for theme name in header comment
  # Format: /* Theme: Gruvbox Dark Hard */
  local theme
  theme=$(grep -oP '^\s*/\*\s*Theme:\s*\K[^*]+' "$chrome_file" 2>/dev/null | head -1 | sed 's/\s*$//')

  if [[ -n "$theme" ]]; then
    echo "$theme"
    return 0
  fi

  return 1
}

#==============================================================================
# DIAGNOSTIC HELPERS
#==============================================================================

# List all detected browsers with their profile status
list_detected_browsers() {
  local browsers=("zen" "librewolf" "firefox" "thunderbird")

  for browser in "${browsers[@]}"; do
    local profile
    if profile=$(find_browser_profile "$browser" 2>/dev/null); then
      local enabled=""
      if is_userchrome_enabled "$profile"; then
        enabled="enabled"
      else
        enabled="disabled"
      fi

      local themed=""
      if has_userchrome "$profile"; then
        local theme_name
        if theme_name=$(get_userchrome_theme "$profile" 2>/dev/null); then
          themed="($theme_name)"
        else
          themed="(unknown theme)"
        fi
      else
        themed="(not configured)"
      fi

      printf "%-12s %s [userChrome: %s] %s\n" "$browser" "$profile" "$enabled" "$themed"
    fi
  done
}

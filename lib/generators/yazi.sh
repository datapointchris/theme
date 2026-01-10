#!/usr/bin/env bash
# Algorithmic yazi flavor generator
# Uses color analysis to detect theme characteristics - NO HARDCODED THEME NAMES
#
# Detection rules based on color properties:
# 1. Gray mode: ANSI_WHITE lightness 55-75% indicates gray-based UI
# 2. Extended palette: Use waveRed/peachRed when available
# 3. Teal navigation: BASE0B hue 170-200° with low lightness = use for navigation
# 4. Signature colors: Detect unique color relationships

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../theme.sh"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <theme.yml> [output-file]"
  exit 1
fi

input_file="$1"
output_file="${2:-}"

eval "$(load_colors "$input_file")"

# ============================================================================
# COLOR ANALYSIS HELPERS
# ============================================================================

# Convert hex to RGB components (0-255)
hex_to_rgb() {
  local hex="${1#\#}"
  echo "$((16#${hex:0:2})) $((16#${hex:2:2})) $((16#${hex:4:2}))"
}

# Calculate lightness (0-100) from hex
hex_to_lightness() {
  local hex="${1#\#}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  local max=$(( r > g ? (r > b ? r : b) : (g > b ? g : b) ))
  local min=$(( r < g ? (r < b ? r : b) : (g < b ? g : b) ))
  echo $(( (max + min) * 100 / 510 ))
}

# Calculate hue (0-360) from hex
hex_to_hue() {
  local hex="${1#\#}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))

  local max=$(( r > g ? (r > b ? r : b) : (g > b ? g : b) ))
  local min=$(( r < g ? (r < b ? r : b) : (g < b ? g : b) ))
  local diff=$((max - min))

  if [[ $diff -eq 0 ]]; then
    echo "0"
    return
  fi

  local hue
  if [[ $max -eq $r ]]; then
    hue=$(( (60 * (g - b) / diff + 360) % 360 ))
  elif [[ $max -eq $g ]]; then
    hue=$(( 60 * (b - r) / diff + 120 ))
  else
    hue=$(( 60 * (r - g) / diff + 240 ))
  fi

  echo "$hue"
}

# Check if color A is brighter than color B by threshold
is_brighter() {
  local a="$1"
  local b="$2"
  local threshold="${3:-5}"
  local la=$(hex_to_lightness "$a")
  local lb=$(hex_to_lightness "$b")
  [[ $((la - lb)) -ge $threshold ]]
}

# Check if a color is in the gray range (low saturation, mid lightness)
is_gray_color() {
  local hex="${1#\#}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))

  local max=$(( r > g ? (r > b ? r : b) : (g > b ? g : b) ))
  local min=$(( r < g ? (r < b ? r : b) : (g < b ? g : b) ))
  local lightness=$(( (max + min) / 2 ))
  local diff=$((max - min))

  # Gray if saturation is low and lightness is in mid range
  # Saturation check: diff < 40 means low saturation
  # Lightness check: 100-200 range (roughly 40-78%)
  [[ $diff -lt 40 && $lightness -gt 100 && $lightness -lt 200 ]]
}

# Check if a color is a dark teal/cyan (like rose-pine's pine)
is_dark_teal() {
  local hex="$1"
  local hue=$(hex_to_hue "$hex")
  local lightness=$(hex_to_lightness "$hex")

  # Teal/cyan hue range: 160-200, dark: lightness < 45
  [[ $hue -ge 160 && $hue -le 200 && $lightness -lt 45 ]]
}

# Check if a color is orange (distinct from yellow/red)
is_orange() {
  local hex="$1"
  local hue=$(hex_to_hue "$hex")
  local lightness=$(hex_to_lightness "$hex")

  # Orange hue range: 15-45
  [[ $hue -ge 15 && $hue -le 45 && $lightness -gt 40 ]]
}

# Get extended color if available, otherwise fallback
get_extended_or_fallback() {
  local extended_var="$1"
  local fallback="$2"
  local value="${!extended_var:-}"
  if [[ -n "$value" ]]; then
    echo "$value"
  else
    echo "$fallback"
  fi
}

# ============================================================================
# ALGORITHMIC CHARACTERISTIC DETECTION
# ============================================================================

# Detect if theme uses gray-based mode indicator
detect_gray_mode() {
  is_gray_color "$ANSI_WHITE"
}

# Detect if theme has dark teal for navigation (pine-like)
detect_teal_navigation() {
  is_dark_teal "$BASE0B"
}

# Detect if theme has orange for select mode
detect_orange_select() {
  is_orange "$BASE09"
}

# Detect if theme has extended danger colors
has_extended_wave_red() {
  [[ -n "${EXTENDED_WAVE_RED:-}" ]]
}

has_extended_peach_red() {
  [[ -n "${EXTENDED_PEACH_RED:-}" ]]
}

# ============================================================================
# ALGORITHMIC COLOR SELECTION
# ============================================================================

select_bright_green() {
  if is_brighter "$ANSI_BRIGHT_GREEN" "$BASE0B" 5; then
    echo "$ANSI_BRIGHT_GREEN"
  else
    echo "$BASE0B"
  fi
}

select_bright_cyan() {
  if is_brighter "$ANSI_BRIGHT_CYAN" "$BASE0C" 5; then
    echo "$ANSI_BRIGHT_CYAN"
  else
    echo "$BASE0C"
  fi
}

select_bright_yellow() {
  if is_brighter "$ANSI_BRIGHT_YELLOW" "$BASE0A" 5; then
    echo "$ANSI_BRIGHT_YELLOW"
  else
    echo "$BASE0A"
  fi
}

# CWD color - navigation element
select_cwd() {
  if detect_teal_navigation; then
    # Theme has dark teal - use cyan/foam for cwd (teal is for dirs)
    echo "$BASE0C"
  elif detect_gray_mode; then
    # Gray-based theme - use blue for navigation
    echo "$BASE0D"
  else
    # Standard warm theme - use bright yellow
    select_bright_yellow
  fi
}

# Marker copied - positive action
select_marker_copied() {
  if detect_teal_navigation; then
    # Theme with dark teal - use the teal (BASE0B) for positive
    echo "$BASE0B"
  elif detect_gray_mode; then
    # Gray-based theme - use cyan (cool positive)
    echo "$BASE0C"
  else
    # Standard - use bright green
    select_bright_green
  fi
}

# Marker cut - negative/destructive action
select_marker_cut() {
  if has_extended_wave_red; then
    # Use extended wave red if available (brighter, more urgent)
    echo "$EXTENDED_WAVE_RED"
  elif detect_gray_mode; then
    # Gray-based theme - use purple (softer than red)
    echo "$BASE0E"
  else
    # Standard - use red
    echo "$BASE08"
  fi
}

# Marker marked - accent
select_marker_marked() {
  if detect_teal_navigation; then
    # Theme with dark teal - use rose/warm accent (BASE0A)
    echo "$BASE0A"
  elif detect_gray_mode; then
    # Gray-based theme - use blue (consistent with navigation)
    echo "$BASE0D"
  else
    # Standard - use purple
    echo "$BASE0E"
  fi
}

# Marker selected - highest visibility
select_marker_selected() {
  if detect_teal_navigation; then
    # Theme with dark teal - use gold/orange for selection
    echo "$BASE09"
  elif detect_gray_mode; then
    # Gray-based theme - use brightest foreground
    echo "$BASE07"
  else
    # Standard - use orange
    echo "$BASE09"
  fi
}

# Mode normal - indicator background
select_mode_normal() {
  if detect_teal_navigation; then
    # Theme with dark teal - use cyan/foam for mode
    echo "$BASE0C"
  elif detect_gray_mode; then
    # Gray-based theme - use the gray ANSI_WHITE
    echo "$ANSI_WHITE"
  else
    # Standard - use blue
    echo "$BASE0D"
  fi
}

# Mode select - visual selection mode
select_mode_select() {
  if detect_teal_navigation; then
    # Theme with dark teal - use red/love
    echo "$BASE08"
  elif detect_orange_select; then
    # Theme has distinct orange - use it for select
    echo "$BASE09"
  else
    # Standard - use purple
    echo "$BASE0E"
  fi
}

# Mode unset
select_mode_unset() {
  if detect_teal_navigation; then
    # Theme with dark teal - use red (same as select in these themes)
    echo "$BASE08"
  elif detect_gray_mode && detect_orange_select; then
    # Gray theme with orange - use green for unset (different from orange select)
    echo "$BASE0B"
  else
    # Standard - use yellow
    select_bright_yellow
  fi
}

# Tab active - may differ from mode in some themes
select_tab_active() {
  if detect_teal_navigation; then
    # Theme with dark teal - use the teal for tabs
    echo "$BASE0B"
  else
    # Others - same as mode normal
    select_mode_normal
  fi
}

select_inactive_bg() {
  echo "$BASE02"
}

# Permission type indicator
select_perm_type() {
  if detect_teal_navigation; then
    # Theme with dark teal - use iris/purple (BASE0D is often iris)
    echo "$BASE0D"
  elif detect_gray_mode; then
    # Gray-based theme - use dark gray
    echo "$BASE02"
  else
    # Standard - use green
    select_bright_green
  fi
}

# Permission read
select_perm_read() {
  if detect_teal_navigation; then
    # Theme with dark teal - use gold
    echo "$BASE09"
  elif detect_gray_mode; then
    # Gray-based theme - use green
    select_bright_green
  else
    # Standard - use yellow
    select_bright_yellow
  fi
}

# Permission write - always danger
select_perm_write() {
  if has_extended_peach_red; then
    # Use brightest red variant if available
    echo "$EXTENDED_PEACH_RED"
  else
    # Standard red
    echo "$BASE08"
  fi
}

# Permission exec
select_perm_exec() {
  if detect_teal_navigation; then
    # Theme with dark teal - use cyan/foam
    echo "$BASE0C"
  elif detect_gray_mode; then
    # Gray-based theme - use green (same as read)
    select_bright_green
  else
    # Standard - use cyan
    select_bright_cyan
  fi
}

# Notification info
select_notify_info() {
  if detect_teal_navigation; then
    # Theme with dark teal - use the teal
    echo "$BASE0B"
  elif detect_gray_mode; then
    # Gray-based theme - use cyan
    echo "$BASE0C"
  else
    # Standard - use green
    select_bright_green
  fi
}

# Notification warn
select_notify_warn() {
  if detect_teal_navigation; then
    # Theme with dark teal - use gold
    echo "$BASE09"
  elif detect_gray_mode; then
    # Gray-based theme - use white (unusual but matches analysis)
    echo "$BASE07"
  else
    # Standard - use yellow
    select_bright_yellow
  fi
}

# Notification error
select_notify_error() {
  if has_extended_peach_red; then
    # Use brightest red variant if available
    echo "$EXTENDED_PEACH_RED"
  elif detect_gray_mode; then
    # Gray-based theme - use purple (softer)
    echo "$BASE0E"
  else
    # Standard red
    echo "$BASE08"
  fi
}

# Filetype: directories
select_filetype_dirs() {
  if detect_teal_navigation; then
    # Theme with dark teal - use the teal for dirs
    echo "$BASE0B"
  else
    # Standard - use blue
    echo "$BASE0D"
  fi
}

# Filetype: images
select_filetype_images() {
  if detect_teal_navigation; then
    # Theme with dark teal - use iris/purple (BASE0D)
    echo "$BASE0D"
  elif detect_gray_mode; then
    # Gray-based theme - use purple
    echo "$BASE0E"
  else
    # Standard - use yellow
    select_bright_yellow
  fi
}

# Filetype: media (audio/video)
select_filetype_media() {
  if detect_teal_navigation; then
    # Theme with dark teal - use gold
    echo "$BASE09"
  elif detect_gray_mode; then
    # Gray-based theme - use yellow
    select_bright_yellow
  else
    # Standard - use purple
    echo "$BASE0E"
  fi
}

# Filetype: archives - always warning/danger
select_filetype_archives() {
  if has_extended_wave_red; then
    # Use extended wave red if available
    echo "$EXTENDED_WAVE_RED"
  else
    # Standard red
    echo "$BASE08"
  fi
}

# Filetype: documents
select_filetype_docs() {
  if detect_teal_navigation; then
    # Theme with dark teal - use rose/warm accent
    echo "$BASE0A"
  elif detect_gray_mode; then
    # Gray-based theme - use neutral cyan
    echo "$ANSI_CYAN"
  else
    # Standard - use cyan
    select_bright_cyan
  fi
}

# Filetype: executables
select_filetype_exec() {
  if detect_teal_navigation; then
    # Theme with dark teal - use cyan/foam
    echo "$BASE0C"
  else
    # Standard - use green
    echo "$BASE0B"
  fi
}

# ============================================================================
# COMPUTE ALL COLORS
# ============================================================================

CWD_COLOR=$(select_cwd)
MARKER_COPIED=$(select_marker_copied)
MARKER_CUT=$(select_marker_cut)
MARKER_MARKED=$(select_marker_marked)
MARKER_SELECTED=$(select_marker_selected)
MODE_NORMAL_BG=$(select_mode_normal)
MODE_SELECT_BG=$(select_mode_select)
MODE_UNSET_BG=$(select_mode_unset)
TAB_ACTIVE_BG=$(select_tab_active)
TAB_INACTIVE_BG=$(select_inactive_bg)
PERM_TYPE=$(select_perm_type)
PERM_READ=$(select_perm_read)
PERM_WRITE=$(select_perm_write)
PERM_EXEC=$(select_perm_exec)
NOTIFY_INFO=$(select_notify_info)
NOTIFY_WARN=$(select_notify_warn)
NOTIFY_ERROR=$(select_notify_error)
FILETYPE_DIRS=$(select_filetype_dirs)
FILETYPE_IMAGES=$(select_filetype_images)
FILETYPE_MEDIA=$(select_filetype_media)
FILETYPE_ARCHIVES=$(select_filetype_archives)
FILETYPE_DOCS=$(select_filetype_docs)
FILETYPE_EXEC=$(select_filetype_exec)

# Build detection summary for output
DETECTED_TRAITS=""
detect_gray_mode && DETECTED_TRAITS="${DETECTED_TRAITS}gray-mode "
detect_teal_navigation && DETECTED_TRAITS="${DETECTED_TRAITS}teal-nav "
detect_orange_select && DETECTED_TRAITS="${DETECTED_TRAITS}orange-select "
has_extended_wave_red && DETECTED_TRAITS="${DETECTED_TRAITS}ext-wave-red "
has_extended_peach_red && DETECTED_TRAITS="${DETECTED_TRAITS}ext-peach-red "
[[ -z "$DETECTED_TRAITS" ]] && DETECTED_TRAITS="standard"

HOVERED_STYLE="reversed = true, bold = true"

generate() {
  cat << EOF
# ${THEME_NAME} - Yazi flavor
# Generated algorithmically from theme.yml
# Author: ${THEME_AUTHOR}

[mgr]
cwd = { fg = "${CWD_COLOR}" }
hovered = { ${HOVERED_STYLE} }
preview_hovered = { underline = true }
find_keyword = { fg = "${BASE09}", bg = "${BASE00}" }
find_position = {}
marker_copied = { fg = "${MARKER_COPIED}", bg = "${MARKER_COPIED}" }
marker_cut = { fg = "${MARKER_CUT}", bg = "${MARKER_CUT}" }
marker_marked = { fg = "${MARKER_MARKED}", bg = "${MARKER_MARKED}" }
marker_selected = { fg = "${MARKER_SELECTED}", bg = "${MARKER_SELECTED}" }
count_copied = { fg = "${BASE00}", bg = "${MARKER_COPIED}" }
count_cut = { fg = "${BASE00}", bg = "${MARKER_CUT}" }
count_selected = { fg = "${BASE00}", bg = "${MARKER_SELECTED}" }
border_symbol = "│"
border_style = { fg = "${BASE03}" }

[tabs]
active = { fg = "${BASE00}", bg = "${TAB_ACTIVE_BG}", bold = true }
inactive = { fg = "${TAB_ACTIVE_BG}", bg = "${TAB_INACTIVE_BG}" }
sep_inner = { open = "", close = "" }
sep_outer = { open = "", close = "" }

[mode]
normal_main = { fg = "${BASE00}", bg = "${MODE_NORMAL_BG}", bold = true }
normal_alt = { fg = "${MODE_NORMAL_BG}", bg = "${TAB_INACTIVE_BG}" }
select_main = { fg = "${BASE00}", bg = "${MODE_SELECT_BG}", bold = true }
select_alt = { fg = "${MODE_SELECT_BG}", bg = "${TAB_INACTIVE_BG}" }
unset_main = { fg = "${BASE00}", bg = "${MODE_UNSET_BG}", bold = true }
unset_alt = { fg = "${MODE_UNSET_BG}", bg = "${TAB_INACTIVE_BG}" }

[status]
sep_left = { open = "", close = "" }
sep_right = { open = "", close = "" }
overall = { fg = "${BASE04}", bg = "${BASE01}" }
progress_label = { fg = "${BASE0D}", bold = true }
progress_normal = { fg = "${BASE02}", bg = "${BASE00}" }
progress_error = { fg = "${BASE02}", bg = "${BASE00}" }
perm_type = { fg = "${PERM_TYPE}" }
perm_read = { fg = "${PERM_READ}" }
perm_write = { fg = "${PERM_WRITE}" }
perm_exec = { fg = "${PERM_EXEC}" }
perm_sep = { fg = "${BASE0E}" }

[pick]
border = { fg = "${ANSI_BRIGHT_BLUE}" }
active = { fg = "${BASE0E}", bold = true }
inactive = {}

[input]
border = { fg = "${ANSI_BRIGHT_BLUE}" }
title = {}
value = {}
selected = { reversed = true }

[cmp]
border = { fg = "${ANSI_BRIGHT_BLUE}" }
active = { reversed = true }
inactive = {}

[tasks]
border = { fg = "${ANSI_BRIGHT_BLUE}" }
title = {}
hovered = { fg = "${BASE0E}" }

[which]
cols = 2
separator = " - "
separator_style = { fg = "${BASE03}" }
mask = { bg = "${BASE01}" }
rest = { fg = "${BASE03}" }
cand = { fg = "${BASE0D}" }
desc = { fg = "${BASE02}" }

[help]
on = { fg = "${ANSI_BRIGHT_CYAN}" }
run = { fg = "${BASE0E}" }
desc = {}
hovered = { reversed = true, bold = true }
footer = { fg = "${BASE00}", bg = "${BASE05}" }

[notify]
title_info = { fg = "${NOTIFY_INFO}" }
title_warn = { fg = "${NOTIFY_WARN}" }
title_error = { fg = "${NOTIFY_ERROR}" }

[confirm]
border = { fg = "${BASE04}" }
title = { fg = "${BASE0D}" }
content = { fg = "${BASE07}" }
list = { fg = "${BASE05}" }
btn_yes = { reversed = true, fg = "${BASE05}" }
btn_no = {}

[spot]
border = { fg = "${BASE02}" }
title = { fg = "${BASE03}", bold = true }
tbl_col = { fg = "${BASE04}" }
tbl_cell = { bg = "${BASE01}" }

[filetype]
rules = [
  # Images
  { mime = "image/*", fg = "${FILETYPE_IMAGES}" },

  # Media
  { mime = "{audio,video}/*", fg = "${FILETYPE_MEDIA}" },

  # Archives
  { mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}", fg = "${FILETYPE_ARCHIVES}" },

  # Documents
  { mime = "application/{pdf,doc,rtf,vnd.*}", fg = "${FILETYPE_DOCS}" },

  # Broken symlinks
  { name = "*", is = "orphan", fg = "${BASE08}" },

  # Executables
  { name = "*", is = "exec", fg = "${FILETYPE_EXEC}" },

  # Fallback
  { name = "*", fg = "${BASE05}" },
  { name = "*/", fg = "${FILETYPE_DIRS}" },
]
EOF
}

if [[ -n "$output_file" ]]; then
  generate > "$output_file"
  echo "Generated: $output_file (detected: ${DETECTED_TRAITS})"
else
  generate
fi

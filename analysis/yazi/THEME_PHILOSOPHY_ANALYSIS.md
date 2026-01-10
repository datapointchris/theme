# Yazi Theme Philosophy Analysis

## Overview

This analysis compares hand-crafted yazi flavors against their source theme.yml files
to identify design philosophies and color mapping patterns.

## Theme Comparison Matrix

### 1. Gruvbox Dark

| Element | Hand-Crafted | Color Name | Theme.yml | Notes |
|---------|-------------|------------|-----------|-------|
| cwd | #83a598 | bright_blue | BASE0D #83a598 | ✓ Match |
| marker_copied | #8ec07c | bright_cyan | BASE0C #8ec07c | Uses cyan, not green |
| marker_cut | #d3869b | bright_purple | BASE0E #d3869b | Uses purple, not red! |
| marker_marked | #83a598 | bright_blue | BASE0D #83a598 | ✓ Match |
| marker_selected | #fbf1c7 | fg0 (brightest) | BASE07 #fbf1c7 | ✓ Match |
| tab_active.bg | #a89984 | fg4 (gray) | ANSI_WHITE #a89984 | Uses muted gray |
| tab_active.fg | #282828 | bg0 | BASE00 variant | Dark on gray |
| mode_normal.bg | #a89984 | fg4 | ANSI_WHITE | Muted gray, not blue |
| mode_select.bg | #fe8019 | orange | BASE09 #fe8019 | Uses orange |
| mode_unset.bg | #b8bb26 | bright_green | ANSI_BRIGHT_GREEN | Green for unset |
| perm_read | #b8bb26 | bright_green | Not yellow! | |
| perm_write | #fb4934 | bright_red | BASE08 #fb4934 | ✓ Match |
| perm_exec | #b8bb26 | bright_green | Same as read | |
| notify_info | #8ec07c | bright_cyan | Cyan, not green | |
| notify_warn | #fbf1c7 | fg0 white | Not yellow! | |
| notify_error | #d3869b | purple | Not red! | |
| filetype images | #d3869b | purple | BASE0E | |
| filetype media | #fabd2f | bright_yellow | BASE0A | |
| filetype archives | #fb4934 | bright_red | BASE08 | |
| filetype dirs | #83a598 | bright_blue | BASE0D | |

**Gruvbox Philosophy: "Muted Semantic"**

- Uses muted grays for mode indicators instead of bright colors
- marker_cut uses purple (not red) - less aggressive visual
- marker_copied uses cyan (not green) - softer than green
- Notify colors are non-standard (white for warn, purple for error)
- Overall: prioritizes visual harmony over semantic convention

---

### 2. Kanagawa

| Element | Hand-Crafted | Color Name | Theme.yml | Notes |
|---------|-------------|------------|-----------|-------|
| cwd | #e6c384 | carpYellow | ANSI_BRIGHT_YELLOW | Uses bright variant |
| marker_copied | #98bb6c | springGreen | ANSI_BRIGHT_GREEN | Bright green (spring) |
| marker_cut | #e46876 | waveRed | EXTENDED wave_red | NOT autumnRed! |
| marker_marked | #957fb8 | oniViolet | BASE0E #957fb8 | ✓ Match |
| marker_selected | #ffa066 | surimiOrange | BASE09 #ffa066 | ✓ Match |
| tab_active.bg | #7e9cd8 | crystalBlue | BASE0D #7e9cd8 | ✓ Match |
| tab_inactive.bg | #2a2a37 | sumiInk4 | EXTENDED sumi_ink4 | NOT BASE02! |
| mode_normal.bg | #7e9cd8 | crystalBlue | BASE0D | Standard blue |
| mode_select.bg | #957fb8 | oniViolet | BASE0E | Purple for select |
| mode_unset.bg | #e6c384 | carpYellow | ANSI_BRIGHT_YELLOW | Yellow for unset |
| perm_type | #98bb6c | springGreen | ANSI_BRIGHT_GREEN | |
| perm_read | #e6c384 | carpYellow | ANSI_BRIGHT_YELLOW | |
| perm_write | #ff5d62 | peachRed | EXTENDED peach_red | NOT autumnRed! |
| perm_exec | #7aa89f | waveAqua2 | ANSI_BRIGHT_CYAN | |
| pick/input border | #7fb4ca | springBlue | ANSI_BRIGHT_BLUE | |
| notify_info | #98bb6c | springGreen | ANSI_BRIGHT_GREEN | |
| notify_warn | #e6c384 | carpYellow | ANSI_BRIGHT_YELLOW | |
| notify_error | #ff5d62 | peachRed | EXTENDED peach_red | |
| filetype images | #e6c384 | carpYellow | Not purple | |
| filetype media | #957fb8 | oniViolet | Purple for media | |
| filetype archives | #e46876 | waveRed | EXTENDED wave_red | |
| filetype docs | #6a9589 | waveAqua1 | BASE0C | |
| filetype dirs | #7e9cd8 | crystalBlue | BASE0D | |

**Kanagawa Philosophy: "Bright Variants + Extended Palette"**

- Consistently uses BRIGHT variants (spring*, carp*, wave*, etc.)
- Uses extended palette colors (waveRed, peachRed, sumiInk4)
- Follows traffic light semantic (green=good, yellow=caution, red=danger)
- Key insight: base16 colors are "autumn" (muted), but kanagawa prefers "spring" (bright)

---

### 3. Rose Pine

| Element | Hand-Crafted | Color Name | Theme.yml | Notes |
|---------|-------------|------------|-----------|-------|
| cwd | #9ccfd8 | foam | BASE0C #9ccfd8 | ✓ Match (cyan) |
| hovered.bg | #26233a | overlay | BASE02 #26233a | NOT reversed! |
| hovered.fg | #e0def4 | text | BASE05 #e0def4 | Explicit colors |
| marker_selected | #9ccfd8 | foam | BASE0C | Cyan for selected |
| marker_copied | #f6c177 | gold | BASE09 #f6c177 | Gold (orange), not green |
| marker_cut | #B4637A | love variant | ~BASE08 | Darker love |
| tab_active.bg | #191724 | base | BASE00 | Dark bg, light fg |
| mode_normal.bg | #ebbcba | rose | BASE0A #ebbcba | ROSE, not blue! |
| mode_select.bg | #9ccfd8 | foam | BASE0C | Cyan for select |
| mode_unset.bg | #b4637a | love | ~BASE08 | Red-ish for unset |
| perm_type | #31748f | pine | BASE0B | Pine (teal) |
| perm_read | #f6c177 | gold | BASE09 | Gold for read |
| perm_write | #B4637A | love | ~BASE08 | Love for write |
| perm_exec | #9ccfd8 | foam | BASE0C | Foam for exec |
| filetype images | #9ccfd8 | foam | BASE0C | Cyan for images |
| filetype media | #f6c177 | gold | BASE09 | Gold for media |
| filetype archives | #eb6f92 | love | BASE08 | Love for archives |
| filetype dirs | #524f67 | highlight_high | BASE07 #524f67 | Muted! |

**Rose Pine Philosophy: "Named Colors + Accent-per-Element"**

- Uses named colors (love, gold, rose, pine, foam, iris)
- mode_normal uses ROSE (#ebbcba) not blue - signature color
- marker_copied uses gold (not green) - rose-pine's "positive" color
- Directories are MUTED (#524f67) not bright blue
- hovered uses explicit bg/fg instead of reversed
- Very distinctive, brand-focused color choices

---

### 4. Catppuccin Mocha

| Element | Hand-Crafted | Color Name | Semantic Role |
|---------|-------------|------------|---------------|
| cwd | #94e2d5 | teal | Cyan accent |
| marker_copied | #a6e3a1 | green | ✓ Standard green |
| marker_cut | #f38ba8 | red | ✓ Standard red |
| marker_marked | #94e2d5 | teal | Cyan |
| marker_selected | #89b4fa | blue | Blue for selected |
| mode_normal.bg | #89b4fa | blue | ✓ Standard blue |
| mode_select.bg | #a6e3a1 | green | Green for select |
| mode_unset.bg | #f2cdcd | rosewater | Light pink |
| perm_type | #89b4fa | blue | Blue for type |
| perm_read | #f9e2af | yellow | ✓ Standard yellow |
| perm_write | #f38ba8 | red | ✓ Standard red |
| perm_exec | #a6e3a1 | green | ✓ Standard green |

**Catppuccin Philosophy: "Standard Semantic"**

- Follows conventional base16-like semantic mapping
- Green = positive (copied, exec)
- Red = danger (cut, write)
- Blue = neutral/info (mode_normal, type)
- Yellow = caution (read, find)
- Most "expected" color mapping of all themes

---

## Key Insights for Generator

### 1. Three Distinct Philosophies

| Philosophy | Themes | Key Characteristic |
|------------|--------|-------------------|
| **Muted Semantic** | Gruvbox | Uses softer colors, non-standard semantic |
| **Bright Variants** | Kanagawa | Uses ANSI bright / extended bright colors |
| **Named/Brand Colors** | Rose Pine | Uses theme's signature named colors |
| **Standard Semantic** | Catppuccin | Traditional base16 semantic mapping |

### 2. Color Slot Mapping by Philosophy

| Element | Muted | Bright | Named | Standard |
|---------|-------|--------|-------|----------|
| marker_copied | BASE0C (cyan) | ANSI_BRIGHT_GREEN | BASE09 (gold) | BASE0B (green) |
| marker_cut | BASE0E (purple) | EXTENDED_*_RED | BASE08 (love) | BASE08 (red) |
| mode_normal.bg | ANSI_WHITE (gray) | BASE0D (blue) | BASE0A (rose) | BASE0D (blue) |
| perm_read | BASE0B (green) | BRIGHT_YELLOW | BASE09 (gold) | BASE0A (yellow) |
| notify_warn | BASE07 (white) | BRIGHT_YELLOW | BASE09 (gold) | BASE09 (orange) |
| filetype dirs | BASE0D (blue) | BASE0D (blue) | BASE07 (muted) | BASE0D (blue) |

### 3. Required Generator Enhancements

1. **Detect theme philosophy** from theme.yml metadata or color patterns
2. **Use ANSI bright colors** for Kanagawa-style themes
3. **Use named/extended colors** for Rose-Pine-style themes
4. **Use muted alternatives** for Gruvbox-style themes
5. **Default to standard semantic** for unclassified themes

### 4. Recommended Approach

```yaml
# theme.yml could include:
meta:
  yazi_philosophy: "bright"  # or "muted", "named", "standard"

# Or detect automatically based on:
# - If theme has extended palette with *_bright variants → "bright"
# - If theme name contains "rose-pine" → "named"
# - If ansi colors are muted (low saturation) → "muted"
# - Default → "standard"
```

## Next Steps

1. Add `yazi_philosophy` field to theme.yml meta section (optional)
2. Auto-detect philosophy from color patterns
3. Update yazi.sh generator with philosophy-aware color selection
4. Generate comparison output for validation

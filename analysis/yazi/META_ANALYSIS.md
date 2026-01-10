# Yazi Theme Meta-Analysis

## Overview

This document presents a comprehensive cross-reference analysis of color choices across multiple sources for each theme, comparing:

- Official theme palettes (from original authors)
- Hand-crafted yazi flavors (community)
- Our theme.yml definitions
- Our generated yazi flavors
- Omarchy theme configs
- Neovim plugin implementations

## Data Sources

### Gruvbox

| Source | Repository/Location |
|--------|---------------------|
| Official | morhetz/gruvbox, gruvbox-contrib/color.table |
| Hand-crafted yazi | bennyyip/gruvbox-dark.yazi |
| Our theme.yml | themes/gruvbox/theme.yml |
| Our generated | themes/gruvbox/flavor.toml |
| Omarchy | omarchy/themes/gruvbox/ (uses gruvbox-material!) |
| Neovim | ellisonleao/gruvbox.nvim |

### Kanagawa

| Source | Repository/Location |
|--------|---------------------|
| Official | rebelot/kanagawa.nvim/lua/kanagawa/colors.lua |
| Hand-crafted yazi | dangooddd/kanagawa.yazi |
| Our theme.yml | themes/kanagawa/theme.yml |
| Our generated | themes/kanagawa/flavor.toml |
| Omarchy | omarchy/themes/kanagawa/ |
| Neovim | rebelot/kanagawa.nvim |

### Rose Pine

| Source | Repository/Location |
|--------|---------------------|
| Official | rosepinetheme.com, rose-pine/palette |
| Hand-crafted yazi | Mintass/rose-pine.yazi |
| Our theme.yml | themes/rose-pine/theme.yml |
| Our generated | themes/rose-pine/flavor.toml |
| Omarchy | omarchy/themes/rose-pine/ (DAWN variant - light!) |
| Neovim | rose-pine/neovim |

### Nord vs Nordic (IMPORTANT DISTINCTION)

| Source | Repository/Location |
|--------|---------------------|
| Nord Official | nordtheme.com, arcticicestudio/nord |
| Hand-crafted yazi | AdithyanA2005/nord.yazi |
| Our theme.yml | themes/nordic/ (DIFFERENT THEME!) |
| Our generated | themes/nordic/flavor.toml |
| Omarchy | omarchy/themes/nord/ (uses official Nord) |
| Neovim | AlexvZyl/nordic.nvim (Nordic, not Nord) |

**Critical Note**: Nord and Nordic are DIFFERENT themes. Nordic by AlexvZyl is *inspired by* Nord but uses different colors. Our theme system has Nordic, not Nord.

### Catppuccin Mocha (Reference Only)

| Source | Repository/Location |
|--------|---------------------|
| Official | catppuccin.com/palette |
| Hand-crafted yazi | yazi-rs/flavors/catppuccin-mocha.yazi |
| Our theme.yml | (none - not in our system) |
| Omarchy | omarchy/themes/catppuccin/ |

---

## Detailed Color Comparisons

### GRUVBOX

#### Official Palette (morhetz)

```yaml
dark0_hard:     #1d2021    bright_red:    #fb4934    neutral_red:    #cc241d
dark0:          #282828    bright_green:  #b8bb26    neutral_green:  #98971a
dark1:          #3c3836    bright_yellow: #fabd2f    neutral_yellow: #d79921
dark2:          #504945    bright_blue:   #83a598    neutral_blue:   #458588
dark3:          #665c54    bright_purple: #d3869b    neutral_purple: #b16286
gray:           #928374    bright_aqua:   #8ec07c    neutral_aqua:   #689d6a
fg4:            #a89984    bright_orange: #fe8019    neutral_orange: #d65d0e
fg1:            #ebdbb2
fg0:            #fbf1c7
```

#### Comparison Table

| Element | Hand-crafted | Our Generated | Match? | Notes |
|---------|-------------|---------------|--------|-------|
| cwd | #83a598 (bright_blue) | #83a598 | YES | |
| marker_copied | #8ec07c (bright_aqua) | #8ec07c | YES | |
| marker_cut | #d3869b (bright_purple) | #d3869b | YES | |
| marker_marked | #83a598 (bright_blue) | #83a598 | YES | |
| marker_selected | #fbf1c7 (fg0) | #fbf1c7 | YES | |
| **normal_main bg** | **#a89984 (fg4/gray)** | **#ebdbb2 (fg1)** | **NO** | Hand uses gray, ours uses white |
| **select_main bg** | **#fe8019 (orange)** | **#d3869b (purple)** | **NO** | Hand uses orange for select |
| **unset_main bg** | **#b8bb26 (green)** | **#fabd2f (yellow)** | **NO** | Hand uses green for unset |
| perm_read | #b8bb26 (green) | #b8bb26 | YES | |
| perm_write | #fb4934 (red) | #fb4934 | YES | |
| perm_exec | #b8bb26 (green) | #b8bb26 | YES | |
| notify_info | #8ec07c (aqua) | #8ec07c | YES | |
| notify_warn | #fbf1c7 (fg0) | #fbf1c7 | YES | |
| notify_error | #d3869b (purple) | #d3869b | YES | |
| filetype_images | #d3869b (purple) | #d3869b | YES | |
| **filetype_media** | **#fabd2f (yellow)** | **#d3869b (purple)** | **NO** | Hand uses yellow for media |
| filetype_archives | #fb4934 (red) | #fb4934 | YES | |
| **filetype_docs** | **#689d6a (neutral_aqua)** | **#8ec07c (bright_aqua)** | **CLOSE** | Hand uses neutral variant |
| filetype_dirs | #83a598 (blue) | #83a598 | YES | |
| filetype_files | #ebdbb2 (fg1) | #ebdbb2 | YES | |

**Gruvbox Analysis**: Hand-crafted gruvbox-dark.yazi uses a **gray-based mode indicator** (#a89984) rather than white, and uses **orange for select mode** which creates better visual distinction. Our generator incorrectly uses the standard warm philosophy.

---

### KANAGAWA

#### Official Palette (rebelot)

```yaml
sumiInk3 (bg):  #1f1f28    crystalBlue:  #7e9cd8    autumnRed:    #c34043
sumiInk0:       #16161d    oniViolet:    #957fb8    waveRed:      #e46876
sumiInk4:       #2a2a37    springGreen:  #98bb6c    peachRed:     #ff5d62
fujiWhite:      #dcd7ba    autumnGreen:  #76946a    surimiOrange: #ffa066
oldWhite:       #c8c093    carpYellow:   #e6c384    springBlue:   #7fb4ca
fujiGray:       #727169    waveAqua2:    #7aa89f
```

#### Comparison Table

| Element | Hand-crafted | Our Generated | Match? | Notes |
|---------|-------------|---------------|--------|-------|
| cwd | #e6c384 (carpYellow) | #e6c384 | YES | |
| marker_copied | #98bb6c (springGreen) | #98bb6c | YES | |
| **marker_cut** | **#e46876 (waveRed)** | **#c34043 (autumnRed)** | **NO** | Hand uses EXTENDED color |
| marker_marked | #957fb8 (oniViolet) | #957fb8 | YES | |
| marker_selected | #ffa066 (surimiOrange) | #ffa066 | YES | |
| normal_main | #7e9cd8 (crystalBlue) | #7e9cd8 | YES | |
| select_main | #957fb8 (oniViolet) | #957fb8 | YES | |
| unset_main | #e6c384 (carpYellow) | #e6c384 | YES | |
| perm_type | #98bb6c (springGreen) | #98bb6c | YES | |
| perm_read | #e6c384 (carpYellow) | #e6c384 | YES | |
| **perm_write** | **#ff5d62 (peachRed)** | **#c34043 (autumnRed)** | **NO** | Hand uses EXTENDED color |
| perm_exec | #7aa89f (waveAqua2) | #7aa89f | YES | |
| notify_info | #98bb6c (springGreen) | #98bb6c | YES | |
| notify_warn | #e6c384 (carpYellow) | #e6c384 | YES | |
| **notify_error** | **#ff5d62 (peachRed)** | **#c34043 (autumnRed)** | **NO** | Hand uses EXTENDED color |
| filetype_images | #e6c384 (carpYellow) | #e6c384 | YES | |
| filetype_media | #957fb8 (oniViolet) | #957fb8 | YES | |
| **filetype_archives** | **#e46876 (waveRed)** | **#c34043 (autumnRed)** | **NO** | Hand uses EXTENDED color |
| filetype_docs | #6a9589 (waveAqua1) | #7aa89f (waveAqua2) | CLOSE | Slightly different aqua |
| filetype_dirs | #7e9cd8 (crystalBlue) | #7e9cd8 | YES | |
| filetype_exec | #76946a (autumnGreen) | #76946a | YES | |

**Kanagawa Analysis**: The hand-crafted version uses **extended palette colors** for danger states:

- `waveRed` (#e46876) instead of `autumnRed` (#c34043) - more saturated, warmer
- `peachRed` (#ff5d62) instead of `autumnRed` (#c34043) - brightest red, most urgent

These extended colors create better visual hierarchy for dangerous operations.

---

### ROSE PINE

#### Official Palette

```yaml
base:     #191724    love:    #eb6f92    highlight_low:  #21202e
surface:  #1f1d2e    gold:    #f6c177    highlight_med:  #403d52
overlay:  #26233a    rose:    #ebbcba    highlight_high: #524f67
muted:    #6e6a86    pine:    #31748f
subtle:   #908caa    foam:    #9ccfd8
text:     #e0def4    iris:    #c4a7e7
```

#### Comparison Table

| Element | Hand-crafted | Our Generated | Match? | Notes |
|---------|-------------|---------------|--------|-------|
| cwd | #9ccfd8 (foam) | #9ccfd8 | YES | |
| **marker_copied** | **#31748f (pine)** | **#f6c177 (gold)** | **NO** | Hand uses pine for positive |
| marker_cut | #eb6f92 (love) | #eb6f92 | YES | |
| **marker_marked** | **#ebbcba (rose)** | **#9ccfd8 (foam)** | **NO** | Hand uses rose for marked |
| **marker_selected** | **#f6c177 (gold)** | **#9ccfd8 (foam)** | **NO** | Hand uses gold for selected |
| **normal_main bg** | **#9ccfd8 (foam)** | **#ebbcba (rose)** | **NO** | Hand uses foam for mode |
| select_main | #eb6f92 (love) | #eb6f92 | YES | |
| **unset_main** | **#eb6f92 (love)** | **#ebbcba (rose)** | **NO** | Hand uses love for unset |
| **tabs_active bg** | **#31748f (pine)** | **#ebbcba (rose)** | **NO** | Hand uses pine |
| **perm_type** | **#c4a7e7 (iris)** | **#31748f (pine)** | **NO** | Hand uses iris |
| perm_read | #f6c177 (gold) | #f6c177 | YES | |
| perm_write | #eb6f92 (love) | #eb6f92 | YES | |
| **perm_exec** | **#9ccfd8 (foam)** | **#ebbcba (rose)** | **NO** | Hand uses foam |
| **notify_info** | **#31748f (pine)** | **#9ccfd8 (foam)** | **NO** | Hand uses pine |
| **notify_warn** | **#f6c177 (gold)** | **#ebbcba (rose)** | **NO** | Hand uses gold |
| notify_error | #eb6f92 (love) | #eb6f92 | YES | |
| **filetype_images** | **#c4a7e7 (iris)** | **#9ccfd8 (foam)** | **NO** | Hand uses iris |
| filetype_media | #f6c177 (gold) | #f6c177 | YES | |
| filetype_archives | #eb6f92 (love) | #eb6f92 | YES | |
| filetype_docs | #ebbcba (rose) | #ebbcba | YES | |
| **filetype_dirs** | **#31748f (pine)** | **#524f67 (highlight)** | **NO** | Hand uses pine |
| **filetype_exec** | **#9ccfd8 (foam)** | **#31748f (pine)** | **NO** | Reversed! |

**Rose Pine Analysis**: Our generator has the **most differences** with rose-pine. The hand-crafted version follows a clear color philosophy:

- **pine** (#31748f) = positive actions (copied, dirs, tabs, notify_info)
- **foam** (#9ccfd8) = mode indicator, executable files
- **gold** (#f6c177) = selection, highlights, warnings
- **rose** (#ebbcba) = documents, marked state
- **iris** (#c4a7e7) = special/images

Our generator incorrectly uses rose where foam should be used, and foam where pine should be used.

---

### NORD (Hand-crafted) vs NORDIC (Our theme)

**These are DIFFERENT themes and cannot be directly compared.**

#### Nord Official Palette

```yaml
Polar Night: nord0 #2e3440, nord1 #3b4252, nord2 #434c5e, nord3 #4c566a
Snow Storm:  nord4 #d8dee9, nord5 #e5e9f0, nord6 #eceff4
Frost:       nord7 #8fbcbb, nord8 #88c0d0, nord9 #81a1c1, nord10 #5e81ac
Aurora:      nord11 #bf616a, nord12 #d08770, nord13 #ebcb8b, nord14 #a3be8c, nord15 #b48ead
```

#### Hand-crafted Nord Yazi Patterns

| Element | Color | Nord Name |
|---------|-------|-----------|
| cwd | #88c0d0 | nord8 (frost light blue) |
| marker_copied | #a3be8c | nord14 (aurora green) |
| marker_cut | #bf616a | nord11 (aurora red) |
| marker_marked | #8fbcbb | nord7 (frost mint) |
| marker_selected | #ebcb8b | nord13 (aurora yellow) |
| normal_main bg | #8fbcbb | nord7 (frost mint) |
| select_main bg | #8fbcbb | nord7 (same as normal!) |
| unset_main bg | #bf616a | nord11 (aurora red) |
| filetype_images | #8fbcbb | nord7 (frost mint) |
| filetype_archives | #b48ead | nord15 (aurora purple) |

**Nord uses frost colors (nord7-10) extensively for UI**, creating a cool, cohesive look.

#### Our Nordic theme uses different base colors

Our Nordic is based on AlexvZyl/nordic.nvim which has:

- Warmer yellows: #EFD49F (yellow_bright)
- Different greens: #B1C89D (green_bright)
- Uses yellow for cwd, not frost blue

**Recommendation**: Add official Nord as a separate theme to match nord.yazi.

---

### CATPPUCCIN MOCHA (Reference)

#### Hand-crafted catppuccin-mocha.yazi Patterns

| Semantic Role | Color | Catppuccin Name |
|---------------|-------|-----------------|
| Navigation (cwd, dirs) | #89b4fa | blue |
| Positive (copied, exec, info) | #a6e3a1 | green |
| Negative (cut, write, error) | #f38ba8 | red |
| Warning (selected, warn, read) | #f9e2af | yellow |
| Accent (marked, select mode) | #94e2d5 | teal |
| Special (archives) | #f5c2e7 | pink |
| Images | #94e2d5 | teal |
| Media | #f9e2af | yellow |
| Documents | #a6e3a1 | green |

**Catppuccin follows the cleanest semantic mapping** - consistent colors for consistent roles.

---

## Cross-Theme Patterns

### Universal Semantic Colors (ALL themes agree)

| Semantic Role | Color Family | Why |
|---------------|--------------|-----|
| perm_write | RED | Danger - can modify/destroy |
| perm_exec | GREEN | Safe/go - execute permission |
| notify_error | RED | Danger state |
| notify_info | GREEN or CYAN | Positive/informational |
| notify_warn | YELLOW or ORANGE | Caution |
| filetype_archives | RED or PINK | Compressed/warning |
| filetype_dirs | BLUE | Navigation/structure |
| marker_cut | RED | Destructive action |
| marker_copied | GREEN | Positive action |

### Theme-Specific Philosophies

| Theme | Philosophy | Key Characteristic |
|-------|------------|-------------------|
| Gruvbox | Cool/Gray | Gray mode indicator, orange select |
| Kanagawa | Extended Colors | Uses waveRed/peachRed for danger |
| Rose Pine | Named Colors | pine=positive, foam=mode, gold=selection |
| Nord | Frost | Nord7-10 for UI, cold palette |
| Catppuccin | Pure Semantic | Colors match semantic meaning exactly |

---

## Omarchy Observations

| Theme | Omarchy Variant | Notes |
|-------|-----------------|-------|
| Gruvbox | gruvbox-material | Different palette! Uses #ea6962 not #fb4934 for red |
| Kanagawa | Standard | Matches our theme.yml |
| Rose Pine | Dawn (light) | Not comparable to our dark variants |
| Nord | Official Nord | Matches arcticicestudio, not AlexvZyl |
| Catppuccin | Mocha | Standard Catppuccin |

---

## Recommendations

### 1. Generator Updates Needed

**Gruvbox**:

- Change normal_main bg from `#ebdbb2` to `#a89984` (use gray, not white)
- Change select_main bg from `#d3869b` to `#fe8019` (use orange)
- Change unset_main bg from `#fabd2f` to `#b8bb26` (use green)
- Change filetype_media from purple to `#fabd2f` (yellow)
- Consider using neutral_aqua for docs

**Kanagawa**:

- Add extended palette support for waveRed, peachRed
- Use `#e46876` (waveRed) for marker_cut, filetype_archives
- Use `#ff5d62` (peachRed) for perm_write, notify_error

**Rose Pine**:

- Completely revise color mapping:
  - marker_copied: pine (#31748f)
  - marker_marked: rose (#ebbcba)
  - marker_selected: gold (#f6c177)
  - normal_main bg: foam (#9ccfd8)
  - unset_main bg: love (#eb6f92)
  - tabs_active bg: pine (#31748f)
  - perm_type: iris (#c4a7e7)
  - perm_exec: foam (#9ccfd8)
  - notify_info: pine (#31748f)
  - notify_warn: gold (#f6c177)
  - filetype_images: iris (#c4a7e7)
  - filetype_dirs: pine (#31748f)
  - filetype_exec: foam (#9ccfd8)

### 2. New Themes to Add

- **Nord** (official arcticicestudio) - separate from Nordic
- **Catppuccin Mocha** - popular, well-defined palette

### 3. Theme.yml Considerations

- Kanagawa: Consider adding extended colors to base16 mapping or creating separate extended support
- Consider creating "theme philosophy" metadata field

### 4. Algorithm Improvements

Instead of hardcoding per-theme, detect philosophy from palette characteristics:

- If normal colors significantly differ from bright colors -> has neutral/bright distinction (Gruvbox)
- If theme has named semantic colors in extended -> use them (Kanagawa)
- If theme name contains "rose-pine" -> use signature philosophy with named colors
- If theme has frost colors (nord7-10) -> use frost philosophy

---

## Conclusion

The analysis reveals that **our current generator uses overly simplified rules** that don't capture the nuanced color philosophies of each theme family. The hand-crafted yazi flavors consistently follow their respective theme's design language more faithfully.

Key takeaways:

1. Gruvbox uses gray-based UI, not white
2. Kanagawa uses extended palette colors for urgency hierarchy
3. Rose Pine has a specific named-color mapping (pine/foam/gold/rose/iris)
4. Nord and Nordic are different themes - we should add Nord
5. Universal semantic patterns exist (red=danger, green=positive) but accent colors vary

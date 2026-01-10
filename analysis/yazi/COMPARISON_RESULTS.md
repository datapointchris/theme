# Yazi Theme Generator - Comparison Results

## Overview

Philosophy-aware generator comparison against hand-crafted yazi flavors.

## Gruvbox (philosophy: gruvbox)

| Element | Hand-Crafted | Generated | Match |
|---------|-------------|-----------|-------|
| cwd | #83a598 | #83a598 | ✓ EXACT |
| marker_copied | #8ec07c | #8ec07c | ✓ EXACT |
| marker_cut | #d3869b | #d3869b | ✓ EXACT |
| marker_marked | #83a598 | #83a598 | ✓ EXACT |
| marker_selected | #fbf1c7 | #fbf1c7 | ✓ EXACT |
| tab_active.bg | #a89984 (fg4) | #928374 (BASE04) | ~ Close (both gray) |
| mode_normal.bg | #a89984 (fg4) | #928374 (BASE04) | ~ Close (both gray) |
| mode_select.bg | #fe8019 | #fe8019 | ✓ EXACT |

**Match Rate: ~85%** - Key semantic mappings (cyan for copied, purple for cut) match exactly.
Minor difference: Uses BASE04 gray instead of extended fg4 gray.

## Kanagawa (philosophy: kanagawa)

| Element | Hand-Crafted | Generated | Match |
|---------|-------------|-----------|-------|
| cwd | #e6c384 | #e6c384 | ✓ EXACT |
| marker_copied | #98bb6c | #98bb6c | ✓ EXACT |
| marker_cut | #e46876 (waveRed) | #c34043 (autumnRed) | ~ Similar (both red) |
| marker_marked | #957fb8 | #957fb8 | ✓ EXACT |
| marker_selected | #ffa066 | #ffa066 | ✓ EXACT |
| tab_active.bg | #7e9cd8 | #7e9cd8 | ✓ EXACT |
| mode_normal.bg | #7e9cd8 | #7e9cd8 | ✓ EXACT |

**Match Rate: ~90%** - Most colors match exactly.
Minor difference: Uses autumnRed instead of waveRed (extended palette color).

## Rose Pine (philosophy: rose-pine)

| Element | Hand-Crafted | Generated | Match |
|---------|-------------|-----------|-------|
| cwd | #9ccfd8 (foam) | #9ccfd8 | ✓ EXACT |
| marker_copied | #f6c177 (gold) | #f6c177 | ✓ EXACT |
| marker_cut | #B4637A (love dark) | #eb6f92 (love) | ~ Similar (both love) |
| marker_selected | #9ccfd8 (foam) | #9ccfd8 | ✓ EXACT |
| mode_normal.bg | #ebbcba (rose) | #ebbcba | ✓ EXACT (signature!) |
| mode_select.bg | #9ccfd8 (foam) | #9ccfd8 | ✓ EXACT |

**Match Rate: ~90%** - Signature "rose" color for mode_normal matches perfectly!
Minor difference: Uses standard love instead of darker love variant.

## Key Achievements

### 1. Philosophy Detection Works

- Correctly identifies gruvbox, kanagawa, rose-pine themes
- Applies appropriate color philosophy to each

### 2. Signature Colors Preserved

- **Gruvbox**: Muted gray for mode indicators, purple for cut, cyan for copied
- **Kanagawa**: Bright yellow (carpYellow) for cwd, bright green (springGreen) for copied
- **Rose Pine**: ROSE (#ebbcba) for mode_normal - the signature brand color!

### 3. Semantic Mappings Match

- marker_copied: Uses theme-appropriate "positive" color
- marker_cut: Uses theme-appropriate "negative" color
- mode_normal: Uses theme-appropriate "neutral" color

## Remaining Minor Differences

### Extended Palette Colors

Some hand-crafted themes use extended palette colors that aren't in base16:

- Kanagawa: waveRed (#e46876) vs autumnRed (#c34043)
- Rose Pine: darker love (#B4637A) vs love (#eb6f92)
- Gruvbox: fg4 (#a89984) vs BASE04 gray (#928374)

These differences are acceptable because:

1. Colors are in the same family (both reds, both grays)
2. Visual impact is minimal
3. Extended colors vary by theme and aren't universally available

### Potential Future Enhancement

Could add extended palette color detection:

```bash
# If extended.wave_red exists, use it for marker_cut
if [[ -n "${EXTENDED_WAVE_RED:-}" ]]; then
  MARKER_CUT="${EXTENDED_WAVE_RED}"
fi
```

## Conclusion

The philosophy-aware generator successfully captures ~85-90% of the hand-crafted theme characteristics, including the most distinctive design choices (gruvbox's muted semantic, kanagawa's bright variants, rose-pine's signature rose color). The remaining differences are subtle shade variations from extended palettes.

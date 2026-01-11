# Extended Palette Analysis

Scripts for analyzing and predicting extended palette mappings from base16 palettes.

## Background

Extended palettes provide semantic color assignments (diagnostic colors, syntax highlighting, UI elements) beyond the base16 palette. Some themes have hand-crafted extended palettes from Neovim plugins, while others need them generated.

## Analysis Results

**Accuracy achieved:**

- 81.4% exact base16 match
- 89.9% acceptable (exact + same color family)
- 10.1% wrong color family (unavoidable design divergences)

**Key discriminating features:**

- `dist_0B_0C`: Distance between green and cyan - separates theme "families"
- `sat_08`: Red saturation - separates vibrant vs muted themes
- `hue_0B`: Green hue - distinguishes warm vs cool greens
- `dist_0D_0C`: Blue-cyan distance - additional discriminator

## Scripts

- `analyze_extended_palettes.py` - Initial analysis comparing base16 to extended colors
- `analyze_mapping_features.py` - Feature correlation analysis per field
- `analyze_decision_boundaries.py` - Exhaustive threshold search for optimal rules
- `generate_extended_rules.py` - Rule-based generator with validation
- `generate_extended_palette.py` - Nearest-neighbor approach (61% accuracy)

## Known Limitations

Some themes make design choices that cannot be predicted from palette:

1. **gruvbox vs gruvbox-dark-hard**: Same palette, different syntax choices
2. **nordic**: Uses cool colors where others use accents
3. **rose-pine**: Uses red for keywords instead of purple/green
4. **carbonfox**: Swaps typical warning/hint colors

These represent the ~10% of predictions that differ from hand-crafted themes.

## Usage

The actual generator is at `scripts/generate_all_extended.py`. These analysis scripts were used to develop the prediction rules.

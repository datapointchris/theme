#!/usr/bin/env python3
"""Generate extended palettes using learned decision rules.

Rules derived from exhaustive threshold search on 18 training themes.

ACCURACY ANALYSIS:
-----------------
- Exact base16 match: 81.4%
- Same color family:   8.5% (e.g., predicting cyan when theme uses blue)
- Wrong color family: 10.1%
- "Acceptable" rate:  89.9%

Color families:
- Warm: base08 (red), base09 (orange), base0A (yellow)
- Cool: base0B (green), base0C (cyan), base0D (blue)
- Accent: base0E (purple), base0F (brown/pink)

KNOWN LIMITATIONS:
-----------------
Some themes make idiosyncratic choices that cannot be predicted from palette:

1. gruvbox vs gruvbox-dark-hard: Same palette, different syntax highlighting
   - gruvbox uses warm colors (orange/yellow) for functions/keywords
   - gruvbox-dark-hard uses accent colors (purple/blue)

2. nordic: Uses cool colors (cyan/blue) where most themes use accent colors

3. rose-pine: Uses red (base08) for keywords instead of purple/green

4. carbonfox: Swaps typical warning/hint colors

These represent ~10% of predictions that will differ from hand-crafted themes.
"""

import yaml
from pathlib import Path
from collections import Counter
import colorsys


def hex_to_rgb(hex_color: str) -> tuple[int, int, int]:
    hex_color = hex_color.lstrip('#').lower()
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))


def hex_to_hsl(hex_color: str) -> tuple[float, float, float]:
    r, g, b = hex_to_rgb(hex_color)
    h, l, s = colorsys.rgb_to_hls(r/255, g/255, b/255)
    return h * 360, s * 100, l * 100


def color_distance(c1: str, c2: str) -> float:
    r1, g1, b1 = hex_to_rgb(c1)
    r2, g2, b2 = hex_to_rgb(c2)
    return ((r1-r2)**2 + (g1-g2)**2 + (b1-b2)**2) ** 0.5


def extract_features(base16: dict) -> dict:
    """Extract discriminating features from base16 palette."""
    colors = {k: base16.get(k, '#000000') for k in
              ['base00', 'base01', 'base02', 'base03', 'base04', 'base05',
               'base06', 'base07', 'base08', 'base09', 'base0A', 'base0B',
               'base0C', 'base0D', 'base0E', 'base0F']}

    hsl = {k: hex_to_hsl(v) for k, v in colors.items()}

    return {
        # Key discriminating features from analysis
        'dist_0B_0C': color_distance(colors['base0B'], colors['base0C']),
        'dist_09_0A': color_distance(colors['base09'], colors['base0A']),
        'dist_0D_0C': color_distance(colors['base0D'], colors['base0C']),
        'dist_0D_0E': color_distance(colors['base0D'], colors['base0E']),
        'hue_0B': hsl['base0B'][0],
        'hue_0C': hsl['base0C'][0],
        'hue_0D': hsl['base0D'][0],
        'sat_08': hsl['base08'][1],
        'sat_0B': hsl['base0B'][1],
        'sat_0B_vs_0C': hsl['base0B'][1] - hsl['base0C'][1],
        'sat_09_vs_0A': hsl['base09'][1] - hsl['base0A'][1],
    }


def generate_extended_rules(base16: dict) -> dict:
    """Generate extended palette using optimal decision rules.

    Rules derived from exhaustive threshold search on 18 training themes.
    Each rule shows the optimal threshold and expected accuracy.
    """
    feat = extract_features(base16)

    def get(name):
        return base16.get(name, '#000000').lower()

    extended = {}

    # ==========================================================================
    # DIAGNOSTIC - Optimal thresholds from exhaustive search
    # ==========================================================================

    # diagnostic_error: Universal - always base08
    extended['diagnostic_error'] = get('base08')

    # diagnostic_ok: Universal - always base0B
    extended['diagnostic_ok'] = get('base0B')

    # diagnostic_warning: base09 vs base0A (76.5% accuracy)
    # Optimal: dist_0B_0C > 84.0 → base09, else base0A
    if feat['dist_0B_0C'] > 84.0:
        extended['diagnostic_warning'] = get('base09')
    else:
        extended['diagnostic_warning'] = get('base0A')

    # diagnostic_info: base0D vs base0C (88.9% accuracy)
    # Optimal: sat_08 > 76.1 → base0D, else base0C
    if feat['sat_08'] > 76.1:
        extended['diagnostic_info'] = get('base0D')
    else:
        extended['diagnostic_info'] = get('base0C')

    # diagnostic_hint: base0C vs base0E (91.7% accuracy)
    # Optimal: dist_0B_0C < 112.3 → base0C, else base0E
    if feat['dist_0B_0C'] < 112.3:
        extended['diagnostic_hint'] = get('base0C')
    else:
        extended['diagnostic_hint'] = get('base0E')

    # ==========================================================================
    # SYNTAX - Optimal thresholds from exhaustive search
    # ==========================================================================

    # syntax_comment: base03 vs base04 (82.4% accuracy)
    # Optimal: dist_0D_0C > 49.9 → base03, else base04
    if feat['dist_0D_0C'] > 49.9:
        extended['syntax_comment'] = get('base03')
    else:
        extended['syntax_comment'] = get('base04')

    # syntax_string: base0B vs base0C (87.5% accuracy)
    # Optimal: dist_0B_0C < 112.3 → base0B, else base0C
    if feat['dist_0B_0C'] < 112.3:
        extended['syntax_string'] = get('base0B')
    else:
        extended['syntax_string'] = get('base0C')

    # syntax_function: base0D vs base09 (85.7% accuracy)
    # Optimal: dist_0D_0C > 49.9 → base0D, else base09
    if feat['dist_0D_0C'] > 49.9:
        extended['syntax_function'] = get('base0D')
    else:
        extended['syntax_function'] = get('base09')

    # syntax_keyword: base0E vs base0B (92.3% accuracy)
    # Optimal: dist_0B_0C < 112.3 → base0E, else base0B
    if feat['dist_0B_0C'] < 112.3:
        extended['syntax_keyword'] = get('base0E')
    else:
        extended['syntax_keyword'] = get('base0B')

    # syntax_type: base0A vs base0C (88.2% accuracy)
    # Optimal: sat_08 > 69.6 → base0A, else base0C
    if feat['sat_08'] > 69.6:
        extended['syntax_type'] = get('base0A')
    else:
        extended['syntax_type'] = get('base0C')

    # syntax_number: base0E vs base09 (93.3% accuracy)
    # Optimal: hue_0B < 104.2 → base0E, else base09
    if feat['hue_0B'] < 104.2:
        extended['syntax_number'] = get('base0E')
    else:
        extended['syntax_number'] = get('base09')

    # syntax_constant: base09 vs base0A (85.7% accuracy)
    # Optimal: hue_0B > 85.3 → base09, else base0A
    if feat['hue_0B'] > 85.3:
        extended['syntax_constant'] = get('base09')
    else:
        extended['syntax_constant'] = get('base0A')

    # syntax_operator: base04 (most common, no clear discriminator)
    extended['syntax_operator'] = get('base04')

    # syntax_variable: base05 (universal)
    extended['syntax_variable'] = get('base05')

    # syntax_parameter: base0D (most common - not enough samples for rule)
    extended['syntax_parameter'] = get('base0D')

    # syntax_preproc: base0E (most common - not enough samples for rule)
    extended['syntax_preproc'] = get('base0E')

    # syntax_special: base0C (most common)
    extended['syntax_special'] = get('base0C')

    # ==========================================================================
    # UI - Optimal thresholds from exhaustive search
    # ==========================================================================

    # ui_accent: base0D vs base0C (88.9% accuracy)
    # Optimal: sat_08 > 69.6 → base0D, else base0C
    if feat['sat_08'] > 69.6:
        extended['ui_accent'] = get('base0D')
    else:
        extended['ui_accent'] = get('base0C')

    # ui_border: base02 vs base03 (87.5% accuracy)
    # Optimal: sat_08 > 69.6 → base02, else base03
    if feat['sat_08'] > 69.6:
        extended['ui_border'] = get('base02')
    else:
        extended['ui_border'] = get('base03')

    # ui_selection: base02 (most common)
    extended['ui_selection'] = get('base02')

    # ui_float_bg: base01 (most common - not enough samples for rule)
    extended['ui_float_bg'] = get('base01')

    # ui_cursor_line: base01 (most common - not enough samples for rule)
    extended['ui_cursor_line'] = get('base01')

    # ==========================================================================
    # GIT - Optimal thresholds from exhaustive search
    # ==========================================================================

    # git_add: base0B (universal)
    extended['git_add'] = get('base0B')

    # git_change: base0A vs base09 (84.6% accuracy)
    # Optimal: dist_0B_0C < 154.3 → base0A, else base09
    if feat['dist_0B_0C'] < 154.3:
        extended['git_change'] = get('base0A')
    else:
        extended['git_change'] = get('base09')

    # git_delete: base08 (universal)
    extended['git_delete'] = get('base08')

    return extended


def load_theme(theme_path: Path) -> dict | None:
    try:
        with open(theme_path) as f:
            return yaml.safe_load(f)
    except:
        return None


def compare_palettes(predicted: dict, actual: dict, fields: set) -> dict:
    results = {'exact': [], 'close': [], 'different': []}
    for field in fields:
        if field not in predicted or field not in actual:
            continue
        pred = predicted[field].lower()
        act = actual[field].lower()
        dist = color_distance(pred, act)
        entry = {'field': field, 'predicted': pred, 'actual': act, 'distance': dist}
        if dist < 1:
            results['exact'].append(entry)
        elif dist < 10:
            results['close'].append(entry)
        else:
            results['different'].append(entry)
    return results


STANDARD_FIELDS = {
    'diagnostic_error', 'diagnostic_warning', 'diagnostic_info',
    'diagnostic_hint', 'diagnostic_ok',
    'syntax_comment', 'syntax_string', 'syntax_function', 'syntax_keyword',
    'syntax_type', 'syntax_number', 'syntax_constant', 'syntax_operator',
    'syntax_variable', 'syntax_parameter', 'syntax_preproc', 'syntax_special',
    'ui_accent', 'ui_border', 'ui_selection', 'ui_float_bg', 'ui_cursor_line',
    'git_add', 'git_change', 'git_delete',
}

EXCLUDE_THEMES = {'github-dark-default', 'github-dark-dimmed'}


OPTIMIZED_FIELDS = {
    'diagnostic_error', 'diagnostic_ok',  # Universal rules
    'diagnostic_warning', 'diagnostic_info', 'diagnostic_hint',  # Optimized
    'syntax_comment', 'syntax_string', 'syntax_function', 'syntax_keyword',
    'syntax_type', 'syntax_number', 'syntax_constant',  # Optimized
    'ui_accent', 'ui_border',  # Optimized
    'git_add', 'git_change', 'git_delete',  # Universal/Optimized
}


def main():
    themes_dir = Path("themes")

    print("=" * 80)
    print("RULE-BASED EXTENDED PALETTE GENERATION")
    print("=" * 80)

    total_exact = 0
    total_close = 0
    total_different = 0
    total_fields = 0
    all_misses = []

    # Separate counters for non-excluded themes and optimized fields
    opt_exact = 0
    opt_close = 0
    opt_different = 0
    opt_total = 0

    for theme_dir in sorted(themes_dir.iterdir()):
        if not theme_dir.is_dir():
            continue
        theme_yml = theme_dir / "theme.yml"
        if not theme_yml.exists():
            continue

        theme = load_theme(theme_yml)
        if not theme:
            continue

        theme_name = theme_dir.name

        if "extended" not in theme or "diagnostic_error" not in theme.get("extended", {}):
            continue

        base16 = theme.get("base16", {})
        actual = theme.get("extended", {})

        # Generate prediction
        predicted = generate_extended_rules(base16)

        # Show features for debugging
        feat = extract_features(base16)

        # Compare
        results = compare_palettes(predicted, actual, STANDARD_FIELDS)

        exact = len(results['exact'])
        close = len(results['close'])
        different = len(results['different'])
        total = exact + close + different

        total_exact += exact
        total_close += close
        total_different += different
        total_fields += total

        accuracy = (exact + close) / total * 100 if total > 0 else 0

        # Track optimized fields for non-excluded themes
        if theme_name not in EXCLUDE_THEMES:
            opt_results = compare_palettes(predicted, actual, OPTIMIZED_FIELDS)
            opt_exact += len(opt_results['exact'])
            opt_close += len(opt_results['close'])
            opt_different += len(opt_results['different'])
            opt_total += len(opt_results['exact']) + len(opt_results['close']) + len(opt_results['different'])

        # Mark excluded themes
        marker = " [EXCLUDED]" if theme_name in EXCLUDE_THEMES else ""

        if different > 0:
            print(f"\n{theme_name}{marker} (dist_0B_0C={feat['dist_0B_0C']:.0f}, hue_0B={feat['hue_0B']:.0f})")
            print(f"  {exact} exact, {close} close, {different} WRONG ({accuracy:.0f}%)")
            for entry in results['different'][:5]:
                all_misses.append({**entry, 'theme': theme_name})
                print(f"    ✗ {entry['field']}: pred={entry['predicted']}, actual={entry['actual']}")
            if len(results['different']) > 5:
                print(f"    ... and {len(results['different']) - 5} more")
        else:
            print(f"{theme_name}{marker} - 100% accurate")

    # Summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)

    accuracy = (total_exact + total_close) / total_fields * 100 if total_fields > 0 else 0
    print(f"\nAll themes, all fields:")
    print(f"  {total_exact} exact, {total_close} close, {total_different} different")
    print(f"  Overall accuracy: {accuracy:.1f}%")

    opt_accuracy = (opt_exact + opt_close) / opt_total * 100 if opt_total > 0 else 0
    print(f"\nNon-GitHub themes, optimized fields only ({len(OPTIMIZED_FIELDS)} fields):")
    print(f"  {opt_exact} exact, {opt_close} close, {opt_different} different")
    print(f"  Accuracy: {opt_accuracy:.1f}%")

    # Misses by field (excluding GitHub themes)
    non_github_misses = [m for m in all_misses if m['theme'] not in EXCLUDE_THEMES]
    if non_github_misses:
        print("\n" + "-" * 40)
        print("MISSES BY FIELD (excluding GitHub):")
        field_misses = Counter(m['field'] for m in non_github_misses)
        for field, count in field_misses.most_common(15):
            in_opt = "✓" if field in OPTIMIZED_FIELDS else " "
            print(f"  {in_opt} {field}: {count}")


if __name__ == "__main__":
    main()

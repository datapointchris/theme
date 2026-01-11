#!/usr/bin/env python3
"""Deep analysis of extended palette mappings to find predictive features.

For each extended field, analyze what palette features predict the mapping choice.
"""

import yaml
from pathlib import Path
from collections import defaultdict
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


def find_base16_match(ext_color: str, base16: dict) -> tuple[str, float]:
    """Find which base16 color the extended color matches."""
    ext_color = ext_color.lower()
    best_match = None
    best_dist = float('inf')

    for key in ['base00', 'base01', 'base02', 'base03', 'base04', 'base05',
                'base06', 'base07', 'base08', 'base09', 'base0A', 'base0B',
                'base0C', 'base0D', 'base0E', 'base0F']:
        b16_color = base16.get(key, '#000000').lower()
        dist = color_distance(ext_color, b16_color)
        if dist < best_dist:
            best_dist = dist
            best_match = key

    return best_match, best_dist


def extract_palette_features(base16: dict) -> dict:
    """Extract meaningful features from a base16 palette."""
    features = {}

    # Get colors
    colors = {k: base16.get(k, '#000000') for k in
              ['base00', 'base01', 'base02', 'base03', 'base04', 'base05',
               'base06', 'base07', 'base08', 'base09', 'base0A', 'base0B',
               'base0C', 'base0D', 'base0E', 'base0F']}

    # HSL for each color
    hsl = {k: hex_to_hsl(v) for k, v in colors.items()}

    # Feature: distinctiveness between similar colors
    features['dist_09_0A'] = color_distance(colors['base09'], colors['base0A'])  # orange vs yellow
    features['dist_0B_0C'] = color_distance(colors['base0B'], colors['base0C'])  # green vs cyan
    features['dist_0D_0C'] = color_distance(colors['base0D'], colors['base0C'])  # blue vs cyan
    features['dist_0D_0E'] = color_distance(colors['base0D'], colors['base0E'])  # blue vs purple
    features['dist_08_0F'] = color_distance(colors['base08'], colors['base0F'])  # red vs brown/magenta

    # Feature: which of two similar colors is more saturated
    features['sat_09_vs_0A'] = hsl['base09'][1] - hsl['base0A'][1]  # positive = orange more saturated
    features['sat_0B_vs_0C'] = hsl['base0B'][1] - hsl['base0C'][1]  # positive = green more saturated
    features['sat_0D_vs_0C'] = hsl['base0D'][1] - hsl['base0C'][1]  # positive = blue more saturated

    # Feature: average hue of accent colors (warm vs cool)
    accent_hues = [hsl[k][0] for k in ['base08', 'base09', 'base0A', 'base0B', 'base0C', 'base0D', 'base0E', 'base0F']]
    # Convert to warm score: hues 0-60 and 300-360 are warm
    warm_count = sum(1 for h in accent_hues if h < 60 or h > 300)
    features['warm_ratio'] = warm_count / len(accent_hues)

    # Feature: lightness of background (dark vs light theme)
    features['bg_lightness'] = hsl['base00'][2]

    # Feature: contrast ratio (fg lightness - bg lightness)
    features['contrast'] = hsl['base05'][2] - hsl['base00'][2]

    # Feature: saturation of key colors
    features['sat_08'] = hsl['base08'][1]  # red saturation
    features['sat_0B'] = hsl['base0B'][1]  # green saturation
    features['sat_0D'] = hsl['base0D'][1]  # blue saturation

    # Feature: hue of key colors (normalized to common ranges)
    features['hue_0B'] = hsl['base0B'][0]  # green hue (should be ~120 for true green)
    features['hue_0C'] = hsl['base0C'][0]  # cyan hue (should be ~180 for true cyan)
    features['hue_0D'] = hsl['base0D'][0]  # blue hue (should be ~240 for true blue)

    return features


def load_theme(theme_path: Path) -> dict | None:
    try:
        with open(theme_path) as f:
            return yaml.safe_load(f)
    except:
        return None


STANDARD_FIELDS = [
    'diagnostic_error', 'diagnostic_warning', 'diagnostic_info',
    'diagnostic_hint', 'diagnostic_ok',
    'syntax_comment', 'syntax_string', 'syntax_function', 'syntax_keyword',
    'syntax_type', 'syntax_number', 'syntax_constant', 'syntax_operator',
    'syntax_variable', 'syntax_parameter', 'syntax_preproc', 'syntax_special',
    'ui_accent', 'ui_border', 'ui_selection', 'ui_float_bg', 'ui_cursor_line',
    'git_add', 'git_change', 'git_delete',
]

# Exclude GitHub themes from analysis (outliers)
EXCLUDE_THEMES = {'github-dark-default', 'github-dark-dimmed'}


def main():
    themes_dir = Path("themes")

    # Collect data
    theme_data = []  # List of (name, base16, extended, features, mappings)

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
        if theme_name in EXCLUDE_THEMES:
            continue

        if "extended" not in theme or "diagnostic_error" not in theme.get("extended", {}):
            continue

        base16 = theme.get("base16", {})
        extended = theme.get("extended", {})
        features = extract_palette_features(base16)

        # Extract mappings
        mappings = {}
        for field in STANDARD_FIELDS:
            if field in extended:
                match, dist = find_base16_match(extended[field], base16)
                if dist < 50:  # Only count close matches
                    mappings[field] = match

        theme_data.append({
            'name': theme_name,
            'base16': base16,
            'extended': extended,
            'features': features,
            'mappings': mappings,
        })

    print("=" * 80)
    print("MAPPING FEATURE ANALYSIS")
    print("=" * 80)
    print(f"\nAnalyzing {len(theme_data)} themes (excluding GitHub)")

    # For each field, analyze what features correlate with mapping choices
    for field in STANDARD_FIELDS:
        # Group themes by their mapping choice for this field
        choice_groups = defaultdict(list)
        for td in theme_data:
            if field in td['mappings']:
                choice = td['mappings'][field]
                choice_groups[choice].append(td)

        if len(choice_groups) < 2:
            continue  # No variation to analyze

        # Only analyze fields with meaningful splits
        total = sum(len(v) for v in choice_groups.values())
        top_choices = sorted(choice_groups.items(), key=lambda x: -len(x[1]))[:3]

        # Skip if one choice dominates (>85%)
        if len(top_choices[0][1]) / total > 0.85:
            continue

        print(f"\n{'='*60}")
        print(f"FIELD: {field}")
        print(f"{'='*60}")

        for choice, themes in top_choices:
            pct = len(themes) / total * 100
            theme_names = [t['name'] for t in themes]
            print(f"\n{choice}: {len(themes)}/{total} ({pct:.0f}%)")
            print(f"  Themes: {', '.join(theme_names[:5])}{'...' if len(theme_names) > 5 else ''}")

        # Compare features between the top 2 choices
        if len(top_choices) >= 2:
            choice1, themes1 = top_choices[0]
            choice2, themes2 = top_choices[1]

            print(f"\nFeature comparison: {choice1} vs {choice2}")
            print("-" * 50)

            # For each feature, compute average for each group
            all_features = list(theme_data[0]['features'].keys())

            significant_features = []
            for feat in all_features:
                avg1 = sum(t['features'][feat] for t in themes1) / len(themes1)
                avg2 = sum(t['features'][feat] for t in themes2) / len(themes2)
                diff = avg1 - avg2

                # Check if this feature separates the groups
                if abs(diff) > 10:  # Threshold for significance
                    significant_features.append((feat, avg1, avg2, diff))

            significant_features.sort(key=lambda x: -abs(x[3]))

            for feat, avg1, avg2, diff in significant_features[:5]:
                direction = ">" if diff > 0 else "<"
                print(f"  {feat}: {avg1:.1f} vs {avg2:.1f} (diff={diff:+.1f})")

            if not significant_features:
                print("  No strongly discriminating features found")

    # Print a summary of all mappings
    print("\n" + "=" * 80)
    print("COMPLETE MAPPING TABLE")
    print("=" * 80)

    # Build a table
    print(f"\n{'Theme':<25}", end="")
    short_fields = ['err', 'warn', 'info', 'hint', 'ok', 'str', 'func', 'kw', 'type', 'num']
    field_map = {
        'err': 'diagnostic_error', 'warn': 'diagnostic_warning',
        'info': 'diagnostic_info', 'hint': 'diagnostic_hint', 'ok': 'diagnostic_ok',
        'str': 'syntax_string', 'func': 'syntax_function',
        'kw': 'syntax_keyword', 'type': 'syntax_type', 'num': 'syntax_number'
    }
    for sf in short_fields:
        print(f"{sf:>6}", end="")
    print()
    print("-" * 85)

    for td in theme_data:
        print(f"{td['name']:<25}", end="")
        for sf in short_fields:
            full_field = field_map[sf]
            if full_field in td['mappings']:
                # Just show the base16 number part
                b16 = td['mappings'][full_field].replace('base', '')
                print(f"{b16:>6}", end="")
            else:
                print(f"{'?':>6}", end="")
        print()


if __name__ == "__main__":
    main()

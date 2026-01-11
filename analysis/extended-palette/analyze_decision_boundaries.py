#!/usr/bin/env python3
"""Find optimal decision boundaries for each field by exhaustive search."""

import yaml
from pathlib import Path
import colorsys
from collections import defaultdict
from itertools import product


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


def find_base16_match(ext_color: str, base16: dict) -> str:
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
    return best_match if best_dist < 50 else None


def extract_features(base16: dict) -> dict:
    colors = {k: base16.get(k, '#000000') for k in
              ['base00', 'base01', 'base02', 'base03', 'base04', 'base05',
               'base06', 'base07', 'base08', 'base09', 'base0A', 'base0B',
               'base0C', 'base0D', 'base0E', 'base0F']}
    hsl = {k: hex_to_hsl(v) for k, v in colors.items()}

    return {
        'dist_0B_0C': color_distance(colors['base0B'], colors['base0C']),
        'dist_09_0A': color_distance(colors['base09'], colors['base0A']),
        'dist_0D_0C': color_distance(colors['base0D'], colors['base0C']),
        'hue_0B': hsl['base0B'][0],
        'hue_0C': hsl['base0C'][0],
        'sat_08': hsl['base08'][1],
        'sat_0B': hsl['base0B'][1],
    }


def load_theme(theme_path: Path) -> dict:
    try:
        with open(theme_path) as f:
            return yaml.safe_load(f)
    except:
        return None


FIELDS = [
    'diagnostic_warning', 'diagnostic_info', 'diagnostic_hint',
    'syntax_comment', 'syntax_string', 'syntax_function', 'syntax_keyword',
    'syntax_type', 'syntax_number', 'syntax_constant',
    'ui_accent', 'ui_border', 'git_change',
]

EXCLUDE = {'github-dark-default', 'github-dark-dimmed'}


def main():
    themes_dir = Path("themes")

    # Collect data
    data = []
    for theme_dir in sorted(themes_dir.iterdir()):
        if not theme_dir.is_dir():
            continue
        theme_yml = theme_dir / "theme.yml"
        if not theme_yml.exists():
            continue
        theme = load_theme(theme_yml)
        if not theme:
            continue
        name = theme_dir.name
        if name in EXCLUDE:
            continue
        if "extended" not in theme or "diagnostic_error" not in theme.get("extended", {}):
            continue

        base16 = theme.get("base16", {})
        extended = theme.get("extended", {})
        features = extract_features(base16)

        mappings = {}
        for field in FIELDS:
            if field in extended:
                match = find_base16_match(extended[field], base16)
                if match:
                    mappings[field] = match

        data.append({'name': name, 'features': features, 'mappings': mappings})

    print("=" * 80)
    print("OPTIMAL DECISION BOUNDARY ANALYSIS")
    print("=" * 80)
    print(f"\nAnalyzing {len(data)} themes")

    feature_names = list(data[0]['features'].keys())

    for field in FIELDS:
        # Get all themes that have this field mapped
        field_data = [(d['features'], d['mappings'][field], d['name'])
                      for d in data if field in d['mappings']]

        if len(field_data) < 5:
            continue

        # Get unique choices
        choices = list(set(m for _, m, _ in field_data))
        if len(choices) < 2:
            continue

        # Only analyze top 2 choices
        choice_counts = defaultdict(int)
        for _, m, _ in field_data:
            choice_counts[m] += 1

        top2 = sorted(choice_counts.items(), key=lambda x: -x[1])[:2]
        if top2[1][1] < 2:  # Need at least 2 samples for minor class
            continue

        choice_a, count_a = top2[0]
        choice_b, count_b = top2[1]

        print(f"\n{'='*60}")
        print(f"FIELD: {field}")
        print(f"  {choice_a}: {count_a}, {choice_b}: {count_b}")
        print(f"{'='*60}")

        # Find best single-feature threshold
        best_accuracy = 0
        best_rule = None

        for feat in feature_names:
            # Get values for each choice
            values_a = [f[feat] for f, m, _ in field_data if m == choice_a]
            values_b = [f[feat] for f, m, _ in field_data if m == choice_b]

            if not values_a or not values_b:
                continue

            # Try different thresholds
            all_values = sorted(set(values_a + values_b))
            for i in range(len(all_values) - 1):
                thresh = (all_values[i] + all_values[i+1]) / 2

                # Try both directions
                for direction in ['>', '<']:
                    correct = 0
                    total = 0
                    for features, mapping, _ in field_data:
                        if mapping not in [choice_a, choice_b]:
                            continue
                        total += 1
                        val = features[feat]
                        if direction == '>':
                            pred = choice_a if val > thresh else choice_b
                        else:
                            pred = choice_a if val < thresh else choice_b
                        if pred == mapping:
                            correct += 1

                    if total > 0:
                        acc = correct / total
                        if acc > best_accuracy:
                            best_accuracy = acc
                            best_rule = (feat, direction, thresh, choice_a, choice_b)

        if best_rule:
            feat, direction, thresh, ca, cb = best_rule
            print(f"\nBest single-feature rule:")
            print(f"  IF {feat} {direction} {thresh:.1f} THEN {ca} ELSE {cb}")
            print(f"  Accuracy: {best_accuracy*100:.1f}%")

            # Show which themes this rule gets wrong
            print(f"\n  Predictions:")
            for features, mapping, name in field_data:
                if mapping not in [choice_a, choice_b]:
                    continue
                val = features[feat]
                if direction == '>':
                    pred = choice_a if val > thresh else choice_b
                else:
                    pred = choice_a if val < thresh else choice_b
                status = "✓" if pred == mapping else "✗"
                print(f"    {status} {name}: {feat}={val:.1f} → pred={pred}, actual={mapping}")


if __name__ == "__main__":
    main()

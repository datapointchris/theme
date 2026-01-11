#!/usr/bin/env python3
"""Generate extended palettes using nearest-neighbor approach.

For each theme, find the most similar theme (by base16 palette) that has
an extended palette, then learn the mapping pattern from that neighbor.

Uses leave-one-out cross-validation: when testing a theme, it's excluded
from the neighbor search.
"""

import yaml
from pathlib import Path
from collections import Counter


def hex_to_rgb(hex_color: str) -> tuple[int, int, int]:
    """Convert hex color to RGB tuple."""
    hex_color = hex_color.lstrip('#').lower()
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))


def color_distance(c1: str, c2: str) -> float:
    """Euclidean distance in RGB space."""
    r1, g1, b1 = hex_to_rgb(c1)
    r2, g2, b2 = hex_to_rgb(c2)
    return ((r1-r2)**2 + (g1-g2)**2 + (b1-b2)**2) ** 0.5


def palette_distance(base16_a: dict, base16_b: dict) -> float:
    """Calculate total distance between two base16 palettes."""
    total = 0
    for key in ['base00', 'base01', 'base02', 'base03', 'base04', 'base05',
                'base06', 'base07', 'base08', 'base09', 'base0A', 'base0B',
                'base0C', 'base0D', 'base0E', 'base0F']:
        c1 = base16_a.get(key, '#000000')
        c2 = base16_b.get(key, '#000000')
        total += color_distance(c1, c2)
    return total


def learn_mapping(neighbor_base16: dict, neighbor_extended: dict) -> dict:
    """Learn which base16 color maps to each extended field.

    Returns a dict like: {'diagnostic_error': 'base08', 'syntax_string': 'base0C', ...}
    """
    mapping = {}

    # All base16 keys to search
    base16_keys = ['base00', 'base01', 'base02', 'base03', 'base04', 'base05',
                   'base06', 'base07', 'base08', 'base09', 'base0A', 'base0B',
                   'base0C', 'base0D', 'base0E', 'base0F']

    for ext_field, ext_color in neighbor_extended.items():
        ext_color = ext_color.lower()

        # Find which base16 color this extended color matches (or is closest to)
        best_match = None
        best_dist = float('inf')

        for b16_key in base16_keys:
            b16_color = neighbor_base16.get(b16_key, '#000000').lower()
            dist = color_distance(ext_color, b16_color)
            if dist < best_dist:
                best_dist = dist
                best_match = b16_key

        # Only learn the mapping if it's a reasonably close match
        # (extended color is derived from a base16 color)
        if best_dist < 100:  # Allow some transformation
            mapping[ext_field] = best_match

    return mapping


def apply_mapping(target_base16: dict, mapping: dict) -> dict:
    """Apply a learned mapping to generate extended palette for target theme."""
    extended = {}

    for ext_field, b16_key in mapping.items():
        if b16_key in target_base16:
            extended[ext_field] = target_base16[b16_key].lower()

    return extended


def load_theme(theme_path: Path) -> dict | None:
    """Load a theme.yml file."""
    try:
        with open(theme_path) as f:
            return yaml.safe_load(f)
    except Exception as e:
        print(f"Error loading {theme_path}: {e}")
        return None


def compare_palettes(predicted: dict, actual: dict, fields_to_compare: set = None) -> dict:
    """Compare predicted vs actual extended palette."""
    results = {
        'exact': [],
        'close': [],
        'different': [],
    }

    for field, pred_color in predicted.items():
        if field not in actual:
            continue
        if fields_to_compare and field not in fields_to_compare:
            continue

        actual_color = actual[field].lower()
        pred_color = pred_color.lower()

        dist = color_distance(pred_color, actual_color)

        entry = {
            'field': field,
            'predicted': pred_color,
            'actual': actual_color,
            'distance': dist,
        }

        if dist < 1:
            results['exact'].append(entry)
        elif dist < 10:
            results['close'].append(entry)
        else:
            results['different'].append(entry)

    return results


# Themes to exclude as neighbors (they use non-standard mappings)
EXCLUDE_AS_NEIGHBORS = {'github-dark-default', 'github-dark-dimmed'}

# Standard extended fields we care about
STANDARD_FIELDS = {
    'diagnostic_error', 'diagnostic_warning', 'diagnostic_info',
    'diagnostic_hint', 'diagnostic_ok',
    'syntax_comment', 'syntax_string', 'syntax_function', 'syntax_keyword',
    'syntax_type', 'syntax_number', 'syntax_constant', 'syntax_operator',
    'syntax_variable', 'syntax_parameter', 'syntax_preproc', 'syntax_special',
    'ui_accent', 'ui_border', 'ui_selection', 'ui_float_bg', 'ui_cursor_line',
    'git_add', 'git_change', 'git_delete',
}


def main():
    themes_dir = Path("themes")

    # Load all themes
    all_themes = {}
    themes_with_extended = {}

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
        all_themes[theme_name] = theme

        if "extended" in theme and "diagnostic_error" in theme.get("extended", {}):
            themes_with_extended[theme_name] = theme

    print("=" * 80)
    print("NEAREST-NEIGHBOR EXTENDED PALETTE GENERATION")
    print("=" * 80)
    print(f"\nThemes with extended (training set): {len(themes_with_extended)}")
    print(f"Excluded as neighbors: {EXCLUDE_AS_NEIGHBORS}")
    print(f"Comparing only {len(STANDARD_FIELDS)} standard fields")

    total_exact = 0
    total_close = 0
    total_different = 0
    total_fields = 0
    all_misses = []

    # Leave-one-out cross-validation
    for test_name, test_theme in themes_with_extended.items():
        test_base16 = test_theme.get("base16", {})
        actual_extended = test_theme.get("extended", {})

        # Find nearest neighbor (excluding self)
        best_neighbor = None
        best_distance = float('inf')

        for neighbor_name, neighbor_theme in themes_with_extended.items():
            if neighbor_name == test_name:
                continue  # Skip self!
            if neighbor_name in EXCLUDE_AS_NEIGHBORS:
                continue  # Skip outlier themes as neighbors

            neighbor_base16 = neighbor_theme.get("base16", {})
            dist = palette_distance(test_base16, neighbor_base16)

            if dist < best_distance:
                best_distance = dist
                best_neighbor = neighbor_name

        if not best_neighbor:
            print(f"\n{test_name}: No neighbor found!")
            continue

        neighbor_theme = themes_with_extended[best_neighbor]
        neighbor_base16 = neighbor_theme.get("base16", {})
        neighbor_extended = neighbor_theme.get("extended", {})

        # Learn mapping from neighbor
        mapping = learn_mapping(neighbor_base16, neighbor_extended)

        # Apply mapping to test theme
        predicted = apply_mapping(test_base16, mapping)

        # Compare only standard fields
        results = compare_palettes(predicted, actual_extended, STANDARD_FIELDS)

        exact = len(results['exact'])
        close = len(results['close'])
        different = len(results['different'])
        total = exact + close + different

        total_exact += exact
        total_close += close
        total_different += different
        total_fields += total

        accuracy = (exact + close) / total * 100 if total > 0 else 0

        if different > 0:
            print(f"\n{test_name} (neighbor: {best_neighbor}, dist={best_distance:.0f})")
            print(f"  {exact} exact, {close} close, {different} WRONG ({accuracy:.0f}% accurate)")
            for entry in results['different'][:5]:  # Show first 5 misses
                all_misses.append({**entry, 'theme': test_name, 'neighbor': best_neighbor})
                print(f"    ✗ {entry['field']}: predicted {entry['predicted']}, actual {entry['actual']}")
            if len(results['different']) > 5:
                print(f"    ... and {len(results['different']) - 5} more")
        else:
            print(f"{test_name} (neighbor: {best_neighbor}) - 100% accurate")

    # Summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)

    overall_accuracy = (total_exact + total_close) / total_fields * 100 if total_fields > 0 else 0

    print(f"\nTotal: {total_exact} exact, {total_close} close, {total_different} different")
    print(f"Overall accuracy: {overall_accuracy:.1f}%")
    print(f"Exact match rate: {total_exact / total_fields * 100:.1f}%")

    # Analyze misses by field
    if all_misses:
        print("\n" + "-" * 40)
        print("MISSES BY FIELD:")
        print("-" * 40)
        field_misses = Counter(m['field'] for m in all_misses)
        for field, count in field_misses.most_common(10):
            print(f"  {field}: {count} misses")


if __name__ == "__main__":
    main()

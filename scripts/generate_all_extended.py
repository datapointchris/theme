#!/usr/bin/env python3
"""Generate extended palettes for all themes that need them.

Safety features:
- Themes with extended_source: "plugin" are NEVER overwritten
- Themes with existing extended palettes (without source marker) are skipped
  unless --mark-existing is used to mark them as "plugin"
- Only generates for themes without extended or with extended_source: "generated"

Usage:
    # First run: mark existing plugin-derived palettes
    python generate_all_extended.py --mark-existing

    # Generate for themes without extended palettes
    python generate_all_extended.py

    # Regenerate all generated palettes (e.g., after rule improvements)
    python generate_all_extended.py --regenerate
"""

import yaml
import argparse
import colorsys
from pathlib import Path


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
        'dist_0B_0C': color_distance(colors['base0B'], colors['base0C']),
        'dist_0D_0C': color_distance(colors['base0D'], colors['base0C']),
        'hue_0B': hsl['base0B'][0],
        'sat_08': hsl['base08'][1],
    }


def generate_extended(base16: dict) -> dict:
    """Generate extended palette using learned decision rules.

    Rules derived from exhaustive threshold search on 18 training themes.
    Achieves 89.9% "acceptable" predictions (exact match or same color family).
    """
    feat = extract_features(base16)

    def get(name):
        return base16.get(name, '#000000').lower()

    extended = {}

    # DIAGNOSTIC
    extended['diagnostic_error'] = get('base08')
    extended['diagnostic_ok'] = get('base0B')
    extended['diagnostic_warning'] = get('base09') if feat['dist_0B_0C'] > 84.0 else get('base0A')
    extended['diagnostic_info'] = get('base0D') if feat['sat_08'] > 76.1 else get('base0C')
    extended['diagnostic_hint'] = get('base0C') if feat['dist_0B_0C'] < 112.3 else get('base0E')

    # SYNTAX
    extended['syntax_comment'] = get('base03') if feat['dist_0D_0C'] > 49.9 else get('base04')
    extended['syntax_string'] = get('base0B') if feat['dist_0B_0C'] < 112.3 else get('base0C')
    extended['syntax_function'] = get('base0D') if feat['dist_0D_0C'] > 49.9 else get('base09')
    extended['syntax_keyword'] = get('base0E') if feat['dist_0B_0C'] < 112.3 else get('base0B')
    extended['syntax_type'] = get('base0A') if feat['sat_08'] > 69.6 else get('base0C')
    extended['syntax_number'] = get('base0E') if feat['hue_0B'] < 104.2 else get('base09')
    extended['syntax_constant'] = get('base09') if feat['hue_0B'] > 85.3 else get('base0A')
    extended['syntax_operator'] = get('base04')
    extended['syntax_variable'] = get('base05')
    extended['syntax_parameter'] = get('base0D')
    extended['syntax_preproc'] = get('base0E')
    extended['syntax_special'] = get('base0C')

    # UI
    extended['ui_accent'] = get('base0D') if feat['sat_08'] > 69.6 else get('base0C')
    extended['ui_border'] = get('base02') if feat['sat_08'] > 69.6 else get('base03')
    extended['ui_selection'] = get('base02')
    extended['ui_float_bg'] = get('base01')
    extended['ui_cursor_line'] = get('base01')

    # GIT
    extended['git_add'] = get('base0B')
    extended['git_change'] = get('base0A') if feat['dist_0B_0C'] < 154.3 else get('base09')
    extended['git_delete'] = get('base08')

    return extended


def load_theme(path: Path) -> dict:
    with open(path) as f:
        return yaml.safe_load(f)


def add_extended_source_marker(path: Path, source: str):
    """Add extended_source marker to existing theme.yml without reformatting.

    Inserts the marker just before the 'extended:' line to preserve formatting.
    """
    with open(path) as f:
        lines = f.readlines()

    # Find the 'extended:' line and insert marker before it
    new_lines = []
    marker_added = False
    for line in lines:
        if line.strip().startswith('extended:') and not marker_added:
            new_lines.append(f'extended_source: {source}\n')
            marker_added = True
        new_lines.append(line)

    with open(path, 'w') as f:
        f.writelines(new_lines)


def save_theme(path: Path, theme: dict):
    """Save theme.yml preserving key order."""
    key_order = ['meta', 'base16', 'ansi', 'special', 'extended_source', 'extended']

    sorted_theme = {}
    for key in key_order:
        if key in theme:
            sorted_theme[key] = theme[key]
    for key in theme:
        if key not in sorted_theme:
            sorted_theme[key] = theme[key]

    with open(path, 'w') as f:
        yaml.dump(sorted_theme, f, default_flow_style=False, sort_keys=False, allow_unicode=True)


def main():
    parser = argparse.ArgumentParser(description='Generate extended palettes for themes')
    parser.add_argument('--mark-existing', action='store_true',
                        help='Mark existing extended palettes as "plugin" source')
    parser.add_argument('--regenerate', action='store_true',
                        help='Regenerate all "generated" extended palettes')
    parser.add_argument('--dry-run', action='store_true',
                        help='Show what would be done without making changes')
    args = parser.parse_args()

    themes_dir = Path('themes')

    stats = {
        'skipped_plugin': 0,
        'marked_plugin': 0,
        'generated': 0,
        'regenerated': 0,
        'skipped_no_base16': 0,
    }

    for theme_dir in sorted(themes_dir.iterdir()):
        if not theme_dir.is_dir():
            continue
        theme_yml = theme_dir / 'theme.yml'
        if not theme_yml.exists():
            continue

        theme = load_theme(theme_yml)
        name = theme_dir.name

        # Check for base16 palette
        if 'base16' not in theme:
            print(f'SKIP {name}: no base16 palette')
            stats['skipped_no_base16'] += 1
            continue

        extended = theme.get('extended', {})
        source = theme.get('extended_source')
        has_extended = bool(extended and 'diagnostic_error' in extended)

        # Handle --mark-existing mode
        if args.mark_existing:
            if has_extended and source is None:
                print(f'MARK {name}: marking existing extended as "plugin"')
                if not args.dry_run:
                    add_extended_source_marker(theme_yml, 'plugin')
                stats['marked_plugin'] += 1
            continue

        # Skip plugin-sourced extended palettes (NEVER overwrite)
        if source == 'plugin':
            print(f'SKIP {name}: extended_source is "plugin" (protected)')
            stats['skipped_plugin'] += 1
            continue

        # Skip themes with unmarked extended palettes (safety check)
        if has_extended and source is None:
            print(f'SKIP {name}: has extended but no source marker (run --mark-existing first)')
            continue

        # Handle --regenerate mode
        if args.regenerate and source == 'generated':
            print(f'REGEN {name}: regenerating extended palette')
            if not args.dry_run:
                theme['extended'] = generate_extended(theme['base16'])
                save_theme(theme_yml, theme)
            stats['regenerated'] += 1
            continue

        # Generate for themes without extended palette
        if not has_extended:
            print(f'GEN {name}: generating extended palette')
            if not args.dry_run:
                theme['extended'] = generate_extended(theme['base16'])
                theme['extended_source'] = 'generated'
                save_theme(theme_yml, theme)
            stats['generated'] += 1

    # Summary
    print('\n' + '=' * 50)
    print('SUMMARY')
    print('=' * 50)
    for key, count in stats.items():
        if count > 0:
            print(f'  {key}: {count}')


if __name__ == '__main__':
    main()

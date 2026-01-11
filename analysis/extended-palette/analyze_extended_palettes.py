#!/usr/bin/env python3
"""Analyze relationships between base16 and extended palettes.

This script compares extended palette colors to base16 colors across all themes
to find patterns that could be used to generate extended palettes for themes
that don't have them.
"""

import os
import yaml
from pathlib import Path
from collections import defaultdict
import colorsys


def hex_to_rgb(hex_color: str) -> tuple[int, int, int]:
    """Convert hex color to RGB tuple."""
    hex_color = hex_color.lstrip('#').lower()
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))


def rgb_to_hex(r: int, g: int, b: int) -> str:
    """Convert RGB to hex."""
    return f"#{r:02x}{g:02x}{b:02x}"


def color_distance(c1: str, c2: str) -> float:
    """Calculate Euclidean distance between two colors in RGB space."""
    r1, g1, b1 = hex_to_rgb(c1)
    r2, g2, b2 = hex_to_rgb(c2)
    return ((r1-r2)**2 + (g1-g2)**2 + (b1-b2)**2) ** 0.5


def colors_match(c1: str, c2: str, threshold: float = 5.0) -> bool:
    """Check if two colors are essentially the same (within threshold)."""
    return color_distance(c1, c2) < threshold


def find_closest_base16(extended_color: str, base16: dict) -> tuple[str, str, float]:
    """Find the closest base16 color to an extended color."""
    min_dist = float('inf')
    closest_name = None
    closest_color = None

    for name, color in base16.items():
        dist = color_distance(extended_color, color)
        if dist < min_dist:
            min_dist = dist
            closest_name = name
            closest_color = color

    return closest_name, closest_color, min_dist


def analyze_color_transform(base_color: str, extended_color: str) -> dict:
    """Analyze how an extended color differs from its base."""
    r1, g1, b1 = hex_to_rgb(base_color)
    r2, g2, b2 = hex_to_rgb(extended_color)

    # Convert to HSL for analysis
    h1, l1, s1 = colorsys.rgb_to_hls(r1/255, g1/255, b1/255)
    h2, l2, s2 = colorsys.rgb_to_hls(r2/255, g2/255, b2/255)

    return {
        "rgb_diff": (r2-r1, g2-g1, b2-b1),
        "hue_diff": (h2-h1) * 360,
        "lightness_diff": (l2-l1) * 100,
        "saturation_diff": (s2-s1) * 100,
        "distance": color_distance(base_color, extended_color),
    }


def load_theme(theme_path: Path) -> dict | None:
    """Load a theme.yml file."""
    try:
        with open(theme_path) as f:
            return yaml.safe_load(f)
    except Exception as e:
        print(f"Error loading {theme_path}: {e}")
        return None


def main():
    themes_dir = Path("themes")

    # Collect all themes with extended palettes
    themes_with_extended = []
    themes_without_extended = []

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
        has_extended = "extended" in theme and "diagnostic_error" in theme.get("extended", {})

        if has_extended:
            themes_with_extended.append((theme_name, theme))
        else:
            themes_without_extended.append((theme_name, theme))

    print("=" * 80)
    print("EXTENDED PALETTE ANALYSIS")
    print("=" * 80)
    print(f"\nThemes WITH extended: {len(themes_with_extended)}")
    print(f"Themes WITHOUT extended: {len(themes_without_extended)}")

    # Define the extended fields we care about
    extended_fields = [
        # Diagnostic
        "diagnostic_error", "diagnostic_warning", "diagnostic_info",
        "diagnostic_hint", "diagnostic_ok",
        # Syntax
        "syntax_comment", "syntax_string", "syntax_function", "syntax_keyword",
        "syntax_type", "syntax_number", "syntax_constant", "syntax_operator",
        "syntax_variable", "syntax_parameter", "syntax_preproc", "syntax_special",
        # UI
        "ui_accent", "ui_border", "ui_selection", "ui_float_bg", "ui_cursor_line",
        # Git
        "git_add", "git_change", "git_delete",
    ]

    # Track mappings: extended_field -> list of (theme, base16_match, distance)
    field_mappings = defaultdict(list)

    print("\n" + "=" * 80)
    print("DETAILED THEME ANALYSIS")
    print("=" * 80)

    for theme_name, theme in themes_with_extended:
        base16 = theme.get("base16", {})
        extended = theme.get("extended", {})

        print(f"\n--- {theme_name} ---")

        # Also include ANSI colors in our search
        ansi = theme.get("ansi", {})
        all_base_colors = {**base16}
        for ansi_name, ansi_color in ansi.items():
            all_base_colors[f"ansi_{ansi_name}"] = ansi_color

        exact_matches = 0
        close_matches = 0
        different = 0

        for field in extended_fields:
            if field not in extended:
                continue

            ext_color = extended[field].lower()
            closest_name, closest_color, dist = find_closest_base16(ext_color, all_base_colors)

            # Determine match type
            if dist < 1:
                match_type = "EXACT"
                exact_matches += 1
            elif dist < 10:
                match_type = "CLOSE"
                close_matches += 1
            else:
                match_type = "DIFF"
                different += 1

            field_mappings[field].append({
                "theme": theme_name,
                "extended_color": ext_color,
                "closest_base16": closest_name,
                "closest_color": closest_color,
                "distance": dist,
                "match_type": match_type,
            })

            if dist >= 10:
                print(f"  {field}: {ext_color} -> {closest_name} ({closest_color}) dist={dist:.1f} [{match_type}]")

        total = exact_matches + close_matches + different
        if total > 0:
            print(f"  Summary: {exact_matches} exact, {close_matches} close, {different} different (of {total})")

    # Analyze patterns across all themes
    print("\n" + "=" * 80)
    print("CROSS-THEME PATTERN ANALYSIS")
    print("=" * 80)

    for field in extended_fields:
        mappings = field_mappings.get(field, [])
        if not mappings:
            continue

        print(f"\n{field}:")

        # Count which base16 colors map to this field
        base16_counts = defaultdict(list)
        for m in mappings:
            # Normalize base16 name (strip ansi_ prefix for counting)
            base_name = m["closest_base16"]
            if base_name.startswith("ansi_"):
                base_name = base_name[5:]
            base16_counts[base_name].append((m["theme"], m["distance"]))

        # Sort by frequency
        sorted_counts = sorted(base16_counts.items(), key=lambda x: -len(x[1]))

        total_themes = len(mappings)
        for base_name, theme_dists in sorted_counts[:3]:  # Top 3
            count = len(theme_dists)
            pct = count / total_themes * 100
            avg_dist = sum(d for _, d in theme_dists) / len(theme_dists)
            exact = sum(1 for _, d in theme_dists if d < 1)
            print(f"  -> {base_name}: {count}/{total_themes} ({pct:.0f}%) avg_dist={avg_dist:.1f} exact={exact}")

    # Generate recommendations
    print("\n" + "=" * 80)
    print("RECOMMENDATIONS FOR AUTO-GENERATION")
    print("=" * 80)

    recommendations = {}
    confidence_levels = {}

    for field in extended_fields:
        mappings = field_mappings.get(field, [])
        if not mappings:
            continue

        # Find most common base16 mapping
        base16_counts = defaultdict(int)
        exact_counts = defaultdict(int)

        for m in mappings:
            base_name = m["closest_base16"]
            if base_name.startswith("ansi_"):
                base_name = base_name[5:]
            base16_counts[base_name] += 1
            if m["distance"] < 1:
                exact_counts[base_name] += 1

        # Find the dominant mapping
        sorted_counts = sorted(base16_counts.items(), key=lambda x: -x[1])
        if sorted_counts:
            dominant_base, dominant_count = sorted_counts[0]
            total = len(mappings)
            pct = dominant_count / total * 100
            exact_pct = exact_counts[dominant_base] / dominant_count * 100 if dominant_count > 0 else 0

            # Determine confidence
            if pct >= 90 and exact_pct >= 80:
                confidence = "HIGH"
            elif pct >= 70:
                confidence = "MEDIUM"
            elif pct >= 50:
                confidence = "LOW"
            else:
                confidence = "UNCERTAIN"

            recommendations[field] = dominant_base
            confidence_levels[field] = confidence

    print("\nRecommended base16 mappings for auto-generation:")
    print("-" * 60)

    for category in ["diagnostic", "syntax", "ui", "git"]:
        print(f"\n{category.upper()}:")
        for field, base in sorted(recommendations.items()):
            if field.startswith(category):
                conf = confidence_levels[field]
                print(f"  {field}: {base} [{conf}]")

    # Show themes without extended
    print("\n" + "=" * 80)
    print("THEMES NEEDING EXTENDED PALETTES")
    print("=" * 80)
    for theme_name, _ in themes_without_extended:
        print(f"  - {theme_name}")


if __name__ == "__main__":
    main()

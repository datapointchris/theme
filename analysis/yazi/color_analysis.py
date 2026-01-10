#!/usr/bin/env python3
"""
Deep algorithmic analysis of yazi theme colors.
Finds mathematical relationships between hand-crafted yazi colors and theme.yml source colors.
"""

import colorsys
import math
from dataclasses import dataclass


@dataclass
class Color:
    hex: str
    name: str = ""

    @property
    def rgb(self) -> tuple[int, int, int]:
        h = self.hex.lstrip('#')
        return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

    @property
    def hsl(self) -> tuple[float, float, float]:
        r, g, b = [x / 255.0 for x in self.rgb]
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        return (h * 360, s * 100, l * 100)

    def lightness(self) -> float:
        """Perceptual lightness (0-100)"""
        return self.hsl[2]

    def saturation(self) -> float:
        """Saturation (0-100)"""
        return self.hsl[1]

    def hue(self) -> float:
        """Hue (0-360)"""
        return self.hsl[0]


def color_distance(c1: Color, c2: Color) -> float:
    """Simple RGB Euclidean distance"""
    r1, g1, b1 = c1.rgb
    r2, g2, b2 = c2.rgb
    return math.sqrt((r1-r2)**2 + (g1-g2)**2 + (b1-b2)**2)


def find_closest_match(target: Color, palette: dict[str, Color]) -> tuple[str, Color, float]:
    """Find the closest color in palette to target"""
    best_name = None
    best_color = None
    best_dist = float('inf')

    for name, color in palette.items():
        dist = color_distance(target, color)
        if dist < best_dist:
            best_dist = dist
            best_name = name
            best_color = color

    return best_name, best_color, best_dist


def analyze_relationship(target: Color, source: Color) -> dict:
    """Analyze the relationship between target and source color"""
    t_h, t_s, t_l = target.hsl
    s_h, s_s, s_l = source.hsl

    return {
        "lightness_diff": t_l - s_l,
        "saturation_diff": t_s - s_s,
        "hue_diff": min(abs(t_h - s_h), 360 - abs(t_h - s_h)),
        "is_lighter": t_l > s_l,
        "is_brighter": t_s > s_s,
    }


# ============================================================================
# THEME DATA
# ============================================================================

# Gruvbox theme.yml palette
gruvbox_palette = {
    "BASE00": Color("#1d2021", "bg_hard"),
    "BASE01": Color("#3c3836", "bg1"),
    "BASE02": Color("#504945", "bg2"),
    "BASE03": Color("#665c54", "bg3"),
    "BASE04": Color("#928374", "gray"),
    "BASE05": Color("#ebdbb2", "fg1"),
    "BASE06": Color("#d5c4a1", "fg2"),
    "BASE07": Color("#fbf1c7", "fg0"),
    "BASE08": Color("#fb4934", "bright_red"),
    "BASE09": Color("#fe8019", "orange"),
    "BASE0A": Color("#fabd2f", "bright_yellow"),
    "BASE0B": Color("#b8bb26", "bright_green"),
    "BASE0C": Color("#8ec07c", "bright_cyan"),
    "BASE0D": Color("#83a598", "bright_blue"),
    "BASE0E": Color("#d3869b", "bright_purple"),
    "BASE0F": Color("#d65d0e", "brown"),
    # Extended
    "ANSI_WHITE": Color("#a89984", "fg4"),
    "BRIGHT_GREEN": Color("#b8bb26"),
    "BRIGHT_YELLOW": Color("#fabd2f"),
    "BRIGHT_CYAN": Color("#8ec07c"),
}

# Gruvbox yazi hand-crafted colors
gruvbox_yazi = {
    "cwd": Color("#83a598"),
    "marker_copied": Color("#8ec07c"),
    "marker_cut": Color("#d3869b"),
    "marker_marked": Color("#83a598"),
    "marker_selected": Color("#fbf1c7"),
    "tab_active_bg": Color("#a89984"),
    "tab_inactive_bg": Color("#504945"),
    "mode_normal_bg": Color("#a89984"),
    "mode_select_bg": Color("#fe8019"),
    "mode_unset_bg": Color("#b8bb26"),
    "perm_read": Color("#b8bb26"),
    "perm_write": Color("#fb4934"),
    "perm_exec": Color("#b8bb26"),
    "notify_info": Color("#8ec07c"),
    "notify_warn": Color("#fbf1c7"),
    "notify_error": Color("#d3869b"),
    "filetype_images": Color("#d3869b"),
    "filetype_media": Color("#fabd2f"),
    "filetype_archives": Color("#fb4934"),
    "filetype_dirs": Color("#83a598"),
}

# Kanagawa theme.yml palette
kanagawa_palette = {
    "BASE00": Color("#1f1f28", "sumiInk3"),
    "BASE01": Color("#16161d", "sumiInk0"),
    "BASE02": Color("#2d4f67", "waveBlue2"),
    "BASE03": Color("#727169", "fujiGray"),
    "BASE04": Color("#c8c093", "oldWhite"),
    "BASE05": Color("#dcd7ba", "fujiWhite"),
    "BASE06": Color("#c8c093", "oldWhite"),
    "BASE07": Color("#717c7c", "katanaGray"),
    "BASE08": Color("#c34043", "autumnRed"),
    "BASE09": Color("#ffa066", "surimiOrange"),
    "BASE0A": Color("#c0a36e", "boatYellow2"),
    "BASE0B": Color("#76946a", "autumnGreen"),
    "BASE0C": Color("#6a9589", "waveAqua1"),
    "BASE0D": Color("#7e9cd8", "crystalBlue"),
    "BASE0E": Color("#957fb8", "oniViolet"),
    "BASE0F": Color("#d27e99", "sakuraPink"),
    # Extended / ANSI bright
    "BRIGHT_GREEN": Color("#98bb6c", "springGreen"),
    "BRIGHT_YELLOW": Color("#e6c384", "carpYellow"),
    "BRIGHT_BLUE": Color("#7fb4ca", "springBlue"),
    "BRIGHT_CYAN": Color("#7aa89f", "waveAqua2"),
    "WAVE_RED": Color("#e46876", "waveRed"),
    "PEACH_RED": Color("#ff5d62", "peachRed"),
    "SUMI_INK4": Color("#2a2a37"),
}

# Kanagawa yazi hand-crafted colors
kanagawa_yazi = {
    "cwd": Color("#e6c384"),
    "marker_copied": Color("#98bb6c"),
    "marker_cut": Color("#e46876"),
    "marker_marked": Color("#957fb8"),
    "marker_selected": Color("#ffa066"),
    "tab_active_bg": Color("#7e9cd8"),
    "tab_inactive_bg": Color("#2a2a37"),
    "mode_normal_bg": Color("#7e9cd8"),
    "mode_select_bg": Color("#957fb8"),
    "mode_unset_bg": Color("#e6c384"),
    "perm_type": Color("#98bb6c"),
    "perm_read": Color("#e6c384"),
    "perm_write": Color("#ff5d62"),
    "perm_exec": Color("#7aa89f"),
    "notify_info": Color("#98bb6c"),
    "notify_warn": Color("#e6c384"),
    "notify_error": Color("#ff5d62"),
    "filetype_images": Color("#e6c384"),
    "filetype_media": Color("#957fb8"),
    "filetype_archives": Color("#e46876"),
    "filetype_dirs": Color("#7e9cd8"),
}

# Rose Pine theme.yml palette
rosepine_palette = {
    "BASE00": Color("#191724", "base"),
    "BASE01": Color("#1f1d2e", "surface"),
    "BASE02": Color("#26233a", "overlay"),
    "BASE03": Color("#6e6a86", "muted"),
    "BASE04": Color("#908caa", "subtle"),
    "BASE05": Color("#e0def4", "text"),
    "BASE06": Color("#e0def4", "text"),
    "BASE07": Color("#524f67", "highlight_high"),
    "BASE08": Color("#eb6f92", "love"),
    "BASE09": Color("#f6c177", "gold"),
    "BASE0A": Color("#ebbcba", "rose"),
    "BASE0B": Color("#31748f", "pine"),
    "BASE0C": Color("#9ccfd8", "foam"),
    "BASE0D": Color("#c4a7e7", "iris"),
    "BASE0E": Color("#eb6f92", "love"),
    "BASE0F": Color("#95b1ac", "leaf"),
}

# Rose Pine yazi hand-crafted colors
rosepine_yazi = {
    "cwd": Color("#9ccfd8"),
    "hovered_bg": Color("#26233a"),
    "hovered_fg": Color("#e0def4"),
    "marker_copied": Color("#f6c177"),
    "marker_cut": Color("#B4637A"),
    "marker_selected": Color("#9ccfd8"),
    "tab_active_bg": Color("#191724"),
    "tab_inactive_bg": Color("#2A273F"),
    "mode_normal_bg": Color("#ebbcba"),
    "mode_select_bg": Color("#9ccfd8"),
    "mode_unset_bg": Color("#b4637a"),
    "perm_type": Color("#31748f"),
    "perm_read": Color("#f6c177"),
    "perm_write": Color("#B4637A"),
    "perm_exec": Color("#9ccfd8"),
    "filetype_images": Color("#9ccfd8"),
    "filetype_media": Color("#f6c177"),
    "filetype_archives": Color("#eb6f92"),
    "filetype_dirs": Color("#524f67"),
}


def analyze_theme(name: str, palette: dict, yazi_colors: dict):
    print(f"\n{'='*60}")
    print(f"THEME: {name}")
    print(f"{'='*60}\n")

    results = []

    for element, target_color in yazi_colors.items():
        match_name, match_color, distance = find_closest_match(target_color, palette)

        if distance < 1:
            match_type = "EXACT"
        elif distance < 20:
            match_type = "CLOSE"
        else:
            match_type = "DIFFERENT"

        rel = analyze_relationship(target_color, match_color)

        results.append({
            "element": element,
            "yazi_color": target_color.hex,
            "closest": match_name,
            "closest_hex": match_color.hex,
            "distance": distance,
            "match_type": match_type,
            "lightness_diff": rel["lightness_diff"],
            "saturation_diff": rel["saturation_diff"],
        })

        print(f"{element:20} | {target_color.hex} → {match_name:15} ({match_color.hex}) | dist={distance:5.1f} | {match_type}")
        if match_type != "EXACT":
            print(f"                       L: {rel['lightness_diff']:+.1f}%  S: {rel['saturation_diff']:+.1f}%")

    # Summary
    exact = sum(1 for r in results if r["match_type"] == "EXACT")
    close = sum(1 for r in results if r["match_type"] == "CLOSE")
    diff = sum(1 for r in results if r["match_type"] == "DIFFERENT")

    print(f"\nSUMMARY: {exact} exact, {close} close, {diff} different out of {len(results)}")
    print(f"Match rate: {(exact + close) / len(results) * 100:.1f}%")

    return results


def find_patterns():
    """Find common patterns across all themes"""
    print("\n" + "="*60)
    print("CROSS-THEME PATTERN ANALYSIS")
    print("="*60)

    # Analyze which base16 slot each element uses
    patterns = {
        "marker_copied": [],
        "marker_cut": [],
        "mode_normal_bg": [],
        "filetype_dirs": [],
        "perm_read": [],
        "perm_write": [],
        "perm_exec": [],
    }

    themes = [
        ("gruvbox", gruvbox_palette, gruvbox_yazi),
        ("kanagawa", kanagawa_palette, kanagawa_yazi),
        ("rosepine", rosepine_palette, rosepine_yazi),
    ]

    for theme_name, palette, yazi in themes:
        for element in patterns.keys():
            if element in yazi:
                match_name, _, dist = find_closest_match(yazi[element], palette)
                patterns[element].append((theme_name, match_name, dist < 20))

    print("\nElement → Which palette color is used:")
    for element, matches in patterns.items():
        print(f"\n{element}:")
        for theme, slot, is_match in matches:
            marker = "✓" if is_match else "~"
            print(f"  {theme:12} → {slot:15} {marker}")


def find_brightness_rules():
    """Analyze if themes use 'brightest' or 'normal' variants"""
    print("\n" + "="*60)
    print("BRIGHTNESS VARIANT ANALYSIS")
    print("="*60)

    print("\nKANAGAWA: Autumn (normal) vs Spring (bright) variants")
    print("-" * 50)

    autumn_spring = [
        ("green", "#76946a", "#98bb6c", "autumnGreen", "springGreen"),
        ("yellow", "#c0a36e", "#e6c384", "boatYellow2", "carpYellow"),
        ("cyan", "#6a9589", "#7aa89f", "waveAqua1", "waveAqua2"),
        ("blue", "#7e9cd8", "#7fb4ca", "crystalBlue", "springBlue"),
        ("red", "#c34043", "#e46876", "autumnRed", "waveRed"),
    ]

    for name, autumn, spring, a_name, s_name in autumn_spring:
        a_color = Color(autumn, a_name)
        s_color = Color(spring, s_name)
        l_diff = s_color.lightness() - a_color.lightness()
        s_diff = s_color.saturation() - a_color.saturation()
        print(f"{name:8}: {a_name:12} L={a_color.lightness():5.1f} → {s_name:12} L={s_color.lightness():5.1f} (Δ={l_diff:+.1f})")

    print("\nKanagawa yazi uses:")
    uses_spring = ["marker_copied→springGreen", "cwd→carpYellow", "perm_exec→waveAqua2"]
    uses_autumn = ["marker_cut→waveRed (not autumn)"]
    print(f"  BRIGHT variants: {', '.join(uses_spring)}")
    print(f"  SPECIAL cases: {', '.join(uses_autumn)}")

    print("\n→ RULE: For 'positive' elements (copied, info), use BRIGHT variant")
    print("→ RULE: For 'warning' elements (cut), use INTERMEDIATE variant (not base08)")


if __name__ == "__main__":
    # Analyze each theme
    analyze_theme("GRUVBOX", gruvbox_palette, gruvbox_yazi)
    analyze_theme("KANAGAWA", kanagawa_palette, kanagawa_yazi)
    analyze_theme("ROSE PINE", rosepine_palette, rosepine_yazi)

    # Find patterns
    find_patterns()
    find_brightness_rules()

    print("\n" + "="*60)
    print("ALGORITHMIC RULES DISCOVERED")
    print("="*60)
    print("""
1. BRIGHTNESS SELECTION:
   - "Positive" elements (copied, info, exec) → use BRIGHT/SPRING variant
   - "Warning" elements (cut, error) → use INTERMEDIATE variant (not darkest)
   - "Neutral" elements (borders, bg) → use BASE variant

2. MODE INDICATOR:
   - Signature themes → use signature color (rose-pine: rose, kanagawa: crystalBlue)
   - Neutral themes → use muted gray (gruvbox: fg4/BASE04)

3. SEMANTIC OVERRIDES:
   - perm_write → ALWAYS red family (BASE08 or variant)
   - filetype_archives → ALWAYS red family
   - filetype_dirs → PRIMARY accent color

4. CONTRAST HIERARCHY:
   - marker_selected → HIGHEST contrast (often brightest white)
   - tab_active → MORE prominent than inactive
   - tab_inactive → ONE layer darker than active

5. COLOR FAMILY RULES:
   - If theme has "bright" ANSI variants → prefer them for positive actions
   - If theme has extended palette → check for intermediate variants
""")

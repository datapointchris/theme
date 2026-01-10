#!/usr/bin/env python3
"""
Analyze color transformations used in hand-crafted themes.
Find the mathematical relationships for generating derived colors.
"""

import colorsys
import math


def hex_to_hsl(hex_color: str) -> tuple[float, float, float]:
    """Convert hex to HSL (H: 0-360, S: 0-100, L: 0-100)"""
    h = hex_color.lstrip('#')
    r, g, b = tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    return (h * 360, s * 100, l * 100)


def hsl_to_hex(h: float, s: float, l: float) -> str:
    """Convert HSL to hex"""
    h, s, l = h / 360, s / 100, l / 100
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return f"#{int(r*255):02x}{int(g*255):02x}{int(b*255):02x}"


def analyze_transformation(source: str, target: str, source_name: str, target_name: str):
    """Analyze the transformation from source to target color"""
    s_h, s_s, s_l = hex_to_hsl(source)
    t_h, t_s, t_l = hex_to_hsl(target)

    print(f"\n{source_name} ({source}) → {target_name} ({target})")
    print(f"  Source HSL: H={s_h:.1f}° S={s_s:.1f}% L={s_l:.1f}%")
    print(f"  Target HSL: H={t_h:.1f}° S={t_s:.1f}% L={t_l:.1f}%")
    print(f"  Delta:      ΔH={t_h-s_h:+.1f}° ΔS={t_s-s_s:+.1f}% ΔL={t_l-s_l:+.1f}%")

    # Calculate relative changes
    if s_l > 0:
        l_ratio = t_l / s_l
        print(f"  Lightness ratio: {l_ratio:.2f}x ({(l_ratio-1)*100:+.1f}%)")
    if s_s > 0:
        s_ratio = t_s / s_s
        print(f"  Saturation ratio: {s_ratio:.2f}x ({(s_ratio-1)*100:+.1f}%)")

    return {
        "h_diff": t_h - s_h,
        "s_diff": t_s - s_s,
        "l_diff": t_l - s_l,
        "l_ratio": t_l / s_l if s_l > 0 else 1,
        "s_ratio": t_s / s_s if s_s > 0 else 1,
    }


print("=" * 60)
print("ROSE PINE: Love variants analysis")
print("=" * 60)

# Rose Pine love colors
love_base = "#eb6f92"  # BASE08 - standard love
love_dark = "#B4637A"  # Used in hand-crafted yazi for cut/write

result = analyze_transformation(love_base, love_dark, "love (base)", "love (dark)")

# Can we derive this?
print("\n" + "-" * 40)
print("DERIVATION TEST: Can we recreate the dark variant?")
print("-" * 40)

s_h, s_s, s_l = hex_to_hsl(love_base)
# Apply the discovered transformation
new_l = s_l * result["l_ratio"]
new_s = s_s * result["s_ratio"]
derived = hsl_to_hex(s_h, new_s, new_l)
print(f"Original love:     {love_base}")
print(f"Target dark:       {love_dark}")
print(f"Derived (ratio):   {derived}")

# Try simpler rules
print("\n" + "-" * 40)
print("SIMPLER RULES TEST")
print("-" * 40)

# Rule: L * 0.85, S * 0.60
simple_l = s_l * 0.85
simple_s = s_s * 0.60
simple = hsl_to_hex(s_h, simple_s, simple_l)
print(f"Rule: L*0.85, S*0.60 → {simple}")

# Rule: L - 10, S - 30
offset_l = s_l - 10
offset_s = s_s - 30
offset = hsl_to_hex(s_h, offset_s, offset_l)
print(f"Rule: L-10, S-30    → {offset}")


print("\n" + "=" * 60)
print("KANAGAWA: Autumn vs Spring (bright) variants")
print("=" * 60)

pairs = [
    ("#76946a", "#98bb6c", "autumnGreen", "springGreen"),
    ("#c0a36e", "#e6c384", "boatYellow", "carpYellow"),
    ("#6a9589", "#7aa89f", "waveAqua1", "waveAqua2"),
    ("#c34043", "#e46876", "autumnRed", "waveRed"),
    ("#c34043", "#ff5d62", "autumnRed", "peachRed"),
]

for base, bright, base_name, bright_name in pairs:
    analyze_transformation(base, bright, base_name, bright_name)


print("\n" + "=" * 60)
print("PATTERN DISCOVERY: How to select bright variant")
print("=" * 60)

print("""
FINDINGS:

1. KANAGAWA BRIGHT SELECTION:
   - Spring variants are ~8-14 L% brighter than Autumn
   - Saturation varies (+5 to +35%)
   - Hue shifts slightly (-3° to +3°)

   RULE: If ANSI_BRIGHT_* exists and is 5-15 L% brighter → use it for positive elements

2. ROSE PINE DARK SELECTION:
   - Dark love is ~13 L% darker and ~40 S% less saturated
   - Same hue

   RULE: For "muted danger" elements, reduce L by 10-15% and S by 30-40%

3. GRUVBOX MUTED GRAY:
   - Uses fg4 (#a89984) which is in extended palette
   - This is ANSI white (ansi.white) - the "muted foreground"

   RULE: For "neutral mode" indicator, use ANSI_WHITE (the muted white, not bright)

ALGORITHMIC APPROACH:
---------------------

def get_positive_color(theme, base_color, color_family):
    '''Get color for positive elements (copied, info, exec)'''
    # Check if ANSI bright variant exists and is brighter
    bright_variant = theme.ansi.get(f"bright_{color_family}")
    if bright_variant and is_brighter(bright_variant, base_color, threshold=5):
        return bright_variant
    return base_color

def get_muted_color(theme, base_color):
    '''Get color for muted/danger elements (cut, warning)'''
    # Check for extended intermediate variant
    extended = theme.extended.get(f"wave_{color_family}")
    if extended and is_intermediate(extended, base_color):
        return extended
    # Otherwise reduce lightness and saturation
    return adjust_hsl(base_color, l_mult=0.85, s_mult=0.60)

def get_mode_indicator_color(theme):
    '''Get color for mode_normal background'''
    if has_signature_color(theme):
        return theme.signature_color  # rose, crystalBlue, etc.
    else:
        return theme.ansi.white  # muted gray
""")


print("\n" + "=" * 60)
print("IMPLEMENTATION RECOMMENDATION")
print("=" * 60)

print("""
Instead of hardcoding colors, the generator should:

1. DETECT available color variants:
   - ANSI bright colors (ANSI_BRIGHT_*)
   - Extended palette colors (EXTENDED_*)
   - Calculate lightness/saturation of each

2. CLASSIFY elements by semantic role:
   - Positive: marker_copied, notify_info, perm_exec
   - Negative: marker_cut, notify_error, perm_write
   - Neutral: borders, tabs, mode_normal
   - Highlight: marker_selected, find_keyword

3. APPLY selection rules:
   - Positive → prefer BRIGHTEST available variant
   - Negative → prefer INTERMEDIATE variant (not darkest base08)
   - Neutral → prefer MUTED variant (ANSI_WHITE or BASE04)
   - Highlight → prefer MAXIMUM contrast (BASE07 or BASE09)

4. SIGNATURE COLOR detection:
   - If BASE0A has unique name (rose, gold) → it's signature
   - If theme name matches a color → that's signature
   - Use signature for mode_normal.bg

This allows the generator to work with ANY theme, not just known ones.
""")

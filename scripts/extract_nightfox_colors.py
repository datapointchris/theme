#!/usr/bin/env python3
"""Extract extended palette colors from nightfox.nvim themes.

Computes exact hex values for diagnostic, syntax, UI, and git colors
based on the nightfox palette definitions.
"""

import colorsys
import re
from dataclasses import dataclass


@dataclass
class Shade:
    """Color with bright and dim variants."""
    base: str
    bright: str
    dim: str


def hex_to_rgb(hex_color: str) -> tuple[int, int, int]:
    """Convert hex to RGB tuple."""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))


def rgb_to_hex(rgb: tuple[int, int, int]) -> str:
    """Convert RGB tuple to hex."""
    return "#{:02x}{:02x}{:02x}".format(*[max(0, min(255, int(c))) for c in rgb])


def brighten(hex_color: str, ratio: float) -> str:
    """Brighten a color by ratio (0.0 to 1.0)."""
    r, g, b = hex_to_rgb(hex_color)
    h, l, s = colorsys.rgb_to_hls(r/255, g/255, b/255)
    # Brighten by moving lightness toward 1.0
    new_l = l + (1.0 - l) * ratio
    new_r, new_g, new_b = colorsys.hls_to_rgb(h, new_l, s)
    return rgb_to_hex((int(new_r * 255), int(new_g * 255), int(new_b * 255)))


def darken(hex_color: str, ratio: float) -> str:
    """Darken a color by ratio (0.0 to 1.0)."""
    r, g, b = hex_to_rgb(hex_color)
    h, l, s = colorsys.rgb_to_hls(r/255, g/255, b/255)
    # Darken by moving lightness toward 0.0
    new_l = l * (1.0 - abs(ratio))
    new_r, new_g, new_b = colorsys.hls_to_rgb(h, new_l, s)
    return rgb_to_hex((int(new_r * 255), int(new_g * 255), int(new_b * 255)))


def make_shade(base: str, bright_ratio: float, dim_ratio: float) -> Shade:
    """Create a Shade with computed bright and dim variants."""
    return Shade(
        base=base,
        bright=brighten(base, bright_ratio),
        dim=darken(base, abs(dim_ratio))
    )


# Carbonfox palette
CARBONFOX = {
    "name": "carbonfox",
    "palette": {
        "black": make_shade("#282828", 0.15, -0.15),
        "red": make_shade("#EE5396", 0.15, -0.15),
        "green": make_shade("#25be6a", 0.15, -0.15),
        "yellow": make_shade("#08BDBA", 0.15, -0.15),
        "blue": make_shade("#78A9FF", 0.15, -0.15),
        "magenta": make_shade("#BE95FF", 0.15, -0.15),
        "cyan": make_shade("#33B1FF", 0.15, -0.15),
        "white": make_shade("#dfdfe0", 0.15, -0.15),
        "orange": make_shade("#3DDBD9", 0.15, -0.15),
        "pink": make_shade("#FF7EB6", 0.15, -0.15),
    },
    "comment": "#6e6e6e",  # bg:blend(fg, 0.4) ≈ this
    "bg0": "#101010",
    "bg1": "#161616",
    "bg2": "#1e1e1e",
    "bg3": "#262626",
    "bg4": "#393939",
    "fg0": "#f7f7f7",
    "fg1": "#f2f4f8",
    "fg2": "#b6b8bb",
    "fg3": "#7a7c7e",
    "sel0": "#2a2a2a",
    "sel1": "#525253",
}

# Nightfox palette
NIGHTFOX = {
    "name": "nightfox",
    "palette": {
        "black": make_shade("#393b44", 0.15, -0.15),
        "red": make_shade("#c94f6d", 0.15, -0.15),
        "green": make_shade("#81b29a", 0.10, -0.15),
        "yellow": make_shade("#dbc074", 0.15, -0.15),
        "blue": make_shade("#719cd6", 0.15, -0.15),
        "magenta": make_shade("#9d79d6", 0.30, -0.15),
        "cyan": make_shade("#63cdcf", 0.15, -0.15),
        "white": make_shade("#dfdfe0", 0.15, -0.15),
        "orange": make_shade("#f4a261", 0.15, -0.15),
        "pink": make_shade("#d67ad2", 0.15, -0.15),
    },
    "comment": "#738091",
    "bg0": "#131a24",
    "bg1": "#192330",
    "bg2": "#212e3f",
    "bg3": "#29394f",
    "bg4": "#39506d",
    "fg0": "#d6d6d7",
    "fg1": "#cdcecf",
    "fg2": "#aeafb0",
    "fg3": "#71839b",
    "sel0": "#2b3b51",
    "sel1": "#3c5372",
}

# Terafox palette (has explicit bright/dim values)
TERAFOX = {
    "name": "terafox",
    "palette": {
        "black": Shade("#2F3239", "#4e5157", "#282a30"),
        "red": Shade("#e85c51", "#eb746b", "#c54e45"),
        "green": Shade("#7aa4a1", "#8eb2af", "#688b89"),
        "yellow": Shade("#fda47f", "#fdb292", "#d78b6c"),
        "blue": Shade("#5a93aa", "#73a3b7", "#4d7d90"),
        "magenta": Shade("#ad5c7c", "#b97490", "#934e69"),
        "cyan": Shade("#a1cdd8", "#afd4de", "#89aeb8"),
        "white": Shade("#ebebeb", "#eeeeee", "#c8c8c8"),
        "orange": Shade("#ff8349", "#ff9664", "#d96f3e"),
        "pink": Shade("#cb7985", "#d38d97", "#ad6771"),
    },
    "comment": "#6d7f8b",
    "bg0": "#0f1c1e",
    "bg1": "#152528",
    "bg2": "#1d3337",
    "bg3": "#254147",
    "bg4": "#2d4f56",
    "fg0": "#eaeeee",
    "fg1": "#e6eaea",
    "fg2": "#cbd9d8",
    "fg3": "#587b7b",
    "sel0": "#293e40",
    "sel1": "#425e5e",
}


def generate_extended_palette(theme: dict) -> dict:
    """Generate extended palette from nightfox theme definition."""
    pal = theme["palette"]

    # Carbonfox uses different diagnostic mappings than nightfox/terafox
    if theme["name"] == "carbonfox":
        diag = {
            "diagnostic_error": pal["red"].base,
            "diagnostic_warning": pal["magenta"].base,  # carbonfox uses magenta for warn
            "diagnostic_info": pal["blue"].base,
            "diagnostic_hint": pal["orange"].base,
            "diagnostic_ok": pal["green"].base,
        }
    else:
        # nightfox and terafox use standard mapping
        diag = {
            "diagnostic_error": pal["red"].base,
            "diagnostic_warning": pal["yellow"].base,
            "diagnostic_info": pal["blue"].base,
            "diagnostic_hint": pal["green"].base,
            "diagnostic_ok": pal["green"].base,
        }

    # Syntax colors (same for all nightfox themes)
    syntax = {
        "syntax_comment": theme["comment"],
        "syntax_string": pal["green"].base,
        "syntax_function": pal["blue"].bright,
        "syntax_keyword": pal["magenta"].base,
        "syntax_type": pal["yellow"].base,
        "syntax_number": pal["orange"].base,
        "syntax_constant": pal["orange"].bright,
        "syntax_operator": theme["fg2"],
        "syntax_variable": pal["white"].base,
        "syntax_parameter": pal["cyan"].base,
        "syntax_field": pal["blue"].base,
        "syntax_conditional": pal["magenta"].bright,
        "syntax_preproc": pal["pink"].bright,
        "syntax_regex": pal["yellow"].bright,
    }

    # UI colors
    ui = {
        "ui_accent": pal["blue"].base,
        "ui_border": theme["bg4"],
        "ui_selection": theme["sel0"],
        "ui_float_bg": theme["bg0"],
        "ui_cursor_line": theme["bg3"],
    }

    # Git colors
    git = {
        "git_add": pal["green"].base,
        "git_change": pal["yellow"].base,
        "git_delete": pal["red"].base,
    }

    return {**diag, **syntax, **ui, **git}


def format_yaml_extended(extended: dict) -> str:
    """Format extended palette as YAML."""
    lines = ["extended:"]

    # Group by prefix
    groups = {}
    for key, value in sorted(extended.items()):
        prefix = key.split("_")[0]
        if prefix not in groups:
            groups[prefix] = []
        groups[prefix].append((key, value))

    for prefix in ["diagnostic", "syntax", "ui", "git"]:
        if prefix in groups:
            lines.append(f"  # {prefix.title()} colors")
            for key, value in groups[prefix]:
                lines.append(f'  {key}: "{value}"')
            lines.append("")

    return "\n".join(lines)


def main():
    for theme in [CARBONFOX, NIGHTFOX, TERAFOX]:
        print(f"\n{'='*60}")
        print(f"Theme: {theme['name']}")
        print('='*60)

        extended = generate_extended_palette(theme)

        print("\n# Computed extended palette colors:")
        for key, value in sorted(extended.items()):
            print(f"  {key}: {value}")

        print("\n# YAML format:")
        print(format_yaml_extended(extended))


if __name__ == "__main__":
    main()

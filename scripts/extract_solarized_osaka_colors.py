#!/usr/bin/env python3
"""Extract extended palette colors from solarized-osaka.nvim.

Converts HSL values to hex and maps them to our extended palette format.
"""

import colorsys


def hsl_to_hex(h: float, s: float, l: float) -> str:
    """Convert HSL to hex. H is 0-360, S and L are 0-100."""
    h = h / 360.0
    s = s / 100.0
    l = l / 100.0
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return "#{:02x}{:02x}{:02x}".format(int(r * 255), int(g * 255), int(b * 255))


# Solarized Osaka default (dark) palette from colors.lua
PALETTE = {
    # Base colors
    "base04": hsl_to_hex(192, 100, 5),
    "base03": hsl_to_hex(192, 100, 11),
    "base02": hsl_to_hex(192, 81, 14),
    "base01": hsl_to_hex(194, 14, 40),
    "base00": hsl_to_hex(196, 13, 45),
    "base0": hsl_to_hex(186, 8, 65),
    "base1": hsl_to_hex(180, 7, 70),
    "base2": hsl_to_hex(46, 42, 88),
    "base3": hsl_to_hex(44, 87, 94),
    "base4": hsl_to_hex(0, 0, 100),

    # Yellow
    "yellow": hsl_to_hex(45, 100, 35),
    "yellow100": hsl_to_hex(47, 100, 80),
    "yellow300": hsl_to_hex(45, 100, 50),
    "yellow500": hsl_to_hex(45, 100, 35),
    "yellow700": hsl_to_hex(45, 100, 20),
    "yellow900": hsl_to_hex(46, 100, 10),

    # Orange
    "orange": hsl_to_hex(18, 80, 44),
    "orange100": hsl_to_hex(17, 100, 70),
    "orange300": hsl_to_hex(17, 94, 51),
    "orange500": hsl_to_hex(18, 80, 44),
    "orange700": hsl_to_hex(18, 81, 35),
    "orange900": hsl_to_hex(18, 80, 20),

    # Red
    "red": hsl_to_hex(1, 71, 52),
    "red100": hsl_to_hex(1, 100, 80),
    "red300": hsl_to_hex(1, 90, 64),
    "red500": hsl_to_hex(1, 71, 52),
    "red700": hsl_to_hex(1, 71, 42),
    "red900": hsl_to_hex(1, 71, 20),

    # Magenta
    "magenta": hsl_to_hex(331, 64, 52),
    "magenta100": hsl_to_hex(331, 100, 73),
    "magenta300": hsl_to_hex(331, 86, 64),
    "magenta500": hsl_to_hex(331, 64, 52),
    "magenta700": hsl_to_hex(331, 64, 42),
    "magenta900": hsl_to_hex(331, 65, 20),

    # Violet
    "violet": hsl_to_hex(237, 43, 60),
    "violet100": hsl_to_hex(236, 100, 90),
    "violet300": hsl_to_hex(237, 69, 77),
    "violet500": hsl_to_hex(237, 43, 60),
    "violet700": hsl_to_hex(237, 43, 50),
    "violet900": hsl_to_hex(237, 42, 25),

    # Blue
    "blue": hsl_to_hex(205, 69, 49),
    "blue100": hsl_to_hex(205, 100, 83),
    "blue300": hsl_to_hex(205, 90, 62),
    "blue500": hsl_to_hex(205, 69, 49),
    "blue700": hsl_to_hex(205, 70, 35),
    "blue900": hsl_to_hex(205, 69, 20),

    # Cyan
    "cyan": hsl_to_hex(175, 59, 40),
    "cyan100": hsl_to_hex(176, 100, 86),
    "cyan300": hsl_to_hex(175, 85, 55),
    "cyan500": hsl_to_hex(175, 59, 40),
    "cyan700": hsl_to_hex(182, 59, 25),
    "cyan900": hsl_to_hex(183, 58, 15),

    # Green
    "green": hsl_to_hex(68, 100, 30),
    "green100": hsl_to_hex(90, 100, 84),
    "green300": hsl_to_hex(76, 100, 49),
    "green500": hsl_to_hex(68, 100, 30),
    "green700": hsl_to_hex(68, 100, 20),
    "green900": hsl_to_hex(68, 100, 10),
}


def generate_extended_palette() -> dict:
    """Generate extended palette from solarized-osaka definitions."""
    pal = PALETTE

    # Diagnostic colors (from colors.lua)
    # error = red500, warning = yellow500, info = blue500, hint = cyan500
    diag = {
        "diagnostic_error": pal["red500"],
        "diagnostic_warning": pal["yellow500"],
        "diagnostic_info": pal["blue500"],
        "diagnostic_hint": pal["cyan500"],
        "diagnostic_ok": pal["green500"],
    }

    # Syntax colors (from groups/syntax.lua)
    # Comment = base01, String = cyan500, Identifier/Function = blue500
    # Statement/Operator/Keyword = green500, PreProc = red500
    # Type = yellow500, Special/Debug = orange500
    syntax = {
        "syntax_comment": pal["base01"],
        "syntax_string": pal["cyan500"],
        "syntax_function": pal["blue500"],
        "syntax_keyword": pal["green500"],
        "syntax_type": pal["yellow500"],
        "syntax_number": pal["violet500"],  # Not explicitly defined, using violet
        "syntax_constant": pal["cyan500"],
        "syntax_operator": pal["green500"],
        "syntax_variable": pal["blue500"],
        "syntax_parameter": pal["blue300"],
        "syntax_preproc": pal["red500"],
        "syntax_special": pal["orange500"],
    }

    # UI colors
    ui = {
        "ui_accent": pal["blue500"],
        "ui_border": pal["base02"],
        "ui_selection": pal["base02"],
        "ui_float_bg": pal["base03"],
        "ui_cursor_line": pal["base02"],
    }

    # Git colors (from DiffAdd/Change/Delete in editor.lua)
    git = {
        "git_add": pal["green500"],
        "git_change": pal["yellow500"],
        "git_delete": pal["red500"],
    }

    return {**diag, **syntax, **ui, **git}


def main():
    print("=" * 60)
    print("Solarized Osaka - Extracted Colors")
    print("=" * 60)

    print("\n# Base palette (converted from HSL):")
    for name, color in sorted(PALETTE.items()):
        print(f"  {name}: {color}")

    print("\n# Extended palette:")
    extended = generate_extended_palette()
    for key, value in sorted(extended.items()):
        print(f"  {key}: {value}")

    print("\n# YAML format for theme.yml:")
    print("extended:")

    # Group by prefix
    groups = {}
    for key, value in sorted(extended.items()):
        prefix = key.split("_")[0]
        if prefix not in groups:
            groups[prefix] = []
        groups[prefix].append((key, value))

    for prefix in ["diagnostic", "syntax", "ui", "git"]:
        if prefix in groups:
            print(f"  # {prefix.title()} colors (from solarized-osaka.nvim)")
            for key, value in groups[prefix]:
                print(f'  {key}: "{value}"')
            print()


if __name__ == "__main__":
    main()

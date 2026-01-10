#!/usr/bin/env python3
"""Extract extended palette colors from flexoki-moon-nvim.

Based on palette structure from datapointchris/flexoki-moon-nvim.
"""

# Variants from palette.lua
VARIANTS = {
    "black": {
        "base": "#100f0f",
        "surface": "#1f1d2e",
        "overlay": "#1c1b1a",
        "muted": "#575653",
        "subtle": "#878580",
        "text": "#cecdc3",
        "yellow_one": "#ad8301",
        "red_one": "#af3029",
        "orange_one": "#bc5215",
        "magenta_one": "#a02f6f",
        "blue_one": "#205ea6",
        "cyan_one": "#24837b",
        "purple_one": "#5e409d",
        "green_one": "#66800b",
        "yellow_two": "#d0a215",
        "red_two": "#d14d41",
        "orange_two": "#da702c",
        "magenta_two": "#ce5d97",
        "blue_two": "#4385be",
        "cyan_two": "#3aa99f",
        "purple_two": "#8b7ec8",
        "green_two": "#879a39",
        "highlight_low": "#282726",
        "highlight_med": "#343331",
        "highlight_high": "#403e3c",
    },
    "purple": {
        "base": "#12101d",
        "surface": "#181620",
        "overlay": "#1c1a25",
        "muted": "#625f68",
        "subtle": "#8f8a98",
        "text": "#ddd8e8",
        "yellow_one": "#ad8301",
        "red_one": "#af3029",
        "orange_one": "#bc5215",
        "magenta_one": "#a02f6f",
        "blue_one": "#205ea6",
        "cyan_one": "#24837b",
        "purple_one": "#5e409d",
        "green_one": "#66800b",
        "yellow_two": "#d0a215",
        "red_two": "#d14d41",
        "orange_two": "#da702c",
        "magenta_two": "#ce5d97",
        "blue_two": "#4385be",
        "cyan_two": "#3aa99f",
        "purple_two": "#8b7ec8",
        "green_two": "#879a39",
        "highlight_low": "#1f1d2a",
        "highlight_med": "#252330",
        "highlight_high": "#2b2936",
    },
    "green": {
        "base": "#08120b",
        "surface": "#101a13",
        "overlay": "#151f18",
        "muted": "#6b7d6e",
        "subtle": "#8f8a98",
        "text": "#ddd8e8",
        "yellow_one": "#ad8301",
        "red_one": "#af3029",
        "orange_one": "#bc5215",
        "magenta_one": "#a02f6f",
        "blue_one": "#205ea6",
        "cyan_one": "#24837b",
        "purple_one": "#5e409d",
        "green_one": "#66800b",
        "yellow_two": "#d0a215",
        "red_two": "#d14d41",
        "orange_two": "#da702c",
        "magenta_two": "#ce5d97",
        "blue_two": "#4385be",
        "cyan_two": "#3aa99f",
        "purple_two": "#8b7ec8",
        "green_two": "#879a39",
        "highlight_low": "#253426",
        "highlight_med": "#2c3b2d",
        "highlight_high": "#334235",
    },
    "red": {
        "base": "#18090b",
        "surface": "#201315",
        "overlay": "#251a1a",
        "muted": "#8a6b60",
        "subtle": "#b5967e",
        "text": "#f0e8dd",
        "yellow_one": "#ad8301",
        "red_one": "#af3029",
        "orange_one": "#bc5215",
        "magenta_one": "#a02f6f",
        "blue_one": "#205ea6",
        "cyan_one": "#24837b",
        "purple_one": "#5e409d",
        "green_one": "#66800b",
        "yellow_two": "#d0a215",
        "red_two": "#d14d41",
        "orange_two": "#da702c",
        "magenta_two": "#ce5d97",
        "blue_two": "#4385be",
        "cyan_two": "#3aa99f",
        "purple_two": "#8b7ec8",
        "green_two": "#879a39",
        "highlight_low": "#3a2b28",
        "highlight_med": "#42322e",
        "highlight_high": "#4a3935",
    },
    "toddler": {
        "base": "#2a1f16",
        "surface": "#3c3426",
        "overlay": "#464132",
        "muted": "#726250",
        "subtle": "#c4b199",
        "text": "#d4c4a8",
        "yellow_one": "#e1a100",
        "red_one": "#ce291d",
        "orange_one": "#cf980c",
        "magenta_one": "#cb0036",
        "blue_one": "#5586e6",
        "cyan_one": "#1f554d",
        "purple_one": "#664568",
        "green_one": "#6da700",
        "yellow_two": "#957209",
        "red_two": "#dd634d",
        "orange_two": "#d19812",
        "magenta_two": "#ca1447",
        "blue_two": "#3672da",
        "cyan_two": "#4f7edc",
        "purple_two": "#be0033",
        "green_two": "#7eae0f",
        "highlight_low": "#713d3a",
        "highlight_med": "#693c4e",
        "highlight_high": "#56415c",
    },
}


def generate_extended(variant_name: str) -> dict:
    """Generate extended palette from flexoki-moon variant."""
    p = VARIANTS[variant_name]

    # From config.lua groups
    extended = {
        # Diagnostic colors
        "diagnostic_error": p["red_two"],
        "diagnostic_warning": p["orange_two"],
        "diagnostic_info": p["cyan_two"],
        "diagnostic_hint": p["purple_two"],
        "diagnostic_ok": p["green_two"],

        # Syntax colors (from flexoki.lua highlight groups)
        "syntax_comment": p["subtle"],
        "syntax_string": p["cyan_two"],
        "syntax_function": p["orange_two"],
        "syntax_keyword": p["green_two"],
        "syntax_type": p["cyan_two"],
        "syntax_number": p["purple_two"],
        "syntax_constant": p["yellow_two"],
        "syntax_operator": p["subtle"],
        "syntax_variable": p["text"],
        "syntax_parameter": p["purple_two"],
        "syntax_preproc": p["purple_two"],
        "syntax_special": p["cyan_two"],

        # UI colors
        "ui_accent": p["cyan_two"],
        "ui_border": p["muted"],
        "ui_selection": p["highlight_med"],
        "ui_float_bg": p["surface"],
        "ui_cursor_line": p["overlay"],

        # Git colors (from config.lua)
        "git_add": p["green_one"],
        "git_change": p["yellow_one"],
        "git_delete": p["red_one"],
    }

    return extended


def print_yaml(variant_name: str, extended: dict):
    """Print extended palette in YAML format."""
    print(f"\n# flexoki-moon-{variant_name} extended palette:")
    print("extended:")

    sections = [
        ("Diagnostic", "diagnostic_"),
        ("Syntax", "syntax_"),
        ("UI", "ui_"),
        ("Git", "git_"),
    ]

    for section_name, prefix in sections:
        print(f"  # {section_name} colors (from flexoki-moon-nvim)")
        for key, value in extended.items():
            if key.startswith(prefix):
                print(f'  {key}: "{value}"')
        print()


def main():
    print("=" * 60)
    print("Flexoki Moon - Extracted Colors")
    print("=" * 60)

    for variant in ["black", "purple", "green", "red", "toddler"]:
        ext = generate_extended(variant)
        print_yaml(variant, ext)


if __name__ == "__main__":
    main()

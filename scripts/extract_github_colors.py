#!/usr/bin/env python3
"""Extract extended palette colors from github-nvim-theme.

Based on palette structure from projekt0n/github-nvim-theme.
"""

# Scale colors from primitives/dark.lua
DARK_SCALE = {
    "black": "#010409",
    "white": "#ffffff",
    "gray": [
        "#f0f6fc", "#c9d1d9", "#b1bac4", "#8b949e", "#6e7681",
        "#484f58", "#30363d", "#21262d", "#161b22", "#0d1117"
    ],
    "blue": [
        "#cae8ff", "#a5d6ff", "#79c0ff", "#58a6ff", "#388bfd",
        "#1f6feb", "#1158c7", "#0d419d", "#0c2d6b", "#051d4d"
    ],
    "green": [
        "#aff5b4", "#7ee787", "#56d364", "#3fb950", "#2ea043",
        "#238636", "#196c2e", "#0f5323", "#033a16", "#04260f"
    ],
    "yellow": [
        "#f8e3a1", "#f2cc60", "#e3b341", "#d29922", "#bb8009",
        "#9e6a03", "#845306", "#693e00", "#4b2900", "#341a00"
    ],
    "orange": [
        "#ffdfb6", "#ffc680", "#ffa657", "#f0883e", "#db6d28",
        "#bd561d", "#9b4215", "#762d0a", "#5a1e02", "#3d1300"
    ],
    "red": [
        "#ffdcd7", "#ffc1ba", "#ffa198", "#ff7b72", "#f85149",
        "#da3633", "#b62324", "#8e1519", "#67060c", "#490202"
    ],
    "purple": [
        "#eddeff", "#e2c5ff", "#d2a8ff", "#bc8cff", "#a371f7",
        "#8957e5", "#6e40c9", "#553098", "#3c1e70", "#271052"
    ],
    "pink": [
        "#ffdaec", "#ffbedd", "#ff9bce", "#f778ba", "#db61a2",
        "#bf4b8a", "#9e3670", "#7d2457", "#5e103e", "#42062a"
    ],
}

# Prettylights syntax colors from primitives/dark.lua
DARK_PRETTYLIGHTS = {
    "comment": "#8b949e",
    "constant": "#79c0ff",
    "entity": "#d2a8ff",
    "entityTag": "#7ee787",
    "keyword": "#ff7b72",
    "string": "#a5d6ff",
    "variable": "#ffa657",
    "stringRegexp": "#7ee787",
}

# Scale colors from primitives/dark_dimmed.lua
DIMMED_SCALE = {
    "black": "#0a0c10",
    "white": "#cdd9e5",
    "gray": [
        "#cdd9e5", "#adbac7", "#909dab", "#768390", "#636e7b",
        "#545d68", "#444c56", "#373e47", "#2d333b", "#22272e"
    ],
    "blue": [
        "#c6e6ff", "#96d0ff", "#6cb6ff", "#539bf5", "#4184e4",
        "#316dca", "#255ab2", "#1b4b91", "#143d79", "#0f2d5c"
    ],
    "green": [
        "#b4f1b4", "#8ddb8c", "#6bc46d", "#57ab5a", "#46954a",
        "#347d39", "#2b6a30", "#245829", "#1b4721", "#113417"
    ],
    "yellow": [
        "#fbe090", "#eac55f", "#daaa3f", "#c69026", "#ae7c14",
        "#966600", "#805400", "#6c4400", "#593600", "#452700"
    ],
    "orange": [
        "#ffddb0", "#ffbc6d", "#f69d50", "#e0823d", "#cc6b2c",
        "#ae5622", "#964430", "#7f3c28", "#682d1f", "#4d210f"
    ],
    "red": [
        "#ffd8d3", "#ffb8b0", "#ff938a", "#f47067", "#e5534b",
        "#c93c37", "#ad2e2c", "#922323", "#78191b", "#5d0f12"
    ],
    "purple": [
        "#eedcff", "#dcbdfb", "#dcbdfb", "#b083f0", "#986ee2",
        "#8256d0", "#6b44bc", "#5936a2", "#472c82", "#352160"
    ],
    "pink": [
        "#ffd7eb", "#ffb3d8", "#fc8dc7", "#e275ad", "#c96198",
        "#ae4c82", "#983b6e", "#7e325a", "#69264a", "#551639"
    ],
}

DIMMED_PRETTYLIGHTS = {
    "comment": "#768390",
    "constant": "#6cb6ff",
    "entity": "#dcbdfb",
    "entityTag": "#8ddb8c",
    "keyword": "#f47067",
    "string": "#96d0ff",
    "variable": "#f69d50",
    "stringRegexp": "#8ddb8c",
}


def generate_extended(name: str, scale: dict, prettylights: dict) -> dict:
    """Generate extended palette from GitHub theme data."""

    # Diagnostic colors (from palette.lua spec.diag)
    # error = danger.fg = scale.red[5]
    # warn = attention.fg = scale.yellow[4]
    # info = accent.fg (hardcoded in palette)
    # hint = fg.muted (hardcoded in palette)

    if name == "github_dark_default":
        diag_info = "#2f81f7"
        diag_hint = "#7d8590"
        fg_default = "#e6edf3"
    elif name == "github_dark_dimmed":
        diag_info = "#539bf5"
        diag_hint = "#768390"
        fg_default = "#adbac7"
    else:
        diag_info = scale["blue"][4]
        diag_hint = scale["gray"][3]
        fg_default = scale["gray"][1]

    extended = {
        # Diagnostic colors
        "diagnostic_error": scale["red"][5],
        "diagnostic_warning": scale["yellow"][4],
        "diagnostic_info": diag_info,
        "diagnostic_hint": diag_hint,
        "diagnostic_ok": scale["green"][4],

        # Syntax colors (from prettylights)
        "syntax_comment": prettylights["comment"],
        "syntax_string": prettylights["string"],
        "syntax_function": prettylights["entity"],
        "syntax_keyword": prettylights["keyword"],
        "syntax_type": prettylights["variable"],
        "syntax_number": prettylights["constant"],
        "syntax_constant": prettylights["constant"],
        "syntax_operator": prettylights["constant"],
        "syntax_variable": fg_default,
        "syntax_parameter": fg_default,
        "syntax_preproc": prettylights["keyword"],
        "syntax_special": prettylights["entityTag"],

        # UI colors
        "ui_accent": diag_info,
        "ui_border": scale["gray"][6],
        "ui_selection": scale["gray"][7],
        "ui_float_bg": scale["gray"][8],
        "ui_cursor_line": scale["gray"][7],

        # Git colors
        "git_add": scale["green"][4],
        "git_change": scale["yellow"][4],
        "git_delete": scale["red"][5],
    }

    return extended


def print_yaml(name: str, extended: dict):
    """Print extended palette in YAML format."""
    print(f"\n# {name} extended palette:")
    print("extended:")

    sections = [
        ("Diagnostic", "diagnostic_"),
        ("Syntax", "syntax_"),
        ("UI", "ui_"),
        ("Git", "git_"),
    ]

    for section_name, prefix in sections:
        print(f"  # {section_name} colors")
        for key, value in extended.items():
            if key.startswith(prefix):
                print(f'  {key}: "{value}"')
        print()


def main():
    print("=" * 60)
    print("GitHub Theme - Extracted Colors")
    print("=" * 60)

    # github_dark_default
    ext_default = generate_extended("github_dark_default", DARK_SCALE, DARK_PRETTYLIGHTS)
    print_yaml("github_dark_default", ext_default)

    # github_dark_dimmed
    ext_dimmed = generate_extended("github_dark_dimmed", DIMMED_SCALE, DIMMED_PRETTYLIGHTS)
    print_yaml("github_dark_dimmed", ext_dimmed)


if __name__ == "__main__":
    main()

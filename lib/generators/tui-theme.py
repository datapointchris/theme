#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml"]
# ///
"""Generate tui-theme.json, the TUI theme file terminal programs read their colors from.

Usage: tui-theme.py <theme.yml> <output.json>

The format is gotermstyle's tuitheme: groups ui, markdown and syntax, each value
a #rrggbb color or a style object. The schema named in $schema documents every
key. markdown and syntax resolve the Neovim highlight groups in
lib/neovim_highlights.py, so text in a terminal program wears the style the same
text has in Neovim. Every key the format names is written, so a reader never
falls back to its built-in 16-color default for this theme.
"""

import json
import re
import sys
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from neovim_highlights import (
    SEMANTIC_COLORS,
    TREESITTER_GROUPS,
    UI_SLOTS,
    VIM_SYNTAX_GROUPS,
)

SCHEMA_URL = "https://raw.githubusercontent.com/datapointchris/gotermstyle/main/tuitheme/schema/v1.json"

MARKDOWN_KEYS = [
    "strong", "italic", "strikethrough", "underline",
    "heading", "heading.1", "heading.2", "heading.3", "heading.4", "heading.5", "heading.6",
    "quote", "math", "link", "link.label", "link.url", "raw", "raw.block",
    "list", "list.checked", "list.unchecked",
]

# The format's base syntax roles, each read from the capture Neovim draws it
# with. Neovim has no bare @parameter or @punctuation.
SYNTAX_BASE = {
    "comment": "@comment",
    "string": "@string",
    "number": "@number",
    "constant": "@constant",
    "parameter": "@variable.parameter",
    "function": "@function",
    "keyword": "@keyword",
    "type": "@type",
    "operator": "@operator",
    "punctuation": "@punctuation.delimiter",
    "attribute": "@attribute",
    "variable": "@variable",
    "tag": "@tag",
}

HEX = re.compile(r"^#[0-9a-fA-F]{6}$")
ATTRIBUTES = ("bold", "italic", "underline", "strikethrough")


def is_hex(value) -> bool:
    return isinstance(value, str) and bool(HEX.match(value))


def required_hex(value, what: str) -> str:
    if not is_hex(value):
        sys.exit(f"tui-theme: {what} is {value!r}, not #rrggbb")
    return value


def theme_colors(theme: dict) -> dict:
    """M.theme's colors as hex, keyed as the highlight groups name them."""
    base16 = theme.get("base16") or {}
    extended = theme.get("extended") or {}
    colors = {}
    for group, rows in SEMANTIC_COLORS.items():
        for name, key, fallback in rows:
            value = extended.get(key) if key else None
            colors[f"{group}.{name}"] = value if is_hex(value) else base16.get(fallback)
    for name, slot in UI_SLOTS.items():
        colors[f"ui.{name}"] = base16.get(slot)
    return colors


GROUPS = {name: spec for _, run in VIM_SYNTAX_GROUPS + TREESITTER_GROUPS for name, spec in run}


def group_style(name: str, colors: dict) -> dict | None:
    """A highlight group's style in the format's terms, or None where its link
    leads outside the shared table."""
    spec = GROUPS.get(name)
    while spec is not None and "link" in spec:
        spec = GROUPS.get(spec["link"])
    if spec is None:
        return None
    style = {}
    for key in ("fg", "bg"):
        if key in spec and spec[key] != "NONE":
            style[key] = required_hex(colors.get(spec[key]), f"{name} {key} ({spec[key]})")
    for key in ATTRIBUTES:
        if spec.get(key) or (key == "underline" and spec.get("undercurl")):
            style[key] = True
    return style


def capture_style(capture: str, colors: dict) -> dict | None:
    """A capture's style, falling back along its dots as Neovim does."""
    while True:
        if capture in GROUPS:
            return group_style(capture, colors)
        head, dot, _ = capture.rpartition(".")
        if not dot:
            return None
        capture = head


def value(style: dict):
    """A style as the format writes it: a bare color where it is only a foreground."""
    return style["fg"] if list(style) == ["fg"] else style


def ui_group(theme: dict, colors: dict) -> dict:
    base16 = theme.get("base16") or {}
    extended = theme.get("extended") or {}
    special = theme.get("special") or {}

    def pick(what: str, *candidates) -> str:
        return required_hex(next((c for c in candidates if c), None), what)

    return {
        "text": pick("ui.text", special.get("foreground"), base16.get("base05")),
        "muted": pick("ui.muted", extended.get("fg_dim"), colors["ui.fg_dim"]),
        "accent": pick("ui.accent", extended.get("ui_accent"), base16.get("base0D")),
        "selection": {
            "fg": pick("ui.selection.fg", special.get("selection_fg"), base16.get("base05")),
            "bg": pick(
                "ui.selection.bg",
                extended.get("ui_selection"), special.get("selection_bg"), base16.get("base02"),
            ),
        },
        "match": pick("ui.match", extended.get("ui_match"), base16.get("base0A")),
        "border": pick(
            "ui.border", extended.get("ui_border"), special.get("border"), base16.get("base03"),
        ),
        "panel": {
            "bg": pick("ui.panel", extended.get("ui_panel"), special.get("panel"), base16.get("base01")),
        },
        "error": pick("ui.error", colors["diag.error"]),
        "warning": pick("ui.warning", colors["diag.warning"]),
        "info": pick("ui.info", colors["diag.info"]),
        "success": pick("ui.success", colors["diag.ok"]),
    }


def markdown_group(colors: dict) -> dict:
    group = {}
    for key in MARKDOWN_KEYS:
        style = capture_style(f"@markup.{key}", colors)
        if style is None:
            sys.exit(f"tui-theme: markdown.{key} resolves to no Neovim group")
        group[key] = value(style)
    return group


def syntax_group(colors: dict) -> dict:
    group = {key: value(capture_style(capture, colors)) for key, capture in SYNTAX_BASE.items()}
    for _, run in TREESITTER_GROUPS:
        for capture, _ in run:
            key = capture.removeprefix("@")
            if key in group or key.startswith("markup."):
                continue
            # A link into an editor group, such as Directory, is left to the
            # reader's fallback along the dots.
            style = group_style(capture, colors)
            if style is not None:
                group[key] = value(style)
    return group


def main():
    if len(sys.argv) != 3:
        sys.exit("Usage: tui-theme.py <theme.yml> <output.json>")
    theme_path, output = Path(sys.argv[1]), Path(sys.argv[2])
    with open(theme_path) as f:
        theme = yaml.safe_load(f)
    colors = theme_colors(theme)
    document = {
        "$schema": SCHEMA_URL,
        "ui": ui_group(theme, colors),
        "markdown": markdown_group(colors),
        "syntax": syntax_group(colors),
    }
    output.write_text(json.dumps(document, indent=2) + "\n")


if __name__ == "__main__":
    main()

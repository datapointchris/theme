#!/usr/bin/env python3
"""Generate Neovim colorscheme from theme.yml.

Creates a standalone Neovim colorscheme plugin that can be loaded via Lazy.nvim.
"""

import os
import re
from pathlib import Path

import yaml


def load_theme(theme_path: Path) -> dict:
    """Load theme.yml file."""
    with open(theme_path) as f:
        return yaml.safe_load(f)


def slug_to_module(slug: str) -> str:
    """Convert slug to valid Lua module name."""
    return slug.replace("-", "_")


def get_color(extended: dict, extended_key: str, base16_fallback: str) -> str:
    """Get color preferring extended palette, falling back to base16."""
    if extended_key in extended:
        return f"M.palette.{extended_key}"
    return f"M.palette.{base16_fallback}"


def generate_palette_lua(theme: dict) -> str:
    """Generate palette.lua from theme.yml."""
    meta = theme.get("meta", {})
    base16 = theme.get("base16", {})
    extended = theme.get("extended", {})
    special = theme.get("special", {})

    lines = [
        "-- Auto-generated palette from theme.yml",
        f"-- Theme: {meta.get('name', 'Unknown')}",
        f"-- Source: {meta.get('source', 'Unknown')}",
        "",
        "local M = {}",
        "",
        "M.palette = {",
    ]

    # Base16 colors
    lines.append("  -- Base16 palette")
    for i in range(16):
        slot = f"base{i:02X}"
        color = base16.get(slot, "#000000")
        lines.append(f'  {slot} = "{color}",')

    # Extended colors
    if extended:
        lines.append("")
        lines.append("  -- Extended palette")
        for key, color in extended.items():
            if isinstance(color, str) and color.startswith("#"):
                lines.append(f'  {key} = "{color}",')

    lines.append("}")
    lines.append("")

    # Special colors
    lines.append("M.special = {")
    for key, color in special.items():
        if isinstance(color, str):
            lines.append(f'  {key} = "{color}",')
    lines.append("}")
    lines.append("")

    # Theme colors (semantic mapping from base16)
    lines.extend([
        "-- Semantic theme colors derived from palette",
        "M.theme = {",
        "  ui = {",
        f'    bg = M.palette.base00,',
        f'    bg_dim = M.palette.bg_dim or M.palette.base00,',
        f'    bg_p1 = M.palette.base01,',
        f'    bg_p2 = M.palette.base02,',
        f'    bg_m1 = M.palette.base01,',
        f'    bg_m3 = M.palette.base01,',
        f'    bg_gutter = M.palette.base00,',
        f'    bg_visual = M.palette.base02,',
        f'    bg_search = M.palette.base0A,',
        f'    fg = M.palette.base05,',
        f'    fg_dim = M.palette.base04,',
        f'    fg_reverse = M.palette.base00,',
        f'    special = M.palette.base0C,',
        f'    nontext = M.palette.base03,',
        f'    whitespace = M.palette.base02,',
        "    float = {",
        f'      fg = M.palette.base05,',
        f'      bg = M.palette.base01,',
        f'      fg_border = M.palette.base04,',
        f'      bg_border = M.palette.base01,',
        "    },",
        "    pmenu = {",
        f'      fg = M.palette.base05,',
        f'      fg_sel = M.palette.base05,',
        f'      bg = M.palette.base01,',
        f'      bg_sel = M.palette.base02,',
        f'      bg_sbar = M.palette.base02,',
        f'      bg_thumb = M.palette.base03,',
        "    },",
        "  },",
        "  syn = {",
        f'    comment = {get_color(extended, "syntax_comment", "base03")},',
        f'    string = {get_color(extended, "syntax_string", "base0B")},',
        f'    number = {get_color(extended, "syntax_number", "base0E")},',
        f'    constant = {get_color(extended, "syntax_constant", "base0E")},',
        f'    identifier = {get_color(extended, "syntax_identifier", "base0D")},',
        f'    parameter = {get_color(extended, "syntax_parameter", "base0D")},',
        f'    fun = {get_color(extended, "syntax_function", "base0B")},',
        f'    statement = {get_color(extended, "syntax_statement", "base08")},',
        f'    keyword = {get_color(extended, "syntax_keyword", "base08")},',
        f'    operator = {get_color(extended, "syntax_operator", "base09")},',
        f'    preproc = {get_color(extended, "syntax_preproc", "base0C")},',
        f'    type = {get_color(extended, "syntax_type", "base0A")},',
        f'    special1 = {get_color(extended, "syntax_special1", "base09")},',
        f'    special2 = {get_color(extended, "syntax_special2", "base08")},',
        f'    special3 = {get_color(extended, "syntax_special3", "base0C")},',
        f'    punct = {get_color(extended, "syntax_punct", "base09")},',
        f'    regex = {get_color(extended, "syntax_regex", "base0C")},',
        f'    deprecated = M.palette.base03,',
        "  },",
        "  diag = {",
        f'    error = {get_color(extended, "diagnostic_error", "base08")},',
        f'    warning = {get_color(extended, "diagnostic_warning", "base09")},',
        f'    info = {get_color(extended, "diagnostic_info", "base0D")},',
        f'    hint = {get_color(extended, "diagnostic_hint", "base0C")},',
        f'    ok = {get_color(extended, "diagnostic_ok", "base0B")},',
        "  },",
        "  vcs = {",
        f'    added = {get_color(extended, "git_add", "base0B")},',
        f'    changed = {get_color(extended, "git_change", "base0A")},',
        f'    removed = {get_color(extended, "git_delete", "base08")},',
        "  },",
        "  diff = {",
        f'    add = M.palette.base0B,',
        f'    change = M.palette.base0A,',
        f'    delete = M.palette.base08,',
        f'    text = M.palette.base0D,',
        "  },",
        "}",
        "",
        "return M",
    ])

    return "\n".join(lines)


def generate_editor_lua() -> str:
    """Generate editor.lua with UI highlight groups."""
    return '''-- Auto-generated editor highlights
local M = {}

function M.setup(colors)
  local theme = colors.theme
  return {
    -- Basic UI
    ColorColumn = { bg = theme.ui.bg_p1 },
    Conceal = { fg = theme.ui.special, bold = true },
    CurSearch = { fg = theme.ui.fg, bg = theme.ui.bg_search, bold = true },
    Cursor = { fg = theme.ui.bg, bg = theme.ui.fg },
    lCursor = { link = "Cursor" },
    CursorIM = { link = "Cursor" },
    CursorColumn = { link = "CursorLine" },
    CursorLine = { bg = theme.ui.bg_p2 },
    Directory = { fg = theme.syn.fun },

    -- Diff
    DiffAdd = { bg = theme.diff.add },
    DiffChange = { bg = theme.diff.change },
    DiffDelete = { fg = theme.vcs.removed, bg = theme.diff.delete },
    DiffText = { bg = theme.diff.text },

    EndOfBuffer = { fg = theme.ui.bg },
    ErrorMsg = { fg = theme.diag.error },
    WinSeparator = { fg = theme.ui.bg_m3 },
    VertSplit = { link = "WinSeparator" },
    Folded = { fg = theme.ui.special, bg = theme.ui.bg_p1 },
    FoldColumn = { fg = theme.ui.nontext, bg = theme.ui.bg_gutter },
    SignColumn = { fg = theme.ui.special, bg = theme.ui.bg_gutter },

    -- Search
    IncSearch = { fg = theme.ui.fg_reverse, bg = theme.diag.warning },
    Substitute = { fg = theme.ui.fg, bg = theme.vcs.removed },

    -- Line numbers
    LineNr = { fg = theme.ui.nontext, bg = theme.ui.bg_gutter },
    CursorLineNr = { fg = theme.diag.warning, bg = theme.ui.bg_gutter, bold = true },

    MatchParen = { fg = theme.diag.warning, bold = true },
    ModeMsg = { fg = theme.diag.warning, bold = true },
    MsgArea = { fg = theme.ui.fg_dim },
    MsgSeparator = { bg = theme.ui.bg_m3, fg = theme.ui.bg_m3 },
    MoreMsg = { fg = theme.diag.info },
    NonText = { fg = theme.ui.nontext },

    -- Normal
    Normal = { fg = theme.ui.fg, bg = theme.ui.bg },
    NormalFloat = { fg = theme.ui.float.fg, bg = theme.ui.float.bg },
    FloatBorder = { fg = theme.ui.float.fg_border, bg = theme.ui.float.bg_border },
    FloatTitle = { fg = theme.ui.special, bg = theme.ui.float.bg_border, bold = true },
    FloatFooter = { fg = theme.ui.nontext, bg = theme.ui.float.bg_border },
    NormalNC = { link = "Normal" },

    -- Popup menu
    Pmenu = { fg = theme.ui.pmenu.fg, bg = theme.ui.pmenu.bg },
    PmenuSel = { fg = theme.ui.pmenu.fg_sel, bg = theme.ui.pmenu.bg_sel },
    PmenuKind = { fg = theme.ui.fg_dim, bg = theme.ui.pmenu.bg },
    PmenuKindSel = { fg = theme.ui.fg_dim, bg = theme.ui.pmenu.bg_sel },
    PmenuExtra = { fg = theme.ui.special, bg = theme.ui.pmenu.bg },
    PmenuExtraSel = { fg = theme.ui.special, bg = theme.ui.pmenu.bg_sel },
    PmenuSbar = { bg = theme.ui.pmenu.bg_sbar },
    PmenuThumb = { bg = theme.ui.pmenu.bg_thumb },
    PmenuBorder = { link = "FloatBorder" },

    Question = { link = "MoreMsg" },
    QuickFixLine = { bg = theme.ui.bg_p1 },
    Search = { fg = theme.ui.fg, bg = theme.ui.bg_search },
    SpecialKey = { fg = theme.ui.special },

    -- Spell
    SpellBad = { undercurl = true, sp = theme.diag.error },
    SpellCap = { undercurl = true, sp = theme.diag.warning },
    SpellLocal = { undercurl = true, sp = theme.diag.warning },
    SpellRare = { undercurl = true, sp = theme.diag.warning },

    -- Status line
    StatusLine = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },
    StatusLineNC = { fg = theme.ui.nontext, bg = theme.ui.bg_m3 },

    -- Tab line
    TabLine = { bg = theme.ui.bg_m3, fg = theme.ui.special },
    TabLineFill = { bg = theme.ui.bg },
    TabLineSel = { fg = theme.ui.fg_dim, bg = theme.ui.bg_p1 },

    Title = { fg = theme.syn.fun, bold = true },
    Visual = { bg = theme.ui.bg_visual },
    VisualNOS = { link = "Visual" },
    WarningMsg = { fg = theme.diag.warning },
    Whitespace = { fg = theme.ui.whitespace },
    WildMenu = { link = "Pmenu" },
    WinBar = { fg = theme.ui.fg_dim, bg = "NONE" },
    WinBarNC = { fg = theme.ui.fg_dim, bg = "NONE" },

    -- Debug
    debugPC = { bg = theme.diff.delete },
    debugBreakpoint = { fg = theme.syn.special1, bg = theme.ui.bg_gutter },

    -- LSP references
    LspReferenceText = { bg = theme.diff.text },
    LspReferenceRead = { link = "LspReferenceText" },
    LspReferenceWrite = { bg = theme.diff.text, underline = true },

    -- Diagnostics
    DiagnosticError = { fg = theme.diag.error },
    DiagnosticWarn = { fg = theme.diag.warning },
    DiagnosticInfo = { fg = theme.diag.info },
    DiagnosticHint = { fg = theme.diag.hint },
    DiagnosticOk = { fg = theme.diag.ok },

    DiagnosticFloatingError = { fg = theme.diag.error },
    DiagnosticFloatingWarn = { fg = theme.diag.warning },
    DiagnosticFloatingInfo = { fg = theme.diag.info },
    DiagnosticFloatingHint = { fg = theme.diag.hint },
    DiagnosticFloatingOk = { fg = theme.diag.ok },

    DiagnosticSignError = { fg = theme.diag.error, bg = theme.ui.bg_gutter },
    DiagnosticSignWarn = { fg = theme.diag.warning, bg = theme.ui.bg_gutter },
    DiagnosticSignInfo = { fg = theme.diag.info, bg = theme.ui.bg_gutter },
    DiagnosticSignHint = { fg = theme.diag.hint, bg = theme.ui.bg_gutter },

    DiagnosticVirtualTextError = { link = "DiagnosticError" },
    DiagnosticVirtualTextWarn = { link = "DiagnosticWarn" },
    DiagnosticVirtualTextInfo = { link = "DiagnosticInfo" },
    DiagnosticVirtualTextHint = { link = "DiagnosticHint" },

    DiagnosticUnderlineError = { undercurl = true, sp = theme.diag.error },
    DiagnosticUnderlineWarn = { undercurl = true, sp = theme.diag.warning },
    DiagnosticUnderlineInfo = { undercurl = true, sp = theme.diag.info },
    DiagnosticUnderlineHint = { undercurl = true, sp = theme.diag.hint },

    LspSignatureActiveParameter = { fg = theme.diag.warning },
    LspCodeLens = { fg = theme.syn.comment },

    -- VCS
    diffAdded = { fg = theme.vcs.added },
    diffRemoved = { fg = theme.vcs.removed },
    diffDeleted = { fg = theme.vcs.removed },
    diffChanged = { fg = theme.vcs.changed },
    diffOldFile = { fg = theme.vcs.removed },
    diffNewFile = { fg = theme.vcs.added },
  }
end

return M
'''


def generate_syntax_lua() -> str:
    """Generate syntax.lua with traditional Vim syntax groups."""
    return '''-- Auto-generated syntax highlights
local M = {}

function M.setup(colors)
  local theme = colors.theme
  return {
    Comment = { fg = theme.syn.comment },

    Constant = { fg = theme.syn.constant },
    String = { fg = theme.syn.string },
    Character = { link = "String" },
    Number = { fg = theme.syn.number },
    Boolean = { fg = theme.syn.constant, bold = true },
    Float = { link = "Number" },

    Identifier = { fg = theme.syn.identifier },
    Function = { fg = theme.syn.fun },

    Statement = { fg = theme.syn.statement },
    Conditional = { link = "Statement" },
    Repeat = { link = "Statement" },
    Label = { link = "Statement" },
    Operator = { fg = theme.syn.operator },
    Keyword = { fg = theme.syn.keyword },
    Exception = { fg = theme.syn.special2 },

    PreProc = { fg = theme.syn.preproc },
    Include = { link = "PreProc" },
    Define = { link = "PreProc" },
    Macro = { link = "PreProc" },
    PreCondit = { link = "PreProc" },

    Type = { fg = theme.syn.type },
    StorageClass = { link = "Type" },
    Structure = { link = "Type" },
    Typedef = { link = "Type" },

    Special = { fg = theme.syn.special1 },
    SpecialChar = { link = "Special" },
    Tag = { fg = theme.syn.special3 },
    Delimiter = { fg = theme.syn.punct },
    SpecialComment = { link = "Special" },
    Debug = { fg = theme.diag.warning },

    Underlined = { fg = theme.syn.special1, underline = true },
    Bold = { bold = true },
    Italic = { italic = true },

    Ignore = { link = "NonText" },
    Error = { fg = theme.diag.error },
    Todo = { fg = theme.ui.fg_reverse, bg = theme.diag.info, bold = true },

    qfLineNr = { link = "LineNr" },
    qfFileName = { link = "Directory" },

    markdownCode = { fg = theme.syn.string },
    markdownCodeBlock = { fg = theme.syn.string },
    markdownEscape = { fg = "NONE" },
  }
end

return M
'''


def generate_treesitter_lua() -> str:
    """Generate treesitter.lua with @capture groups."""
    return '''-- Auto-generated treesitter highlights
local M = {}

function M.setup(colors)
  local theme = colors.theme
  return {
    -- Variables
    ["@variable"] = { fg = theme.ui.fg },
    ["@variable.builtin"] = { fg = theme.syn.special2, italic = true },
    ["@variable.parameter"] = { fg = theme.syn.parameter },
    ["@variable.member"] = { fg = theme.syn.identifier },

    -- Constants
    ["@constant"] = { link = "Constant" },
    ["@constant.builtin"] = { fg = theme.syn.constant, bold = true },
    ["@constant.macro"] = { link = "Macro" },

    -- Modules
    ["@module"] = { link = "Structure" },
    ["@module.builtin"] = { fg = theme.syn.special1 },
    ["@label"] = { link = "Label" },

    -- Strings
    ["@string"] = { link = "String" },
    ["@string.documentation"] = { fg = theme.syn.string, italic = true },
    ["@string.regexp"] = { fg = theme.syn.regex },
    ["@string.escape"] = { fg = theme.syn.regex, bold = true },
    ["@string.special"] = { link = "Special" },
    ["@string.special.symbol"] = { fg = theme.syn.identifier },
    ["@string.special.path"] = { link = "Directory" },
    ["@string.special.url"] = { fg = theme.syn.special1, undercurl = true },

    -- Characters
    ["@character"] = { link = "Character" },
    ["@character.special"] = { link = "SpecialChar" },

    -- Booleans and numbers
    ["@boolean"] = { link = "Boolean" },
    ["@number"] = { link = "Number" },
    ["@number.float"] = { link = "Float" },

    -- Types
    ["@type"] = { link = "Type" },
    ["@type.builtin"] = { fg = theme.syn.type, italic = true },
    ["@type.definition"] = { link = "Type" },

    -- Attributes
    ["@attribute"] = { link = "Constant" },
    ["@attribute.builtin"] = { fg = theme.syn.special1 },
    ["@property"] = { fg = theme.syn.identifier },

    -- Functions
    ["@function"] = { link = "Function" },
    ["@function.builtin"] = { fg = theme.syn.fun, italic = true },
    ["@function.call"] = { link = "Function" },
    ["@function.macro"] = { link = "Macro" },
    ["@function.method"] = { link = "Function" },
    ["@function.method.call"] = { link = "Function" },

    -- Constructors
    ["@constructor"] = { fg = theme.syn.special1 },
    ["@constructor.lua"] = { fg = theme.syn.keyword },

    -- Operators
    ["@operator"] = { link = "Operator" },

    -- Keywords
    ["@keyword"] = { link = "Keyword" },
    ["@keyword.coroutine"] = { fg = theme.syn.keyword, italic = true },
    ["@keyword.function"] = { fg = theme.syn.keyword },
    ["@keyword.operator"] = { fg = theme.syn.operator, bold = true },
    ["@keyword.import"] = { link = "PreProc" },
    ["@keyword.type"] = { link = "Type" },
    ["@keyword.modifier"] = { link = "StorageClass" },
    ["@keyword.repeat"] = { link = "Repeat" },
    ["@keyword.return"] = { fg = theme.syn.special3 },
    ["@keyword.debug"] = { link = "Debug" },
    ["@keyword.exception"] = { fg = theme.syn.special3 },
    ["@keyword.conditional"] = { link = "Conditional" },
    ["@keyword.conditional.ternary"] = { link = "Operator" },
    ["@keyword.directive"] = { link = "PreProc" },
    ["@keyword.directive.define"] = { link = "Define" },

    -- Punctuation
    ["@punctuation.delimiter"] = { fg = theme.syn.punct },
    ["@punctuation.bracket"] = { fg = theme.syn.punct },
    ["@punctuation.special"] = { fg = theme.syn.special1 },

    -- Comments
    ["@comment"] = { link = "Comment" },
    ["@comment.documentation"] = { fg = theme.syn.comment },
    ["@comment.error"] = { fg = theme.ui.fg, bg = theme.diag.error, bold = true },
    ["@comment.warning"] = { fg = theme.ui.fg_reverse, bg = theme.diag.warning, bold = true },
    ["@comment.todo"] = { fg = theme.ui.fg_reverse, bg = theme.diag.hint, bold = true },
    ["@comment.note"] = { fg = theme.ui.fg_reverse, bg = theme.diag.info, bold = true },

    -- Markup
    ["@markup.strong"] = { bold = true },
    ["@markup.italic"] = { italic = true },
    ["@markup.strikethrough"] = { strikethrough = true },
    ["@markup.underline"] = { underline = true },
    ["@markup.heading"] = { link = "Function" },
    ["@markup.quote"] = { fg = theme.syn.parameter, italic = true },
    ["@markup.math"] = { link = "Constant" },
    ["@markup.environment"] = { link = "Keyword" },
    ["@markup.link"] = { fg = theme.syn.special1 },
    ["@markup.link.label"] = { link = "Special" },
    ["@markup.link.url"] = { fg = theme.syn.special1, undercurl = true },
    ["@markup.raw"] = { link = "String" },
    ["@markup.raw.block"] = { fg = theme.syn.string },
    ["@markup.list"] = { fg = theme.syn.punct },
    ["@markup.list.checked"] = { fg = theme.diag.ok },
    ["@markup.list.unchecked"] = { fg = theme.ui.nontext },

    -- Diff
    ["@diff.plus"] = { fg = theme.vcs.added },
    ["@diff.minus"] = { fg = theme.vcs.removed },
    ["@diff.delta"] = { fg = theme.vcs.changed },

    -- Tags (HTML/XML)
    ["@tag"] = { link = "Tag" },
    ["@tag.builtin"] = { fg = theme.syn.special3 },
    ["@tag.attribute"] = { fg = theme.syn.identifier },
    ["@tag.delimiter"] = { fg = theme.syn.punct },
  }
end

return M
'''


def generate_lsp_lua() -> str:
    """Generate lsp.lua with semantic token highlights."""
    return '''-- Auto-generated LSP semantic highlights
local M = {}

function M.setup(colors)
  local theme = colors.theme
  return {
    -- LSP semantic tokens
    ["@lsp.type.class"] = { link = "Structure" },
    ["@lsp.type.decorator"] = { link = "Function" },
    ["@lsp.type.enum"] = { link = "Structure" },
    ["@lsp.type.enumMember"] = { link = "Constant" },
    ["@lsp.type.function"] = { link = "Function" },
    ["@lsp.type.interface"] = { link = "Structure" },
    ["@lsp.type.macro"] = { link = "Macro" },
    ["@lsp.type.method"] = { link = "@function.method" },
    ["@lsp.type.namespace"] = { link = "@module" },
    ["@lsp.type.parameter"] = { link = "@variable.parameter" },
    ["@lsp.type.property"] = { link = "@property" },
    ["@lsp.type.struct"] = { link = "Structure" },
    ["@lsp.type.type"] = { link = "Type" },
    ["@lsp.type.typeParameter"] = { link = "Type" },
    ["@lsp.type.variable"] = { fg = "NONE" },
    ["@lsp.type.comment"] = { link = "Comment" },

    ["@lsp.type.const"] = { link = "Constant" },
    ["@lsp.type.comparison"] = { link = "Operator" },
    ["@lsp.type.bitwise"] = { link = "Operator" },
    ["@lsp.type.punctuation"] = { link = "Delimiter" },

    ["@lsp.type.selfParameter"] = { link = "@variable.builtin" },
    ["@lsp.type.builtinConstant"] = { link = "@constant.builtin" },
    ["@lsp.type.magicFunction"] = { link = "@function.builtin" },

    -- Modifiers
    ["@lsp.mod.readonly"] = { link = "Constant" },
    ["@lsp.mod.typeHint"] = { link = "Type" },
    ["@lsp.mod.defaultLibrary"] = { link = "Special" },
    ["@lsp.mod.builtin"] = { link = "Special" },

    -- Type + modifier combinations
    ["@lsp.typemod.operator.controlFlow"] = { link = "@keyword.exception" },
    ["@lsp.type.lifetime"] = { link = "Operator" },
    ["@lsp.typemod.keyword.documentation"] = { link = "Special" },
    ["@lsp.type.decorator.rust"] = { link = "PreProc" },

    ["@lsp.typemod.variable.global"] = { link = "Constant" },
    ["@lsp.typemod.variable.static"] = { link = "Constant" },
    ["@lsp.typemod.variable.defaultLibrary"] = { link = "Special" },

    ["@lsp.typemod.function.builtin"] = { link = "@function.builtin" },
    ["@lsp.typemod.function.defaultLibrary"] = { link = "@function.builtin" },
    ["@lsp.typemod.method.defaultLibrary"] = { link = "@function.builtin" },

    ["@lsp.typemod.variable.injected"] = { link = "@variable" },
    ["@lsp.typemod.function.readonly"] = { fg = theme.syn.fun, bold = true },
  }
end

return M
'''


def generate_plugins_lua() -> str:
    """Generate plugins.lua with plugin-specific highlights."""
    return '''-- Auto-generated plugin highlights
local M = {}

function M.setup(colors)
  local theme = colors.theme
  return {
    -- Gitsigns
    GitSignsAdd = { fg = theme.vcs.added, bg = theme.ui.bg_gutter },
    GitSignsChange = { fg = theme.vcs.changed, bg = theme.ui.bg_gutter },
    GitSignsDelete = { fg = theme.vcs.removed, bg = theme.ui.bg_gutter },

    -- Telescope
    TelescopeBorder = { fg = theme.ui.float.fg_border, bg = theme.ui.bg },
    TelescopeTitle = { fg = theme.ui.special },
    TelescopeSelection = { link = "CursorLine" },
    TelescopeSelectionCaret = { link = "CursorLineNr" },
    TelescopeResultsClass = { link = "Structure" },
    TelescopeResultsStruct = { link = "Structure" },
    TelescopeResultsField = { link = "@variable.member" },
    TelescopeResultsMethod = { link = "Function" },
    TelescopeResultsVariable = { link = "@variable" },
    TelescopePromptPrefix = { fg = theme.syn.fun },
    TelescopeMatching = { fg = theme.diag.warning, bold = true },

    -- blink.cmp
    BlinkCmpMenu = { link = "Pmenu" },
    BlinkCmpMenuSelection = { link = "PmenuSel" },
    BlinkCmpMenuBorder = { fg = theme.ui.bg_search, bg = theme.ui.pmenu.bg },
    BlinkCmpScrollBarThumb = { link = "PmenuThumb" },
    BlinkCmpScrollBarGutter = { link = "PmenuSbar" },
    BlinkCmpLabel = { fg = theme.ui.pmenu.fg },
    BlinkCmpLabelMatch = { fg = theme.syn.fun },
    BlinkCmpLabelDetails = { fg = theme.syn.comment },
    BlinkCmpLabelDeprecated = { fg = theme.syn.comment, strikethrough = true },
    BlinkCmpGhostText = { fg = theme.syn.comment },
    BlinkCmpDoc = { link = "NormalFloat" },
    BlinkCmpDocBorder = { link = "FloatBorder" },
    BlinkCmpDocCursorLine = { link = "Visual" },
    BlinkCmpSignatureHelp = { link = "NormalFloat" },
    BlinkCmpSignatureHelpBorder = { link = "FloatBorder" },
    BlinkCmpSignatureHelpActiveParameter = { link = "LspSignatureActiveParameter" },

    BlinkCmpKind = { fg = theme.ui.fg_dim },
    BlinkCmpKindText = { fg = theme.ui.fg },
    BlinkCmpKindMethod = { link = "@function.method" },
    BlinkCmpKindFunction = { link = "Function" },
    BlinkCmpKindConstructor = { link = "@constructor" },
    BlinkCmpKindField = { link = "@variable.member" },
    BlinkCmpKindVariable = { fg = theme.ui.fg_dim },
    BlinkCmpKindClass = { link = "Type" },
    BlinkCmpKindInterface = { link = "Type" },
    BlinkCmpKindModule = { link = "@module" },
    BlinkCmpKindProperty = { link = "@property" },
    BlinkCmpKindUnit = { link = "Number" },
    BlinkCmpKindValue = { link = "String" },
    BlinkCmpKindEnum = { link = "Type" },
    BlinkCmpKindKeyword = { link = "Keyword" },
    BlinkCmpKindSnippet = { link = "Special" },
    BlinkCmpKindColor = { link = "Special" },
    BlinkCmpKindFile = { link = "Directory" },
    BlinkCmpKindReference = { link = "Special" },
    BlinkCmpKindFolder = { link = "Directory" },
    BlinkCmpKindEnumMember = { link = "Constant" },
    BlinkCmpKindConstant = { link = "Constant" },
    BlinkCmpKindStruct = { link = "Type" },
    BlinkCmpKindEvent = { link = "Type" },
    BlinkCmpKindOperator = { link = "Operator" },
    BlinkCmpKindTypeParameter = { link = "Type" },
    BlinkCmpKindCopilot = { link = "String" },

    -- nvim-cmp (fallback)
    CmpDocumentation = { link = "NormalFloat" },
    CmpDocumentationBorder = { link = "FloatBorder" },
    CmpItemAbbr = { fg = theme.ui.pmenu.fg },
    CmpItemAbbrDeprecated = { fg = theme.syn.comment, strikethrough = true },
    CmpItemAbbrMatch = { fg = theme.syn.fun },
    CmpItemAbbrMatchFuzzy = { link = "CmpItemAbbrMatch" },
    CmpItemKindDefault = { fg = theme.ui.fg_dim },
    CmpItemMenu = { fg = theme.ui.fg_dim },
    CmpGhostText = { fg = theme.syn.comment },

    -- IndentBlankline
    IndentBlanklineChar = { fg = theme.ui.whitespace },
    IndentBlanklineSpaceChar = { fg = theme.ui.whitespace },
    IndentBlanklineSpaceCharBlankline = { fg = theme.ui.whitespace },
    IndentBlanklineContextChar = { fg = theme.ui.special },
    IndentBlanklineContextStart = { sp = theme.ui.special, underline = true },
    IblIndent = { fg = theme.ui.whitespace },
    IblWhitespace = { fg = theme.ui.whitespace },
    IblScope = { fg = theme.ui.special },

    -- Trouble
    TroubleIndent = { fg = theme.ui.whitespace },
    TroublePos = { fg = theme.ui.special },
    TroubleCount = { fg = theme.diag.warning, bold = true },
    TroubleNormal = { link = "Normal" },
    TroubleText = { fg = theme.ui.fg },
    TroubleSource = { fg = theme.syn.comment },
    TroubleFoldIcon = { fg = theme.ui.special },
    TroubleLocation = { fg = theme.ui.nontext },

    -- Todo-comments
    TodoBgFIX = { fg = theme.ui.bg, bg = theme.diag.error, bold = true },
    TodoBgHACK = { fg = theme.ui.bg, bg = theme.diag.warning, bold = true },
    TodoBgNOTE = { fg = theme.ui.bg, bg = theme.diag.info, bold = true },
    TodoBgPERF = { fg = theme.ui.bg, bg = theme.syn.special1, bold = true },
    TodoBgTODO = { fg = theme.ui.bg, bg = theme.diag.hint, bold = true },
    TodoBgWARN = { fg = theme.ui.bg, bg = theme.diag.warning, bold = true },
    TodoFgFIX = { fg = theme.diag.error },
    TodoFgHACK = { fg = theme.diag.warning },
    TodoFgNOTE = { fg = theme.diag.info },
    TodoFgPERF = { fg = theme.syn.special1 },
    TodoFgTODO = { fg = theme.diag.hint },
    TodoFgWARN = { fg = theme.diag.warning },

    -- Which-key
    WhichKey = { fg = theme.syn.fun },
    WhichKeyGroup = { fg = theme.syn.keyword },
    WhichKeyDesc = { fg = theme.ui.fg },
    WhichKeySeperator = { fg = theme.ui.nontext },
    WhichKeySeparator = { fg = theme.ui.nontext },
    WhichKeyFloat = { bg = theme.ui.bg_m1 },
    WhichKeyBorder = { link = "FloatBorder" },
    WhichKeyValue = { fg = theme.syn.comment },

    -- Noice
    NoiceCmdline = { fg = theme.ui.fg },
    NoiceCmdlineIcon = { fg = theme.syn.fun },
    NoiceCmdlineIconSearch = { fg = theme.diag.warning },
    NoiceCmdlinePopup = { link = "NormalFloat" },
    NoiceCmdlinePopupBorder = { link = "FloatBorder" },
    NoiceCmdlinePopupBorderSearch = { fg = theme.diag.warning },
    NoiceConfirm = { link = "NormalFloat" },
    NoiceConfirmBorder = { link = "FloatBorder" },
    NoiceFormatConfirm = { link = "CursorLine" },
    NoiceFormatConfirmDefault = { link = "Visual" },
    NoiceMini = { link = "MsgArea" },
    NoicePopup = { link = "NormalFloat" },
    NoicePopupBorder = { link = "FloatBorder" },
    NoicePopupmenu = { link = "Pmenu" },
    NoicePopupmenuBorder = { link = "FloatBorder" },
    NoicePopupmenuMatch = { fg = theme.syn.fun, bold = true },
    NoicePopupmenuSelected = { link = "PmenuSel" },
    NoiceScrollbar = { link = "PmenuSbar" },
    NoiceScrollbarThumb = { link = "PmenuThumb" },
    NoiceVirtualText = { fg = theme.diag.info },

    -- Oil
    OilDir = { link = "Directory" },
    OilDirIcon = { link = "Directory" },
    OilFile = { fg = theme.ui.fg },
    OilCreate = { fg = theme.vcs.added },
    OilDelete = { fg = theme.vcs.removed },
    OilMove = { fg = theme.vcs.changed },
    OilCopy = { fg = theme.diag.info },
    OilChange = { fg = theme.vcs.changed },
    OilRestore = { fg = theme.diag.hint },
    OilPurge = { fg = theme.diag.error },
    OilTrash = { fg = theme.diag.error },
    OilTrashSourcePath = { fg = theme.syn.comment },

    -- Bufferline
    BufferLineFill = { bg = theme.ui.bg_m3 },
    BufferLineBackground = { fg = theme.ui.nontext, bg = theme.ui.bg_m3 },
    BufferLineBuffer = { fg = theme.ui.nontext, bg = theme.ui.bg_m3 },
    BufferLineBufferSelected = { fg = theme.ui.fg, bg = theme.ui.bg, bold = true },
    BufferLineBufferVisible = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
    BufferLineCloseButton = { fg = theme.ui.nontext, bg = theme.ui.bg_m3 },
    BufferLineCloseButtonSelected = { fg = theme.diag.error, bg = theme.ui.bg },
    BufferLineCloseButtonVisible = { fg = theme.ui.nontext, bg = theme.ui.bg_m1 },
    BufferLineIndicatorSelected = { fg = theme.syn.fun, bg = theme.ui.bg },
    BufferLineModified = { fg = theme.diag.warning, bg = theme.ui.bg_m3 },
    BufferLineModifiedSelected = { fg = theme.diag.warning, bg = theme.ui.bg },
    BufferLineModifiedVisible = { fg = theme.diag.warning, bg = theme.ui.bg_m1 },
    BufferLineSeparator = { fg = theme.ui.bg_m3, bg = theme.ui.bg_m3 },
    BufferLineSeparatorSelected = { fg = theme.ui.bg_m3, bg = theme.ui.bg },
    BufferLineSeparatorVisible = { fg = theme.ui.bg_m3, bg = theme.ui.bg_m1 },
    BufferLineTab = { fg = theme.ui.nontext, bg = theme.ui.bg_m3 },
    BufferLineTabSelected = { fg = theme.ui.fg, bg = theme.ui.bg, bold = true },
    BufferLineTabClose = { fg = theme.diag.error, bg = theme.ui.bg_m3 },

    -- DAP-UI
    DapUIScope = { link = "Special" },
    DapUIType = { link = "Type" },
    DapUIModifiedValue = { fg = theme.syn.special1, bold = true },
    DapUIDecoration = { fg = theme.ui.float.fg_border },
    DapUIThread = { fg = theme.syn.identifier },
    DapUIStoppedThread = { fg = theme.syn.special1 },
    DapUISource = { fg = theme.syn.special2 },
    DapUILineNumber = { fg = theme.syn.special1 },
    DapUIFloatBorder = { fg = theme.ui.float.fg_border },
    DapUIWatchesEmpty = { fg = theme.diag.error },
    DapUIWatchesValue = { fg = theme.syn.identifier },
    DapUIWatchesError = { fg = theme.diag.error },
    DapUIBreakpointsPath = { link = "Directory" },
    DapUIBreakpointsInfo = { fg = theme.diag.info },
    DapUIBreakpointsCurrentLine = { fg = theme.syn.identifier, bold = true },
    DapUIBreakpointsDisabledLine = { link = "Comment" },
    DapUIStepOver = { fg = theme.syn.special1 },
    DapUIStepInto = { fg = theme.syn.special1 },
    DapUIStepBack = { fg = theme.syn.special1 },
    DapUIStepOut = { fg = theme.syn.special1 },
    DapUIStop = { fg = theme.diag.error },
    DapUIPlayPause = { fg = theme.syn.string },
    DapUIRestart = { fg = theme.syn.string },
    DapUIUnavailable = { fg = theme.syn.comment },

    -- Diffview
    DiffviewFilePanelTitle = { fg = theme.syn.fun, bold = true },
    DiffviewFilePanelCounter = { fg = theme.syn.constant },
    DiffviewFilePanelFileName = { fg = theme.ui.fg },
    DiffviewFilePanelPath = { fg = theme.syn.comment },
    DiffviewFilePanelInsertions = { fg = theme.vcs.added },
    DiffviewFilePanelDeletions = { fg = theme.vcs.removed },
    DiffviewStatusAdded = { fg = theme.vcs.added },
    DiffviewStatusModified = { fg = theme.vcs.changed },
    DiffviewStatusRenamed = { fg = theme.vcs.changed },
    DiffviewStatusDeleted = { fg = theme.vcs.removed },
    DiffviewStatusUntracked = { fg = theme.diag.hint },

    -- Mini
    MiniCursorword = { underline = true },
    MiniCursorwordCurrent = { underline = true },
    MiniIndentscopeSymbol = { fg = theme.syn.special1 },
    MiniIndentscopePrefix = { nocombine = true },
    MiniJump = { link = "SpellRare" },
    MiniJump2dSpot = { fg = theme.syn.constant, bold = true, nocombine = true },
    MiniStatuslineDevinfo = { fg = theme.ui.fg_dim, bg = theme.ui.bg_p1 },
    MiniStatuslineFileinfo = { fg = theme.ui.fg_dim, bg = theme.ui.bg_p1 },
    MiniStatuslineFilename = { fg = theme.ui.fg_dim, bg = theme.ui.bg_dim },
    MiniStatuslineInactive = { link = "StatusLineNC" },
    MiniStatuslineModeCommand = { fg = theme.ui.bg, bg = theme.syn.operator, bold = true },
    MiniStatuslineModeInsert = { fg = theme.ui.bg, bg = theme.diag.ok, bold = true },
    MiniStatuslineModeNormal = { fg = theme.ui.bg_m3, bg = theme.syn.fun, bold = true },
    MiniStatuslineModeOther = { fg = theme.ui.bg, bg = theme.syn.type, bold = true },
    MiniStatuslineModeReplace = { fg = theme.ui.bg, bg = theme.syn.constant, bold = true },
    MiniStatuslineModeVisual = { fg = theme.ui.bg, bg = theme.syn.keyword, bold = true },
    MiniSurround = { link = "IncSearch" },
    MiniTrailspace = { bg = theme.vcs.removed },

    -- Lualine (via highlighting)
    LualineNormalA = { fg = theme.ui.bg, bg = theme.syn.fun, bold = true },
    LualineNormalB = { fg = theme.ui.fg, bg = theme.ui.bg_p1 },
    LualineNormalC = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },
    LualineInsertA = { fg = theme.ui.bg, bg = theme.diag.ok, bold = true },
    LualineVisualA = { fg = theme.ui.bg, bg = theme.syn.keyword, bold = true },
    LualineReplaceA = { fg = theme.ui.bg, bg = theme.diag.error, bold = true },
    LualineCommandA = { fg = theme.ui.bg, bg = theme.diag.warning, bold = true },

    -- Lazy
    LazyProgressTodo = { fg = theme.ui.nontext },
    LazyProgressDone = { fg = theme.diag.ok },

    -- Notify
    NotifyBackground = { bg = theme.ui.bg },
    NotifyERRORBorder = { link = "DiagnosticError" },
    NotifyWARNBorder = { link = "DiagnosticWarn" },
    NotifyINFOBorder = { link = "DiagnosticInfo" },
    NotifyHINTBorder = { link = "DiagnosticHint" },
    NotifyDEBUGBorder = { link = "Debug" },
    NotifyTRACEBorder = { link = "Comment" },
    NotifyERRORIcon = { link = "DiagnosticError" },
    NotifyWARNIcon = { link = "DiagnosticWarn" },
    NotifyINFOIcon = { link = "DiagnosticInfo" },
    NotifyHINTIcon = { link = "DiagnosticHint" },
    NotifyDEBUGIcon = { link = "Debug" },
    NotifyTRACEIcon = { link = "Comment" },
    NotifyERRORTitle = { link = "DiagnosticError" },
    NotifyWARNTitle = { link = "DiagnosticWarn" },
    NotifyINFOTitle = { link = "DiagnosticInfo" },
    NotifyHINTTitle = { link = "DiagnosticHint" },
    NotifyDEBUGTitle = { link = "Debug" },
    NotifyTRACETitle = { link = "Comment" },

    -- TreesitterContext
    TreesitterContext = { link = "Folded" },
    TreesitterContextLineNumber = { fg = theme.ui.special, bg = theme.ui.bg_gutter },

    -- Render-markdown
    RenderMarkdownH1Bg = { bg = theme.ui.bg_p1 },
    RenderMarkdownH2Bg = { bg = theme.ui.bg_p1 },
    RenderMarkdownH3Bg = { bg = theme.ui.bg_p1 },
    RenderMarkdownH4Bg = { bg = theme.ui.bg_p1 },
    RenderMarkdownH5Bg = { bg = theme.ui.bg_p1 },
    RenderMarkdownH6Bg = { bg = theme.ui.bg_p1 },
    RenderMarkdownCode = { bg = theme.ui.bg_p1 },
    RenderMarkdownCodeInline = { bg = theme.ui.bg_p1 },
    RenderMarkdownBullet = { fg = theme.syn.fun },
    RenderMarkdownQuote = { fg = theme.syn.comment, italic = true },
    RenderMarkdownDash = { fg = theme.ui.nontext },
    RenderMarkdownLink = { fg = theme.syn.special1 },
    RenderMarkdownSign = { fg = theme.ui.special },
    RenderMarkdownMath = { fg = theme.syn.constant },
    RenderMarkdownUnchecked = { fg = theme.ui.nontext },
    RenderMarkdownChecked = { fg = theme.diag.ok },
    RenderMarkdownTableHead = { fg = theme.syn.fun },
    RenderMarkdownTableRow = { fg = theme.ui.fg },
    RenderMarkdownTableFill = { link = "Conceal" },

    -- Copilot
    CopilotSuggestion = { fg = theme.syn.comment, italic = true },
    CopilotAnnotation = { fg = theme.syn.comment, italic = true },

    -- CodeCompanion
    CodeCompanionChatHeader = { fg = theme.syn.fun, bold = true },
    CodeCompanionChatSeparator = { fg = theme.ui.nontext },
    CodeCompanionChatTokens = { fg = theme.syn.comment },
    CodeCompanionChatAgent = { fg = theme.syn.special1 },
    CodeCompanionChatTool = { fg = theme.syn.keyword },
    CodeCompanionChatVariable = { fg = theme.syn.constant },
    CodeCompanionVirtualText = { fg = theme.syn.comment, italic = true },

    -- Fidget
    FidgetTitle = { fg = theme.syn.fun },
    FidgetTask = { fg = theme.syn.comment },

    -- Health
    healthError = { fg = theme.diag.error },
    healthSuccess = { fg = theme.diag.ok },
    healthWarning = { fg = theme.diag.warning },
  }
end

return M
'''


def generate_overrides_lua(theme_name: str) -> str:
    """Generate overrides.lua template for theme-specific customizations."""
    return f'''-- Theme-specific overrides for {theme_name}
-- This file is NOT regenerated - your customizations are preserved.
--
-- Uncomment and modify any highlights below, or add your own.
-- All examples reference the theme's color palette for consistency.
--
-- Available color references:
--   colors.palette.base00-base0F  -- Base16 palette colors
--   colors.theme.ui.*             -- UI colors (bg, fg, float, pmenu, etc.)
--   colors.theme.syn.*            -- Syntax colors (comment, string, keyword, etc.)
--   colors.theme.diag.*           -- Diagnostic colors (error, warning, info, hint, ok)
--   colors.theme.vcs.*            -- VCS colors (added, changed, removed)
--   colors.theme.diff.*           -- Diff colors (add, change, delete, text)
--
-- Highlight spec options:
--   fg = "#hex" or colors.X       -- Foreground color
--   bg = "#hex" or colors.X       -- Background color
--   sp = "#hex" or colors.X       -- Special color (underlines)
--   bold = true/false
--   italic = true/false
--   underline = true/false
--   undercurl = true/false
--   strikethrough = true/false
--   link = "OtherGroup"           -- Link to another highlight group

local M = {{}}

---@param colors table The palette and theme colors
---@param highlights table All highlight groups collected from base modules
---@return table Modified highlights table
function M.highlights(colors, highlights)
  local p = colors.palette
  local ui = colors.theme.ui
  local syn = colors.theme.syn
  local diag = colors.theme.diag

  ------------------------------------------------------------------------------
  -- SYNTAX (Traditional Vim highlight groups)
  ------------------------------------------------------------------------------
  -- highlights.Comment = {{ fg = syn.comment }}
  -- highlights.String = {{ fg = syn.string }}
  -- highlights.Character = {{ fg = syn.string }}
  -- highlights.Number = {{ fg = syn.number }}
  -- highlights.Boolean = {{ fg = syn.constant, bold = true }}
  -- highlights.Float = {{ fg = syn.number }}
  -- highlights.Constant = {{ fg = syn.constant }}
  -- highlights.Identifier = {{ fg = syn.identifier }}
  -- highlights.Function = {{ fg = syn.fun }}
  -- highlights.Statement = {{ fg = syn.statement }}
  -- highlights.Conditional = {{ fg = syn.statement }}
  -- highlights.Repeat = {{ fg = syn.statement }}
  -- highlights.Label = {{ fg = syn.statement }}
  -- highlights.Operator = {{ fg = syn.operator }}
  -- highlights.Keyword = {{ fg = syn.keyword }}
  -- highlights.Exception = {{ fg = syn.special2 }}
  -- highlights.PreProc = {{ fg = syn.preproc }}
  -- highlights.Include = {{ fg = syn.preproc }}
  -- highlights.Define = {{ fg = syn.preproc }}
  -- highlights.Macro = {{ fg = syn.preproc }}
  -- highlights.Type = {{ fg = syn.type }}
  -- highlights.StorageClass = {{ fg = syn.type }}
  -- highlights.Structure = {{ fg = syn.type }}
  -- highlights.Typedef = {{ fg = syn.type }}
  -- highlights.Special = {{ fg = syn.special1 }}
  -- highlights.SpecialChar = {{ fg = syn.special1 }}
  -- highlights.Tag = {{ fg = syn.special3 }}
  -- highlights.Delimiter = {{ fg = syn.punct }}
  -- highlights.Debug = {{ fg = diag.warning }}
  -- highlights.Error = {{ fg = diag.error }}
  -- highlights.Todo = {{ fg = ui.fg_reverse, bg = diag.info, bold = true }}

  ------------------------------------------------------------------------------
  -- TREESITTER (Modern syntax highlighting)
  ------------------------------------------------------------------------------
  -- Variables
  -- highlights["@variable"] = {{ fg = ui.fg }}
  -- highlights["@variable.builtin"] = {{ fg = syn.special2, italic = true }}
  -- highlights["@variable.parameter"] = {{ fg = syn.parameter }}
  -- highlights["@variable.member"] = {{ fg = syn.identifier }}

  -- Constants
  -- highlights["@constant"] = {{ fg = syn.constant }}
  -- highlights["@constant.builtin"] = {{ fg = syn.constant, bold = true }}
  -- highlights["@constant.macro"] = {{ fg = syn.preproc }}

  -- Strings
  -- highlights["@string"] = {{ fg = syn.string }}
  -- highlights["@string.documentation"] = {{ fg = syn.string, italic = true }}
  -- highlights["@string.regexp"] = {{ fg = syn.regex }}
  -- highlights["@string.escape"] = {{ fg = syn.regex, bold = true }}
  -- highlights["@string.special.url"] = {{ fg = syn.special1, undercurl = true }}

  -- Types
  -- highlights["@type"] = {{ fg = syn.type }}
  -- highlights["@type.builtin"] = {{ fg = syn.type, italic = true }}
  -- highlights["@type.definition"] = {{ fg = syn.type }}
  -- highlights["@property"] = {{ fg = syn.identifier }}
  -- highlights["@attribute"] = {{ fg = syn.constant }}

  -- Functions
  -- highlights["@function"] = {{ fg = syn.fun }}
  -- highlights["@function.builtin"] = {{ fg = syn.fun, italic = true }}
  -- highlights["@function.call"] = {{ fg = syn.fun }}
  -- highlights["@function.macro"] = {{ fg = syn.preproc }}
  -- highlights["@function.method"] = {{ fg = syn.fun }}
  -- highlights["@constructor"] = {{ fg = syn.special1 }}

  -- Keywords
  -- highlights["@keyword"] = {{ fg = syn.keyword }}
  -- highlights["@keyword.coroutine"] = {{ fg = syn.keyword, italic = true }}
  -- highlights["@keyword.function"] = {{ fg = syn.keyword }}
  -- highlights["@keyword.operator"] = {{ fg = syn.operator, bold = true }}
  -- highlights["@keyword.import"] = {{ fg = syn.preproc }}
  -- highlights["@keyword.return"] = {{ fg = syn.special3 }}
  -- highlights["@keyword.exception"] = {{ fg = syn.special3 }}
  -- highlights["@keyword.conditional"] = {{ fg = syn.statement }}
  -- highlights["@keyword.repeat"] = {{ fg = syn.statement }}

  -- Punctuation
  -- highlights["@punctuation.delimiter"] = {{ fg = syn.punct }}
  -- highlights["@punctuation.bracket"] = {{ fg = syn.punct }}
  -- highlights["@punctuation.special"] = {{ fg = syn.special1 }}

  -- Comments
  -- highlights["@comment"] = {{ fg = syn.comment }}
  -- highlights["@comment.documentation"] = {{ fg = syn.comment }}
  -- highlights["@comment.error"] = {{ fg = ui.fg, bg = diag.error, bold = true }}
  -- highlights["@comment.warning"] = {{ fg = ui.fg_reverse, bg = diag.warning, bold = true }}
  -- highlights["@comment.todo"] = {{ fg = ui.fg_reverse, bg = diag.hint, bold = true }}
  -- highlights["@comment.note"] = {{ fg = ui.fg_reverse, bg = diag.info, bold = true }}

  -- Operators
  -- highlights["@operator"] = {{ fg = syn.operator }}

  -- Modules/Namespaces
  -- highlights["@module"] = {{ fg = syn.type }}
  -- highlights["@module.builtin"] = {{ fg = syn.special1 }}
  -- highlights["@label"] = {{ fg = syn.statement }}

  -- Markup (markdown, etc.)
  -- highlights["@markup.strong"] = {{ bold = true }}
  -- highlights["@markup.italic"] = {{ italic = true }}
  -- highlights["@markup.strikethrough"] = {{ strikethrough = true }}
  -- highlights["@markup.underline"] = {{ underline = true }}
  -- highlights["@markup.heading"] = {{ fg = syn.fun, bold = true }}
  -- highlights["@markup.quote"] = {{ fg = syn.parameter, italic = true }}
  -- highlights["@markup.link"] = {{ fg = syn.special1 }}
  -- highlights["@markup.link.url"] = {{ fg = syn.special1, undercurl = true }}
  -- highlights["@markup.raw"] = {{ fg = syn.string }}
  -- highlights["@markup.list"] = {{ fg = syn.punct }}

  -- Tags (HTML/XML)
  -- highlights["@tag"] = {{ fg = syn.special3 }}
  -- highlights["@tag.builtin"] = {{ fg = syn.special3 }}
  -- highlights["@tag.attribute"] = {{ fg = syn.identifier }}
  -- highlights["@tag.delimiter"] = {{ fg = syn.punct }}

  ------------------------------------------------------------------------------
  -- LSP SEMANTIC TOKENS
  ------------------------------------------------------------------------------
  -- highlights["@lsp.type.class"] = {{ link = "Structure" }}
  -- highlights["@lsp.type.decorator"] = {{ link = "Function" }}
  -- highlights["@lsp.type.enum"] = {{ link = "Structure" }}
  -- highlights["@lsp.type.enumMember"] = {{ link = "Constant" }}
  -- highlights["@lsp.type.function"] = {{ link = "Function" }}
  -- highlights["@lsp.type.interface"] = {{ link = "Structure" }}
  -- highlights["@lsp.type.macro"] = {{ link = "Macro" }}
  -- highlights["@lsp.type.method"] = {{ link = "@function.method" }}
  -- highlights["@lsp.type.namespace"] = {{ link = "@module" }}
  -- highlights["@lsp.type.parameter"] = {{ link = "@variable.parameter" }}
  -- highlights["@lsp.type.property"] = {{ link = "@property" }}
  -- highlights["@lsp.type.struct"] = {{ link = "Structure" }}
  -- highlights["@lsp.type.type"] = {{ link = "Type" }}
  -- highlights["@lsp.type.typeParameter"] = {{ link = "Type" }}
  -- highlights["@lsp.type.variable"] = {{ fg = "NONE" }}
  -- highlights["@lsp.mod.readonly"] = {{ link = "Constant" }}
  -- highlights["@lsp.mod.defaultLibrary"] = {{ link = "Special" }}
  -- highlights["@lsp.typemod.function.defaultLibrary"] = {{ link = "@function.builtin" }}

  ------------------------------------------------------------------------------
  -- EDITOR UI
  ------------------------------------------------------------------------------
  -- Cursor and current line
  -- highlights.Cursor = {{ fg = ui.bg, bg = ui.fg }}
  -- highlights.CursorLine = {{ bg = ui.bg_p2 }}
  -- highlights.CursorColumn = {{ bg = ui.bg_p2 }}
  -- highlights.CursorLineNr = {{ fg = diag.warning, bg = ui.bg_gutter, bold = true }}
  -- highlights.LineNr = {{ fg = ui.nontext, bg = ui.bg_gutter }}

  -- Visual selection
  -- highlights.Visual = {{ bg = ui.bg_visual }}
  -- highlights.VisualNOS = {{ bg = ui.bg_visual }}

  -- Search
  -- highlights.Search = {{ fg = ui.fg, bg = ui.bg_search }}
  -- highlights.IncSearch = {{ fg = ui.fg_reverse, bg = diag.warning }}
  -- highlights.CurSearch = {{ fg = ui.fg, bg = ui.bg_search, bold = true }}
  -- highlights.Substitute = {{ fg = ui.fg, bg = colors.theme.vcs.removed }}

  -- Matching
  -- highlights.MatchParen = {{ fg = diag.warning, bold = true }}

  -- Popup menu (completion)
  -- highlights.Pmenu = {{ fg = ui.pmenu.fg, bg = ui.pmenu.bg }}
  -- highlights.PmenuSel = {{ fg = ui.pmenu.fg_sel, bg = ui.pmenu.bg_sel }}
  -- highlights.PmenuSbar = {{ bg = ui.pmenu.bg_sbar }}
  -- highlights.PmenuThumb = {{ bg = ui.pmenu.bg_thumb }}

  -- Floating windows
  -- highlights.NormalFloat = {{ fg = ui.float.fg, bg = ui.float.bg }}
  -- highlights.FloatBorder = {{ fg = ui.float.fg_border, bg = ui.float.bg_border }}
  -- highlights.FloatTitle = {{ fg = ui.special, bg = ui.float.bg_border, bold = true }}

  -- Status/Tab lines
  -- highlights.StatusLine = {{ fg = ui.fg_dim, bg = ui.bg_m3 }}
  -- highlights.StatusLineNC = {{ fg = ui.nontext, bg = ui.bg_m3 }}
  -- highlights.TabLine = {{ bg = ui.bg_m3, fg = ui.special }}
  -- highlights.TabLineFill = {{ bg = ui.bg }}
  -- highlights.TabLineSel = {{ fg = ui.fg_dim, bg = ui.bg_p1 }}

  -- Window separators
  -- highlights.WinSeparator = {{ fg = ui.bg_m3 }}
  -- highlights.VertSplit = {{ fg = ui.bg_m3 }}

  -- Folds
  -- highlights.Folded = {{ fg = ui.special, bg = ui.bg_p1 }}
  -- highlights.FoldColumn = {{ fg = ui.nontext, bg = ui.bg_gutter }}

  -- Sign column
  -- highlights.SignColumn = {{ fg = ui.special, bg = ui.bg_gutter }}

  -- Messages
  -- highlights.ErrorMsg = {{ fg = diag.error }}
  -- highlights.WarningMsg = {{ fg = diag.warning }}
  -- highlights.MoreMsg = {{ fg = diag.info }}
  -- highlights.ModeMsg = {{ fg = diag.warning, bold = true }}

  -- Diff
  -- highlights.DiffAdd = {{ bg = colors.theme.diff.add }}
  -- highlights.DiffChange = {{ bg = colors.theme.diff.change }}
  -- highlights.DiffDelete = {{ fg = colors.theme.vcs.removed, bg = colors.theme.diff.delete }}
  -- highlights.DiffText = {{ bg = colors.theme.diff.text }}
  -- highlights.diffAdded = {{ fg = colors.theme.vcs.added }}
  -- highlights.diffRemoved = {{ fg = colors.theme.vcs.removed }}
  -- highlights.diffChanged = {{ fg = colors.theme.vcs.changed }}

  -- Spelling
  -- highlights.SpellBad = {{ undercurl = true, sp = diag.error }}
  -- highlights.SpellCap = {{ undercurl = true, sp = diag.warning }}
  -- highlights.SpellLocal = {{ undercurl = true, sp = diag.warning }}
  -- highlights.SpellRare = {{ undercurl = true, sp = diag.warning }}

  -- Misc
  -- highlights.Normal = {{ fg = ui.fg, bg = ui.bg }}
  -- highlights.NormalNC = {{ fg = ui.fg, bg = ui.bg }}
  -- highlights.NonText = {{ fg = ui.nontext }}
  -- highlights.Whitespace = {{ fg = ui.whitespace }}
  -- highlights.SpecialKey = {{ fg = ui.special }}
  -- highlights.Directory = {{ fg = syn.fun }}
  -- highlights.Title = {{ fg = syn.fun, bold = true }}
  -- highlights.EndOfBuffer = {{ fg = ui.bg }}
  -- highlights.ColorColumn = {{ bg = ui.bg_p1 }}
  -- highlights.QuickFixLine = {{ bg = ui.bg_p1 }}
  -- highlights.WinBar = {{ fg = ui.fg_dim, bg = "NONE" }}
  -- highlights.WinBarNC = {{ fg = ui.fg_dim, bg = "NONE" }}

  ------------------------------------------------------------------------------
  -- DIAGNOSTICS
  ------------------------------------------------------------------------------
  -- highlights.DiagnosticError = {{ fg = diag.error }}
  -- highlights.DiagnosticWarn = {{ fg = diag.warning }}
  -- highlights.DiagnosticInfo = {{ fg = diag.info }}
  -- highlights.DiagnosticHint = {{ fg = diag.hint }}
  -- highlights.DiagnosticOk = {{ fg = diag.ok }}

  -- highlights.DiagnosticSignError = {{ fg = diag.error, bg = ui.bg_gutter }}
  -- highlights.DiagnosticSignWarn = {{ fg = diag.warning, bg = ui.bg_gutter }}
  -- highlights.DiagnosticSignInfo = {{ fg = diag.info, bg = ui.bg_gutter }}
  -- highlights.DiagnosticSignHint = {{ fg = diag.hint, bg = ui.bg_gutter }}

  -- highlights.DiagnosticUnderlineError = {{ undercurl = true, sp = diag.error }}
  -- highlights.DiagnosticUnderlineWarn = {{ undercurl = true, sp = diag.warning }}
  -- highlights.DiagnosticUnderlineInfo = {{ undercurl = true, sp = diag.info }}
  -- highlights.DiagnosticUnderlineHint = {{ undercurl = true, sp = diag.hint }}

  -- highlights.DiagnosticVirtualTextError = {{ fg = diag.error }}
  -- highlights.DiagnosticVirtualTextWarn = {{ fg = diag.warning }}
  -- highlights.DiagnosticVirtualTextInfo = {{ fg = diag.info }}
  -- highlights.DiagnosticVirtualTextHint = {{ fg = diag.hint }}

  ------------------------------------------------------------------------------
  -- LSP
  ------------------------------------------------------------------------------
  -- highlights.LspReferenceText = {{ bg = colors.theme.diff.text }}
  -- highlights.LspReferenceRead = {{ bg = colors.theme.diff.text }}
  -- highlights.LspReferenceWrite = {{ bg = colors.theme.diff.text, underline = true }}
  -- highlights.LspSignatureActiveParameter = {{ fg = diag.warning }}
  -- highlights.LspCodeLens = {{ fg = syn.comment }}

  ------------------------------------------------------------------------------
  -- PLUGINS
  ------------------------------------------------------------------------------
  -- Gitsigns
  -- highlights.GitSignsAdd = {{ fg = colors.theme.vcs.added, bg = ui.bg_gutter }}
  -- highlights.GitSignsChange = {{ fg = colors.theme.vcs.changed, bg = ui.bg_gutter }}
  -- highlights.GitSignsDelete = {{ fg = colors.theme.vcs.removed, bg = ui.bg_gutter }}

  -- Telescope
  -- highlights.TelescopeBorder = {{ fg = ui.float.fg_border, bg = ui.bg }}
  -- highlights.TelescopeTitle = {{ fg = ui.special }}
  -- highlights.TelescopeSelection = {{ link = "CursorLine" }}
  -- highlights.TelescopeSelectionCaret = {{ link = "CursorLineNr" }}
  -- highlights.TelescopeMatching = {{ fg = diag.warning, bold = true }}
  -- highlights.TelescopePromptPrefix = {{ fg = syn.fun }}

  -- blink.cmp
  -- highlights.BlinkCmpMenu = {{ link = "Pmenu" }}
  -- highlights.BlinkCmpMenuSelection = {{ link = "PmenuSel" }}
  -- highlights.BlinkCmpMenuBorder = {{ fg = ui.bg_search, bg = ui.pmenu.bg }}
  -- highlights.BlinkCmpLabel = {{ fg = ui.pmenu.fg }}
  -- highlights.BlinkCmpLabelMatch = {{ fg = syn.fun }}
  -- highlights.BlinkCmpLabelDeprecated = {{ fg = syn.comment, strikethrough = true }}
  -- highlights.BlinkCmpGhostText = {{ fg = syn.comment }}
  -- highlights.BlinkCmpDoc = {{ link = "NormalFloat" }}
  -- highlights.BlinkCmpDocBorder = {{ link = "FloatBorder" }}
  -- highlights.BlinkCmpKind = {{ fg = ui.fg_dim }}
  -- highlights.BlinkCmpKindFunction = {{ link = "Function" }}
  -- highlights.BlinkCmpKindMethod = {{ link = "@function.method" }}
  -- highlights.BlinkCmpKindVariable = {{ fg = ui.fg_dim }}
  -- highlights.BlinkCmpKindClass = {{ link = "Type" }}
  -- highlights.BlinkCmpKindKeyword = {{ link = "Keyword" }}
  -- highlights.BlinkCmpKindSnippet = {{ link = "Special" }}

  -- Trouble
  -- highlights.TroubleNormal = {{ link = "Normal" }}
  -- highlights.TroubleText = {{ fg = ui.fg }}
  -- highlights.TroubleCount = {{ fg = diag.warning, bold = true }}
  -- highlights.TroubleSource = {{ fg = syn.comment }}

  -- Indent guides (indent-blankline)
  -- highlights.IblIndent = {{ fg = ui.whitespace }}
  -- highlights.IblWhitespace = {{ fg = ui.whitespace }}
  -- highlights.IblScope = {{ fg = ui.special }}

  -- Which-key
  -- highlights.WhichKey = {{ fg = syn.fun }}
  -- highlights.WhichKeyGroup = {{ fg = syn.keyword }}
  -- highlights.WhichKeyDesc = {{ fg = ui.fg }}
  -- highlights.WhichKeySeparator = {{ fg = ui.nontext }}
  -- highlights.WhichKeyFloat = {{ bg = ui.bg_m1 }}
  -- highlights.WhichKeyBorder = {{ link = "FloatBorder" }}

  -- Noice
  -- highlights.NoiceCmdline = {{ fg = ui.fg }}
  -- highlights.NoiceCmdlineIcon = {{ fg = syn.fun }}
  -- highlights.NoiceCmdlineIconSearch = {{ fg = diag.warning }}
  -- highlights.NoicePopup = {{ link = "NormalFloat" }}
  -- highlights.NoicePopupBorder = {{ link = "FloatBorder" }}
  -- highlights.NoiceMini = {{ link = "MsgArea" }}

  -- Oil
  -- highlights.OilDir = {{ link = "Directory" }}
  -- highlights.OilFile = {{ fg = ui.fg }}
  -- highlights.OilCreate = {{ fg = colors.theme.vcs.added }}
  -- highlights.OilDelete = {{ fg = colors.theme.vcs.removed }}
  -- highlights.OilMove = {{ fg = colors.theme.vcs.changed }}

  -- Bufferline
  -- highlights.BufferLineFill = {{ bg = ui.bg_m3 }}
  -- highlights.BufferLineBackground = {{ fg = ui.nontext, bg = ui.bg_m3 }}
  -- highlights.BufferLineBufferSelected = {{ fg = ui.fg, bg = ui.bg, bold = true }}
  -- highlights.BufferLineBufferVisible = {{ fg = ui.fg_dim, bg = ui.bg_m1 }}
  -- highlights.BufferLineIndicatorSelected = {{ fg = syn.fun, bg = ui.bg }}

  -- Render-markdown
  -- highlights.RenderMarkdownH1Bg = {{ bg = ui.bg_p1 }}
  -- highlights.RenderMarkdownH2Bg = {{ bg = ui.bg_p1 }}
  -- highlights.RenderMarkdownCode = {{ bg = ui.bg_p1 }}
  -- highlights.RenderMarkdownCodeInline = {{ bg = ui.bg_p1 }}
  -- highlights.RenderMarkdownBullet = {{ fg = syn.fun }}
  -- highlights.RenderMarkdownQuote = {{ fg = syn.comment, italic = true }}
  -- highlights.RenderMarkdownLink = {{ fg = syn.special1 }}

  -- Mini
  -- highlights.MiniCursorword = {{ underline = true }}
  -- highlights.MiniIndentscopeSymbol = {{ fg = syn.special1 }}
  -- highlights.MiniStatuslineModeNormal = {{ fg = ui.bg_m3, bg = syn.fun, bold = true }}
  -- highlights.MiniStatuslineModeInsert = {{ fg = ui.bg, bg = diag.ok, bold = true }}
  -- highlights.MiniStatuslineModeVisual = {{ fg = ui.bg, bg = syn.keyword, bold = true }}
  -- highlights.MiniStatuslineModeCommand = {{ fg = ui.bg, bg = syn.operator, bold = true }}
  -- highlights.MiniStatuslineModeReplace = {{ fg = ui.bg, bg = syn.constant, bold = true }}

  -- Copilot / AI
  -- highlights.CopilotSuggestion = {{ fg = syn.comment, italic = true }}
  -- highlights.CopilotAnnotation = {{ fg = syn.comment, italic = true }}
  -- highlights.CodeCompanionChatHeader = {{ fg = syn.fun, bold = true }}
  -- highlights.CodeCompanionVirtualText = {{ fg = syn.comment, italic = true }}

  -- TreesitterContext
  -- highlights.TreesitterContext = {{ link = "Folded" }}
  -- highlights.TreesitterContextLineNumber = {{ fg = ui.special, bg = ui.bg_gutter }}

  -- Lazy
  -- highlights.LazyProgressTodo = {{ fg = ui.nontext }}
  -- highlights.LazyProgressDone = {{ fg = diag.ok }}

  -- Fidget
  -- highlights.FidgetTitle = {{ fg = syn.fun }}
  -- highlights.FidgetTask = {{ fg = syn.comment }}

  -- Health
  -- highlights.healthError = {{ fg = diag.error }}
  -- highlights.healthSuccess = {{ fg = diag.ok }}
  -- highlights.healthWarning = {{ fg = diag.warning }}

  return highlights
end

return M
'''


def generate_init_lua(module_name: str, theme_name: str, colorscheme_name: str) -> str:
    """Generate init.lua entry point."""
    return f'''-- Auto-generated colorscheme: {theme_name}
local M = {{}}

M.config = {{
  transparent = false,
  dim_inactive = false,
  terminal_colors = true,
}}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {{}})
end

function M.load()
  if vim.g.colors_name then
    vim.cmd("hi clear")
  end

  vim.g.colors_name = "{colorscheme_name}"
  vim.o.termguicolors = true
  vim.o.background = "dark"

  local colors = require("{module_name}.palette")
  local highlights = {{}}

  -- Collect all highlight groups
  for _, mod in ipairs({{ "editor", "syntax", "treesitter", "lsp", "plugins" }}) do
    local ok, hl_mod = pcall(require, "{module_name}.highlights." .. mod)
    if ok then
      for hl, spec in pairs(hl_mod.setup(colors)) do
        highlights[hl] = spec
      end
    end
  end

  -- Apply theme-specific overrides (if overrides.lua exists)
  local ok, overrides = pcall(require, "{module_name}.overrides")
  if ok and overrides.highlights then
    highlights = overrides.highlights(colors, highlights)
  end

  -- Apply highlights
  for hl, spec in pairs(highlights) do
    vim.api.nvim_set_hl(0, hl, spec)
  end

  -- Terminal colors
  if M.config.terminal_colors then
    local p = colors.palette
    vim.g.terminal_color_0 = p.base00
    vim.g.terminal_color_1 = p.base08
    vim.g.terminal_color_2 = p.base0B
    vim.g.terminal_color_3 = p.base0A
    vim.g.terminal_color_4 = p.base0D
    vim.g.terminal_color_5 = p.base0E
    vim.g.terminal_color_6 = p.base0C
    vim.g.terminal_color_7 = p.base05
    vim.g.terminal_color_8 = p.base03
    vim.g.terminal_color_9 = p.base08
    vim.g.terminal_color_10 = p.base0B
    vim.g.terminal_color_11 = p.base0A
    vim.g.terminal_color_12 = p.base0D
    vim.g.terminal_color_13 = p.base0E
    vim.g.terminal_color_14 = p.base0C
    vim.g.terminal_color_15 = p.base07
  end
end

return M
'''


def generate_highlights_init_lua(module_name: str) -> str:
    """Generate highlights/init.lua."""
    return f'''-- Auto-generated highlights init
local M = {{}}

function M.setup(colors)
  local highlights = {{}}

  for _, mod in ipairs({{ "editor", "syntax", "treesitter", "lsp", "plugins" }}) do
    local ok, hl_mod = pcall(require, "{module_name}.highlights." .. mod)
    if ok then
      for hl, spec in pairs(hl_mod.setup(colors)) do
        highlights[hl] = spec
      end
    end
  end

  return highlights
end

return M
'''


def generate_colors_lua(module_name: str) -> str:
    """Generate colors/{name}.lua entry point."""
    return f'''-- Colorscheme entry point
require("{module_name}").load()
'''


def generate_colorscheme(theme_path: Path, output_dir: Path) -> None:
    """Generate complete Neovim colorscheme from theme.yml."""
    theme = load_theme(theme_path)
    meta = theme.get("meta", {})
    slug = meta.get("id", theme_path.parent.name)
    name = meta.get("display_name", slug)
    module_name = slug_to_module(slug)

    # Create directory structure
    lua_dir = output_dir / "lua" / module_name
    highlights_dir = lua_dir / "highlights"
    colors_dir = output_dir / "colors"

    for d in [lua_dir, highlights_dir, colors_dir]:
        d.mkdir(parents=True, exist_ok=True)

    # Generate files (always overwritten)
    files = {
        lua_dir / "init.lua": generate_init_lua(module_name, name, slug),
        lua_dir / "palette.lua": generate_palette_lua(theme),
        highlights_dir / "init.lua": generate_highlights_init_lua(module_name),
        highlights_dir / "editor.lua": generate_editor_lua(),
        highlights_dir / "syntax.lua": generate_syntax_lua(),
        highlights_dir / "treesitter.lua": generate_treesitter_lua(),
        highlights_dir / "lsp.lua": generate_lsp_lua(),
        highlights_dir / "plugins.lua": generate_plugins_lua(),
        colors_dir / f"{slug}.lua": generate_colors_lua(module_name),
    }

    for filepath, content in files.items():
        with open(filepath, "w") as f:
            f.write(content)
        print(f"  Created: {filepath.relative_to(output_dir)}")

    # Generate overrides.lua only if it doesn't exist (preserve user customizations)
    overrides_path = lua_dir / "overrides.lua"
    if not overrides_path.exists():
        with open(overrides_path, "w") as f:
            f.write(generate_overrides_lua(name))
        print(f"  Created: {overrides_path.relative_to(output_dir)}")
    else:
        print(f"  Preserved: {overrides_path.relative_to(output_dir)} (user customizations)")


def main():
    import sys

    if len(sys.argv) < 2:
        print("Usage: neovim_generator.py <theme_dir> [--force]")
        print("  theme_dir: Directory containing theme.yml")
        print("  --force: Generate even for plugin themes (not recommended)")
        sys.exit(1)

    force = "--force" in sys.argv
    theme_dir = Path(sys.argv[1])
    theme_path = theme_dir / "theme.yml"

    if not theme_path.exists():
        print(f"Error: {theme_path} not found")
        sys.exit(1)

    # Safety check: warn if this theme uses a plugin
    theme = load_theme(theme_path)
    meta = theme.get("meta", {})
    colorscheme_source = meta.get("neovim_colorscheme_source", "generated")

    if colorscheme_source == "plugin":
        plugin = meta.get("plugin", "unknown")
        print(f"Error: Theme '{meta.get('id', theme_dir.name)}' uses neovim_colorscheme_source: plugin")
        print(f"       This theme is designed to use the original plugin: {plugin}")
        print(f"       Generating a colorscheme would shadow the plugin.")
        if not force:
            print("\n       Use --force to generate anyway (not recommended).")
            sys.exit(1)
        print("\n       --force specified, generating anyway...")

    output_dir = theme_dir / "neovim"
    print(f"Generating Neovim colorscheme from: {theme_path}")
    print(f"Output directory: {output_dir}")

    generate_colorscheme(theme_path, output_dir)
    print("Done!")


if __name__ == "__main__":
    main()

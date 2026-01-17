-- Auto-generated palette from theme.yml
-- Theme: Unknown
-- Source: Unknown

local M = {}

M.palette = {
  -- Base16 palette
  base00 = "#1b1b1b",
  base01 = "#2b2b2b",
  base02 = "#207483",
  base03 = "#7a7a7a",
  base04 = "#a1a1a1",
  base05 = "#f7f7f7",
  base06 = "#f7f7f7",
  base07 = "#f7f7f7",
  base08 = "#b84131",
  base09 = "#d6837c",
  base0A = "#c4a500",
  base0B = "#7da900",
  base0C = "#207383",
  base0D = "#62a3c4",
  base0E = "#ba8acc",
  base0F = "#ba8acc",

  -- Extended palette
  diagnostic_error = "#b84131",
  diagnostic_ok = "#7da900",
  diagnostic_warning = "#d6837c",
  diagnostic_info = "#207383",
  diagnostic_hint = "#ba8acc",
  syntax_comment = "#7a7a7a",
  syntax_string = "#207383",
  syntax_function = "#62a3c4",
  syntax_keyword = "#7da900",
  syntax_type = "#207383",
  syntax_number = "#ba8acc",
  syntax_constant = "#c4a500",
  syntax_operator = "#a1a1a1",
  syntax_variable = "#f7f7f7",
  syntax_parameter = "#62a3c4",
  syntax_preproc = "#ba8acc",
  syntax_special = "#207383",
  ui_accent = "#207383",
  ui_border = "#7a7a7a",
  ui_selection = "#207483",
  ui_float_bg = "#2b2b2b",
  ui_cursor_line = "#2b2b2b",
  git_add = "#7da900",
  git_change = "#d6837c",
  git_delete = "#b84131",
}

M.special = {
  background = "#1b1b1b",
  foreground = "#f7f7f7",
  cursor = "#bbbbbb",
  cursor_text = "#ffffff",
  selection_bg = "#207483",
  selection_fg = "#f7f7f7",
}

-- Semantic theme colors derived from palette
M.theme = {
  ui = {
    bg = M.palette.base00,
    bg_dim = M.palette.bg_dim or M.palette.base00,
    bg_p1 = M.palette.base01,
    bg_p2 = M.palette.base02,
    bg_m1 = M.palette.base01,
    bg_m3 = M.palette.base01,
    bg_gutter = M.palette.base00,
    bg_visual = M.palette.base02,
    bg_search = M.palette.base0A,
    fg = M.palette.base05,
    fg_dim = M.palette.base04,
    fg_reverse = M.palette.base00,
    special = M.palette.base0C,
    nontext = M.palette.base03,
    whitespace = M.palette.base02,
    float = {
      fg = M.palette.base05,
      bg = M.palette.base01,
      fg_border = M.palette.base04,
      bg_border = M.palette.base01,
    },
    pmenu = {
      fg = M.palette.base05,
      fg_sel = M.palette.base05,
      bg = M.palette.base01,
      bg_sel = M.palette.base02,
      bg_sbar = M.palette.base02,
      bg_thumb = M.palette.base03,
    },
  },
  syn = {
    comment = M.palette.syntax_comment,
    string = M.palette.syntax_string,
    number = M.palette.syntax_number,
    constant = M.palette.syntax_constant,
    identifier = M.palette.base0D,
    parameter = M.palette.syntax_parameter,
    fun = M.palette.syntax_function,
    statement = M.palette.base08,
    keyword = M.palette.syntax_keyword,
    operator = M.palette.syntax_operator,
    preproc = M.palette.syntax_preproc,
    type = M.palette.syntax_type,
    special1 = M.palette.base09,
    special2 = M.palette.base08,
    special3 = M.palette.base0C,
    punct = M.palette.base09,
    regex = M.palette.base0C,
    deprecated = M.palette.base03,
  },
  diag = {
    error = M.palette.diagnostic_error,
    warning = M.palette.diagnostic_warning,
    info = M.palette.diagnostic_info,
    hint = M.palette.diagnostic_hint,
    ok = M.palette.diagnostic_ok,
  },
  vcs = {
    added = M.palette.git_add,
    changed = M.palette.git_change,
    removed = M.palette.git_delete,
  },
  diff = {
    add = M.palette.base0B,
    change = M.palette.base0A,
    delete = M.palette.base08,
    text = M.palette.base0D,
  },
}

return M

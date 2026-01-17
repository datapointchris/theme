-- Auto-generated palette from theme.yml
-- Theme: Unknown
-- Source: Unknown

local M = {}

M.palette = {
  -- Base16 palette
  base00 = "#181921",
  base01 = "#252631",
  base02 = "#ebdbb2",
  base03 = "#928374",
  base04 = "#a89984",
  base05 = "#ebdbb2",
  base06 = "#ebdbb2",
  base07 = "#ebdbb2",
  base08 = "#cc241d",
  base09 = "#f42c3e",
  base0A = "#d79921",
  base0B = "#98971a",
  base0C = "#689d6a",
  base0D = "#458588",
  base0E = "#b16286",
  base0F = "#b16286",

  -- Extended palette
  diagnostic_error = "#cc241d",
  diagnostic_ok = "#98971a",
  diagnostic_warning = "#f42c3e",
  diagnostic_info = "#689d6a",
  diagnostic_hint = "#689d6a",
  syntax_comment = "#928374",
  syntax_string = "#98971a",
  syntax_function = "#458588",
  syntax_keyword = "#b16286",
  syntax_type = "#d79921",
  syntax_number = "#b16286",
  syntax_constant = "#d79921",
  syntax_operator = "#a89984",
  syntax_variable = "#ebdbb2",
  syntax_parameter = "#458588",
  syntax_preproc = "#b16286",
  syntax_special = "#689d6a",
  ui_accent = "#458588",
  ui_border = "#ebdbb2",
  ui_selection = "#ebdbb2",
  ui_float_bg = "#252631",
  ui_cursor_line = "#252631",
  git_add = "#98971a",
  git_change = "#d79921",
  git_delete = "#cc241d",
}

M.special = {
  background = "#181921",
  foreground = "#ebdbb2",
  cursor = "#c7c7c7",
  cursor_text = "#ffffff",
  selection_bg = "#ebdbb2",
  selection_fg = "#928374",
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

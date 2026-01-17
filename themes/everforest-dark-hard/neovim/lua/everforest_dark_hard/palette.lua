-- Auto-generated palette from theme.yml
-- Theme: Unknown
-- Source: Unknown

local M = {}

M.palette = {
  -- Base16 palette
  base00 = "#1e2326",
  base01 = "#2e383c",
  base02 = "#4c3743",
  base03 = "#a6b0a0",
  base04 = "#f2efdf",
  base05 = "#d3c6aa",
  base06 = "#fffbef",
  base07 = "#fffbef",
  base08 = "#e67e80",
  base09 = "#f85552",
  base0A = "#dbbc7f",
  base0B = "#a7c080",
  base0C = "#83c092",
  base0D = "#7fbbb3",
  base0E = "#d699b6",
  base0F = "#d699b6",

  -- Extended palette
  diagnostic_error = "#e67e80",
  diagnostic_ok = "#a7c080",
  diagnostic_warning = "#dbbc7f",
  diagnostic_info = "#83c092",
  diagnostic_hint = "#83c092",
  syntax_comment = "#f2efdf",
  syntax_string = "#a7c080",
  syntax_function = "#f85552",
  syntax_keyword = "#d699b6",
  syntax_type = "#83c092",
  syntax_number = "#d699b6",
  syntax_constant = "#dbbc7f",
  syntax_operator = "#f2efdf",
  syntax_variable = "#d3c6aa",
  syntax_parameter = "#7fbbb3",
  syntax_preproc = "#d699b6",
  syntax_special = "#83c092",
  ui_accent = "#83c092",
  ui_border = "#414b50",
  ui_selection = "#4c3743",
  ui_float_bg = "#272e33",
  ui_cursor_line = "#2e383c",
  git_add = "#a7c080",
  git_change = "#dbbc7f",
  git_delete = "#e67e80",
}

M.special = {
  background = "#1e2326",
  foreground = "#d3c6aa",
  cursor = "#e69875",
  cursor_text = "#4c3743",
  selection_bg = "#4c3743",
  selection_fg = "#d3c6aa",
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

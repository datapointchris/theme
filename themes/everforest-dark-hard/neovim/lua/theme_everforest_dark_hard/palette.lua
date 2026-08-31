-- Auto-generated palette from theme.yml
-- Theme: Unknown
-- Source: Unknown

local M = {}

M.palette = {
  -- Base16 palette
  base00 = "#1e2326",
  base01 = "#2e383c",
  base02 = "#374145",
  base03 = "#859289",
  base04 = "#9da9a0",
  base05 = "#d3c6aa",
  base06 = "#d3c6aa",
  base07 = "#d3c6aa",
  base08 = "#e67e80",
  base09 = "#e69875",
  base0A = "#dbbc7f",
  base0B = "#a7c080",
  base0C = "#83c092",
  base0D = "#7fbbb3",
  base0E = "#d699b6",
  base0F = "#e69875",

  -- Extended palette
  diagnostic_error = "#e67e80",
  diagnostic_ok = "#a7c080",
  diagnostic_warning = "#dbbc7f",
  diagnostic_info = "#7fbbb3",
  diagnostic_hint = "#d699b6",
  syntax_comment = "#859289",
  syntax_string = "#83c092",
  syntax_function = "#a7c080",
  syntax_keyword = "#e67e80",
  syntax_type = "#dbbc7f",
  syntax_number = "#d699b6",
  syntax_constant = "#d699b6",
  syntax_operator = "#e69875",
  syntax_variable = "#d3c6aa",
  syntax_parameter = "#d3c6aa",
  syntax_punctuation = "#859289",
  syntax_tag = "#e69875",
  syntax_attribute = "#a7c080",
  syntax_preproc = "#d699b6",
  syntax_special = "#dbbc7f",
  ui_accent = "#a7c080",
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
  cursor = "#d3c6aa",
  cursor_text = "#1e2326",
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
    add = "#373f36",
    change = "#3e3d35",
    delete = "#4c383b",
    text = "#5e5744",
  },
}

return M

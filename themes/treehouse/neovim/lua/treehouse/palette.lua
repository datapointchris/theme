-- Auto-generated palette from theme.yml
-- Theme: Unknown
-- Source: Unknown

local M = {}

M.palette = {
  -- Base16 palette
  base00 = "#191919",
  base01 = "#252220",
  base02 = "#786b53",
  base03 = "#504332",
  base04 = "#786b53",
  base05 = "#786b53",
  base06 = "#ffc800",
  base07 = "#ffc800",
  base08 = "#b2270e",
  base09 = "#ed5d20",
  base0A = "#aa820c",
  base0B = "#44a900",
  base0C = "#b25a1e",
  base0D = "#58859a",
  base0E = "#97363d",
  base0F = "#97363d",

  -- Extended palette
  diagnostic_error = "#b2270e",
  diagnostic_ok = "#44a900",
  diagnostic_warning = "#ed5d20",
  diagnostic_info = "#58859a",
  diagnostic_hint = "#97363d",
  syntax_comment = "#504332",
  syntax_string = "#b25a1e",
  syntax_function = "#58859a",
  syntax_keyword = "#44a900",
  syntax_type = "#aa820c",
  syntax_number = "#97363d",
  syntax_constant = "#ed5d20",
  syntax_operator = "#786b53",
  syntax_variable = "#786b53",
  syntax_parameter = "#58859a",
  syntax_preproc = "#97363d",
  syntax_special = "#b25a1e",
  ui_accent = "#58859a",
  ui_border = "#786b53",
  ui_selection = "#786b53",
  ui_float_bg = "#252220",
  ui_cursor_line = "#252220",
  git_add = "#44a900",
  git_change = "#aa820c",
  git_delete = "#b2270e",
}

M.special = {
  background = "#191919",
  foreground = "#786b53",
  cursor = "#fac814",
  cursor_text = "#191919",
  selection_bg = "#786b53",
  selection_fg = "#fac800",
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

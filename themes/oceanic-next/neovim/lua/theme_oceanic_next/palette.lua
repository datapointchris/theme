-- Auto-generated palette from theme.yml
-- Theme: Unknown
-- Source: Unknown

local M = {}

M.palette = {
  -- Base16 palette
  base00 = "#162c35",
  base01 = "#65737e",
  base02 = "#4f5b66",
  base03 = "#65737e",
  base04 = "#ffffff",
  base05 = "#c0c5ce",
  base06 = "#ffffff",
  base07 = "#ffffff",
  base08 = "#ec5f67",
  base09 = "#ec5f67",
  base0A = "#fac863",
  base0B = "#99c794",
  base0C = "#5fb3b3",
  base0D = "#6699cc",
  base0E = "#c594c5",
  base0F = "#c594c5",

  -- Extended palette
  diagnostic_error = "#ec5f67",
  diagnostic_warning = "#fce094",
  diagnostic_info = "#6699cc",
  diagnostic_hint = "#a6dbff",
  diagnostic_ok = "#99c794",
  syntax_comment = "#65737e",
  syntax_string = "#99c794",
  syntax_function = "#6699cc",
  syntax_keyword = "#c594c5",
  syntax_type = "#fac863",
  syntax_number = "#f99157",
  syntax_constant = "#62b3b2",
  syntax_operator = "#f99157",
  syntax_variable = "#cdd3de",
  syntax_parameter = "#cdd3de",
  syntax_preproc = "#fac863",
  syntax_special = "#ab7967",
  syntax_punctuation = "#62b3b2",
  syntax_tag = "#d8dee9",
  syntax_attribute = "#d8dee9",
  ui_accent = "#6699cc",
  ui_border = "#343d46",
  ui_selection = "#4f5b66",
  ui_float_bg = "#343d46",
  ui_cursor_line = "#343d46",
  git_add = "#99c794",
  git_change = "#fac863",
  git_delete = "#ec5f67",
}

M.special = {
  background = "#162c35",
  foreground = "#c0c5ce",
  cursor = "#c0c5ce",
  cursor_text = "#1b2b34",
  selection_bg = "#4f5b66",
  selection_fg = "#c0c5ce",
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

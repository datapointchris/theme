-- Theme-specific overrides for Gruvbox Dark Hard
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

local M = {}

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
  -- highlights.Comment = { fg = syn.comment, italic = true }
  -- highlights.String = { fg = syn.string }
  -- highlights.Character = { fg = syn.string }
  -- highlights.Number = { fg = syn.number }
  -- highlights.Boolean = { fg = syn.constant, bold = true }
  -- highlights.Float = { fg = syn.number }
  -- highlights.Constant = { fg = syn.constant }
  -- highlights.Identifier = { fg = syn.identifier }
  -- highlights.Function = { fg = syn.fun }
  -- highlights.Statement = { fg = syn.statement }
  -- highlights.Conditional = { fg = syn.statement }
  -- highlights.Repeat = { fg = syn.statement }
  -- highlights.Label = { fg = syn.statement }
  -- highlights.Operator = { fg = syn.operator }
  -- highlights.Keyword = { fg = syn.keyword }
  -- highlights.Exception = { fg = syn.special2 }
  -- highlights.PreProc = { fg = syn.preproc }
  -- highlights.Include = { fg = syn.preproc }
  -- highlights.Define = { fg = syn.preproc }
  -- highlights.Macro = { fg = syn.preproc }
  -- highlights.Type = { fg = syn.type }
  -- highlights.StorageClass = { fg = syn.type }
  -- highlights.Structure = { fg = syn.type }
  -- highlights.Typedef = { fg = syn.type }
  -- highlights.Special = { fg = syn.special1 }
  -- highlights.SpecialChar = { fg = syn.special1 }
  -- highlights.Tag = { fg = syn.special3 }
  -- highlights.Delimiter = { fg = syn.punct }
  -- highlights.Debug = { fg = diag.warning }
  -- highlights.Error = { fg = diag.error }
  -- highlights.Todo = { fg = ui.fg_reverse, bg = diag.info, bold = true }

  ------------------------------------------------------------------------------
  -- TREESITTER (Modern syntax highlighting)
  ------------------------------------------------------------------------------
  -- Variables
  -- highlights["@variable"] = { fg = ui.fg }
  -- highlights["@variable.builtin"] = { fg = syn.special2, italic = true }
  -- highlights["@variable.parameter"] = { fg = syn.parameter }
  -- highlights["@variable.member"] = { fg = syn.identifier }

  -- Constants
  -- highlights["@constant"] = { fg = syn.constant }
  -- highlights["@constant.builtin"] = { fg = syn.constant, bold = true }
  -- highlights["@constant.macro"] = { fg = syn.preproc }

  -- Strings
  -- highlights["@string"] = { fg = syn.string }
  -- highlights["@string.documentation"] = { fg = syn.string, italic = true }
  -- highlights["@string.regexp"] = { fg = syn.regex }
  -- highlights["@string.escape"] = { fg = syn.regex, bold = true }
  -- highlights["@string.special.url"] = { fg = syn.special1, undercurl = true }

  -- Types
  -- highlights["@type"] = { fg = syn.type }
  -- highlights["@type.builtin"] = { fg = syn.type, italic = true }
  -- highlights["@type.definition"] = { fg = syn.type }
  -- highlights["@property"] = { fg = syn.identifier }
  -- highlights["@attribute"] = { fg = syn.constant }

  -- Functions
  -- highlights["@function"] = { fg = syn.fun }
  -- highlights["@function.builtin"] = { fg = syn.fun, italic = true }
  -- highlights["@function.call"] = { fg = syn.fun }
  -- highlights["@function.macro"] = { fg = syn.preproc }
  -- highlights["@function.method"] = { fg = syn.fun }
  -- highlights["@constructor"] = { fg = syn.special1 }

  -- Keywords
  -- highlights["@keyword"] = { fg = syn.keyword }
  -- highlights["@keyword.coroutine"] = { fg = syn.keyword, italic = true }
  -- highlights["@keyword.function"] = { fg = syn.keyword }
  -- highlights["@keyword.operator"] = { fg = syn.operator, bold = true }
  -- highlights["@keyword.import"] = { fg = syn.preproc }
  -- highlights["@keyword.return"] = { fg = syn.special3 }
  -- highlights["@keyword.exception"] = { fg = syn.special3 }
  -- highlights["@keyword.conditional"] = { fg = syn.statement }
  -- highlights["@keyword.repeat"] = { fg = syn.statement }

  -- Punctuation
  -- highlights["@punctuation.delimiter"] = { fg = syn.punct }
  -- highlights["@punctuation.bracket"] = { fg = syn.punct }
  -- highlights["@punctuation.special"] = { fg = syn.special1 }

  -- Comments
  -- highlights["@comment"] = { fg = syn.comment, italic = true }
  -- highlights["@comment.documentation"] = { fg = syn.comment, italic = true }
  -- highlights["@comment.error"] = { fg = ui.fg, bg = diag.error, bold = true }
  -- highlights["@comment.warning"] = { fg = ui.fg_reverse, bg = diag.warning, bold = true }
  -- highlights["@comment.todo"] = { fg = ui.fg_reverse, bg = diag.hint, bold = true }
  -- highlights["@comment.note"] = { fg = ui.fg_reverse, bg = diag.info, bold = true }

  -- Operators
  -- highlights["@operator"] = { fg = syn.operator }

  -- Modules/Namespaces
  -- highlights["@module"] = { fg = syn.type }
  -- highlights["@module.builtin"] = { fg = syn.special1 }
  -- highlights["@label"] = { fg = syn.statement }

  -- Markup (markdown, etc.)
  -- highlights["@markup.strong"] = { bold = true }
  -- highlights["@markup.italic"] = { italic = true }
  -- highlights["@markup.strikethrough"] = { strikethrough = true }
  -- highlights["@markup.underline"] = { underline = true }
  -- highlights["@markup.heading"] = { fg = syn.fun, bold = true }
  -- highlights["@markup.quote"] = { fg = syn.parameter, italic = true }
  -- highlights["@markup.link"] = { fg = syn.special1 }
  -- highlights["@markup.link.url"] = { fg = syn.special1, undercurl = true }
  -- highlights["@markup.raw"] = { fg = syn.string }
  -- highlights["@markup.list"] = { fg = syn.punct }

  -- Tags (HTML/XML)
  -- highlights["@tag"] = { fg = syn.special3 }
  -- highlights["@tag.builtin"] = { fg = syn.special3 }
  -- highlights["@tag.attribute"] = { fg = syn.identifier }
  -- highlights["@tag.delimiter"] = { fg = syn.punct }

  ------------------------------------------------------------------------------
  -- LSP SEMANTIC TOKENS
  ------------------------------------------------------------------------------
  -- highlights["@lsp.type.class"] = { link = "Structure" }
  -- highlights["@lsp.type.decorator"] = { link = "Function" }
  -- highlights["@lsp.type.enum"] = { link = "Structure" }
  -- highlights["@lsp.type.enumMember"] = { link = "Constant" }
  -- highlights["@lsp.type.function"] = { link = "Function" }
  -- highlights["@lsp.type.interface"] = { link = "Structure" }
  -- highlights["@lsp.type.macro"] = { link = "Macro" }
  -- highlights["@lsp.type.method"] = { link = "@function.method" }
  -- highlights["@lsp.type.namespace"] = { link = "@module" }
  -- highlights["@lsp.type.parameter"] = { link = "@variable.parameter" }
  -- highlights["@lsp.type.property"] = { link = "@property" }
  -- highlights["@lsp.type.struct"] = { link = "Structure" }
  -- highlights["@lsp.type.type"] = { link = "Type" }
  -- highlights["@lsp.type.typeParameter"] = { link = "Type" }
  -- highlights["@lsp.type.variable"] = { fg = "NONE" }
  -- highlights["@lsp.mod.readonly"] = { link = "Constant" }
  -- highlights["@lsp.mod.defaultLibrary"] = { link = "Special" }
  -- highlights["@lsp.typemod.function.defaultLibrary"] = { link = "@function.builtin" }

  ------------------------------------------------------------------------------
  -- EDITOR UI
  ------------------------------------------------------------------------------
  -- Cursor and current line
  -- highlights.Cursor = { fg = ui.bg, bg = ui.fg }
  -- highlights.CursorLine = { bg = ui.bg_p2 }
  -- highlights.CursorColumn = { bg = ui.bg_p2 }
  -- highlights.CursorLineNr = { fg = diag.warning, bg = ui.bg_gutter, bold = true }
  -- highlights.LineNr = { fg = ui.nontext, bg = ui.bg_gutter }

  -- Visual selection
  -- highlights.Visual = { bg = ui.bg_visual }
  -- highlights.VisualNOS = { bg = ui.bg_visual }

  -- Search
  -- highlights.Search = { fg = ui.fg, bg = ui.bg_search }
  -- highlights.IncSearch = { fg = ui.fg_reverse, bg = diag.warning }
  -- highlights.CurSearch = { fg = ui.fg, bg = ui.bg_search, bold = true }
  -- highlights.Substitute = { fg = ui.fg, bg = colors.theme.vcs.removed }

  -- Matching
  -- highlights.MatchParen = { fg = diag.warning, bold = true }

  -- Popup menu (completion)
  -- highlights.Pmenu = { fg = ui.pmenu.fg, bg = ui.pmenu.bg }
  -- highlights.PmenuSel = { fg = ui.pmenu.fg_sel, bg = ui.pmenu.bg_sel }
  -- highlights.PmenuSbar = { bg = ui.pmenu.bg_sbar }
  -- highlights.PmenuThumb = { bg = ui.pmenu.bg_thumb }

  -- Floating windows
  -- highlights.NormalFloat = { fg = ui.float.fg, bg = ui.float.bg }
  -- highlights.FloatBorder = { fg = ui.float.fg_border, bg = ui.float.bg_border }
  -- highlights.FloatTitle = { fg = ui.special, bg = ui.float.bg_border, bold = true }

  -- Status/Tab lines
  -- highlights.StatusLine = { fg = ui.fg_dim, bg = ui.bg_m3 }
  -- highlights.StatusLineNC = { fg = ui.nontext, bg = ui.bg_m3 }
  -- highlights.TabLine = { bg = ui.bg_m3, fg = ui.special }
  -- highlights.TabLineFill = { bg = ui.bg }
  -- highlights.TabLineSel = { fg = ui.fg_dim, bg = ui.bg_p1 }

  -- Window separators
  -- highlights.WinSeparator = { fg = ui.bg_m3 }
  -- highlights.VertSplit = { fg = ui.bg_m3 }

  -- Folds
  -- highlights.Folded = { fg = ui.special, bg = ui.bg_p1 }
  -- highlights.FoldColumn = { fg = ui.nontext, bg = ui.bg_gutter }

  -- Sign column
  -- highlights.SignColumn = { fg = ui.special, bg = ui.bg_gutter }

  -- Messages
  -- highlights.ErrorMsg = { fg = diag.error }
  -- highlights.WarningMsg = { fg = diag.warning }
  -- highlights.MoreMsg = { fg = diag.info }
  -- highlights.ModeMsg = { fg = diag.warning, bold = true }

  -- Diff
  -- highlights.DiffAdd = { bg = colors.theme.diff.add }
  -- highlights.DiffChange = { bg = colors.theme.diff.change }
  -- highlights.DiffDelete = { fg = colors.theme.vcs.removed, bg = colors.theme.diff.delete }
  -- highlights.DiffText = { bg = colors.theme.diff.text }
  -- highlights.diffAdded = { fg = colors.theme.vcs.added }
  -- highlights.diffRemoved = { fg = colors.theme.vcs.removed }
  -- highlights.diffChanged = { fg = colors.theme.vcs.changed }

  -- Spelling
  -- highlights.SpellBad = { undercurl = true, sp = diag.error }
  -- highlights.SpellCap = { undercurl = true, sp = diag.warning }
  -- highlights.SpellLocal = { undercurl = true, sp = diag.warning }
  -- highlights.SpellRare = { undercurl = true, sp = diag.warning }

  -- Misc
  -- highlights.Normal = { fg = ui.fg, bg = ui.bg }
  -- highlights.NormalNC = { fg = ui.fg, bg = ui.bg }
  -- highlights.NonText = { fg = ui.nontext }
  -- highlights.Whitespace = { fg = ui.whitespace }
  -- highlights.SpecialKey = { fg = ui.special }
  -- highlights.Directory = { fg = syn.fun }
  -- highlights.Title = { fg = syn.fun, bold = true }
  -- highlights.EndOfBuffer = { fg = ui.bg }
  -- highlights.ColorColumn = { bg = ui.bg_p1 }
  -- highlights.QuickFixLine = { bg = ui.bg_p1 }
  -- highlights.WinBar = { fg = ui.fg_dim, bg = "NONE" }
  -- highlights.WinBarNC = { fg = ui.fg_dim, bg = "NONE" }

  ------------------------------------------------------------------------------
  -- DIAGNOSTICS
  ------------------------------------------------------------------------------
  -- highlights.DiagnosticError = { fg = diag.error }
  -- highlights.DiagnosticWarn = { fg = diag.warning }
  -- highlights.DiagnosticInfo = { fg = diag.info }
  -- highlights.DiagnosticHint = { fg = diag.hint }
  -- highlights.DiagnosticOk = { fg = diag.ok }

  -- highlights.DiagnosticSignError = { fg = diag.error, bg = ui.bg_gutter }
  -- highlights.DiagnosticSignWarn = { fg = diag.warning, bg = ui.bg_gutter }
  -- highlights.DiagnosticSignInfo = { fg = diag.info, bg = ui.bg_gutter }
  -- highlights.DiagnosticSignHint = { fg = diag.hint, bg = ui.bg_gutter }

  -- highlights.DiagnosticUnderlineError = { undercurl = true, sp = diag.error }
  -- highlights.DiagnosticUnderlineWarn = { undercurl = true, sp = diag.warning }
  -- highlights.DiagnosticUnderlineInfo = { undercurl = true, sp = diag.info }
  -- highlights.DiagnosticUnderlineHint = { undercurl = true, sp = diag.hint }

  -- highlights.DiagnosticVirtualTextError = { fg = diag.error }
  -- highlights.DiagnosticVirtualTextWarn = { fg = diag.warning }
  -- highlights.DiagnosticVirtualTextInfo = { fg = diag.info }
  -- highlights.DiagnosticVirtualTextHint = { fg = diag.hint }

  ------------------------------------------------------------------------------
  -- LSP
  ------------------------------------------------------------------------------
  -- highlights.LspReferenceText = { bg = colors.theme.diff.text }
  -- highlights.LspReferenceRead = { bg = colors.theme.diff.text }
  -- highlights.LspReferenceWrite = { bg = colors.theme.diff.text, underline = true }
  -- highlights.LspSignatureActiveParameter = { fg = diag.warning }
  -- highlights.LspCodeLens = { fg = syn.comment }

  ------------------------------------------------------------------------------
  -- PLUGINS
  ------------------------------------------------------------------------------
  -- Gitsigns
  -- highlights.GitSignsAdd = { fg = colors.theme.vcs.added, bg = ui.bg_gutter }
  -- highlights.GitSignsChange = { fg = colors.theme.vcs.changed, bg = ui.bg_gutter }
  -- highlights.GitSignsDelete = { fg = colors.theme.vcs.removed, bg = ui.bg_gutter }

  -- Telescope
  -- highlights.TelescopeBorder = { fg = ui.float.fg_border, bg = ui.bg }
  -- highlights.TelescopeTitle = { fg = ui.special }
  -- highlights.TelescopeSelection = { link = "CursorLine" }
  -- highlights.TelescopeSelectionCaret = { link = "CursorLineNr" }
  -- highlights.TelescopeMatching = { fg = diag.warning, bold = true }
  -- highlights.TelescopePromptPrefix = { fg = syn.fun }

  -- blink.cmp
  -- highlights.BlinkCmpMenu = { link = "Pmenu" }
  -- highlights.BlinkCmpMenuSelection = { link = "PmenuSel" }
  -- highlights.BlinkCmpMenuBorder = { fg = ui.bg_search, bg = ui.pmenu.bg }
  -- highlights.BlinkCmpLabel = { fg = ui.pmenu.fg }
  -- highlights.BlinkCmpLabelMatch = { fg = syn.fun }
  -- highlights.BlinkCmpLabelDeprecated = { fg = syn.comment, strikethrough = true }
  -- highlights.BlinkCmpGhostText = { fg = syn.comment }
  -- highlights.BlinkCmpDoc = { link = "NormalFloat" }
  -- highlights.BlinkCmpDocBorder = { link = "FloatBorder" }
  -- highlights.BlinkCmpKind = { fg = ui.fg_dim }
  -- highlights.BlinkCmpKindFunction = { link = "Function" }
  -- highlights.BlinkCmpKindMethod = { link = "@function.method" }
  -- highlights.BlinkCmpKindVariable = { fg = ui.fg_dim }
  -- highlights.BlinkCmpKindClass = { link = "Type" }
  -- highlights.BlinkCmpKindKeyword = { link = "Keyword" }
  -- highlights.BlinkCmpKindSnippet = { link = "Special" }

  -- Trouble
  -- highlights.TroubleNormal = { link = "Normal" }
  -- highlights.TroubleText = { fg = ui.fg }
  -- highlights.TroubleCount = { fg = diag.warning, bold = true }
  -- highlights.TroubleSource = { fg = syn.comment }

  -- Indent guides (indent-blankline)
  -- highlights.IblIndent = { fg = ui.whitespace }
  -- highlights.IblWhitespace = { fg = ui.whitespace }
  -- highlights.IblScope = { fg = ui.special }

  -- Which-key
  -- highlights.WhichKey = { fg = syn.fun }
  -- highlights.WhichKeyGroup = { fg = syn.keyword }
  -- highlights.WhichKeyDesc = { fg = ui.fg }
  -- highlights.WhichKeySeparator = { fg = ui.nontext }
  -- highlights.WhichKeyFloat = { bg = ui.bg_m1 }
  -- highlights.WhichKeyBorder = { link = "FloatBorder" }

  -- Noice
  -- highlights.NoiceCmdline = { fg = ui.fg }
  -- highlights.NoiceCmdlineIcon = { fg = syn.fun }
  -- highlights.NoiceCmdlineIconSearch = { fg = diag.warning }
  -- highlights.NoicePopup = { link = "NormalFloat" }
  -- highlights.NoicePopupBorder = { link = "FloatBorder" }
  -- highlights.NoiceMini = { link = "MsgArea" }

  -- Oil
  -- highlights.OilDir = { link = "Directory" }
  -- highlights.OilFile = { fg = ui.fg }
  -- highlights.OilCreate = { fg = colors.theme.vcs.added }
  -- highlights.OilDelete = { fg = colors.theme.vcs.removed }
  -- highlights.OilMove = { fg = colors.theme.vcs.changed }

  -- Bufferline
  -- highlights.BufferLineFill = { bg = ui.bg_m3 }
  -- highlights.BufferLineBackground = { fg = ui.nontext, bg = ui.bg_m3 }
  -- highlights.BufferLineBufferSelected = { fg = ui.fg, bg = ui.bg, bold = true }
  -- highlights.BufferLineBufferVisible = { fg = ui.fg_dim, bg = ui.bg_m1 }
  -- highlights.BufferLineIndicatorSelected = { fg = syn.fun, bg = ui.bg }

  -- Render-markdown
  -- highlights.RenderMarkdownH1Bg = { bg = ui.bg_p1 }
  -- highlights.RenderMarkdownH2Bg = { bg = ui.bg_p1 }
  -- highlights.RenderMarkdownCode = { bg = ui.bg_p1 }
  -- highlights.RenderMarkdownCodeInline = { bg = ui.bg_p1 }
  -- highlights.RenderMarkdownBullet = { fg = syn.fun }
  -- highlights.RenderMarkdownQuote = { fg = syn.comment, italic = true }
  -- highlights.RenderMarkdownLink = { fg = syn.special1 }

  -- Mini
  -- highlights.MiniCursorword = { underline = true }
  -- highlights.MiniIndentscopeSymbol = { fg = syn.special1 }
  -- highlights.MiniStatuslineModeNormal = { fg = ui.bg_m3, bg = syn.fun, bold = true }
  -- highlights.MiniStatuslineModeInsert = { fg = ui.bg, bg = diag.ok, bold = true }
  -- highlights.MiniStatuslineModeVisual = { fg = ui.bg, bg = syn.keyword, bold = true }
  -- highlights.MiniStatuslineModeCommand = { fg = ui.bg, bg = syn.operator, bold = true }
  -- highlights.MiniStatuslineModeReplace = { fg = ui.bg, bg = syn.constant, bold = true }

  -- Copilot / AI
  -- highlights.CopilotSuggestion = { fg = syn.comment, italic = true }
  -- highlights.CopilotAnnotation = { fg = syn.comment, italic = true }
  -- highlights.CodeCompanionChatHeader = { fg = syn.fun, bold = true }
  -- highlights.CodeCompanionVirtualText = { fg = syn.comment, italic = true }

  -- TreesitterContext
  -- highlights.TreesitterContext = { link = "Folded" }
  -- highlights.TreesitterContextLineNumber = { fg = ui.special, bg = ui.bg_gutter }

  -- Lazy
  -- highlights.LazyProgressTodo = { fg = ui.nontext }
  -- highlights.LazyProgressDone = { fg = diag.ok }

  -- Fidget
  -- highlights.FidgetTitle = { fg = syn.fun }
  -- highlights.FidgetTask = { fg = syn.comment }

  -- Health
  -- highlights.healthError = { fg = diag.error }
  -- highlights.healthSuccess = { fg = diag.ok }
  -- highlights.healthWarning = { fg = diag.warning }

  return highlights
end

return M

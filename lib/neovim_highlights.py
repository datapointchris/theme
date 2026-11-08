"""The Neovim highlight groups that both neovim.py and tui-theme.py read.

neovim.py writes these as Lua, symbolic over the generated palette. tui-theme.py
resolves them to hex, so a note or a snippet in a terminal program wears the
styles the same text has in Neovim. One table means the two cannot drift.

A color in a group is a reference into the generated `M.theme`, such as
"syn.comment", or the literal "NONE". A group whose spec is {"link": name} wears
the linked group's style. This sits outside lib/generators/ because every
script there is a generator, and generate-all.sh runs each one.
"""

# M.theme's semantic colors: (name, extended key, base16 fallback). The extended
# key wins where theme.yml sets it. A None key always takes the fallback.
SEMANTIC_COLORS = {
    "syn": [
        ("comment", "syntax_comment", "base03"),
        ("string", "syntax_string", "base0B"),
        ("number", "syntax_number", "base0E"),
        ("constant", "syntax_constant", "base0E"),
        ("identifier", "syntax_identifier", "base0D"),
        ("parameter", "syntax_parameter", "base0D"),
        ("fun", "syntax_function", "base0B"),
        ("statement", "syntax_statement", "base08"),
        ("keyword", "syntax_keyword", "base08"),
        ("operator", "syntax_operator", "base09"),
        ("preproc", "syntax_preproc", "base0C"),
        ("type", "syntax_type", "base0A"),
        ("special1", "syntax_special1", "base09"),
        ("special2", "syntax_special2", "base08"),
        ("special3", "syntax_special3", "base0C"),
        ("punct", "syntax_punctuation", "base04"),
        ("regex", "syntax_regex", "base0C"),
        ("deprecated", None, "base03"),
    ],
    "diag": [
        ("error", "diagnostic_error", "base08"),
        ("warning", "diagnostic_warning", "base09"),
        ("info", "diagnostic_info", "base0D"),
        ("hint", "diagnostic_hint", "base0C"),
        ("ok", "diagnostic_ok", "base0B"),
    ],
    "vcs": [
        ("added", "git_add", "base0B"),
        ("changed", "git_change", "base0A"),
        ("removed", "git_delete", "base08"),
    ],
}

# The M.theme.ui colors the groups below read, each a base16 slot.
UI_SLOTS = {
    "fg": "base05",
    "fg_dim": "base04",
    "fg_reverse": "base00",
    "nontext": "base03",
}

# syntax.lua: the traditional Vim syntax groups, in blank-line-separated runs.
VIM_SYNTAX_GROUPS = [
    (None, [
        ("Comment", {"fg": "syn.comment"}),
    ]),
    (None, [
        ("Constant", {"fg": "syn.constant"}),
        ("String", {"fg": "syn.string"}),
        ("Character", {"link": "String"}),
        ("Number", {"fg": "syn.number"}),
        ("Boolean", {"fg": "syn.constant", "bold": True}),
        ("Float", {"link": "Number"}),
    ]),
    (None, [
        ("Identifier", {"fg": "syn.identifier"}),
        ("Function", {"fg": "syn.fun"}),
    ]),
    (None, [
        ("Statement", {"fg": "syn.statement"}),
        ("Conditional", {"link": "Statement"}),
        ("Repeat", {"link": "Statement"}),
        ("Label", {"link": "Statement"}),
        ("Operator", {"fg": "syn.operator"}),
        ("Keyword", {"fg": "syn.keyword"}),
        ("Exception", {"fg": "syn.special2"}),
    ]),
    (None, [
        ("PreProc", {"fg": "syn.preproc"}),
        ("Include", {"link": "PreProc"}),
        ("Define", {"link": "PreProc"}),
        ("Macro", {"link": "PreProc"}),
        ("PreCondit", {"link": "PreProc"}),
    ]),
    (None, [
        ("Type", {"fg": "syn.type"}),
        ("StorageClass", {"link": "Type"}),
        ("Structure", {"link": "Type"}),
        ("Typedef", {"link": "Type"}),
    ]),
    (None, [
        ("Special", {"fg": "syn.special1"}),
        ("SpecialChar", {"link": "Special"}),
        ("Tag", {"fg": "syn.special3"}),
        ("Delimiter", {"fg": "syn.punct"}),
        ("SpecialComment", {"link": "Special"}),
        ("Debug", {"fg": "diag.warning"}),
    ]),
    (None, [
        ("Underlined", {"fg": "syn.special1", "underline": True}),
        ("Bold", {"bold": True}),
        ("Italic", {"italic": True}),
    ]),
    (None, [
        ("Ignore", {"link": "NonText"}),
        ("Error", {"fg": "diag.error"}),
        ("Todo", {"fg": "ui.fg_reverse", "bg": "diag.info", "bold": True}),
    ]),
    (None, [
        ("qfLineNr", {"link": "LineNr"}),
        ("qfFileName", {"link": "Directory"}),
    ]),
    (None, [
        ("markdownCode", {"fg": "syn.string"}),
        ("markdownCodeBlock", {"fg": "syn.string"}),
        ("markdownEscape", {"fg": "NONE"}),
    ]),
]

# treesitter.lua: the @capture groups, in titled runs.
TREESITTER_GROUPS = [
    ("Variables", [
        ("@variable", {"fg": "ui.fg"}),
        ("@variable.builtin", {"fg": "syn.special2", "italic": True}),
        ("@variable.parameter", {"fg": "syn.parameter"}),
        ("@variable.member", {"fg": "syn.identifier"}),
    ]),
    ("Constants", [
        ("@constant", {"link": "Constant"}),
        ("@constant.builtin", {"fg": "syn.constant", "bold": True}),
        ("@constant.macro", {"link": "Macro"}),
    ]),
    ("Modules", [
        ("@module", {"link": "Structure"}),
        ("@module.builtin", {"fg": "syn.special1"}),
        ("@label", {"link": "Label"}),
    ]),
    ("Strings", [
        ("@string", {"link": "String"}),
        ("@string.documentation", {"fg": "syn.string", "italic": True}),
        ("@string.regexp", {"fg": "syn.regex"}),
        ("@string.escape", {"fg": "syn.regex", "bold": True}),
        ("@string.special", {"link": "Special"}),
        ("@string.special.symbol", {"fg": "syn.identifier"}),
        ("@string.special.path", {"link": "Directory"}),
        ("@string.special.url", {"fg": "syn.special1", "undercurl": True}),
    ]),
    ("Characters", [
        ("@character", {"link": "Character"}),
        ("@character.special", {"link": "SpecialChar"}),
    ]),
    ("Booleans and numbers", [
        ("@boolean", {"link": "Boolean"}),
        ("@number", {"link": "Number"}),
        ("@number.float", {"link": "Float"}),
    ]),
    ("Types", [
        ("@type", {"link": "Type"}),
        ("@type.builtin", {"fg": "syn.type", "italic": True}),
        ("@type.definition", {"link": "Type"}),
    ]),
    ("Attributes", [
        ("@attribute", {"link": "Constant"}),
        ("@attribute.builtin", {"fg": "syn.special1"}),
        ("@property", {"fg": "syn.identifier"}),
    ]),
    ("Functions", [
        ("@function", {"link": "Function"}),
        ("@function.builtin", {"fg": "syn.fun", "italic": True}),
        ("@function.call", {"link": "Function"}),
        ("@function.macro", {"link": "Macro"}),
        ("@function.method", {"link": "Function"}),
        ("@function.method.call", {"link": "Function"}),
    ]),
    ("Constructors", [
        ("@constructor", {"fg": "syn.special1"}),
        ("@constructor.lua", {"fg": "syn.keyword"}),
    ]),
    ("Operators", [
        ("@operator", {"link": "Operator"}),
    ]),
    ("Keywords", [
        ("@keyword", {"link": "Keyword"}),
        ("@keyword.coroutine", {"fg": "syn.keyword", "italic": True}),
        ("@keyword.function", {"fg": "syn.keyword"}),
        ("@keyword.operator", {"fg": "syn.operator", "bold": True}),
        ("@keyword.import", {"link": "PreProc"}),
        ("@keyword.type", {"link": "Type"}),
        ("@keyword.modifier", {"link": "StorageClass"}),
        ("@keyword.repeat", {"link": "Repeat"}),
        ("@keyword.return", {"fg": "syn.special3"}),
        ("@keyword.debug", {"link": "Debug"}),
        ("@keyword.exception", {"fg": "syn.special3"}),
        ("@keyword.conditional", {"link": "Conditional"}),
        ("@keyword.conditional.ternary", {"link": "Operator"}),
        ("@keyword.directive", {"link": "PreProc"}),
        ("@keyword.directive.define", {"link": "Define"}),
    ]),
    ("Punctuation", [
        ("@punctuation.delimiter", {"fg": "syn.punct"}),
        ("@punctuation.bracket", {"fg": "syn.punct"}),
        ("@punctuation.special", {"fg": "syn.special1"}),
    ]),
    ("Comments", [
        ("@comment", {"link": "Comment"}),
        ("@comment.documentation", {"fg": "syn.comment"}),
        ("@comment.error", {"fg": "ui.fg", "bg": "diag.error", "bold": True}),
        ("@comment.warning", {"fg": "ui.fg_reverse", "bg": "diag.warning", "bold": True}),
        ("@comment.todo", {"fg": "ui.fg_reverse", "bg": "diag.hint", "bold": True}),
        ("@comment.note", {"fg": "ui.fg_reverse", "bg": "diag.info", "bold": True}),
    ]),
    ("Markup", [
        ("@markup.strong", {"bold": True}),
        ("@markup.italic", {"italic": True}),
        ("@markup.strikethrough", {"strikethrough": True}),
        ("@markup.underline", {"underline": True}),
        ("@markup.heading", {"link": "Function"}),
        ("@markup.quote", {"fg": "syn.parameter", "italic": True}),
        ("@markup.math", {"link": "Constant"}),
        ("@markup.environment", {"link": "Keyword"}),
        ("@markup.link", {"fg": "syn.special1"}),
        ("@markup.link.label", {"link": "Special"}),
        ("@markup.link.url", {"fg": "syn.special1", "undercurl": True}),
        ("@markup.raw", {"link": "String"}),
        ("@markup.raw.block", {"fg": "syn.string"}),
        ("@markup.list", {"fg": "syn.punct"}),
        ("@markup.list.checked", {"fg": "diag.ok"}),
        ("@markup.list.unchecked", {"fg": "ui.nontext"}),
    ]),
    ("Diff", [
        ("@diff.plus", {"fg": "vcs.added"}),
        ("@diff.minus", {"fg": "vcs.removed"}),
        ("@diff.delta", {"fg": "vcs.changed"}),
    ]),
    ("Tags (HTML/XML)", [
        ("@tag", {"link": "Tag"}),
        ("@tag.builtin", {"fg": "syn.special3"}),
        ("@tag.attribute", {"fg": "syn.identifier"}),
        ("@tag.delimiter", {"fg": "syn.punct"}),
    ]),
]

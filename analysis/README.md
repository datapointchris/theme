# Analysis

Research behind the theme system. None of it runs at theme-apply time — it is
the **provenance** for rules that now live in code, which is the reason it is
kept rather than deleted. `lib/generators/yazi.sh` opens with thresholds like
"gray mode: ANSI_WHITE lightness 55-75%"; without `yazi/algorithmic-rules.md`
those numbers read as arbitrary.

Conclusions that are settled live in the repo's `CLAUDE.md` (Key Insights). Go
looking here for *why* a rule is the way it is, or for the data behind it.

## base16/ — how the same palette differs between sources

- [Ghostty vs base16 canonical](base16/ghostty-vs-base16-canonical.md) — Neovim
  colorschemes and Ghostty themes measured against tinted-theming's canonical
  schemes; the "no single canonical source" finding
- [Gruvbox source comparison](base16/gruvbox-source-comparison.md) — one theme
  across three authoritative sources, and gruvbox's ANSI strategy

## experiments/ — the four runs, and the scripts behind them

- [Experiment summary](experiments/experiment-summary.md) — all four runs
  distilled, starting with the ML color predictor

## extended-palette/ — where the `extended:` block rules came from

- [Extended palette analysis](extended-palette/README.md) — predicting a
  semantic palette from a base16 one, and which features discriminate
- [Algorithm design](extended-palette/algorithm-design.md) — the semantic-role
  algorithm, derived against omarchy's hand-crafted themes

## neovim/ — the generated-vs-plugin investigation

- [Experiment plan](neovim/experiment-plan.md) — what was going to be measured,
  and marked completed
- [Generated vs plugin](neovim/generated-vs-plugin.md) — three generator
  versions compared
- [Generator analysis](neovim/generator-analysis.md) — the `syntax_*` fields a
  theme.yml declares and the generator ignores in favor of base16 mappings

## yazi/ — derivation of the rules hardcoded in the yazi generator

- [Algorithmic rules](yazi/algorithmic-rules.md) — the color-selection rules
  read out of hand-crafted flavors, which is what the generator now encodes
- [Comparison results](yazi/comparison-results.md) — the philosophy-aware
  generator against hand-crafted flavors
- [Meta-analysis](yazi/meta-analysis.md) — one theme's color choices
  cross-referenced across every source that defines it
- [Theme philosophy analysis](yazi/theme-philosophy-analysis.md) — hand-crafted
  flavors against the theme.yml they came from

## Running the scripts

They declare their own dependencies inline (PEP 723), so no virtualenv is
needed:

```bash
uv run --no-project analysis/experiments/perceptual_analysis.py
```

Reports and data files the scripts write are not committed — the markdown here
is the distilled version. Re-run a script to regenerate its report.

Two caveats before trusting a re-run: the corpus has changed since these were
written (19 themes were removed in `8c7ce14`), and the extractors read from
installed Neovim plugins, which move with `:Lazy update`. Numbers will not
reproduce exactly.

# Analysis

Research behind the theme system. None of it runs at theme-apply time — it is
the **provenance** for rules that now live in code, which is the reason it is
kept rather than deleted. `lib/generators/yazi.sh` opens with thresholds like
"gray mode: ANSI_WHITE lightness 55-75%"; without `yazi/algorithmic-rules.md`
those numbers read as arbitrary.

Conclusions that are settled live in the repo's `CLAUDE.md` (Key Insights). Go
looking here for *why* a rule is the way it is, or for the data behind it.

| Directory | What it covers |
| --------- | -------------- |
| `base16/` | How the same palette differs between sources — the "no single canonical source" finding, and gruvbox's ANSI strategy |
| `experiments/` | The scripts, and `experiment-summary.md` distilling all four experiment runs |
| `extended-palette/` | Where the `extended:` block rules came from, plus the semantic-role algorithm design |
| `neovim/` | The generated-vs-plugin colorscheme investigation and its cross-comparison of 38 palettes |
| `yazi/` | Derivation of the detection rules hardcoded in the yazi generator |

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

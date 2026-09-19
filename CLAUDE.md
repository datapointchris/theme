# Theme System - Claude Code Context

## Overview

Unified theme generation that creates consistent color configurations across terminal and
desktop applications from a single `theme.yml` per theme. Each theme in `themes/` provides app
configs that match a corresponding Neovim colorscheme.

Dev source is `~/tools/theme`. The installed copy everything actually reads is
`~/.local/share/theme` (see Neovim Integration for why that distinction bites). State and
generated data live at:

```text
~/.local/state/theme/history.jsonl   - Unified history (synced via gist)
~/.local/state/theme/current         - Current theme ID
~/.local/state/theme/sync-state.json - Sync configuration
~/.cache/theme/backgrounds/          - Pre-rendered backgrounds per theme
~/.cache/theme/gowall/               - Per-theme gowall palettes, as JSON
```

Generated state belongs in those two cache directories and nowhere else. An app config here is
often a symlink into another repo, so writing generated state into it dirties that repo on every
apply.

## Theme Categories

Every theme is either **generated** (its Neovim colorscheme is built from `theme.yml` into
`themes/{id}/neovim/`) or **plugin** (it supplies app configs that match a Neovim colorscheme
someone else maintains). `theme.yml` is the only place that fact is recorded, so read it there:

```bash
yq -r '[.meta.id, .meta.neovim_colorscheme_source, (.meta.plugin // "-"), .meta.derived_from] | @tsv' \
  themes/*/theme.yml | column -t -s$'\t'
```

Generated themes are the exception. A hand-tuned plugin usually looks better than a colorscheme
derived from the same palette, so most themes pair the original Neovim plugin with generated app
configs. `neovim_colorscheme_name` may differ from the id (`oceanic-next` uses `OceanicNext`).

**Every theme has the identical artifact set.** That uniformity catches both a generator missing
from `generate-all.sh` and a stale artifact left behind by a format migration.
`tests/generators.bats` asserts it.

### Where an applied theme lands

`theme apply` installs each artifact under the **theme's own id** and points a stable `current`
**symlink** at it: `themes/cendre-medium.conf` with `themes/current.conf -> cendre-medium.conf`.
`install_themed_artifact` in `lib.sh` is the one place that happens. yazi is the single
exception, because a flavor is a directory rather than a file.

Both halves are load-bearing. The pointer keeps the name `current` because the apps that can only
`source`/`@import`/`include` a **path** need one that does not move. The apps that resolve a theme
*by name* (ghostty, btop, bat, aerc, rofi) read their config from a symlink into the dotfiles
repo, so writing the name there would write through the link into that checkout. The payload
carries the id so a machine says which theme it is running, every applied theme stays installed
beside the others, and an exported config is self-describing.

Nothing is pruned, deliberately. These are also the directories a user's own themes live in, and
an installer that deletes what it does not recognize is worse than a few stale kilobytes.

Four apps have no pointer at all. dunst reads `dunstrc.d/` as a directory, firefox and Windows
Terminal have their real file rewritten, and sioyek gets a managed block spliced into its own
config.

`tests/apply-install.bats` pins it, including the two migration cases off the copy-based scheme:
a `current` left as a real file, and a `current.yazi` left as a real directory, which `ln -sfn`
would otherwise link *inside*.

## Creating a New Theme

Run from the repo root (`~/tools/theme`). Writing `theme.yml` is the whole job; every app config
is derived from it. `themes/*/theme.yml` shows the format.

1. **Write `themes/{id}/theme.yml`** — meta, base16, ansi, special, extended. Mapping a palette
   into those slots is the only part that takes judgment: see "Mapping a Palette into theme.yml" below.

2. **Generate every app config in one call.** Never invoke generators one by one.
   `generate-all.sh` owns the generator-to-filename mapping, runs them in parallel, and is the
   only thing guaranteed to leave a new theme with the same file set as every existing one:

   ```bash
   lib/generate-all.sh --themes {id}      # one theme, every generator
   lib/generate-all.sh --generators bat   # one generator, every theme
   lib/generate-all.sh --help             # lists the generators it knows about
   ```

   A generator that is not in that script's `GENERATOR_OUTPUT` map is invisible to it, so adding
   a generator means adding its map entry in the same commit.

3. **Verify against the source, not by eye.** When a theme comes from a plugin that ships its own
   terminal configs, diff the generated file against theirs. An exact match on every color is the
   proof the transcription is right:

   ```bash
   diff <(rg -N "^(background|foreground|cursor|selection|palette)" themes/{id}/ghostty.conf) \
        <(rg -N "^(background|foreground|cursor|selection|palette)" /path/to/upstream/extras/ghostty/{name})
   ```

4. **Plugin themes need a Neovim entry too** — see "Neovim Integration" below. Terminal configs
   alone leave the editor on the previous colorscheme.

5. **Deploy.** The installed tool reads `~/.local/share/theme`, not this repo, so nothing takes
   effect until a release ships: commit, push (the Release workflow tags it), then `theme update`,
   then `theme apply {id}`.

### Mapping a Palette into theme.yml

Upstream palettes are organized by *role* ("keywords", "types"); base16 slots are organized by
*hue*. When they conflict, **follow hue**. The generators mix `base16` and `ansi` values in the
same output file, so a role-based mapping puts a green in the slot a generator draws its red from.

- `base0D` is the single most-used slot (`rg -c BASE0D lib/generators/*.sh`), and generators
  treat it as the primary UI accent, not as "the blue". If a theme's true blue is a loud
  diagnostic color, set `base0D` to the restrained blue and put the intended accent in
  `extended.ui_accent`, which overrides `BASE0D` in every generator that draws UI chrome.
- `base06`/`base07` are "lighter/lightest foreground". Duplicating `base05` when a palette has no
  lighter ink is normal.
- The `extended` block is optional, but generators read a fixed set of keys from it and silently
  fall back when one is absent. List what is actually consumed:

  ```bash
  rg -o --no-filename "EXTENDED_[A-Z0-9_]+" lib/ | sort -u
  ```

### The Generated Neovim Colorscheme

Every theme has one, and `generate-all.sh` produces it like any other artifact:
`lib/generators/neovim.py`, mapped under `["neovim"]="neovim"`. It is the only generator written
in Python and the only one whose second argument is a directory. The job runner cares about
neither: it passes the mapped value through as `$2`. The PEP 723 header makes it directly
executable, so it needs no `uv run` wrapper at the call site.

**The name it emits depends on where the theme's colors come from**, and this is the constraint
to preserve:

| `neovim_colorscheme_source` | Emits | Why |
| --- | --- | --- |
| `generated` | `colors/{id}.lua` | The colorscheme *is* the theme, nothing upstream can collide, and the name is already in `history.jsonl` |
| `plugin` | `colors/theme-{id}.lua` | A fallback for a machine without the plugin, and the id is usually the plugin's own colorscheme name |

Most plugin themes have an id identical to the colorscheme their plugin provides (`kanagawa`,
`gruvbox`, `nordic`, `rose-pine`). Emitting `colors/kanagawa.lua` would put a second file of that
name on the runtimepath beside `rebelot/kanagawa.nvim`'s, and `:colorscheme kanagawa` would
resolve to whichever the runtimepath lists first. The prefix makes the fallback addressable
without displacing the real thing. `tests/generators.bats` pins this.

**`overrides.lua` is written only when absent, and preserved otherwise.** It is hand-edited, and
it lives inside the generated tree with nothing marking it. Any reimplementation that writes the
whole file map destroys every theme's customizations with no error. `write_file` rstrips and
re-adds one trailing newline so the templates agree with `end-of-file-fixer`; matching that
byte-for-byte is what keeps a regeneration diff empty.

**Only `palette.lua` is derived from `theme.yml`.** Every highlight file references
`M.palette.*` symbolically and is identical across themes but for the module name, which is the
id with hyphens replaced by underscores.

## Key Insights

- **The gist holds one history file per machine, and a machine writes only its own.** A union
  merge cannot express a deletion: a row removed on one machine is restored by the next machine
  to sync from a copy that still holds it. `_sync_merge_histories` takes each other machine's
  file as authoritative and keeps only this machine's rows from the local file, so removing a row
  you wrote is an ordinary edit. The pre-split gist `history.jsonl` is deliberately never read,
  because a machine on an older release still writes the whole merged set there.
  `scripts/split-gist-history.sh` is the one-time split, and it seeds *every* machine's file; an
  unseeded machine would vanish from the others' rankings until it updated.
- **The local `history.jsonl` is one merged file** holding every machine's rows. `lib/storage.sh`
  never learns the gist has more than one; only `lib/sync.sh` knows.
- **delta rides bat's theme cache.** `delta.conf` sets `syntax-theme = current`, which resolves
  through the bat cache `apply_bat` rebuilds. So delta applies after bat and requires both
  binaries. Renaming `current.tmTheme` breaks delta silently, with a stock Monokai fallback.
- **Generated output goes stale silently.** `themes/*/neovim/` and the app configs are committed
  artifacts, so a generator improvement does not reach a theme until that theme is regenerated.
  Regenerate broadly, and treat an unexpected diff as the generator having moved on, not as noise.
- **A generated colorscheme is a fallback, not a substitute.** It is derived from the palette,
  where the plugin was tuned by hand against real buffers. It exists so a machine without the
  plugin still changes color, and `theme apply` says so by name when Neovim will land on it.
- **Generate only through `generate-all.sh`.** A one-off generator invocation is how a deleted
  legacy artifact (`mako.ini`) came back into eight themes: the regeneration ran outside the
  script that owns the filename map.
- **Keep `GENERATOR_OUTPUT`'s subscripts quoted.** Unquoted, shfmt reads a subscript as
  arithmetic and rewrites `[ghostty-css]` as `[ghostty - css]`. Bash accepts the key, so the only
  symptom is a generator path that does not exist while every run reports all its jobs
  successful. `tests/generators.bats` pins this. The totals the script prints cannot, because
  they come from the map rather than the jobs.
- **A generator runs once per theme, so per-key `yq` calls are the cost.** `load_theme` reads
  `theme.yml` in a single yq pass. Add to that one program rather than alongside it.
- **An apply discards stderr, so a warning needs the array and not `echo`.**
  `apply_theme_to_apps` calls every `apply_*` as `apply_x "$theme" 2>/dev/null`, which keeps `cp`
  and reload noise off the screen and throws away anything written to stderr during an apply.
  `apply_warn` appends to `APPLY_WARNINGS`, which the caller prints after the per-app ticks.
- **The one failure with no output is Neovim.** A plugin theme names a colorscheme this tool does
  not ship, so a machine without the plugin gets a terminal that changes color and an editor that
  does not, while every tick says the apply worked. `check_neovim_colorscheme` looks for the
  `colors/<name>.{lua,vim}` that `:colorscheme` actually needs. It deliberately does not ask
  lazy.nvim where it puts plugins, so a plugin-manager migration cannot turn it into "always fine".
- **Config generation is seconds; the minutes are the backgrounds.** A full `generate-all.sh`
  takes seconds (`time bash lib/generate-all.sh` to re-measure). `background-recolor.sh` (gowall)
  and `background-lowpoly.sh` (ImageMagick at 3840x2160) are the slow part, and they are not in
  `generate-all.sh`.
- **Parenthesize a jq object value that pipes into `//`**: `last_used: map(…) |
  max_by(.ts) | .ts // "never"` parses on jq 1.8 and is a *syntax error* on 1.7,
  which fails the whole program rather than that one field. The workstations run
  1.8 and the CI runner runs 1.7, so this shape passes locally and breaks in CI —
  and broke `get_theme_stats()` in `lib/storage.sh`, which `theme info` reaches,
  on any machine still on 1.7. `jq --version` before believing a jq program works.
- **Change-signal colors are solved, not blended by a fixed fraction.** A fixed fraction lands at
  a different perceived strength on every palette. `delta.sh` searches for the blend that hits a
  target contrast ratio against that theme's own background.
- **`theme random` weights by recency, and every eligible theme stays reachable.**
  `compute_theme_weights` scores each candidate from days since its last apply, and
  `weighted_random_choice` samples that distribution. Apply count is the wrong axis: narrowing the
  draw to the least-applied set makes a newly added theme the only thing `random` can return
  until it catches up. `list_themes_not_rejected` is what the draw reads.

## Neovim Integration

Lives in `~/dotfiles/configs/common/.config/nvim/lua/plugins/colorscheme-manager.lua`.

**The coupling is two state files and nothing else.** This tool never knows
Neovim exists — it writes state, and Neovim pulls:

- `~/.local/state/theme/current` holds the theme id. `theme apply` writes it; a
  libuv `fs_event` watcher on that directory wakes Neovim on the write, so there
  is no polling and no restart. The manager reads the id, parses that theme's
  `theme.yml`, and runs `:colorscheme <meta.neovim_colorscheme_name>`. The same
  path runs at startup, which is why Neovim comes up matching the terminal.
- `~/.local/state/theme/history.jsonl` is parsed for reject/unreject entries so a
  rejected theme also disappears from the Telescope picker.

**It reads the installed copy** (`~/.local/share/theme/themes`), never this repo.
A new theme is invisible to Neovim until `theme update` has run.

**meta fields the manager reads** — these are the contract, so a typo here fails
silently rather than loudly:

| Field | Effect |
| ----- | ------ |
| `neovim_colorscheme_name` | What `:colorscheme` is called with |
| `neovim_colorscheme_source` | `plugin` or `generated`; also the picker's label suffix |
| `variant` | Sets `vim.o.background` before applying |
| `neovim_plugin_background` | Optional. Passed to `require(<colorscheme>).setup({background = ...})` before applying, for plugins whose variants are setup options rather than separate colorscheme names (cendre's three depths) |
| `plugin` | Not read by Neovim, but it names the repo that needs a lazy.nvim entry |
| `display_name` | Picker label |
| `id` | Breaks the tie when several themes share one colorscheme name |

**Adding a theme needs no Neovim-side edit.** `colorscheme-manager.lua` scans
`themes/*/neovim/` for the generated colorschemes and reads each `theme.yml`'s
`meta.plugin` for the lazy.nvim specs, so both halves come from this repo.

**Plugin palettes are a snapshot, and the seam is silent.** `theme.yml` is a
one-time transcription of the plugin's palette; nothing re-reads the plugin, so
Neovim follows upstream while every other app keeps whatever was transcribed.
`scripts/check-plugin-drift.sh` is the check — see below.

## Checking Plugin Themes Against Upstream

`scripts/check-plugin-drift.sh [theme-id ...]` compares every plugin theme with the colorscheme it
claims to mirror. It is development tooling and deliberately not a `theme` subcommand. Run it after
adding a plugin theme and occasionally otherwise. It finds upstream changing a color after the
transcription, and a transcription that was wrong from the start.

It cannot tell a wrong transcription from **deliberate divergence**. `solarized-osaka` carries
*classic* Solarized rather than craftzdog's variant, whose `bright.black` is the background and
makes bright-black text invisible. Do not "fix" it toward upstream. Decisions like this go in the
script's `SETTLED` map with their reason, so the check stops re-raising them.

Repos shipping a terminal config get an **exact** color-set check; only colors we have and upstream
lacks are errors. Everything else gets a **history** check, which only ever says "look at this".
The traps it encodes:

- **Do not baseline against `lazy-lock.json`.** The pin moves on every `:Lazy update`, so
  comparing against it reports nothing. The baseline is the date `theme.yml` was last committed.
- **A repo can host several colorschemes**, so the check keeps only changed files naming this
  theme's variant.
- **Judge by colors changed, never by filename.** A repo may keep its palette anywhere, and its
  `colors/*.lua` may be loaders holding no colors.
- **A shipped extra can be as stale as our own copy.** kanagawa's `extras/alacritty` disagrees
  with its own Lua source, so it is out of the exact-check map. Where formats disagree, check the
  freshest against the plugin's source before believing it.

When it flags something, read the upstream palette, fix `theme.yml`, then run
`lib/generate-all.sh --themes <id>`.

## Tests

`bats tests/` runs the suite; the pre-commit hook and CI run `tests/*.bats` flat.
`tests/helpers.bash` is shared.

**Every test must isolate before sourcing anything.** `isolate_theme_state`
repoints `HOME` **and the four XDG variables** at the sandbox and clears
`THEME_ENV` and `PLATFORM`, and it has to run first: both libraries read `HOME`
and `THEME_ENV` at *source* time to decide where state lives. A developer's shell
exports the XDG variables as absolute paths, so overriding `HOME` alone left the
Neovim colorscheme check reading the real `~/.local/share/nvim` and answering from
whichever plugins the machine running the suite happened to have. `THEME_ENV` is the one that bites — `.envrc` sets it to
`development` through direnv, so a suite inheriting a developer's shell writes its
history into `.dev-data` and passes while editing state a later manual run reads
back. `THEMES_DIR` is repointed separately by `use_fixture_themes_dir`, because it
is derived from `lib.sh`'s own location.

**Nothing may touch the machine it runs on.** `stub_command` shadows what the
opacity and reload paths shell out to: an unstubbed `tmux source-file` reaches the
developer's live tmux server and restyles their panes from the sandbox file.

**Speed is a design constraint**, because the hook runs this on every commit. Fixture records use
`printf`, not `jq`, since one process per record was a large fraction of the runtime. Assertions
on a pipeline use `run pipeline "foo | jq ..."`, never `run bash -c "source ../lib/lib.sh; ..."`,
which respawns a shell and re-sources the libraries for every assertion.

Coverage is the pure library functions, one file per concern. The apply path itself is not
covered: it mutates the live machine, which is what `scripts/test-all-themes.sh` and
`scripts/test-theme-apps.sh` are for, and why neither can run in CI.

`tests/generators.bats` carries the repo-wide invariants: every generator is in `generate-all.sh`'s
map and vice versa, no map subscript contains a space, every theme carries the identical artifact
set, and every artifact is one some generator produces. Its strongest check regenerates one theme
and diffs the result against what is committed. A mismatch means either the artifacts are stale
or a generator is not deterministic.

## Generators worth knowing

`ls lib/generators/` is the list, and each takes `<theme.yml> [output]`. `theme --help` lists the
CLI verbs. These generators behave unlike the rest:

- `sioyek.sh` emits a managed block spliced into the user's config, not a whole file.
- `aerc.sh` relies on aerc.conf pinning `styleset-name = current`, so the applied filename is a contract.
- `firefox-based.sh` writes one userChrome.css covering Firefox, Zen, Librewolf and Thunderbird.
- `vscode.sh` is not wired into `theme apply`; run it directly when needed.
- `glow.sh` emits a glamour style whose code blocks reach the screen quantized to xterm-256.
  glow never sets glamour's chroma formatter, so only prose keeps true color. `apply_glow` writes
  `glow.yml`'s `style` as an absolute path, because glamour expands neither `~` nor `$HOME` and
  glow exits 1 when the file is missing.

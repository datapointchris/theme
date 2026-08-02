# Theme System - Claude Code Context

## Overview

Unified theme generation system that creates consistent color configurations
across terminal and desktop applications from a single `theme.yml` source file.
Supports Ghostty, Kitty, Alacritty, tmux, btop, bat, delta, yazi, sioyek, JankyBorders,
Hyprland, Waybar, Rofi, Dunst/Mako, Firefox-based and Chromium browsers, Windows
Terminal, and more. Each theme in `themes/` provides app configs that match a
corresponding Neovim colorscheme.

## Directory Structure

Dev source is `~/tools/theme`; the installed copy everything actually reads is
`~/.local/share/theme` (see Neovim Integration for why that distinction bites).

```text
~/tools/theme/
├── bin/theme              # CLI: apply, change, like/dislike, background, sync
├── lib/
│   ├── theme.sh           # Loads theme.yml into the shell vars generators read
│   ├── generate-all.sh    # Runs every generator over every theme, in parallel
│   ├── generators/        # One script per app: <theme.yml> [output] -> config
│   ├── neovim_generator.py  # Builds a Neovim colorscheme plugin from theme.yml
│   ├── lib.sh, storage.sh, sync.sh  # Apply logic, JSONL history, Gist sync
│   └── browser-profiles.sh, theme-preview.sh
├── themes/{id}/           # theme.yml source + every generated app config
│   └── neovim/            # Present only for generated themes
├── demo/                  # Sample code files for generated backgrounds
├── scripts/               # Migration and test utilities
├── analysis/              # Research from the original palette investigation
└── install.sh

# Data locations (XDG-compliant):
# ~/.local/state/theme/history.jsonl   - Unified history (synced via gist)
# ~/.local/state/theme/current         - Current theme ID
# ~/.local/state/theme/sync-state.json - Sync configuration
```

## Theme Categories

Every theme is either **generated** (its Neovim colorscheme is built from
`theme.yml` into `themes/{id}/neovim/`) or **plugin** (it supplies app configs
that match a Neovim colorscheme someone else maintains). `theme.yml` is the only
place that fact is recorded, so read it from there rather than from a list here:

```bash
yq -r '[.meta.id, .meta.neovim_colorscheme_source, (.meta.plugin // "-"), .meta.derived_from] | @tsv' \
  themes/*/theme.yml | column -t -s$'\t'
```

Generated themes are the exception, not the rule — see Key Insights below for
why most themes are better off pairing a hand-tuned plugin with generated app
configs.

## Theme Files

Each theme directory contains app-specific configs generated from `theme.yml`:

```text
themes/{theme-id}/
├── theme.yml           # Source palette (required)
├── ghostty.conf        # Ghostty terminal colors
├── ghostty.css         # Ghostty tab custom CSS
├── kitty.conf          # Kitty terminal
├── alacritty.toml      # Alacritty terminal
├── tmux.conf           # tmux status bar
├── btop.theme          # btop system monitor
├── bat.tmTheme         # bat pager syntax theme
├── delta.conf          # delta git pager (included from gitconfig)
├── flavor.toml         # yazi file manager flavor
├── sioyek.config       # sioyek PDF viewer (managed block, spliced on apply)
├── userChrome.css      # Firefox-based browsers (Zen/Librewolf/Firefox/Thunderbird)
├── chromium.theme      # Chromium DevTools theme
├── icons.theme         # GTK icon theme (Arch)
├── bordersrc           # JankyBorders (macOS)
├── hyprland.conf       # Hyprland WM (Arch)
├── hyprland-picker.css # Hyprland color picker (Arch)
├── hyprlock.conf       # Hyprlock lock screen (Arch)
├── waybar.css          # Waybar status bar (Arch)
├── walker.css          # Walker launcher (Arch)
├── swayosd.css         # SwayOSD on-screen display (Arch)
├── rofi.rasi           # Rofi launcher (Arch)
├── dunst.conf          # Dunst notifications (Arch)
├── mako.conf           # Mako notifications (Arch)
├── windows-terminal.json  # Windows Terminal (WSL)
└── neovim/             # Only for generated themes - colorscheme plugin
```

**Every theme has the identical file set** — that uniformity is the check that
catches both a new theme built with a generator missing from `generate-all.sh`
and a stale artifact left behind by a format migration. Anything below the theme
count (other than `neovim/`, which only generated themes have) is a defect:

```bash
total=$(fd -HI '^theme.yml$' themes | wc -l)
for f in $(fd -HI -t f . themes -x basename {} | sort -u); do
  n=$(fd -HI "^${f}$" themes | wc -l)
  [ "$n" -ne "$total" ] && printf "%-24s %s/%s\n" "$f" "$n" "$total"
done
```

### theme.yml Format

```yaml
meta:
  id: "gruvbox-dark-hard"              # Directory name, lowercase-hyphen
  display_name: "Gruvbox Dark Hard"    # Pretty name for UI
  neovim_colorscheme_name: "gruvbox-dark-hard"  # What :colorscheme uses
  neovim_colorscheme_source: "generated"  # "generated" or "plugin"
  plugin: null                         # "author/repo" or null
  neovim_plugin_background: null       # Optional. Plugin variant that has no
                                       # colorscheme name of its own — passed to
                                       # require(<colorscheme>).setup{background=}
                                       # before applying (cendre's three depths)
  derived_from: "ghostty-builtin"      # Where colors came from
  variant: "dark"
  author: "morhetz"

base16:
  base00: "#1d2021"  # Background through base0F
  # ...

ansi:
  black: "#..."      # 16 ANSI terminal colors
  # ...

special:
  background: "#..."
  foreground: "#..."
  cursor: "#..."
  # ...

extended:
  # Theme-specific extra colors (optional)
```

## Theme Workflow

### Using Existing Themes

```bash
theme list                       # List with display names
theme change                     # Interactive picker
theme apply gruvbox-dark-hard    # Apply by id
theme current                    # Show current theme
theme like "great contrast"      # Rate current theme
theme reject "too bright"        # Remove from rotation
theme upgrade                    # Update to latest version

# Background management
theme background                 # Show background usage
theme background current         # Show current background
theme background rotate          # Rotate to new background
theme background mode set recolor generated:plasma  # Set modes
theme background source add ~/Pictures/wallpapers   # Add source

# Opacity
theme opacity                    # Show opacity usage
theme opacity current            # Show current opacity
theme opacity set 90             # Set opacity to 90%

# Sync
theme sync                       # Show sync usage
theme sync init                  # Initialize GitHub Gist sync
theme sync status                # Show sync status
```

### Creating a New Theme

Run from the repo root (`~/tools/theme`). Writing `theme.yml` is the whole job;
every app config is derived from it.

1. **Write `themes/{id}/theme.yml`** — meta, base16, ansi, special, extended.
   Mapping a palette into those slots is the only part that takes judgement:
   see "Mapping a Palette into theme.yml" below.

2. **Generate every app config in one call.** Never invoke generators one by one
   — `generate-all.sh` owns the generator-to-filename mapping, runs them in
   parallel, and is the only thing guaranteed to leave a new theme with the same
   file set as every existing one:

   ```bash
   lib/generate-all.sh --themes {id}      # one theme, every generator
   lib/generate-all.sh --generators bat   # one generator, every theme
   lib/generate-all.sh --help             # lists the generators it knows about
   ```

   A generator that is not in that script's `GENERATOR_OUTPUT` map is invisible
   to it, so adding a generator means adding its map entry in the same commit.

3. **Verify against the source, not by eye.** When a theme comes from a plugin
   that ships its own terminal configs, diff the generated file against theirs —
   an exact match on every colour is the proof the transcription is right:

   ```bash
   diff <(rg -N "^(background|foreground|cursor|selection|palette)" themes/{id}/ghostty.conf) \
        <(rg -N "^(background|foreground|cursor|selection|palette)" /path/to/upstream/extras/ghostty/{name})
   ```

4. **Plugin themes need a Neovim entry too** — see "Neovim Integration" below.
   Terminal configs alone leave the editor on the previous colorscheme.

5. **Deploy.** The installed tool reads `~/.local/share/theme`, not this repo, so
   nothing takes effect until a release ships: commit, push (the Release workflow
   tags it), then `theme upgrade`, then `theme apply {id}`.

### Mapping a Palette into theme.yml

Upstream palettes are organised by *role* ("keywords", "types"); base16 slots are
organised by *hue*. When they conflict, **follow hue** — every theme here does,
and the generators mix `base16` and `ansi` values in the same output file, so a
role-based mapping puts a green in the slot a generator draws its red from.

- `base0D` is the single most-used slot (`rg -c BASE0D lib/generators/*.sh`), and
  generators treat it as the primary UI accent, not as "the blue". If a theme's
  true blue is a loud diagnostic colour, set `base0D` to the restrained blue and
  put the intended accent in `extended.ui_accent`, which overrides `BASE0D` in
  every generator that draws UI chrome.
- `base06`/`base07` are "lighter/lightest foreground". Duplicating `base05` when
  a palette has no lighter ink is normal — several themes do it.
- The `extended` block is optional, but generators read a fixed set of keys from
  it and silently fall back when one is absent. List what is actually consumed:

  ```bash
  rg -o --no-filename "EXTENDED_[A-Z0-9_]+" lib/ | sort -u
  ```

### Creating a Generated Neovim Colorscheme

Only for themes with no upstream plugin (`neovim_colorscheme_source: "generated"`):

1. Generate the colorscheme:

   ```bash
   uv run --with pyyaml python3 lib/neovim_generator.py themes/{id}
   ```

2. `colorscheme-manager.lua` scans for `themes/*/neovim/` directories and
   registers each as a lazy.nvim plugin, so no Neovim-side edit is needed.

## Key Insights

- **Same palette ≠ same result**: Hand-crafted Neovim plugins often look
  better than generated colorschemes
- **Generated themes are rare**: Most themes work best with original Neovim
  plugin + generated terminal configs
- **neovim_colorscheme_name may differ from id**: e.g., `oceanic-next`
  directory uses `OceanicNext` colorscheme
- **delta rides bat's theme cache**: `delta.conf` sets `syntax-theme = current`,
  which resolves through the bat cache `apply_bat` rebuilds — hence delta applies
  after bat and requires both binaries. Renaming `current.tmTheme` breaks delta
  silently, with no error and a stock Monokai fallback.
- **Generated output goes stale silently**: `themes/*/neovim/` and the app
  configs are committed artifacts, so a generator improvement does not reach a
  theme until that theme is regenerated. Regenerate broadly rather than only the
  theme being worked on, and treat an unexpected diff as the generator having
  moved on, not as noise.
- **Generate only through `generate-all.sh`**: a one-off generator invocation is
  how `mako.ini` came back a week after the migration that deleted it — eight
  themes carried a dead legacy file for months because the regeneration ran
  outside the script that owns the filename map.
- **Change-signal colors are solved, not blended by a fixed fraction**: a fixed
  fraction lands at a different perceived strength on every palette. `delta.sh`
  searches for the blend that hits a target contrast ratio against that theme's
  own background, so every theme gets an equally legible diff.

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
A new theme is invisible to Neovim until `theme upgrade` has run.

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

**Adding a plugin theme needs an edit on both sides.** Generated themes are
picked up automatically (the manager scans for `themes/*/neovim/`), but a plugin
theme also needs its lazy.nvim entry adding to `colorscheme-manager.lua`, or
`:colorscheme` finds nothing and the apply silently leaves the old theme up.

**Plugin palettes are a snapshot, and the seam is silent.** `theme.yml` is a
one-time transcription of the plugin's palette; nothing re-reads the plugin, and
`analysis/experiments/neovim_palette_extractor.py` is research code from the
original investigation, not a pipeline. The plugin is pinned in `lazy-lock.json`,
so neither side drifts on its own — but `:Lazy update` moves Neovim to a re-tuned
upstream palette while every other app keeps the old values, with nothing to
report the divergence. After updating a colorscheme plugin, re-check its palette
against `theme.yml`.

## Files Reference

| File | Purpose |
| ---- | ------- |
| `bin/theme` | Theme CLI (apply, list, like/dislike, reject, sync) |
| `lib/lib.sh` | Core functions (get_theme_display_info, apply_theme_to_apps) |
| `lib/storage.sh` | Unified JSONL history with machine context |
| `lib/sync.sh` | GitHub Gist synchronization |
| `lib/theme.sh` | Loads theme.yml into shell variables for generators |
| `lib/neovim_generator.py` | Generates Neovim colorscheme from theme.yml |
| `install.sh` | Installation script for fresh installs |
| `scripts/migrate-history.sh` | One-time migration from old format |
| `lib/generate-all.sh` | Runs every generator over every theme in parallel; owns the generator-to-filename map |
| `lib/generators/*.sh` | One per app. `ls lib/generators/` enumerates them; each takes `<theme.yml> [output]` |
| `lib/generators/delta.sh` | Resolves through bat's theme cache — see Key Insights |
| `lib/generators/sioyek.sh` | Emits a managed block spliced into the user's config, not a whole file |
| `lib/generators/firefox-based.sh` | One userChrome.css covering Firefox, Zen, Librewolf and Thunderbird |
| `lib/generators/background*.sh` | Wallpaper generation and recolouring modes (macOS); `background.sh` dispatches |
| `lib/generators/vscode.sh` | Not wired into `theme apply`; run directly when needed |
| `lib/browser-profiles.sh` | Firefox-based browser profile discovery |
| `lib/theme-preview.sh` | ANSI color-swatch preview for the `theme change` fzf picker |

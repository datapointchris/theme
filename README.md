# theme

Unified theme management for terminal and desktop applications. Apply consistent color schemes across Ghostty, Kitty, tmux, btop, Neovim, and more from a single command — with themed backgrounds, opacity control, and cross-machine sync.

## Features

- **20+ themes** including Gruvbox, Rose Pine, Kanagawa, Nordic, Flexoki, and more
- **Cross-platform**: macOS, Linux (Arch/Hyprland), WSL
- **Themed backgrounds**: generated or recolored wallpapers that follow the active theme
- **Opacity control**: adjust terminal transparency across apps from one command
- **Cross-machine sync**: GitHub Gist synchronization keeps preferences in sync
- **Smart tracking**: like/dislike themes, track usage time, filter out rejected themes
- **Neovim integration**: themes match Neovim colorschemes (plugin or generated)

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/datapointchris/theme/main/install.sh | bash
```

Or manually:

```bash
git clone https://github.com/datapointchris/theme.git ~/.local/share/theme
ln -sf ~/.local/share/theme/bin/theme ~/.local/bin/theme
```

### Requirements

Core:

- `jq` — JSON processing
- `yq` — YAML processing ([mikefarah/yq](https://github.com/mikefarah/yq), the Go implementation)
- `fzf` — interactive theme picker
- `gh` — GitHub CLI (for the sync feature)

Optional:

- `bat` — syntax-highlighted output in `theme log`
- `imagemagick` (`convert`) — the `plasma` and `lowpoly` backgrounds
- `gowall` — the `recolor` background
- `ascii-image-converter` — the `ascii` background

## Usage

Running `theme` with no arguments prints the full help.

### Basic Commands

```bash
theme list                    # List all available themes
theme change                  # Interactive picker with color preview
theme apply <theme-id>        # Apply a specific theme
theme current                 # Show current theme and stats
theme random                  # Apply a random (least-used) theme
theme info [theme]            # Browse themes and view detailed history
theme verify                  # Check the theme system is healthy
```

### Rating Themes

```bash
theme like "great contrast"   # Mark current theme as liked
theme dislike "too dim"       # Mark as disliked
theme note "good for coding"  # Add a freeform note
theme reject "hurts my eyes"  # Remove from rotation (hidden from list)
theme unreject                # Restore a rejected theme (interactive picker)
```

### Rankings and History

```bash
theme rank                    # Rankings: by likes and by hours used
theme log                     # View complete history
theme rejected                # List rejected themes
```

### Backgrounds

Each theme can drive a matching desktop background. Four modes: `plasma` draws a
fractal cloud from the palette alone, while `ascii`, `lowpoly` and `recolor`
transform one of your own photos — into characters, into triangles, or into the
theme's colors.

```bash
theme background              # Show background usage/help
theme background current      # Show the active background
theme background rotate       # Pick a new background, keep the theme
theme background list         # List available backgrounds and current mode
theme background like         # Rate the current background (per theme)
theme background rank         # Rankings for this theme (--global for all)
theme background pre-generate # Pre-render all backgrounds for instant switching

# Which kinds of background to draw from
theme background mode current
theme background mode set generated:plasma recolor
theme background mode all

# Source images used by 'recolor' mode
theme background source add ~/Pictures/wallpapers
theme background source list
theme background source verify
```

### Opacity

```bash
theme opacity                 # Show opacity usage/help
theme opacity current         # Show current opacity
theme opacity set 90          # Set opacity to 90%
theme opacity up              # Increase by 5%
theme opacity down            # Decrease by 5%
```

Restart the terminal to see opacity changes.

### Browser Theming

```bash
theme browsers                # Show detected browsers and theme status
```

Firefox-based browsers (Zen, Librewolf, Firefox, Thunderbird) and Chromium are
themed automatically on `theme apply`. Firefox-based browsers require
`toolkit.legacyUserProfileCustomizations.stylesheets = true` in `about:config`,
then a restart, for `userChrome.css` to take effect.

### Cross-Machine Sync

Sync your theme preferences across machines using a GitHub Gist:

```bash
theme sync init               # One-time setup (creates gist)
theme sync status             # Show sync status
theme sync push               # Manual push
theme sync pull               # Manual pull
theme sync off                # Disable sync
theme sync on                 # Re-enable sync
```

After initialization, sync happens automatically in the background.

### Version and Updates

```bash
theme --version               # Show current version
theme update                  # Update to the latest tagged release
```

Releases are automated via [release-please](https://github.com/googleapis/release-please). The update command only checks out tagged releases, so you always land on a stable version.

theme also checks once a day and prints one line when a newer release exists:

```text
theme v4.12.0 available (running v4.11.0) — run `theme update`
```

It never installs anything and never prints an error — a failed check is recorded and swallowed, because an update notice must not break the command you typed. Nothing is printed when either stream is not a terminal, under CI, from a checkout that is not sitting on a release tag, or within the interval. Set `NO_AUTO_UPDATE` or `THEME_NO_AUTO_UPDATE` to turn it off, and `THEME_AUTO_UPDATE_INTERVAL=6h` to change the cadence.

Both commands come from [`bashselfupdate`](https://github.com/datapointchris/bashselfupdate), which `install.sh` installs. theme runs fine without it; only these two features need it.

## Supported Applications

### All Platforms

- **Ghostty** — terminal emulator (colors + tab CSS)
- **Kitty** — terminal emulator
- **tmux** — terminal multiplexer
- **btop** — system monitor
- **bat** — syntax highlighter / pager
- **delta** — git diff pager (requires bat; include
  `~/.config/delta/current.gitconfig` from your gitconfig)
- **yazi** — file manager
- **sioyek** — PDF viewer (custom color mode)
- **Neovim** — text editor (via colorscheme plugins or generated)
- **Browsers** — Firefox-based (Zen, Librewolf, Firefox, Thunderbird) and Chromium
- **Wallpaper** — themed desktop background, set through Finder on macOS,
  hyprpaper on Hyprland, and the Windows host on WSL

### macOS

- **JankyBorders** — window border highlights

### Arch Linux / Hyprland

- **Hyprland** — window manager colors
- **Hyprlock** — lock screen
- **Waybar** — status bar
- **Rofi** — application launcher
- **Dunst** / **Mako** — notification daemons

### WSL

- **Windows Terminal** — terminal colors

Additional generators (Alacritty, VS Code, walker, swayosd, GTK icons) live in
`lib/generators/` and can be run directly when needed.

## Theme Types

**Plugin themes** pair an existing Neovim colorscheme with generated app configs.
The plugin's author tuned the editor colors by hand and this tool matches
everything else to them, which in practice beats generating a colorscheme from
the same palette.

**Generated themes** build both the app configs *and* a Neovim colorscheme from a
single `theme.yml`, for palettes with no Neovim plugin behind them.

A plugin theme's `theme.yml` is a snapshot of that plugin's palette taken by
hand. Nothing re-reads the plugin, so if you update a colorscheme plugin and its
author has changed a color, Neovim moves and the other apps do not — re-check the
palette after updating one.

`theme list` shows every theme. To see which kind each one is, and which upstream
plugin a theme matches, read it from the source of truth:

```bash
yq -r '[.meta.display_name, .meta.neovim_colorscheme_source, (.meta.plugin // "-")] | @tsv' \
  themes/*/theme.yml | column -t -s$'\t'
```

## Data Storage

Data and configuration live in XDG-compliant locations:

```text
~/.local/state/theme/
├── history.jsonl      # Usage/rating history (synced)
├── current            # Current theme ID
└── sync-state.json    # Sync configuration

~/.config/theme/
├── background-mode          # Enabled background modes
└── background-sources.conf  # Source image references for recolor mode

~/.cache/theme/backgrounds/  # Pre-generated background cache
```

Opacity is stored per-app under each app's config directory (e.g.
`~/.config/ghostty/opacity`, `~/.config/tmux/opacity.conf`).

## Creating New Themes

1. Create a directory in `themes/` with your theme ID
2. Create `theme.yml` with color definitions:

```yaml
meta:
  id: "my-theme"
  display_name: "My Theme"
  neovim_colorscheme_source: "plugin"  # or "generated"
  plugin: "author/nvim-theme"          # if using a plugin
  variant: "dark"

base16:
  base00: "#1d2021"  # Background
  base01: "#3c3836"  # Lighter background
  # ... base02 through base0F

ansi:
  black: "#282828"
  red: "#cc241d"
  # ... all 16 ANSI colors

special:
  background: "#1d2021"
  foreground: "#ebdbb2"
  cursor: "#ebdbb2"
```

1. Generate every app config in one call:

   ```bash
   lib/generate-all.sh --themes my-theme
   ```

   Then `theme apply my-theme`. Plugin themes also need a lazy.nvim entry in
   `colorscheme-manager.lua` — `CLAUDE.md` covers the Neovim side and how to map
   an upstream palette into the base16 slots.

## License

MIT

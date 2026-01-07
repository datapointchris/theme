# theme

Unified theme management for terminal and desktop applications. Apply consistent color schemes across Ghostty, Kitty, tmux, btop, Neovim, and more from a single command.

## Features

- **40+ themes** including Gruvbox, Rose Pine, Kanagawa, Nordic, and more
- **Cross-platform**: macOS, Linux (Arch/Hyprland), WSL
- **Cross-machine sync**: GitHub Gist synchronization keeps preferences in sync
- **Smart tracking**: Like/dislike themes, track usage time, filter out rejected themes
- **Neovim integration**: Themes match Neovim colorschemes (plugin or generated)

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

- `jq` - JSON processing
- `fzf` - Interactive theme picker
- `gh` - GitHub CLI (for sync feature)

## Usage

### Basic Commands

```bash
theme list                    # List all available themes
theme change                  # Interactive picker with preview
theme apply <theme-id>        # Apply a specific theme
theme current                 # Show current theme and stats
theme random                  # Apply a random theme
```

### Rating Themes

```bash
theme like "great contrast"   # Mark current theme as liked
theme dislike "too dim"       # Mark as disliked
theme note "good for coding"  # Add a note
theme reject "hurts my eyes"  # Remove from rotation (hidden from list)
theme unreject                # Restore a rejected theme
```

### Rankings and History

```bash
theme rank                    # Show themes ranked by score and usage time
theme log                     # View complete history
theme rejected                # List rejected themes
```

### Cross-Machine Sync

Sync your theme preferences across machines using GitHub Gist:

```bash
theme sync init               # One-time setup (creates gist)
theme sync status             # Show sync status
theme sync push               # Manual push
theme sync pull               # Manual pull
theme sync off                # Disable sync
theme sync on                 # Re-enable sync
```

After initialization, sync happens automatically in the background.

### Updates

```bash
theme upgrade                 # Pull latest changes (shows changelog)
```

## Supported Applications

### All Platforms

- **Ghostty** - Terminal emulator
- **Kitty** - Terminal emulator
- **tmux** - Terminal multiplexer
- **btop** - System monitor
- **Neovim** - Text editor (via colorscheme plugins or generated)

### macOS

- **JankyBorders** - Window border highlights
- **Wallpaper** - Themed desktop wallpaper

### Arch Linux / Hyprland

- **Hyprland** - Window manager colors
- **Hyprlock** - Lock screen
- **Waybar** - Status bar
- **Rofi** - Application launcher
- **Dunst** / **Mako** - Notification daemons

### WSL

- **Windows Terminal** - Terminal colors

## Theme Types

### Plugin Themes

Most themes use existing Neovim colorscheme plugins. The theme system generates matching terminal configs:

| Theme | Neovim Plugin |
|-------|---------------|
| Gruvbox | ellisonleao/gruvbox.nvim |
| Rose Pine | rose-pine/neovim |
| Kanagawa | rebelot/kanagawa.nvim |
| Nordic | AlexvZyl/nordic.nvim |
| Terafox | EdenEast/nightfox.nvim |

### Generated Themes

Some themes generate both terminal configs AND a Neovim colorscheme from a single `theme.yml` source file.

## Data Storage

All data is stored in XDG-compliant locations:

```text
~/.local/state/theme/
├── history.jsonl      # Usage history (synced)
├── current            # Current theme ID
└── sync-state.json    # Sync configuration
```

## Creating New Themes

1. Create a directory in `themes/` with your theme ID
2. Create `theme.yml` with color definitions:

```yaml
meta:
  id: "my-theme"
  display_name: "My Theme"
  neovim_colorscheme_source: "plugin"  # or "generated"
  plugin: "author/nvim-theme"          # if using plugin
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

3. Generate app configs using the generators in `lib/generators/`

## License

MIT

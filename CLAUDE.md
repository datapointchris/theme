# Theme System - Claude Code Context

## Overview

Unified theme generation system that creates consistent color configurations
across terminal and desktop applications from a single `theme.yml` source file.
Supports Ghostty, Kitty, Alacritty, tmux, btop, bat, yazi, sioyek, JankyBorders,
Hyprland, Waybar, Rofi, Dunst/Mako, Firefox-based and Chromium browsers, Windows
Terminal, and more. Each theme in `themes/` provides app configs that match a
corresponding Neovim colorscheme.

## Directory Structure

```text
apps/common/theme/
├── bin/theme           # Theme CLI tool (apply, change, like/dislike)
├── demo/               # Sample code files for generated backgrounds
├── lib/                # Core libraries and generators
│   ├── generators/     # App-specific generators
│   │   ├── ghostty.sh, kitty.sh, alacritty.sh  # Terminal emulators (colors)
│   │   ├── ghostty-css.sh           # Ghostty tab custom CSS
│   │   ├── tmux.sh, btop.sh         # Terminal apps
│   │   ├── bat.sh                   # bat pager .tmTheme
│   │   ├── yazi.sh                  # yazi file manager flavor
│   │   ├── sioyek.sh                # PDF viewer (custom color mode)
│   │   ├── firefox-based.sh         # Firefox/Zen/Librewolf/Thunderbird userChrome
│   │   ├── chromium.sh              # Chromium DevTools theme
│   │   ├── vscode.sh                # VS Code theme
│   │   ├── borders.sh               # JankyBorders (macOS)
│   │   ├── background*.sh           # Themed backgrounds + transforms (macOS)
│   │   ├── hyprland.sh, hyprland-picker.sh, hyprlock.sh  # Hyprland WM (Arch)
│   │   ├── waybar.sh, rofi.sh, walker.sh  # Desktop apps (Arch)
│   │   ├── swayosd.sh, icons.sh     # OSD + GTK icon theme (Arch)
│   │   ├── dunst.sh, mako.sh        # Notification daemons
│   │   └── windows-terminal.sh      # WSL terminal
│   ├── neovim_generator.py  # Generates Neovim colorscheme plugin
│   └── theme.sh        # Loads theme.yml into shell variables
├── themes/             # 20+ themes with theme.yml source and generated configs
│   ├── gruvbox-dark-hard/  # With generated neovim/
│   ├── rose-pine-darker/   # With generated neovim/
│   ├── kanagawa/           # Terminal configs only (uses plugin for Neovim)
│   └── .../
├── scripts/            # Migration and utility scripts
├── install.sh          # Installation script
├── analysis/           # Research documentation
└── screenshots/        # Theme preview screenshots

# Data locations (XDG-compliant):
# ~/.local/state/theme/history.jsonl   - Unified history (synced via gist)
# ~/.local/state/theme/current         - Current theme ID
# ~/.local/state/theme/sync-state.json - Sync configuration
```

## Theme Categories

### Generated Themes (neovim_colorscheme_source: "generated")

These themes have generated Neovim colorschemes from theme.yml:

| Directory | display_name | Notes |
| --------- | ------------ | ----- |
| `charcoal-ember` | Charcoal Ember | Generated |
| `gruvbox-dark-hard` | Gruvbox Dark Hard | Ghostty-derived, neutral ANSI |
| `popping-and-locking` | Popping and Locking | Generated |
| `rose-pine-darker` | Rose Pine Darker | Base16-derived, darker background |
| `smyck` | Smyck | Generated |
| `treehouse` | Treehouse | Generated |

### Plugin Themes (neovim_colorscheme_source: "plugin")

These themes provide terminal configs that match original Neovim plugins:

- `gruvbox` - Gruvbox - ellisonleao/gruvbox.nvim
- `rose-pine` - Rose Pine - rose-pine/neovim
- `kanagawa` - Kanagawa - rebelot/kanagawa.nvim
- `nordic` - Nordic - AlexvZyl/nordic.nvim
- `nightfox` - Nightfox - EdenEast/nightfox.nvim
- `terafox` - Terafox - EdenEast/nightfox.nvim
- `everforest-dark-hard` - Everforest Dark Hard - neanias/everforest-nvim
- `oceanic-next` - Oceanic Next (`OceanicNext`) - mhartington/oceanic-next
- `github-dark-dimmed` - GitHub Dark Dimmed - projekt0n/github-nvim-theme
- `solarized-osaka` - Solarized Osaka - craftzdog/solarized-osaka.nvim
- `flexoki-moon-{black,green,purple,red}` - Flexoki Moon -
  datapointchris/flexoki-moon-nvim
- `retrobox` - Retrobox (`retrobox`) - Neovim built-in colorscheme (no plugin)

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
├── mako.conf, mako.ini # Mako notifications (Arch)
├── windows-terminal.json  # Windows Terminal (WSL)
└── neovim/             # Only for generated themes - colorscheme plugin
```

### theme.yml Format

```yaml
meta:
  id: "gruvbox-dark-hard"              # Directory name, lowercase-hyphen
  display_name: "Gruvbox Dark Hard"    # Pretty name for UI
  neovim_colorscheme_name: "gruvbox-dark-hard"  # What :colorscheme uses
  neovim_colorscheme_source: "generated"  # "generated" or "plugin"
  plugin: null                         # "author/repo" or null
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

1. Create `themes/{id}/theme.yml` with meta, base16, ansi, and special sections
2. Set `neovim_colorscheme_source: "plugin"` if using existing Neovim plugin
3. Set `neovim_colorscheme_source: "generated"` if generating Neovim colorscheme
4. Generate app configs using generators in `lib/generators/`:

```bash
cd apps/common/theme

# Core apps (all platforms)
bash lib/generators/ghostty.sh themes/{id}/theme.yml themes/{id}/ghostty.conf
bash lib/generators/ghostty-css.sh themes/{id}/theme.yml themes/{id}/ghostty.css
bash lib/generators/kitty.sh themes/{id}/theme.yml themes/{id}/kitty.conf
bash lib/generators/alacritty.sh themes/{id}/theme.yml themes/{id}/alacritty.toml
bash lib/generators/tmux.sh themes/{id}/theme.yml themes/{id}/tmux.conf
bash lib/generators/btop.sh themes/{id}/theme.yml themes/{id}/btop.theme
bash lib/generators/bat.sh themes/{id}/theme.yml themes/{id}/bat.tmTheme
bash lib/generators/yazi.sh themes/{id}/theme.yml themes/{id}/flavor.toml
bash lib/generators/sioyek.sh themes/{id}/theme.yml themes/{id}/sioyek.config
bash lib/generators/firefox-based.sh themes/{id}/theme.yml themes/{id}/userChrome.css
bash lib/generators/chromium.sh themes/{id}/theme.yml themes/{id}/chromium.theme

# macOS
bash lib/generators/borders.sh themes/{id}/theme.yml themes/{id}/bordersrc

# Arch/Hyprland
bash lib/generators/hyprland.sh themes/{id}/theme.yml themes/{id}/hyprland.conf
bash lib/generators/hyprland-picker.sh themes/{id}/theme.yml themes/{id}/hyprland-picker.css
bash lib/generators/hyprlock.sh themes/{id}/theme.yml themes/{id}/hyprlock.conf
bash lib/generators/waybar.sh themes/{id}/theme.yml themes/{id}/waybar.css
bash lib/generators/walker.sh themes/{id}/theme.yml themes/{id}/walker.css
bash lib/generators/swayosd.sh themes/{id}/theme.yml themes/{id}/swayosd.css
bash lib/generators/icons.sh themes/{id}/theme.yml themes/{id}/icons.theme
bash lib/generators/dunst.sh themes/{id}/theme.yml themes/{id}/dunst.conf
bash lib/generators/mako.sh themes/{id}/theme.yml themes/{id}/mako.conf
bash lib/generators/rofi.sh themes/{id}/theme.yml themes/{id}/rofi.rasi

# WSL
bash lib/generators/windows-terminal.sh themes/{id}/theme.yml themes/{id}/windows-terminal.json
```

### Creating a Generated Neovim Colorscheme

If creating a new colorscheme (not using a plugin):

1. Generate Neovim colorscheme:

   ```bash
   uv run --with pyyaml python3 \
     ~/dotfiles/apps/common/theme/lib/neovim_generator.py \
     ~/dotfiles/apps/common/theme/themes/{id}
   ```

2. The colorscheme is auto-loaded by `colorscheme-manager.lua` which scans
   for `neovim/` directories

## Key Insights

- **Same palette ≠ same result**: Hand-crafted Neovim plugins often look
  better than generated colorschemes
- **Generated themes are rare**: Most themes work best with original Neovim
  plugin + generated terminal configs
- **neovim_colorscheme_name may differ from id**: e.g., `oceanic-next`
  directory uses `OceanicNext` colorscheme

## Neovim Integration

The `colorscheme-manager.lua` plugin:

- Dynamically loads generated colorschemes from `themes/*/neovim/` directories
- Builds display name mapping from theme.yml meta fields
- Filters rejected themes from the picker
- Watches `~/.local/state/theme/current` for changes (auto-updates when
  `theme apply` runs)

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
| `lib/generators/ghostty.sh` | Ghostty terminal colors |
| `lib/generators/ghostty-css.sh` | Ghostty tab custom CSS |
| `lib/generators/kitty.sh` | Kitty terminal colors |
| `lib/generators/alacritty.sh` | Alacritty terminal colors |
| `lib/generators/tmux.sh` | tmux status bar theme |
| `lib/generators/btop.sh` | btop system monitor theme |
| `lib/generators/bat.sh` | bat pager .tmTheme |
| `lib/generators/yazi.sh` | yazi file manager flavor |
| `lib/generators/sioyek.sh` | sioyek PDF viewer custom-color-mode block |
| `lib/generators/firefox-based.sh` | Firefox/Zen/Librewolf/Thunderbird userChrome |
| `lib/generators/chromium.sh` | Chromium DevTools theme |
| `lib/generators/vscode.sh` | VS Code theme |
| `lib/generators/borders.sh` | JankyBorders window highlights (macOS) |
| `lib/generators/background.sh` | Themed background generator (macOS) |
| `lib/generators/hyprland.sh` | Hyprland WM colors (Arch) |
| `lib/generators/hyprland-picker.sh` | Hyprland color picker (Arch) |
| `lib/generators/hyprlock.sh` | Hyprlock lock screen (Arch) |
| `lib/generators/waybar.sh` | Waybar status bar (Arch) |
| `lib/generators/walker.sh` | Walker launcher (Arch) |
| `lib/generators/swayosd.sh` | SwayOSD on-screen display (Arch) |
| `lib/generators/icons.sh` | GTK icon theme (Arch) |
| `lib/generators/rofi.sh` | Rofi launcher (Arch) |
| `lib/generators/dunst.sh` | Dunst notifications (Arch) |
| `lib/generators/mako.sh` | Mako notifications (Arch) |
| `lib/generators/windows-terminal.sh` | Windows Terminal (WSL) |
| `lib/browser-profiles.sh` | Firefox-based browser profile discovery |
| `lib/theme-preview.sh` | ANSI color-swatch preview for the `theme change` fzf picker |

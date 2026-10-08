-- Retrobox - hyprland theme
-- Generated from theme.yml
-- Author: Maxim Kim (https://github.com/vim/colorschemes)
--
-- Applied as ~/.config/hypr/themes/current.lua, which a Hyprland config loads
-- with require('themes.current') after its own colors so these win.

local palette = {
  -- Base16
  base00 = 'rgb(1c1c1c)', -- Main background
  base01 = 'rgb(3c3836)', -- Lighter background
  base02 = 'rgb(504945)', -- Selection
  base03 = 'rgb(928374)', -- Comments
  base04 = 'rgb(a89984)', -- Dark foreground
  base05 = 'rgb(ebdbb2)', -- Foreground
  base06 = 'rgb(d5c4a1)', -- Light foreground
  base07 = 'rgb(fbf1c7)', -- Brightest
  base08 = 'rgb(fb4934)', -- Red
  base09 = 'rgb(fe8019)', -- Orange
  base0A = 'rgb(fabd2f)', -- Yellow
  base0B = 'rgb(b8bb26)', -- Green
  base0C = 'rgb(8ec07c)', -- Cyan
  base0D = 'rgb(83a598)', -- Blue
  base0E = 'rgb(d3869b)', -- Magenta
  base0F = 'rgb(d65d0e)', -- Brown

  -- Extended palette (when available)
  uiAccent = 'rgb(83a598)',
  uiBorder = 'rgb(504945)',
}

hl.config({
  -- Window borders
  general = {
    col = {
      active_border = palette.uiAccent,
      inactive_border = palette.uiBorder,
    },
  },

  -- Group borders
  group = {
    col = {
      border_active = palette.base0E,
      border_inactive = palette.base03,
      border_locked_active = palette.base09,
      border_locked_inactive = palette.base01,
    },
  },
})

return palette

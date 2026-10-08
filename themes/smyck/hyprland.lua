-- Smyck - hyprland theme
-- Generated from theme.yml
-- Author: hukl
--
-- Applied as ~/.config/hypr/themes/current.lua, which a Hyprland config loads
-- with require('themes.current') after its own colors so these win.

local palette = {
  -- Base16
  base00 = 'rgb(1b1b1b)', -- Main background
  base01 = 'rgb(2b2b2b)', -- Lighter background
  base02 = 'rgb(207483)', -- Selection
  base03 = 'rgb(7a7a7a)', -- Comments
  base04 = 'rgb(a1a1a1)', -- Dark foreground
  base05 = 'rgb(f7f7f7)', -- Foreground
  base06 = 'rgb(f7f7f7)', -- Light foreground
  base07 = 'rgb(f7f7f7)', -- Brightest
  base08 = 'rgb(b84131)', -- Red
  base09 = 'rgb(d6837c)', -- Orange
  base0A = 'rgb(c4a500)', -- Yellow
  base0B = 'rgb(7da900)', -- Green
  base0C = 'rgb(207383)', -- Cyan
  base0D = 'rgb(62a3c4)', -- Blue
  base0E = 'rgb(ba8acc)', -- Magenta
  base0F = 'rgb(ba8acc)', -- Brown

  -- Extended palette (when available)
  uiAccent = 'rgb(207383)',
  uiBorder = 'rgb(7a7a7a)',
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

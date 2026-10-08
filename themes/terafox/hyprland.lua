-- Terafox - hyprland theme
-- Generated from theme.yml
-- Author: EdenEast
--
-- Applied as ~/.config/hypr/themes/current.lua, which a Hyprland config loads
-- with require('themes.current') after its own colors so these win.

local palette = {
  -- Base16
  base00 = 'rgb(152528)', -- Main background
  base01 = 'rgb(1d3337)', -- Lighter background
  base02 = 'rgb(254147)', -- Selection
  base03 = 'rgb(6d7f8b)', -- Comments
  base04 = 'rgb(587b7b)', -- Dark foreground
  base05 = 'rgb(e6eaea)', -- Foreground
  base06 = 'rgb(eaeeee)', -- Light foreground
  base07 = 'rgb(cbd9d8)', -- Brightest
  base08 = 'rgb(e85c51)', -- Red
  base09 = 'rgb(ff8349)', -- Orange
  base0A = 'rgb(fda47f)', -- Yellow
  base0B = 'rgb(7aa4a1)', -- Green
  base0C = 'rgb(a1cdd8)', -- Cyan
  base0D = 'rgb(5a93aa)', -- Blue
  base0E = 'rgb(ad5c7c)', -- Magenta
  base0F = 'rgb(cb7985)', -- Brown

  -- Extended palette (when available)
  uiAccent = 'rgb(5a93aa)',
  uiBorder = 'rgb(2d4f56)',
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

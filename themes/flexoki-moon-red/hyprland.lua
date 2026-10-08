-- Flexoki Moon Red - hyprland theme
-- Generated from theme.yml
-- Author: datapointchris
--
-- Applied as ~/.config/hypr/themes/current.lua, which a Hyprland config loads
-- with require('themes.current') after its own colors so these win.

local palette = {
  -- Base16
  base00 = 'rgb(18090b)', -- Main background
  base01 = 'rgb(251a1a)', -- Lighter background
  base02 = 'rgb(3a2b28)', -- Selection
  base03 = 'rgb(8a6b60)', -- Comments
  base04 = 'rgb(b5967e)', -- Dark foreground
  base05 = 'rgb(f0e8dd)', -- Foreground
  base06 = 'rgb(ffeaec)', -- Light foreground
  base07 = 'rgb(ffffff)', -- Brightest
  base08 = 'rgb(d14d41)', -- Red
  base09 = 'rgb(da702c)', -- Orange
  base0A = 'rgb(d0a215)', -- Yellow
  base0B = 'rgb(879a39)', -- Green
  base0C = 'rgb(3aa99f)', -- Cyan
  base0D = 'rgb(4385be)', -- Blue
  base0E = 'rgb(8b7ec8)', -- Magenta
  base0F = 'rgb(ce5d97)', -- Brown

  -- Extended palette (when available)
  uiAccent = 'rgb(3aa99f)',
  uiBorder = 'rgb(8a6b60)',
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

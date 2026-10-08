-- Flexoki Moon Black - hyprland theme
-- Generated from theme.yml
-- Author: datapointchris
--
-- Applied as ~/.config/hypr/themes/current.lua, which a Hyprland config loads
-- with require('themes.current') after its own colors so these win.

local palette = {
  -- Base16
  base00 = 'rgb(100f0f)', -- Main background
  base01 = 'rgb(1c1b1a)', -- Lighter background
  base02 = 'rgb(282726)', -- Selection
  base03 = 'rgb(575653)', -- Comments
  base04 = 'rgb(878580)', -- Dark foreground
  base05 = 'rgb(cecdc3)', -- Foreground
  base06 = 'rgb(EDEECF)', -- Light foreground
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
  uiBorder = 'rgb(575653)',
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

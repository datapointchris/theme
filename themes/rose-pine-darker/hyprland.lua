-- Rose Pine Darker - hyprland theme
-- Generated from theme.yml
-- Author: Emilia Dunfelt <edun@dunfelt.se>
--
-- Applied as ~/.config/hypr/themes/current.lua, which a Hyprland config loads
-- with require('themes.current') after its own colors so these win.

local palette = {
  -- Base16
  base00 = 'rgb(191724)', -- Main background
  base01 = 'rgb(1f1d2e)', -- Lighter background
  base02 = 'rgb(26233a)', -- Selection
  base03 = 'rgb(6e6a86)', -- Comments
  base04 = 'rgb(908caa)', -- Dark foreground
  base05 = 'rgb(e0def4)', -- Foreground
  base06 = 'rgb(e0def4)', -- Light foreground
  base07 = 'rgb(524f67)', -- Brightest
  base08 = 'rgb(eb6f92)', -- Red
  base09 = 'rgb(f6c177)', -- Orange
  base0A = 'rgb(ebbcba)', -- Yellow
  base0B = 'rgb(31748f)', -- Green
  base0C = 'rgb(9ccfd8)', -- Cyan
  base0D = 'rgb(c4a7e7)', -- Blue
  base0E = 'rgb(f6c177)', -- Magenta
  base0F = 'rgb(524f67)', -- Brown

  -- Extended palette (when available)
  uiAccent = 'rgb(c4a7e7)',
  uiBorder = 'rgb(26233a)',
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

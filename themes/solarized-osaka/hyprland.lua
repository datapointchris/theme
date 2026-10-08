-- Solarized Osaka - hyprland theme
-- Generated from theme.yml
-- Author: Takuya Matsuyama (craftzdog)
--
-- Applied as ~/.config/hypr/themes/current.lua, which a Hyprland config loads
-- with require('themes.current') after its own colors so these win.

local palette = {
  -- Base16
  base00 = 'rgb(001419)', -- Main background
  base01 = 'rgb(002b36)', -- Lighter background
  base02 = 'rgb(073642)', -- Selection
  base03 = 'rgb(586e75)', -- Comments
  base04 = 'rgb(657b83)', -- Dark foreground
  base05 = 'rgb(839395)', -- Foreground
  base06 = 'rgb(a9b1b1)', -- Light foreground
  base07 = 'rgb(eee8d5)', -- Brightest
  base08 = 'rgb(db302d)', -- Red
  base09 = 'rgb(c94c16)', -- Orange
  base0A = 'rgb(b28500)', -- Yellow
  base0B = 'rgb(849900)', -- Green
  base0C = 'rgb(29a298)', -- Cyan
  base0D = 'rgb(268bd3)', -- Blue
  base0E = 'rgb(d23681)', -- Magenta
  base0F = 'rgb(f55350)', -- Brown

  -- Extended palette (when available)
  uiAccent = 'rgb(268bd3)',
  uiBorder = 'rgb(073642)',
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

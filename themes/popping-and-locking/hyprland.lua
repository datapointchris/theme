-- Popping and Locking - hyprland theme
-- Generated from theme.yml
-- Author: Hedinn Eiriksson
--
-- Applied as ~/.config/hypr/themes/current.lua, which a Hyprland config loads
-- with require('themes.current') after its own colors so these win.

local palette = {
  -- Base16
  base00 = 'rgb(181921)', -- Main background
  base01 = 'rgb(252631)', -- Lighter background
  base02 = 'rgb(383637)', -- Selection
  base03 = 'rgb(928374)', -- Comments
  base04 = 'rgb(a89984)', -- Dark foreground
  base05 = 'rgb(ebdbb2)', -- Foreground
  base06 = 'rgb(ebdbb2)', -- Light foreground
  base07 = 'rgb(ebdbb2)', -- Brightest
  base08 = 'rgb(cc5351)', -- Red
  base09 = 'rgb(e1656a)', -- Orange
  base0A = 'rgb(d79921)', -- Yellow
  base0B = 'rgb(98971a)', -- Green
  base0C = 'rgb(689d6a)', -- Cyan
  base0D = 'rgb(458588)', -- Blue
  base0E = 'rgb(b16286)', -- Magenta
  base0F = 'rgb(b16286)', -- Brown

  -- Extended palette (when available)
  uiAccent = 'rgb(458588)',
  uiBorder = 'rgb(ebdbb2)',
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

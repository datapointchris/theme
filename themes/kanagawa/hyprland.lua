-- Kanagawa - hyprland theme
-- Generated from theme.yml
-- Author: Tommaso Laurenzi (rebelot)
--
-- Applied as ~/.config/hypr/themes/current.lua, which a Hyprland config loads
-- with require('themes.current') after its own colors so these win.

local palette = {
  -- Base16
  base00 = 'rgb(1f1f28)', -- Main background
  base01 = 'rgb(16161d)', -- Lighter background
  base02 = 'rgb(2d4f67)', -- Selection
  base03 = 'rgb(727169)', -- Comments
  base04 = 'rgb(c8c093)', -- Dark foreground
  base05 = 'rgb(dcd7ba)', -- Foreground
  base06 = 'rgb(c8c093)', -- Light foreground
  base07 = 'rgb(717c7c)', -- Brightest
  base08 = 'rgb(c34043)', -- Red
  base09 = 'rgb(ffa066)', -- Orange
  base0A = 'rgb(c0a36e)', -- Yellow
  base0B = 'rgb(76946a)', -- Green
  base0C = 'rgb(6a9589)', -- Cyan
  base0D = 'rgb(7e9cd8)', -- Blue
  base0E = 'rgb(957fb8)', -- Magenta
  base0F = 'rgb(d27e99)', -- Brown

  -- Extended palette (when available)
  uiAccent = 'rgb(7e9cd8)',
  uiBorder = 'rgb(54546d)',
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

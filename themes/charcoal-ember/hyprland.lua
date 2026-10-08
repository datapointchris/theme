-- Charcoal Ember - hyprland theme
-- Generated from theme.yml
-- Author: datapointchris
--
-- Applied as ~/.config/hypr/themes/current.lua, which a Hyprland config loads
-- with require('themes.current') after its own colors so these win.

local palette = {
  -- Base16
  base00 = 'rgb(1d1f21)', -- Main background
  base01 = 'rgb(2d2d2d)', -- Lighter background
  base02 = 'rgb(373b41)', -- Selection
  base03 = 'rgb(969896)', -- Comments
  base04 = 'rgb(969896)', -- Dark foreground
  base05 = 'rgb(c5c8c6)', -- Foreground
  base06 = 'rgb(e0e0e0)', -- Light foreground
  base07 = 'rgb(ffffff)', -- Brightest
  base08 = 'rgb(c90d00)', -- Red
  base09 = 'rgb(f79802)', -- Orange
  base0A = 'rgb(ffc400)', -- Yellow
  base0B = 'rgb(60b45a)', -- Green
  base0C = 'rgb(5fb3b3)', -- Cyan
  base0D = 'rgb(4eb6fe)', -- Blue
  base0E = 'rgb(b294bb)', -- Magenta
  base0F = 'rgb(c09c24)', -- Brown

  -- Extended palette (when available)
  uiAccent = 'rgb(4eb6fe)',
  uiBorder = 'rgb(373b41)',
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

-- Cendre Medium - hyprland theme
-- Generated from theme.yml
-- Author: Aejkatappaja
--
-- Applied as ~/.config/hypr/themes/current.lua, which a Hyprland config loads
-- with require('themes.current') after its own colors so these win.

local palette = {
  -- Base16
  base00 = 'rgb(1d1917)', -- Main background
  base01 = 'rgb(26211f)', -- Lighter background
  base02 = 'rgb(312a28)', -- Selection
  base03 = 'rgb(73665b)', -- Comments
  base04 = 'rgb(a09384)', -- Dark foreground
  base05 = 'rgb(e6d5c2)', -- Foreground
  base06 = 'rgb(e6d5c2)', -- Light foreground
  base07 = 'rgb(e6d5c2)', -- Brightest
  base08 = 'rgb(d1766e)', -- Red
  base09 = 'rgb(ea9875)', -- Orange
  base0A = 'rgb(fcba81)', -- Yellow
  base0B = 'rgb(99af6b)', -- Green
  base0C = 'rgb(20c9cb)', -- Cyan
  base0D = 'rgb(4e89a2)', -- Blue
  base0E = 'rgb(9480ba)', -- Magenta
  base0F = 'rgb(ea9875)', -- Brown

  -- Extended palette (when available)
  uiAccent = 'rgb(ea9875)',
  uiBorder = 'rgb(3d3633)',
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

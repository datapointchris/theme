-- Nightfox - hyprland theme
-- Generated from theme.yml
-- Author: EdenEast
--
-- Applied as ~/.config/hypr/themes/current.lua, which a Hyprland config loads
-- with require('themes.current') after its own colors so these win.

local palette = {
  -- Base16
  base00 = 'rgb(192330)', -- Main background
  base01 = 'rgb(212e3f)', -- Lighter background
  base02 = 'rgb(29394f)', -- Selection
  base03 = 'rgb(738091)', -- Comments
  base04 = 'rgb(71839b)', -- Dark foreground
  base05 = 'rgb(cdcecf)', -- Foreground
  base06 = 'rgb(d6d6d7)', -- Light foreground
  base07 = 'rgb(aeafb0)', -- Brightest
  base08 = 'rgb(c94f6d)', -- Red
  base09 = 'rgb(f4a261)', -- Orange
  base0A = 'rgb(dbc074)', -- Yellow
  base0B = 'rgb(81b29a)', -- Green
  base0C = 'rgb(63cdcf)', -- Cyan
  base0D = 'rgb(719cd6)', -- Blue
  base0E = 'rgb(9d79d6)', -- Magenta
  base0F = 'rgb(d67ad2)', -- Brown

  -- Extended palette (when available)
  uiAccent = 'rgb(719cd6)',
  uiBorder = 'rgb(39506d)',
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

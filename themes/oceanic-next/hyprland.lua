-- Oceanic Next - hyprland theme
-- Generated from theme.yml
-- Author: Ghostty
--
-- Applied as ~/.config/hypr/themes/current.lua, which a Hyprland config loads
-- with require('themes.current') after its own colors so these win.

local palette = {
  -- Base16
  base00 = 'rgb(162c35)', -- Main background
  base01 = 'rgb(65737e)', -- Lighter background
  base02 = 'rgb(4f5b66)', -- Selection
  base03 = 'rgb(65737e)', -- Comments
  base04 = 'rgb(ffffff)', -- Dark foreground
  base05 = 'rgb(c0c5ce)', -- Foreground
  base06 = 'rgb(ffffff)', -- Light foreground
  base07 = 'rgb(ffffff)', -- Brightest
  base08 = 'rgb(ec5f67)', -- Red
  base09 = 'rgb(ec5f67)', -- Orange
  base0A = 'rgb(fac863)', -- Yellow
  base0B = 'rgb(99c794)', -- Green
  base0C = 'rgb(5fb3b3)', -- Cyan
  base0D = 'rgb(6699cc)', -- Blue
  base0E = 'rgb(c594c5)', -- Magenta
  base0F = 'rgb(c594c5)', -- Brown

  -- Extended palette (when available)
  uiAccent = 'rgb(6699cc)',
  uiBorder = 'rgb(343d46)',
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

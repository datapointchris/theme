-- Sora - hyprland theme
-- Generated from theme.yml
-- Author: Aejkatappaja
--
-- Applied as ~/.config/hypr/themes/current.lua, which a Hyprland config loads
-- with require('themes.current') after its own colors so these win.

local palette = {
  -- Base16
  base00 = 'rgb(0e1018)', -- Main background
  base01 = 'rgb(14161e)', -- Lighter background
  base02 = 'rgb(1e2430)', -- Selection
  base03 = 'rgb(586478)', -- Comments
  base04 = 'rgb(9aa4b8)', -- Dark foreground
  base05 = 'rgb(c8d0e0)', -- Foreground
  base06 = 'rgb(dce4f0)', -- Light foreground
  base07 = 'rgb(dce4f0)', -- Brightest
  base08 = 'rgb(d0909c)', -- Red
  base09 = 'rgb(d0a888)', -- Orange
  base0A = 'rgb(d4b878)', -- Yellow
  base0B = 'rgb(90c8a0)', -- Green
  base0C = 'rgb(78b8b0)', -- Cyan
  base0D = 'rgb(80c8e0)', -- Blue
  base0E = 'rgb(b0a0d8)', -- Magenta
  base0F = 'rgb(8898b8)', -- Brown

  -- Extended palette (when available)
  uiAccent = 'rgb(80c8e0)',
  uiBorder = 'rgb(222838)',
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

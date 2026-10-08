-- Everforest Dark Hard - hyprland theme
-- Generated from theme.yml
-- Author: sainnhe
--
-- Applied as ~/.config/hypr/themes/current.lua, which a Hyprland config loads
-- with require('themes.current') after its own colors so these win.

local palette = {
  -- Base16
  base00 = 'rgb(1e2326)', -- Main background
  base01 = 'rgb(2e383c)', -- Lighter background
  base02 = 'rgb(374145)', -- Selection
  base03 = 'rgb(859289)', -- Comments
  base04 = 'rgb(9da9a0)', -- Dark foreground
  base05 = 'rgb(d3c6aa)', -- Foreground
  base06 = 'rgb(d3c6aa)', -- Light foreground
  base07 = 'rgb(d3c6aa)', -- Brightest
  base08 = 'rgb(e67e80)', -- Red
  base09 = 'rgb(e69875)', -- Orange
  base0A = 'rgb(dbbc7f)', -- Yellow
  base0B = 'rgb(a7c080)', -- Green
  base0C = 'rgb(83c092)', -- Cyan
  base0D = 'rgb(7fbbb3)', -- Blue
  base0E = 'rgb(d699b6)', -- Magenta
  base0F = 'rgb(e69875)', -- Brown

  -- Extended palette (when available)
  uiAccent = 'rgb(a7c080)',
  uiBorder = 'rgb(414b50)',
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

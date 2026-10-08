-- GitHub Dark Dimmed - hyprland theme
-- Generated from theme.yml
-- Author: Projekt0n
--
-- Applied as ~/.config/hypr/themes/current.lua, which a Hyprland config loads
-- with require('themes.current') after its own colors so these win.

local palette = {
  -- Base16
  base00 = 'rgb(22272e)', -- Main background
  base01 = 'rgb(2d333b)', -- Lighter background
  base02 = 'rgb(373e47)', -- Selection
  base03 = 'rgb(768390)', -- Comments
  base04 = 'rgb(636e7b)', -- Dark foreground
  base05 = 'rgb(adbac7)', -- Foreground
  base06 = 'rgb(cdd9e5)', -- Light foreground
  base07 = 'rgb(ffffff)', -- Brightest
  base08 = 'rgb(f47067)', -- Red
  base09 = 'rgb(e0823d)', -- Orange
  base0A = 'rgb(c69026)', -- Yellow
  base0B = 'rgb(57ab5a)', -- Green
  base0C = 'rgb(96d0ff)', -- Cyan
  base0D = 'rgb(6cb6ff)', -- Blue
  base0E = 'rgb(dcbdfb)', -- Magenta
  base0F = 'rgb(e5534b)', -- Brown

  -- Extended palette (when available)
  uiAccent = 'rgb(539bf5)',
  uiBorder = 'rgb(444c56)',
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

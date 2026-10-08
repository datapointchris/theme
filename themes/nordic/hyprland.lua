-- Nordic - hyprland theme
-- Generated from theme.yml
-- Author: AlexvZyl
--
-- Applied as ~/.config/hypr/themes/current.lua, which a Hyprland config loads
-- with require('themes.current') after its own colors so these win.

local palette = {
  -- Base16
  base00 = 'rgb(242933)', -- Main background
  base01 = 'rgb(2E3440)', -- Lighter background
  base02 = 'rgb(3B4252)', -- Selection
  base03 = 'rgb(4C566A)', -- Comments
  base04 = 'rgb(60728A)', -- Dark foreground
  base05 = 'rgb(BBC3D4)', -- Foreground
  base06 = 'rgb(D8DEE9)', -- Light foreground
  base07 = 'rgb(E5E9F0)', -- Brightest
  base08 = 'rgb(BF616A)', -- Red
  base09 = 'rgb(D08770)', -- Orange
  base0A = 'rgb(EBCB8B)', -- Yellow
  base0B = 'rgb(A3BE8C)', -- Green
  base0C = 'rgb(8FBCBB)', -- Cyan
  base0D = 'rgb(81A1C1)', -- Blue
  base0E = 'rgb(B48EAD)', -- Magenta
  base0F = 'rgb(5E81AC)', -- Brown

  -- Extended palette (when available)
  uiAccent = 'rgb(88C0D0)',
  uiBorder = 'rgb(191D24)',
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

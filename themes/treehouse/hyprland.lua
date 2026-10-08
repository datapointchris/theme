-- Treehouse - hyprland theme
-- Generated from theme.yml
-- Author: Ghostty
--
-- Applied as ~/.config/hypr/themes/current.lua, which a Hyprland config loads
-- with require('themes.current') after its own colors so these win.

local palette = {
  -- Base16
  base00 = 'rgb(191919)', -- Main background
  base01 = 'rgb(252220)', -- Lighter background
  base02 = 'rgb(3a362d)', -- Selection
  base03 = 'rgb(504332)', -- Comments
  base04 = 'rgb(786b53)', -- Dark foreground
  base05 = 'rgb(786b53)', -- Foreground
  base06 = 'rgb(ffc800)', -- Light foreground
  base07 = 'rgb(ffc800)', -- Brightest
  base08 = 'rgb(b2270e)', -- Red
  base09 = 'rgb(ed5d20)', -- Orange
  base0A = 'rgb(aa820c)', -- Yellow
  base0B = 'rgb(44a900)', -- Green
  base0C = 'rgb(b25a1e)', -- Cyan
  base0D = 'rgb(58859a)', -- Blue
  base0E = 'rgb(97363d)', -- Magenta
  base0F = 'rgb(97363d)', -- Brown

  -- Extended palette (when available)
  uiAccent = 'rgb(58859a)',
  uiBorder = 'rgb(786b53)',
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

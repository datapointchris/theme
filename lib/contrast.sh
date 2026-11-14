#!/usr/bin/env bash
# Colors solved to a WCAG contrast ratio, for generators that draw a color pair
# the theme's author never tuned. Sourced by generators; outside lib/generators/
# because every script there is read as a generator.
#
# Every solve blends in gamma sRGB, so a blend toward a tinted background pulls
# the hue toward it and a blend toward white loses chroma.

# The WCAG contrast ratio between two colors.
contrast_ratio() {
  awk -v a="${1#\#}" -v b="${2#\#}" '
    function chan(h, i) { return strtonum("0x" substr(h, i, 2)) }
    function lin(v,  c) { c = v / 255; return (c <= 0.03928) ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4 }
    function lum(h) { return 0.2126 * lin(chan(h, 1)) + 0.7152 * lin(chan(h, 3)) + 0.0722 * lin(chan(h, 5)) }
    BEGIN { x = lum(a); y = lum(b); printf "%.4f\n", (x > y) ? (x + 0.05) / (y + 0.05) : (y + 0.05) / (x + 0.05) }'
}

# Blend accent toward bg until the result reaches target contrast against bg.
# The blend keeps at most cap of the accent (default 0.65), so a near-background
# accent can never produce an opaque slab, and a cap of 1 returns the accent
# itself when even it sits under the target.
band() {
  awk -v accent="${1#\#}" -v bg="${2#\#}" -v target="$3" -v cap="${4:-0.65}" '
    function chan(h, i) { return strtonum("0x" substr(h, i, 2)) }
    function lin(v,  c) { c = v / 255; return (c <= 0.03928) ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4 }
    function lum(r, g, b) { return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b) }
    function ratio(l1, l2) { return (l1 > l2) ? (l1 + 0.05) / (l2 + 0.05) : (l2 + 0.05) / (l1 + 0.05) }
    BEGIN {
      ar = chan(accent, 1); ag = chan(accent, 3); ab = chan(accent, 5)
      br = chan(bg, 1);     bg_ = chan(bg, 3);    bb = chan(bg, 5)
      base = lum(br, bg_, bb)
      best = cap
      for (f = 0.02; f <= cap; f += 0.01) {
        r = ar * f + br * (1 - f); g = ag * f + bg_ * (1 - f); b = ab * f + bb * (1 - f)
        if (ratio(lum(r, g, b), base) >= target) { best = f; break }
      }
      r = ar * best + br * (1 - best); g = ag * best + bg_ * (1 - best); b = ab * best + bb * (1 - best)
      printf "#%02x%02x%02x\n", int(r + 0.5), int(g + 0.5), int(b + 0.5)
    }'
}

# Push text toward white or black until it reads at target on surface. The push
# goes toward whichever extreme contrasts more with the surface. The two
# contrasts multiply to 21, so that one is never below 4.58:1 and the target is
# always reachable. Each candidate is rounded before it is measured, so the
# check is on the color actually emitted. Text already at the target comes back
# unchanged.
legible() {
  awk -v text="${1#\#}" -v surface="${2#\#}" -v target="$3" '
    function chan(h, i) { return strtonum("0x" substr(h, i, 2)) }
    function lin(v,  c) { c = v / 255; return (c <= 0.03928) ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4 }
    function lum(r, g, b) { return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b) }
    function ratio(l1, l2) { return (l1 > l2) ? (l1 + 0.05) / (l2 + 0.05) : (l2 + 0.05) / (l1 + 0.05) }
    BEGIN {
      tr = chan(text, 1); tg = chan(text, 3); tb = chan(text, 5)
      base = lum(chan(surface, 1), chan(surface, 3), chan(surface, 5))
      toward = (ratio(1, base) >= ratio(0, base)) ? 255 : 0
      r = toward; g = toward; b = toward
      for (f = 0; f < 1; f += 0.02) {
        cr = int(toward * f + tr * (1 - f) + 0.5)
        cg = int(toward * f + tg * (1 - f) + 0.5)
        cb = int(toward * f + tb * (1 - f) + 0.5)
        if (ratio(lum(cr, cg, cb), base) >= target) { r = cr; g = cg; b = cb; break }
      }
      printf "#%02x%02x%02x\n", r, g, b
    }'
}

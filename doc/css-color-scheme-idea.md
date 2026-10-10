# Idea (shelved): store color schemes entirely in CSS

Currently `ColorScheme` (see `src/ColorScheme.coffee`, `src/Settings.coffee`)
defines naub palettes and their light/dark `background`/`foreground` pairs in
CoffeeScript. `Naubino#apply_color_scheme` pushes the active scheme's
background onto `--canvas-background-color` so CSS can pick it up.

An alternative would be to flip that: define schemes as CSS custom
properties, scoped by a `data-scheme` attribute on `<html>`, with
`prefers-color-scheme` nested per scheme:

```css
:root { color-scheme: light dark; }

[data-scheme="output"] {
  --naub-0: rgb(229,53,23);
  --naub-1: rgb(151,190,13);
  /* ... */
  --background: white;
  --foreground: black;
}

[data-scheme="70"] {
  --background: rgb(237,224,194);
  --foreground: rgb(41,14,3);
}
@media (prefers-color-scheme: dark) {
  [data-scheme="70"] {
    --background: rgb(41,14,3);
    --foreground: rgb(237,224,194);
  }
}
```

JS would set `document.documentElement.dataset.scheme = name` instead of
mutating a settings object, and read colors back for canvas drawing via
`getComputedStyle(document.documentElement).getPropertyValue('--background')`
(cached, re-read only on scheme/theme change, not per frame).

## Why this could be nice

- Single source of truth for theming; no code changes needed to retheme.
- Dark/light switching becomes free and instant via
  `@media (prefers-color-scheme: dark)` - no `matchMedia(...).addEventListener`
  plumbing needed just to keep colors in sync.
- The CSS Color 5 `light-dark()` function is a close native analog to
  `ColorScheme`'s "dark defaults to inverted light" fallback.

## Why we're not doing it now

- Canvas drawing still needs real color strings, so naub/join colors would
  have to be read back from computed styles and cached/parsed into arrays
  anyway (e.g. for `Util.interpolate_color`). This moves complexity rather
  than removing it.
- Loses the colocated named/commented tuples
  (`[229, 53, 23, 1, "red"]`) unless mirrored with CSS comments.
- Bigger refactor with more moving parts for payoff that's mostly aesthetic
  at our current scale (a handful of palettes).

If we revisit this, the lowest-risk first step is migrating only
`--background`/`--foreground` per scheme to CSS (since those are already
being pushed into a CSS var), leaving the 7-color `naubs` arrays in
CoffeeScript.

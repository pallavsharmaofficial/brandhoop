# Colour palette

One source: `tools/brand/palette.py`. Run it after any change.

```
python3 tools/brand/palette.py
```

It writes

- `site/assets/brand-tokens.css`: CSS variables for the website (`--navy-700`, `--accent`, `--ink`, `--bg`, ...), with the dark theme.
- `lib/app/palette.dart`: the same colours as Dart constants (`Palette.navy700`, `Palette.lightBg`, `Palette.nightBg`, ...). `BrandColors` in `lib/app/theme.dart` points at them.
- `site/brand/palette/index.html`: a swatch page (tap to copy) with the contrast checks. Live at `/brand/palette/`.

Three ramps from the logo, 50 (lightest) to 900 (darkest):

| Ramp | Logo colour | Use |
|---|---|---|
| Navy | 700 `#1F2744` | brand, headings, the dark hero |
| Saffron | 500 `#D8662A` | the one accent: buttons, highlights, active states |
| Slate | 600 `#566170` | text, borders, page grounds |

Semantic tokens (`bg`, `surface`, `ink`, `muted`, `brand`, `accent`, `accent-ink`, `accent-soft`, `accent-text`, ...) switch between light and night. The script checks WCAG contrast for every text pair in use (21 checks) and stops if one is too low. The accent button label is dark navy-black (`accent-ink`), not white, because white on `#D8662A` is under 4.5:1.

## Motion

Website: reveal on scroll, hover lift on cards and tiles, a button shine, floating hero chips, an auto-advancing offers banner, live brand filter and search. All of it stops under `prefers-reduced-motion`, and the page is complete without scripts.
App: `lib/widgets/motion.dart` has `Reveal` (fade and rise as a section is built, which in a lazy list means as it scrolls into view), `Pressable` (press and hover scale) and `Floating` (hero phones). Each shows its end state when the phone's "remove animations" setting is on.

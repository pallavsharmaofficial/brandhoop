# Visiting card for the printer: vector, CMYK

Files in `site/brand/print/vector/`:

| File | What it is |
|---|---|
| `brandhoop-visiting-card-CMYK-vector-bleed-3mm.pdf` | Front and back (2 pages), 94.9 x 56.8 mm with 3 mm bleed on every side, TrimBox 88.9 x 50.8 mm (3.5 x 2 in). Give the printer this one. |
| `brandhoop-visiting-card-CMYK-vector-trim.pdf` | The same two pages cropped to the finished size (no bleed). |

Everything is vector: the logo, the traced phone-accessory line art (5 % white), the grid, the QR code and the text (Montserrat and Noto Sans Devanagari, subset and embedded, both OFL). There are no pictures in the PDFs. Colours are DeviceCMYK, converted through the sRGB to Ghostscript-default-CMYK ICC profile (relative colorimetric, black point compensation). Largest ink total is 296 %.

Brand colours as CMYK: orange #D8662A is C11 M73 Y99 K1, navy #1F2744 is C91 M84 Y45 K47, the dark card ground is C87 M80 Y52 K67, white is 0/0/0/0.

Rebuild: `bash tools/brand/build_all.sh`, or just the card: `node tools/brand/make_vector_card.js && python3 tools/brand/make_vector_cmyk.py`. To use the printer's own profile: `CMYK_ICC=/path/to/profile.icc python3 tools/brand/make_vector_cmyk.py`.

How: `make_vector_card.js` runs the Card Studio's own drawing code against canvas2svg, so the layout is the one in the PNGs, then Chromium prints the SVG to a vector PDF; `make_vector_cmyk.py` rewrites the colours in place (Ghostscript would turn every gradient that has transparency into a low-resolution picture), converts the soft masks to grey and sets the page boxes. The logo's soft glow and shadow (blur filters) are left out of the print version, because a blur is a picture in a PDF.

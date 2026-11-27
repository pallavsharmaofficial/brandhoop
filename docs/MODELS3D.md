# 3D phone view

Product pages of phones that have a 3D model show **Photos | 3D View**. Nothing 3D is downloaded
until the customer taps the play button on the poster.

## How it fits together

| Piece | Where |
|---|---|
| Viewer page (model-viewer 4.4.0, self-hosted, no CDN) | `site/viewer3d.html`, `site/vendor/` (model-viewer + Draco decoder) |
| Models and posters | `site/models/<productId>.glb` and `.webp` |
| Product data | `model3d` object on the product in `assets/live/shop.json` (`lib/domain/model3d.dart`) |
| Product page UI | `lib/features/catalog/product_media.dart` |
| iframe (web) / webview (Android) | `lib/features/catalog/viewer3d/` |
| Collection tools | `tools/models3d/` |
| Credits | `site/credits.html` (made by `tools/catalog/make_credits_page.py`) |

The viewer page talks to the app with `{source:'brandhoop-3d', type, ...}` messages (`ready`, `progress`,
`load`, `error`, `fullscreen`): `postMessage` in the browser, the `Brandhoop3D` JS channel in the Android
webview. An `error` (no WebGL, blocked or broken file, 45 s without a load) sends the page back to the photos
and hides the 3D tab. Inline, only a sideways drag turns the phone, so the page still scrolls; fullscreen
takes every touch (rotate, pinch zoom) and offers AR (Scene Viewer on Android, Quick Look on iOS).

## Adding a model for a new phone

```
cd tools/models3d && npm ci                       # once
python3 tools/models3d/search_sketchfab.py        # CC0 / CC BY downloadable models, cached in manifest.json
# open manifest.json: put the uid of the right candidate in "choice".
# "exact" means every word of the model name is in the title and the title adds no variant word
# (V80 Lite is not V80). Check the picture. A sibling model needs "representative": true on top.
python3 tools/models3d/pipeline.py <product-id>   # download, optimise (<= 3 MB), poster, manifest
python3 tools/models3d/attach.py                  # write model3d into shop.json
python3 tools/catalog/make_credits_page.py
```

The Sketchfab download needs a free API token. Export `SKETCHFAB_TOKEN` (never commit it). Only licences that
allow commercial use and changes are accepted: CC0 and CC BY.

`tools/models3d/search_commons.py` + `process_photos.py` do the same for Wikimedia Commons photos.
`tools/catalog/build_catalog.py` calls `attach.apply()` so a catalogue rebuild keeps all of this.

## Licences

CC BY needs a credit: the product page shows "3D model: title by author, licence (source)" with links.
A model that is only a stand-in for the phone also says "Representative model, colour may differ".

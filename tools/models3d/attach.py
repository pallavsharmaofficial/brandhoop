#!/usr/bin/env python3
"""Puts the collected media into assets/live/shop.json:

  * product["model3d"]  from manifest.json (entries that have a "model3d" object)
  * extra photos         from photos_manifest.json (entries with "accepted": [files in site/products/])

build_catalog.py calls apply() on every rebuild, so a rebuild never loses them.
Run on its own to patch shop.json without rebuilding the catalogue:

    python3 tools/models3d/attach.py
"""
import json, pathlib

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
RAW = 'https://raw.githubusercontent.com/pallavsharmaofficial/brandhoop/main/'


def _load(name):
    f = HERE / name
    return json.loads(f.read_text()) if f.exists() else {}


def apply(products):
    models, photos = _load('manifest.json'), _load('photos_manifest.json')
    n3d = nph = 0
    for p in products:
        m = (models.get(p['id']) or {}).get('model3d')
        if m and (ROOT / 'site/models' / f"{p['id']}.glb").exists():
            p['model3d'] = m; n3d += 1
        else:
            p.pop('model3d', None)
        acc = (photos.get(p['id']) or {}).get('accepted') or []
        files = [RAW + 'site/products/' + a['saved'] for a in acc if (ROOT / 'site/products' / a['saved']).exists()]
        if files:
            urls = [u for u in p.get('imageUrls', []) if u not in files]
            p['imageUrls'] = files + urls; nph += 1
    return n3d, nph


if __name__ == '__main__':
    path = ROOT / 'assets/live/shop.json'
    shop = json.loads(path.read_text())
    a, b = apply(shop['products'])
    path.write_text(json.dumps(shop, ensure_ascii=False, indent=2) + '\n')
    print(f'{a} products with a 3D model, {b} with extra photos')

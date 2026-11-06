#!/usr/bin/env python3
"""Turns downloaded Wikimedia Commons photos into site/products/<id>.jpg (3:2,
blurred-edge frame) and writes tools/catalog/commons_credits.json.

    python3 tools/catalog/process_commons.py <folder with <id>.jpg> <batch_result.json>

Only photos a person has looked at and accepted are listed in ACCEPT, with the
crop (left, top, right, bottom as fractions) that leaves out store clutter.
"""
import json, pathlib, sys
from PIL import Image, ImageFilter, ImageOps

ACCEPT = {
    'iphone-17': (0, 0, 1, 1),
    'iphone-17-pro': (0, 0, 1, 1),
    'iphone-16': (0, 0, 1, 1),
    'iphone-16e': (0.05, 0, 0.85, 1),
    'google-pixel-9a': (0, 0.10, 0.86, 1),
    'samsung-galaxy-a36-5g': (0, 0, 1, 1),
    'samsung-galaxy-a56-5g': (0, 0, 1, 1),
}
HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]

def frame(im, W=900, H=600):
    im = im.convert('RGB'); cover = ImageOps.fit(im, (W, H), Image.LANCZOS)
    if abs(im.width / im.height - W / H) < 0.12: return cover
    bg = cover.filter(ImageFilter.GaussianBlur(26)); k = min((H - 30) / im.height, (W - 30) / im.width)
    fg = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS); bg.paste(fg, ((W - fg.width) // 2, (H - fg.height) // 2)); return bg

src = pathlib.Path(sys.argv[1]); meta = json.load(open(sys.argv[2])); credits = []
for pid, (l, t, r, b) in ACCEPT.items():
    f = src / f'{pid}.jpg'
    if not f.exists(): print('missing', pid); continue
    im = ImageOps.exif_transpose(Image.open(f)); w, h = im.size
    im = im.crop((int(l * w), int(t * h), int(r * w), int(b * h)))
    frame(im).save(ROOT / 'site' / 'products' / f'{pid}.jpg', quality=82, optimize=True, progressive=True)
    m = meta[pid]; credits.append({'id': pid, 'file': m['file'], 'author': m['artist'], 'license': m['lic'], 'page': 'https://commons.wikimedia.org/wiki/File:' + m['file'].replace(' ', '_')})
    print('ok', pid, m['lic'], m['artist'])
(HERE / 'commons_credits.json').write_text(json.dumps(credits, ensure_ascii=False, indent=1))

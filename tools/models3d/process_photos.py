#!/usr/bin/env python3
"""Downloads accepted Wikimedia Commons photos, frames them 3:2 (blurred-edge frame, like
tools/catalog/process_commons.py), saves site/products/<id>-<n>.jpg and records author and
licence in photos_manifest.json ("accepted") and tools/catalog/commons_credits.json (the credits page).

    python3 tools/models3d/process_photos.py <product-id> <file-index> [<file-index> ...]
    python3 tools/models3d/process_photos.py --preview <product-id>      # saves originals to ./preview/ to look at

Index = position in photos_manifest.json[<id>]["photos"]. Only photos a person has looked at
should be accepted. Rate limits (HTTP 429) are waited out.
"""
import json, pathlib, sys, time, urllib.error, urllib.request, io
from PIL import Image, ImageFilter, ImageOps

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
PM = HERE / 'photos_manifest.json'
CREDITS = ROOT / 'tools/catalog/commons_credits.json'


def fetch(url):
    for i in range(8):
        try:
            time.sleep(2)
            return urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'brandhoop-catalog/1.0'}), timeout=120).read()
        except urllib.error.HTTPError as e:
            if e.code not in (429, 500, 502, 503, 504): raise
            time.sleep(int(e.headers.get('Retry-After') or 0) or 30 * (i + 1))
    raise RuntimeError('still rate-limited: ' + url)


def frame(im, W=900, H=600):
    im = im.convert('RGB'); cover = ImageOps.fit(im, (W, H), Image.LANCZOS)
    if abs(im.width / im.height - W / H) < 0.12: return cover
    bg = cover.filter(ImageFilter.GaussianBlur(26)); k = min((H - 30) / im.height, (W - 30) / im.width)
    fg = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS); bg.paste(fg, ((W - fg.width) // 2, (H - fg.height) // 2)); return bg


def main():
    a = sys.argv[1:]
    man = json.loads(PM.read_text())
    if a and a[0] == '--preview':
        pid = a[1]; (HERE / 'preview').mkdir(exist_ok=True)
        for i, h in enumerate(man[pid]['photos']):
            im = ImageOps.exif_transpose(Image.open(io.BytesIO(fetch(h['url'])))); im.thumbnail((900, 900))
            im.convert('RGB').save(HERE / 'preview' / f'{pid}-{i}.jpg', quality=85); print('preview', pid, i, h['file'])
        return
    pid, idx = a[0], [int(x) for x in a[1:]]
    e = man[pid]; acc = e.setdefault('accepted', []); credits = json.loads(CREDITS.read_text()) if CREDITS.exists() else []
    for i in idx:
        h = e['photos'][i]
        if any(x['file'] == h['file'] for x in acc): print('already', h['file']); continue
        im = ImageOps.exif_transpose(Image.open(io.BytesIO(fetch(h['url']))))
        saved = f'{pid}-{len(acc) + 1}.jpg'
        frame(im).save(ROOT / 'site/products' / saved, quality=82, optimize=True, progressive=True)
        acc.append({'saved': saved, 'file': h['file'], 'author': h['author'], 'license': h['license'], 'licenseUrl': h['licenseUrl'], 'page': h['page']})
        if not any(c['file'] == h['file'] for c in credits):
            credits.append({'id': pid, 'file': h['file'], 'author': h['author'], 'license': h['license'], 'page': h['page']})
        print('saved', saved, h['license'], h['author'])
    PM.write_text(json.dumps(man, ensure_ascii=False, indent=1)); CREDITS.write_text(json.dumps(credits, ensure_ascii=False, indent=1))


main()

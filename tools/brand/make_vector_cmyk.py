#!/usr/bin/env python3
"""Turns the vector RGB PDFs from make_vector_card.js into print files: CMYK, still vector, page boxes set.

    node tools/brand/make_vector_card.js
    python3 tools/brand/make_vector_cmyk.py

Why not Ghostscript: it turns every gradient that has transparency into a low resolution picture. Here the colours are
converted in place instead: every "r g b rg" in the page, in forms and in tiling patterns becomes "c m y k k", and the
colour stops of the gradients (shading functions) are converted too, so shapes, text and gradients stay vector.
The conversion goes through ICC profiles (sRGB to Ghostscript's default CMYK profile, relative colorimetric with black
point compensation); pass CMYK_ICC=/path/to/profile.icc to use the printer's own profile (e.g. a FOGRA39 or SWOP file).

Output, in site/brand/print/vector/ :
  brandhoop-visiting-card-CMYK-vector-bleed-3mm.pdf   front + back, 94.9 x 56.8 mm, TrimBox 88.9 x 50.8 mm (3.5 x 2 in)
  brandhoop-visiting-card-CMYK-vector-trim.pdf        front + back at the finished size
"""
import io, os, pathlib, re, sys
from PIL import Image, ImageCms
from pypdf import PdfReader, PdfWriter
from pypdf.generic import ArrayObject, ContentStream, DictionaryObject, FloatObject, NameObject, NumberObject, RectangleObject

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SRC = HERE / 'build' / 'vector'
OUT = ROOT / 'site' / 'brand' / 'print' / 'vector'
ICC = os.environ.get('CMYK_ICC') or next((p for p in ('/usr/share/color/icc/ghostscript/default_cmyk.icc', '/usr/share/ghostscript/iccprofiles/default_cmyk.icc') if os.path.exists(p)), None)
if not ICC: sys.exit('no CMYK ICC profile found; set CMYK_ICC')
_t = ImageCms.buildTransform(ImageCms.createProfile('sRGB'), ImageCms.getOpenProfile(ICC), 'RGB', 'CMYK',
                             renderingIntent=ImageCms.Intent.RELATIVE_COLORIMETRIC, flags=ImageCms.Flags.BLACKPOINTCOMPENSATION)
_cache = {}
INSET = 0.75


def cmyk(r, g, b):
    key = (round(float(r), 4), round(float(g), 4), round(float(b), 4))
    if key not in _cache:
        px = Image.new('RGB', (1, 1), tuple(max(0, min(255, round(v * 255))) for v in key))
        _cache[key] = tuple(round(v / 255, 4) for v in ImageCms.applyTransform(px, _t).getpixel((0, 0)))
    return _cache[key]


def fnum(v): return FloatObject(str(v))


def convert_function(f, seen):
    f = f.get_object()
    if id(f) in seen: return
    seen.add(id(f))
    t = f['/FunctionType']
    if t == 2:
        for k in ('/C0', '/C1'):
            if k in f and len(f[k]) == 3:
                f[NameObject(k)] = ArrayObject([fnum(v) for v in cmyk(*[float(x) for x in f[k]])])
        if '/Range' in f: f[NameObject('/Range')] = ArrayObject([fnum(0), fnum(1)] * 4)
    elif t == 3:
        for sub in f['/Functions']: convert_function(sub, seen)
        if '/Range' in f: f[NameObject('/Range')] = ArrayObject([fnum(0), fnum(1)] * 4)
    else:
        raise ValueError(f'function type {t} not handled')


COLOUR_OPS = {b'rg': b'k', b'RG': b'K'}


def convert_stream(obj, reader, owner=None):
    """Rewrites rg/RG in a content stream (page or form or pattern)."""
    cs = ContentStream(owner if owner is not None else obj, reader)
    n = 0
    for i, (operands, op) in enumerate(cs.operations):
        if op in COLOUR_OPS and len(operands) == 3:
            cs.operations[i] = (list(map(fnum, cmyk(*[float(x) for x in operands]))), COLOUR_OPS[op]); n += 1
    return cs, n


def lum(r, g, b): return round(0.2126 * r + 0.7152 * g + 0.0722 * b, 4)


def gray_function(f, seen):
    f = f.get_object()
    if id(f) in seen: return
    seen.add(id(f))
    if f['/FunctionType'] == 2:
        for k in ('/C0', '/C1'):
            if k in f and len(f[k]) == 3: f[NameObject(k)] = ArrayObject([fnum(lum(*[float(x) for x in f[k]]))])
        if '/Range' in f: f[NameObject('/Range')] = ArrayObject([fnum(0), fnum(1)])
    elif f['/FunctionType'] == 3:
        for sub in f['/Functions']: gray_function(sub, seen)
        if '/Range' in f: f[NameObject('/Range')] = ArrayObject([fnum(0), fnum(1)])


def gray_form(x, reader, seen, stats):
    """A soft-mask group only says how transparent things are, so its colours become plain grey, not CMYK."""
    x = x.get_object()
    if id(x) in seen: return
    seen.add(id(x))
    cs = ContentStream(x, reader)
    for i, (operands, op) in enumerate(cs.operations):
        if op in (b'rg', b'RG') and len(operands) == 3:
            cs.operations[i] = ([fnum(lum(*[float(v) for v in operands]))], b'g' if op == b'rg' else b'G')
    x.set_data(cs.get_data())
    if '/Group' in x and '/CS' in x['/Group']: x['/Group'][NameObject('/CS')] = NameObject('/DeviceGray')
    res = x.get('/Resources')
    if res is None: return
    res = res.get_object()
    for name, pat in (res.get('/Pattern') or {}).items():
        p = pat.get_object()
        if p.get('/PatternType') == 2:
            sh = p['/Shading'].get_object()
            if id(sh) not in seen:
                seen.add(id(sh)); sh[NameObject('/ColorSpace')] = NameObject('/DeviceGray'); gray_function(sh['/Function'], seen); stats['masks'] += 1


def convert_resources(res, reader, seen, stats):
    if res is None: return
    res = res.get_object()
    if id(res) in seen: return
    seen.add(id(res))
    for name, g in (res.get('/ExtGState') or {}).items():
        sm = g.get_object().get('/SMask')
        if sm is not None and sm != '/None' and '/G' in sm.get_object(): gray_form(sm.get_object()['/G'], reader, seen, stats)
    for name, sh in (res.get('/Shading') or {}).items():
        sh = sh.get_object(); sh[NameObject('/ColorSpace')] = NameObject('/DeviceCMYK'); convert_function(sh['/Function'], seen); stats['shadings'] += 1
    for name, pat in (res.get('/Pattern') or {}).items():
        p = pat.get_object()
        if p.get('/PatternType') == 2:
            sh = p['/Shading'].get_object()
            if id(sh) not in seen:
                seen.add(id(sh)); sh[NameObject('/ColorSpace')] = NameObject('/DeviceCMYK'); convert_function(sh['/Function'], seen); stats['shadings'] += 1
        else:
            cs, n = convert_stream(p, reader); p.set_data(cs.get_data()); stats['colours'] += n
            convert_resources(p.get('/Resources'), reader, seen, stats)
    for name, xo in (res.get('/XObject') or {}).items():
        x = xo.get_object()
        if id(x) in seen: continue
        seen.add(id(x))
        if x.get('/Subtype') == '/Form':
            cs, n = convert_stream(x, reader); x.set_data(cs.get_data()); stats['colours'] += n
            if '/Group' in x and '/CS' in x['/Group']: x['/Group'][NameObject('/CS')] = NameObject('/DeviceCMYK')
            convert_resources(x.get('/Resources'), reader, seen, stats)
        elif x.get('/Subtype') == '/Image':
            stats['images'] += 1


def to_cmyk(src, dst_writer, crop_mm):
    """Converts every page of one PDF and sets its boxes. crop_mm = (width, height) of the real page in mm; Chromium rounds pages up."""
    reader = PdfReader(str(src)); stats = dict(colours=0, shadings=0, images=0, masks=0)
    for page in reader.pages:
        cs, n = convert_stream(page, reader, page.get_contents()); stats['colours'] += n
        page.replace_contents(cs)
        convert_resources(page['/Resources'], reader, set(), stats)
        # Chromium rounds the page up to whole pixels, leaving a white edge at the bottom and right: crop to the true size
        # Chromium also starts the drawing 0.75 pt in from the top and left (3.125 px at its 0.24 scale)
        H = float(page.mediabox.height); w, h = crop_mm[0] * 72 / 25.4, crop_mm[1] * 72 / 25.4; o = INSET
        box = RectangleObject([o, round(H - o - h, 3), round(o + w, 3), round(H - o, 3)])
        for b in ('/MediaBox', '/CropBox', '/BleedBox'): page[NameObject(b)] = box
        dst_writer.add_page(page)
    return stats


def trimbox(writer, bleed_mm):
    for page in writer.pages:
        mb = [float(v) for v in page['/MediaBox']]; k = bleed_mm * 72 / 25.4
        page[NameObject('/TrimBox')] = RectangleObject([mb[0] + k, mb[1] + k, mb[2] - k, mb[3] - k])
        page[NameObject('/ArtBox')] = page['/TrimBox']


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    for tag, name in (('bleed', 'brandhoop-visiting-card-CMYK-vector-bleed-3mm.pdf'), ('trim', 'brandhoop-visiting-card-CMYK-vector-trim.pdf')):
        w = PdfWriter()
        # both files come from the 3 mm bleed drawing; the trim file is the same pages cropped to the finished size,
        # so the artwork runs right to the edge of its page
        for side in ('front', 'back'):
            st = to_cmyk(SRC / f'{side}-bleed-rgb.pdf', w, (88.9 + 6, 50.8 + 6)); print(tag, side, st)
        trimbox(w, 3.0)
        if tag == 'trim':
            for page in w.pages:
                for b in ('/MediaBox', '/CropBox', '/BleedBox'): page[NameObject(b)] = page['/TrimBox']
        w.add_metadata({'/Title': 'Brandhoop Mobile Point visiting card, front and back, CMYK vector', '/Author': 'Brandhoop Mobile Point'})
        with open(OUT / name, 'wb') as f: w.write(f)
        print('wrote', OUT / name)

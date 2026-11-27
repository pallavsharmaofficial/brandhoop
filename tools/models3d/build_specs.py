#!/usr/bin/env python3
"""Writes tools/models3d/specs/<id>.json, the numbers generate_phone.mjs builds an illustrative
3D model from. Sizes, colours and camera layout come from public spec text (OPPO / vivo India
pages, FoneArena, GSMArena, 91mobiles and reviews); where a source did not say, the layout is
an inference and "confidence" says so. Nothing here is copied from a photo or a model.

    python3 tools/models3d/build_specs.py
"""
import json, pathlib
HERE = pathlib.Path(__file__).resolve().parent


def layout(kind, W):
    """Camera island, lenses and flash for a layout family. Millimetres from the top-left of the back as seen from behind."""
    if kind == 'single-pill':
        return dict(island=dict(shape='pill', x=5, y=5, w=17, h=33), lenses=[dict(x=13.5, y=13.5, r=5.6)], flash=[dict(x=13.5, y=30, r=2)])
    if kind == 'pill-v2':          # vertical pill, two lenses, flash beside it on the panel
        return dict(island=dict(shape='pill', x=5, y=5, w=17, h=36), lenses=[dict(x=13.5, y=13.5, r=5.6), dict(x=13.5, y=31, r=5.6)], flash=[dict(x=28, y=12, r=1.7, on='back')])
    if kind == 'square-2':         # square island, two lenses stacked, flash inside
        return dict(island=dict(shape='rounded-rect', r=6.5, x=5, y=5, w=27, h=27), lenses=[dict(x=13.5, y=13, r=5), dict(x=13.5, y=25, r=5)], flash=[dict(x=26, y=11, r=1.9)])
    if kind == 'rect-3':           # rounded rectangle, three lenses in a triangle
        return dict(island=dict(shape='rounded-rect', r=7, x=5, y=5, w=33, h=35), lenses=[dict(x=14.5, y=14.5, r=5.8), dict(x=14.5, y=30.5, r=5.8), dict(x=29, y=22.5, r=5)], flash=[dict(x=30, y=11, r=1.8)])
    if kind == 'pill-h2':          # horizontal bar, top centre
        x0 = (W - 46) / 2
        return dict(island=dict(shape='pill', x=x0, y=5, w=46, h=18), lenses=[dict(x=x0 + 11, y=14, r=5.2), dict(x=x0 + 26, y=14, r=5.2)], flash=[dict(x=x0 + 38.5, y=14, r=2.1)])
    if kind == 'rings-v2':         # two big rings straight on the back, no island
        return dict(island=dict(shape='none'), lenses=[dict(x=14.5, y=14.5, r=6.4, on='back'), dict(x=14.5, y=31.5, r=6.4, on='back')], flash=[dict(x=28, y=12, r=1.8, on='back')])
    raise ValueError(kind)


# id: (brand, name, h, w, t, front, frame, finish, colour, colour name, cutout, layout, corner radius, confidence, note)
PHONES = {
 'oppo-a6x-5g':     ('OPPO', 'OPPO A6x 5G',     166.6, 78.5, 8.6,  'flat',   'flat',    'matte',  '#6B7355', 'Olive Green',  'punch-center', 'single-pill', 9.5,  'medium', 'one 13 MP lens in a vertical pill, top-left'),
 'oppo-a6-5g':      ('OPPO', 'OPPO A6 5G',      166.6, 78.5, 8.6,  'flat',   'flat',    'glossy', '#2F4F8F', 'Sapphire Blue','punch-center', 'pill-v2',     9.5,  'low',    'two lenses stacked top-left; island shape inferred'),
 'oppo-a6s-5g':     ('OPPO', 'OPPO A6s 5G',     166.6, 78.5, 8.6,  'flat',   'flat',    'matte',  '#5E4A6B', 'Plum Purple',  'punch-center', 'rings-v2',    9.5,  'low',    'two ring lenses on the back, no island (one source)'),
 'oppo-k14x-5g':    ('OPPO', 'OPPO K14x 5G',    166.6, 78.5, 8.61, 'flat',   'flat',    'matte',  '#7B6AA8', 'Prism Violet', 'punch-center', 'pill-v2',     9.5,  'medium', 'metal Deco housing, two lenses stacked'),
 'oppo-k14-5g':     ('OPPO', 'OPPO K14 5G',     166.6, 78.5, 8.6,  'flat',   'flat',    'glossy', '#6F4FA0', 'Prism Violet', 'punch-center', 'square-2',    9.5,  'medium', 'square dual-camera island, flash inside'),
 'oppo-f35-5g':     ('OPPO', 'OPPO F35 5G',     159.1, 75.8, 8.8,  'flat',   'flat',    'matte',  '#5B8FD1', 'Wave Blue',    'punch-center', 'pill-v2',     9.5,  'medium', 'capsule module top-left (layout from two sources)'),
 'oppo-f35-pro-5g': ('OPPO', 'OPPO F35 Pro 5G', 162.6, 77.6, 8.4,  'flat',   'flat',    'matte',  '#E88A4A', 'Sunrise Orange','punch-center', 'pill-v2',     9.5,  'medium', 'semi-circular island top-left'),
 'oppo-reno-16c-5g':('OPPO', 'OPPO Reno 16c 5G',158.2, 74.9, 8.4,  'flat',   'flat',    'glossy', '#8E7CC3', 'Twilight Violet','punch-center','rect-3',     10.5, 'low',    'three lenses; layout inferred from the Reno 16 series'),
 'oppo-reno-16-5g': ('OPPO', 'OPPO Reno 16 5G', 151.2, 72.4, 8.22, 'flat',   'flat',    'glossy', '#A98BD6', 'Stellar Purple','punch-center','rect-3',      10.5, 'medium', 'low square island, three lenses'),
 'vivo-y11-5g':     ('vivo', 'vivo Y11 5G',     167.4, 77.1, 8.39, 'flat',   'flat',    'glossy', '#2F4E8C', 'Mystic Blue',  'punch-center', 'square-2',    9.5,  'medium', 'square module top-left, flash inside'),
 'vivo-y21-5g':     ('vivo', 'vivo Y21 5G',     167.4, 77.1, 8.39, 'flat',   'flat',    'glossy', '#2B4A8A', 'Mystic Blue',  'punch-center', 'pill-v2',     9.5,  'medium', 'vertical pill, two lenses, Aura ring'),
 'vivo-y31t-5g':    ('vivo', 'vivo Y31t 5G',    166.64,78.43,8.39, 'flat',   'flat',    'glossy', '#B3262E', 'Crimson Red',  'punch-center', 'square-2',    9.5,  'low',    'square module; the front notch is drawn as a punch hole'),
 'vivo-t5-lite-5g': ('vivo', 'vivo T5 Lite 5G', 167.4, 77.1, 8.39, 'flat',   'flat',    'matte',  '#6FA3D8', 'Wave Blue',    'punch-center', 'square-2',    9.5,  'medium', 'squarish island, sources disagree'),
 'vivo-t5x-5g':     ('vivo', 'vivo T5x 5G',     166.64,78.43,8.39, 'flat',   'flat',    'matte',  '#6FBF73', 'Cyber Green',  'punch-center', 'square-2',    9.5,  'medium', 'rounded square module, Aura light inside'),
 'vivo-t5-pro-5g':  ('vivo', 'vivo T5 Pro 5G',  163.73,76.18,8.25, 'flat',   'flat',    'matte',  '#8FB4D6', 'Glacier Blue', 'punch-center', 'pill-v2',     9.5,  'medium', 'vertical pill, two lenses'),
 'vivo-s2-fe-5g':   ('vivo', 'vivo S2 FE 5G',   163.9, 76.5, 8.69, 'flat',   'flat',    'matte',  '#7FA38A', 'Stellar Green','punch-center', 'square-2',    9.5,  'low',    'squarish island; no source gave the exact layout'),
 'vivo-s2-5g':      ('vivo', 'vivo S2 5G',      164.42,75.25,7.99, 'curved', 'flat',    'glossy', '#2F4C8C', 'Sapphire Blue','punch-center', 'pill-h2',     10.5, 'medium', 'horizontal Skyline bar, top centre'),
 'vivo-v70-fe-5g':  ('vivo', 'vivo V70 FE 5G',  163.7, 76.2, 7.59, 'curved', 'rounded', 'matte',  '#3E5C8A', 'Monsoon Blue', 'punch-center', 'pill-v2',     10.5, 'medium', 'vertical pill with metal rings'),
}
for pid, (brand, name, h, w, t, front, frame, finish, colour, cname, cut, lay, cr, conf, note) in PHONES.items():
    spec = dict(id=pid, name=name, brand=brand, dims=dict(h=h, w=w, t=t), cornerR=cr, front=front, frame=frame, finish=finish, colour=colour, colourName=cname, cutout=cut,
                layout=lay, confidence=conf, note=note, buttons=dict(side='right', volume=dict(y=46, len=22), power=dict(y=70, len=10)), **layout(lay, w))
    (HERE / 'specs' / f'{pid}.json').write_text(json.dumps(spec, ensure_ascii=False, indent=1))
print(len(PHONES), 'specs written')

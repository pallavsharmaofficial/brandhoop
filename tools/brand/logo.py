#!/usr/bin/env python3
"""Brandhoop logo as SVG. Mark = a phone shaped like the letter B; wordmark outlined from Montserrat.

Library use:  from logo import mark_svg, lockup_v, lockup_h, icon_svg, PALETTE
Run directly: writes site/brand/logo/*.svg
"""
import math, pathlib
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
FONTS = ROOT / 'tools' / 'brand' / 'fonts'

PALETTE = {
    'navy': '#1F2744', 'navy2': '#2B3558', 'orange': '#D8662A', 'orange_dark': '#A9481C', 'orange_light': '#F08A45',
    'slate_light': '#8B94A0', 'slate': '#566170', 'slate_dark': '#2F3A45', 'paper': '#F6F6F6', 'ink': '#14182B'
}
P = PALETTE
_fonts = {}


def _font(weight):
    if weight not in _fonts:
        _fonts[weight] = TTFont(str(FONTS / f'montserrat-latin-{weight}-normal.woff'))
    return _fonts[weight]


def text_path(s, size, weight=800, tracking=0.0):
    """Returns (svg path d, width) for text outlined at origin baseline (0,0), x to the right."""
    f = _font(weight); gs = f.getGlyphSet(); cmap = f.getBestCmap(); upm = f['head'].unitsPerEm; k = size / upm
    x = 0.0; ds = []
    for ch in s:
        gname = cmap.get(ord(ch))
        if gname is None:
            x += size * 0.3; continue
        pen = SVGPathPen(gs)
        tp = TransformPen(pen, (k, 0, 0, -k, x, 0))
        gs[gname].draw(tp)
        ds.append(pen.getCommands())
        x += gs[gname].width * k + tracking * size
    return ' '.join(ds), x - tracking * size


def _fp_arcs(cx, cy, color, w=3.2):
    """A stylised fingerprint: nested arcs with gaps, plus a centre line."""
    out = []
    spec = [(9, 205, 335), (17, 190, 350), (25, 180, 360), (33, 172, 20), (41, 165, 30), (49, 160, 40)]
    for r, a0, a1 in spec:
        a0r, a1r = math.radians(a0), math.radians(a1)
        if a1 < a0: a1r += 2 * math.pi
        # draw the top arc and a shorter lower-left arc so it reads as a print, not a target
        x0, y0 = cx + r * math.cos(a0r), cy + r * math.sin(a0r)
        x1, y1 = cx + r * math.cos(a1r), cy + r * math.sin(a1r)
        large = 1 if (a1r - a0r) > math.pi else 0
        out.append(f'<path d="M{x0:.1f} {y0:.1f}A{r} {r} 0 {large} 1 {x1:.1f} {y1:.1f}" fill="none" stroke="{color}" stroke-width="{w}" stroke-linecap="round"/>')
    out.append(f'<path d="M{cx} {cy-4}c0 10 -2 22 -7 34M{cx+6} {cy+2}c0 14 -3 26 -10 40" fill="none" stroke="{color}" stroke-width="{w}" stroke-linecap="round"/>')
    return ''.join(out)


def mark_defs(uid='m'):
    return (f'<defs>'
            f'<linearGradient id="{uid}body" x1="0.85" y1="0.05" x2="0.1" y2="0.95"><stop offset="0" stop-color="{P["slate_light"]}"/><stop offset=".45" stop-color="{P["slate"]}"/><stop offset="1" stop-color="{P["slate_dark"]}"/></linearGradient>'
            f'<linearGradient id="{uid}low" x1="0.2" y1="0" x2="0.8" y2="1"><stop offset="0" stop-color="#3A4655"/><stop offset="1" stop-color="#27313C"/></linearGradient>'
            f'<radialGradient id="{uid}fp" cx=".42" cy=".38" r=".75"><stop offset="0" stop-color="{P["orange_light"]}"/><stop offset=".6" stop-color="{P["orange"]}"/><stop offset="1" stop-color="{P["orange_dark"]}"/></radialGradient>'
            f'<linearGradient id="{uid}shine" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity=".28"/><stop offset=".25" stop-color="#fff" stop-opacity="0"/></linearGradient>'
            f'</defs>')


BODY = 'M348 214C348 177 372 156 408 156L600 156C662 156 702 202 702 262C702 320 664 360 618 384C672 392 712 438 712 508C712 600 664 668 580 668L392 668C364 668 348 650 348 618Z'
LOWER = 'M378 478C378 424 430 394 500 394L618 394C676 402 706 448 706 508C706 590 662 640 584 640L410 640C392 640 378 630 378 612Z'


def mark_inner(style='color', uid='m', body_color=None, detail_color=None):
    """The B-phone in original logo coordinates (x 330..720, y 150..680)."""
    if style == 'color':
        body, low, accent, accent2, dark, bez = f'url(#{uid}body)', f'url(#{uid}low)', P['orange'], P['orange'], '#262B36', '#B9C0C9'
        fp_fill = f'url(#{uid}fp)'; fp_line = '#8F3F17'
    else:  # solid: body in one colour, details knocked out in detail_color
        bc = body_color or P['navy']; dc = detail_color or '#FFFFFF'
        body, low, accent, accent2, dark, bez = bc, bc, dc, dc, dc, dc
        fp_fill = dc; fp_line = bc
    g = [f'<path d="{BODY}" fill="{body}"/>']
    if style == 'color':
        g.append(f'<path d="{LOWER}" fill="{low}" opacity=".62"/>')
        g.append(f'<path d="{BODY}" fill="url(#{uid}shine)"/>')
        g.append(f'<path d="{BODY}" fill="none" stroke="{bez}" stroke-width="6" stroke-opacity=".75"/>')
    # side buttons
    btn = '#7F8791' if style == 'color' else (detail_color or '#FFFFFF')
    g.append(f'<rect x="330" y="238" width="17" height="62" rx="6" fill="{btn}"/><rect x="330" y="352" width="17" height="62" rx="6" fill="{btn}"/>')
    # notch + lens
    g.append(f'<rect x="461" y="181" width="108" height="32" rx="16" fill="{dark}"/>')
    if style == 'color': g.append('<circle cx="551" cy="197" r="5.5" fill="#3B4560"/>')
    # plug icon
    g.append(f'<g fill="none" stroke="{accent}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round">'
             f'<path d="M458 252H498C522 252 540 268 540 289C540 310 522 326 498 326H458Z"/>'
             f'<path d="M412 272H440M408 306H440M440 272V306"/></g>')
    g.append(f'<circle cx="508" cy="289" r="12" fill="none" stroke="{accent}" stroke-width="5"/><circle cx="510" cy="288" r="4" fill="{accent}"/>')
    g.append(f'<circle cx="580" cy="288" r="12" fill="{accent2}"/>')
    # fingerprint disc
    g.append(f'<circle cx="523" cy="518" r="72" fill="{fp_fill}"/>')
    if style == 'color':
        g.append(f'<circle cx="523" cy="518" r="72" fill="none" stroke="{P["orange_dark"]}" stroke-width="5"/><circle cx="523" cy="518" r="62" fill="none" stroke="{P["orange_light"]}" stroke-opacity=".55" stroke-width="2.5"/>')
    g.append(_fp_arcs(523, 518, fp_line))
    return ''.join(g)


def mark_svg(style='color', body_color=None, detail_color=None, uid='m', size=None):
    s = f' width="{size[0]}" height="{size[1]}"' if size else ''
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="322 144 398 536"{s} role="img" aria-label="Brandhoop mark">'
            f'{mark_defs(uid) if style == "color" else ""}{mark_inner(style, uid, body_color, detail_color)}</svg>')


def wordmark(brand_color=None, hoop_color=None, sub_color=None, cx=0, y=0, size=100, sub_size=0.62):
    """BRANDHOOP + MOBILE POINT, centred on cx; returns (svg group, width). Baseline of line 1 at y."""
    brand_color = brand_color or P['navy']; hoop_color = hoop_color or P['orange']; sub_color = sub_color or '#C16D41'
    d1, w1 = text_path('BRAND', size, 800, 0.0); d2, w2 = text_path('HOOP', size, 800, 0.0)
    total = w1 + w2; x0 = cx - total / 2
    sub_fs = size * sub_size; d3, w3 = text_path('MOBILE POINT', sub_fs, 600, 0.04)
    g = (f'<path d="{d1}" transform="translate({x0:.1f} {y})" fill="{brand_color}"/>'
         f'<path d="{d2}" transform="translate({x0 + w1:.1f} {y})" fill="{hoop_color}"/>'
         f'<path d="{d3}" transform="translate({cx - w3 / 2:.1f} {y + size * 0.95:.1f})" fill="{sub_color}"/>')
    return g, total


def lockup_v(style='color', mode='light', uid='v'):
    """Mark above wordmark. mode light: navy/orange text; dark: white/orange text; mono: one colour."""
    if mode == 'dark': bc, hc, sc = '#FFFFFF', P['orange_light'], P['orange_light']
    elif mode == 'mono': bc = hc = sc = P['navy']
    elif mode == 'white': bc = hc = sc = '#FFFFFF'
    else: bc, hc, sc = '#242B45', P['orange'], '#C16D41'
    mark_kw = {}
    if mode == 'mono': mark_kw = dict(style='solid', body_color=P['navy'], detail_color='#FFFFFF')
    elif mode == 'white': mark_kw = dict(style='solid', body_color='#FFFFFF', detail_color=P['navy'])
    else: mark_kw = dict(style=style)
    wm, w = wordmark(bc, hc, sc, cx=521, y=800, size=102)
    inner = mark_inner(uid=uid, **mark_kw)
    defs = mark_defs(uid) if mark_kw['style'] == 'color' else ''
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="150 130 742 800" role="img" aria-label="Brandhoop Mobile Point">{defs}{inner}{wm}</svg>')


def lockup_h(mode='light', uid='h'):
    """Mark on the left, two text lines on the right."""
    if mode == 'dark': bc, hc, sc = '#FFFFFF', P['orange_light'], P['orange_light']
    elif mode == 'mono': bc = hc = sc = P['navy']
    elif mode == 'white': bc = hc = sc = '#FFFFFF'
    else: bc, hc, sc = '#242B45', P['orange'], '#C16D41'
    if mode == 'mono': mk = dict(style='solid', body_color=P['navy'], detail_color='#FFFFFF')
    elif mode == 'white': mk = dict(style='solid', body_color='#FFFFFF', detail_color=P['navy'])
    else: mk = dict(style='color')
    d1, w1 = text_path('BRAND', 112, 800); d2, w2 = text_path('HOOP', 112, 800); d3, w3 = text_path('MOBILE POINT', 70, 600, 0.045)
    tx = 760; ty = 438
    defs = mark_defs(uid) if mk['style'] == 'color' else ''
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="322 144 {tx - 322 + w1 + w2 + 20} 536" role="img" aria-label="Brandhoop Mobile Point">{defs}{mark_inner(uid=uid, **mk)}'
            f'<path d="{d1}" transform="translate({tx} {ty})" fill="{bc}"/><path d="{d2}" transform="translate({tx + w1:.1f} {ty})" fill="{hc}"/>'
            f'<path d="{d3}" transform="translate({tx + 4} {ty + 92})" fill="{sc}"/></svg>')


def icon_svg(variant='light', rounded=True, uid='i'):
    """Square app icon 1024: the mark centred on a plain tile."""
    bg = '#F6F6F6' if variant == 'light' else P['navy']
    rx = 224 if rounded else 0
    if variant == 'light':
        inner = mark_inner('color', uid); defs = mark_defs(uid)
    else:  # on navy: the mark in white with orange details would lose the slate body, so use the colour mark on a lighter navy tile
        inner = mark_inner('color', uid); defs = mark_defs(uid)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" role="img" aria-label="Brandhoop"><rect width="1024" height="1024" rx="{rx}" fill="{bg}"/>'
            f'{defs}<g transform="translate(512 512) scale(1.02) translate(-521 -412)">{inner}</g></svg>')


def write_all(out):
    out = pathlib.Path(out); out.mkdir(parents=True, exist_ok=True)
    files = {
        'brandhoop-logo.svg': lockup_v('color', 'light', 'a'),
        'brandhoop-logo-on-dark.svg': lockup_v('color', 'dark', 'b'),
        'brandhoop-logo-mono-navy.svg': lockup_v('color', 'mono', 'c'),
        'brandhoop-logo-white.svg': lockup_v('color', 'white', 'd'),
        'brandhoop-logo-horizontal.svg': lockup_h('light', 'e'),
        'brandhoop-logo-horizontal-on-dark.svg': lockup_h('dark', 'f'),
        'brandhoop-logo-horizontal-mono.svg': lockup_h('mono', 'g'),
        'brandhoop-mark.svg': mark_svg('color', uid='h1'),
        'brandhoop-mark-mono-navy.svg': mark_svg('solid', P['navy'], '#FFFFFF'),
        'brandhoop-mark-white.svg': mark_svg('solid', '#FFFFFF', P['navy']),
        'brandhoop-mark-orange.svg': mark_svg('solid', P['orange'], '#FFFFFF'),
        'brandhoop-icon.svg': icon_svg('light', True, 'j'),
        'brandhoop-icon-square.svg': icon_svg('light', False, 'k'),
    }
    # the wordmark alone
    wm, w = wordmark(cx=0, y=0, size=100)
    files['brandhoop-wordmark.svg'] = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{-w/2 - 20:.0f} -90 {w + 40:.0f} 170" role="img" aria-label="Brandhoop Mobile Point">{wm}</svg>'
    for n, s in files.items():
        (out / n).write_text(s, encoding='utf-8')
    return sorted(files)


if __name__ == '__main__':
    print(write_all(ROOT / 'site' / 'brand' / 'logo'))

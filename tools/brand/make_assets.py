#!/usr/bin/env python3
"""Builds every brand asset from the logo: app icons, web icons, social images, cards, posters, board.

    python3 tools/brand/make_assets.py        # writes HTML to tools/brand/build and a manifest
    node tools/brand/shoot.js                 # renders PNG/PDF into site/brand/ and assets/branding/

All numbers and words come from CONTENT below; the admin panel's Design Studio edits the same fields.
"""
import json, pathlib, html as H, sys
import segno
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / 'catalog'))
import phones as _phones, shop_data as _sd
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from logo import mark_svg, lockup_v, lockup_h, mark_inner, mark_defs, PALETTE as P, icon_svg

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
BUILD = HERE / 'build'; BUILD.mkdir(exist_ok=True)
FONT = (HERE / 'fonts').as_uri()

CONTENT = {
    'name': 'Brandhoop Mobile Point', 'owner': 'Naresh Saini', 'phone': '86197 67291', 'phone2': '72399 38540', 'phone2_raw': '917239938540', 'phone_raw': '918619767291',
    'addr_en': 'Gate No. 5, Kamla Modi Market, Neem Ka Thana, Rajasthan 332713', 'addr_hi': 'गेट नं. 5, कमला मोदी मार्केट, नीम का थाना, राजस्थान 332713',
    'web': 'https://pallavsharmaofficial.github.io/brandhoop/', 'web_short': 'pallavsharmaofficial.github.io/brandhoop',
    'tag_hi': 'मोबाइल · एक्सेसरी · स्किन कटिंग · रिपेयरिंग · EMI', 'headline_hi': 'नया फ़ोन? आज की कीमत पूछें',
}
C = CONTENT

BASE_CSS = f'''
@font-face{{font-family:Mont;font-weight:600;src:url({FONT}/montserrat-latin-600-normal.woff)}}
@font-face{{font-family:Mont;font-weight:700;src:url({FONT}/montserrat-latin-700-normal.woff)}}
@font-face{{font-family:Mont;font-weight:800;src:url({FONT}/montserrat-latin-800-normal.woff)}}
@font-face{{font-family:Dev;font-weight:600;src:url({FONT}/noto-sans-devanagari-devanagari-600-normal.woff)}}
@font-face{{font-family:Dev;font-weight:700;src:url({FONT}/noto-sans-devanagari-devanagari-700-normal.woff)}}
@font-face{{font-family:Dev;font-weight:800;src:url({FONT}/noto-sans-devanagari-devanagari-800-normal.woff)}}
:root{{--navy:{P['navy']};--navy2:{P['navy2']};--orange:{P['orange']};--orange2:{P['orange_light']};--odark:{P['orange_dark']};--paper:{P['paper']};--ink:{P['ink']};--slate:{P['slate']}}}
*{{box-sizing:border-box;margin:0}} html,body{{margin:0}}
body{{font-family:Mont,Dev,sans-serif;color:var(--ink);-webkit-font-smoothing:antialiased}}
.hi{{font-family:Dev,Mont,sans-serif}}
'''

ICON = {
 'phone': '<path d="M6.6 10.8c1.4 2.8 3.8 5.2 6.6 6.6l2.2-2.2c.3-.3.7-.4 1-.2 1.1.4 2.3.6 3.6.6.6 0 1 .4 1 1V20c0 .6-.4 1-1 1C10.6 21 3 13.4 3 4c0-.6.4-1 1-1h3.5c.6 0 1 .4 1 1 0 1.3.2 2.5.6 3.6.1.3 0 .7-.2 1z"/>',
 'pin': '<path d="M12 2C8.1 2 5 5.1 5 9c0 5.2 7 13 7 13s7-7.8 7-13c0-3.9-3.1-7-7-7zm0 9.5A2.5 2.5 0 1 1 12 6.5a2.5 2.5 0 0 1 0 5z"/>',
 'chat': '<path d="M12 3a9 9 0 0 0-7.8 13.5L3 21l4.6-1.2A9 9 0 1 0 12 3z"/>',
 'globe': '<path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm0 2c1.2 1.5 2 3.6 2.3 6H9.7C10 7.6 10.800 5.500 12 4zM4.300 10a8 8 0 0 1 4-5.300c-.6 1.500-1 3.300-1.100 5.300zm0 2h2.900c.1 2 .5 3.800 1.100 5.300A8 8 0 0 1 4.300 12zm5.400 0h4.600c-.3 2.400-1.100 4.500-2.300 6-1.200-1.500-2-3.600-2.300-6zm6.700 0h2.900a8 8 0 0 1-4 5.300c.6-1.500 1-3.300 1.100-5.300zm0-2c-.1-2-.5-3.800-1.100-5.300a8 8 0 0 1 4 5.300z"/>',
}
def ico(name, size, color):
    return f'<svg viewBox="0 0 24 24" width="{size}" height="{size}" fill="{color}" aria-hidden="true">{ICON[name]}</svg>'

SVC_ICON = {   # line icons for highlight covers, 24 box, stroke currentColor
 'Phones': '<rect x="7" y="2.5" width="10" height="19" rx="2.5"/><path d="M10.5 18.5h3"/>',
 'Accessories': '<path d="M5 9h6v5a3 3 0 0 1-3 3H8a3 3 0 0 1-3-3zM8 9V5M5 5h6M16 13h2.500a2 2 0 0 1 2 2v2M20.500 17H14"/>',
 'Skin cutting': '<circle cx="6" cy="7" r="2.600"/><circle cx="6" cy="17" r="2.600"/><path d="M8 8.500L20 18M8 15.500L20 6"/>',
 'Repair': '<path d="M14.700 6.300a4 4 0 0 0-5.300 5.300L3.500 17.500a1.800 1.800 0 0 0 2.500 2.500l5.900-5.900a4 4 0 0 0 5.300-5.300l-2.600 2.600-2.300-.4-.4-2.300z"/>',
 'EMI': '<rect x="3" y="5" width="18" height="14" rx="2.500"/><path d="M3 10h18M7 15h4"/>',
 'Shop tour': '<path d="M4 9l1.500-5h13L20 9M4 9v10h16V9M4 9h16M9 19v-6h6v6"/>',
 'Customers': '<circle cx="12" cy="12" r="9"/><path d="M8.500 14.500c1 1.600 2.100 2.300 3.500 2.300s2.500-.7 3.500-2.300M9 9.500h.01M15 9.500h.01"/>',
}

def qr(url, color='#1F2744', size=None):
    q = segno.make(url, error='m'); n = q.symbol_size(border=0)[0]
    d = ''.join(f'M{x},{y}h1v1h-1z' for y, row in enumerate(q.matrix_iter(border=0)) for x, v in enumerate(row) if v)
    s = f' width="{size}" height="{size}"' if size else ''
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {n} {n}"{s} shape-rendering="crispEdges"><path d="{d}" fill="{color}"/></svg>'

_uid = [0]
def U(): _uid[0] += 1; return f'u{_uid[0]}'
def logo_dark(w=None): return lockup_v('color', 'dark', U()).replace('<svg ', f'<svg style="width:{w}" ' if w else '<svg ', 1)
def logo_light(w=None): return lockup_v('color', 'light', U()).replace('<svg ', f'<svg style="width:{w}" ' if w else '<svg ', 1)
def mark(w, style='color', **kw): return mark_svg(style, uid=U(), **kw).replace('<svg ', f'<svg style="width:{w};height:auto" ', 1)
def hlogo(w, mode='light'): return lockup_h(mode, U()).replace('<svg ', f'<svg style="width:{w};height:auto" ', 1)

MANIFEST = []
def page(name, w, h, body, css='', unit='px', out_png=None, pdf=None, dsf=1):
    """w,h in CSS units; writes tools/brand/build/name.html and queues renders."""
    doc = (f'<!doctype html><meta charset="utf-8"><title>{name}</title><style>{BASE_CSS}'
           f'@page{{size:{w}{unit} {h}{unit};margin:0}} body{{width:{w}{unit};height:{h}{unit};overflow:hidden;position:relative}}{css}</style><body>{body}</body>')
    (BUILD / f'{name}.html').write_text(doc, encoding='utf-8')
    entry = {'html': f'{name}.html', 'w': w, 'h': h, 'unit': unit, 'dsf': dsf, 'png': out_png, 'pdf': pdf}
    MANIFEST.append(entry)

OUTB = 'site/brand/'

# ------------------------------------------------------------------ business cards (96 x 60 mm incl. 3 mm bleed)
def cards():
    front = f'<div class="f">{logo_dark("46mm")}</div>'
    page('card-front', 96, 60, front, css='''body{background:radial-gradient(120% 140% at 80% 0%,var(--navy2),var(--navy) 60%)}
.f{position:absolute;inset:0;display:flex;align-items:center;justify-content:center}.f svg{height:auto}
body:after{content:"";position:absolute;left:0;right:0;bottom:0;height:3.2mm;background:var(--orange)}''', unit='mm', out_png=OUTB + 'print/business-card-front.png', pdf=None, dsf=3.125)
    back = f'''<div class="l"><div class="nm">{H.escape(C['owner'])}</div><div class="rl">{H.escape(C['name'])}</div>
<div class="ln">{ico('phone', 13, 'var(--orange)')}<span>{C['phone']} · {C['phone2']}</span></div>
<div class="ln">{ico('chat', 13, 'var(--orange)')}<span>WhatsApp</span></div>
<div class="ln">{ico('pin', 13, 'var(--orange)')}<span class="hi">{H.escape(C['addr_hi'].replace(', राजस्थान 332713', ''))}</span></div>
<div class="ln">{ico('globe', 13, 'var(--orange)')}<span>{C['web_short'].replace('pallavsharmaofficial.github.io','…github.io')}</span></div></div>
<div class="r">{qr(C['web'], P['navy'], '23mm')}<div class="sc hi">स्कैन करें</div></div>
<div class="sv hi">{C['tag_hi']}</div>'''
    page('card-back', 96, 60, back, css='''body{background:var(--paper)}
.l{position:absolute;left:7mm;top:6mm;width:55mm}.nm{font-size:4.6mm;font-weight:800;color:var(--navy)}.rl{font-size:2.5mm;font-weight:700;color:var(--orange);margin:.4mm 0 3.4mm;letter-spacing:.05em;text-transform:uppercase}
.ln{display:flex;gap:2mm;align-items:center;font-size:2.5mm;font-weight:600;margin:1.3mm 0;line-height:1.25;word-break:break-all}.ln svg{width:3.2mm;height:3.2mm;flex:none}
.r{position:absolute;right:6mm;top:8mm;text-align:center;width:24mm}.sc{font-size:2.4mm;font-weight:700;margin-top:1.4mm;color:var(--navy)}
.sv{position:absolute;left:0;right:0;bottom:0;height:7.5mm;background:var(--navy);color:#fff;font-size:2.5mm;font-weight:700;display:flex;align-items:center;justify-content:center;letter-spacing:.02em}''', unit='mm', out_png=OUTB + 'print/business-card-back.png', dsf=3.125)

# ------------------------------------------------------------------ A4 poster (210 x 297 mm)
def poster():
    body = f'''<div class="top"><div class="lg">{logo_dark("100mm")}</div><h1 class="hi">{C['headline_hi']}</h1><p class="hi">नए फ़ोन और एक्सेसरी, एक ही दुकान पर</p></div>
<div class="mid"><div class="rows">
<div class="rw">{ico('phone', 30, 'var(--orange)')}<div><b>{C['phone']} · {C['phone2']}</b><span class="hi">कॉल या WhatsApp करें</span></div></div>
<div class="rw">{ico('pin', 30, 'var(--orange)')}<div><b class="hi">{C['addr_hi'].split(',')[0]}, {C['addr_hi'].split(',')[1].strip()}</b><span class="hi">{', '.join(x.strip() for x in C['addr_hi'].split(',')[2:])}</span></div></div>
<div class="rw">{ico('globe', 30, 'var(--orange)')}<div><b style="font-size:4.2mm;word-break:normal">{C['web_short']}</b><span class="hi">ऐप और सारे फ़ोन देखें</span></div></div></div>
<div class="qr">{qr(C['web'], P['navy'], '46mm')}<div class="hi">ऐप खोलने के लिए स्कैन करें</div></div></div>
<div class="svc hi">{C['tag_hi']}</div>
<div class="emi hi">पैन कार्ड · आधार कार्ड · बैंक पासबुक पर EMI · Bajaj Finserv EMI सिर्फ़ दुकान पर (फेस स्कैन ज़रूरी)</div>'''
    css = '''body{background:var(--paper)}
.top{position:absolute;left:0;right:0;top:0;height:150mm;background:radial-gradient(110% 120% at 85% 0%,var(--navy2),var(--navy) 62%);display:flex;flex-direction:column;align-items:center;padding-top:14mm;color:#fff}
.lg svg{height:auto}.top h1{font-size:15.5mm;font-weight:800;margin-top:7mm;text-align:center;line-height:1.15;color:#fff}
.top p{font-size:6.2mm;font-weight:600;margin-top:4mm;color:var(--orange2)}
.mid{position:absolute;left:14mm;right:14mm;top:160mm;display:flex;justify-content:space-between;align-items:center;gap:8mm}.rows{flex:1;min-width:0}.qr{flex:none;width:50mm}
.rw{display:flex;gap:5mm;align-items:center;margin:5mm 0}.rw svg{flex:none;width:9mm;height:9mm}.rw b{display:block;font-size:5.4mm;font-weight:800;color:var(--navy);line-height:1.25;word-break:break-word}.rw span{display:block;font-size:4.2mm;color:var(--slate);font-weight:600}
.qr{text-align:center;font-size:3.8mm;font-weight:700;color:var(--navy)}.qr div{margin-top:3mm}
.svc{position:absolute;left:0;right:0;bottom:19mm;text-align:center;font-size:5mm;font-weight:700;color:var(--navy)}
.emi{position:absolute;left:0;right:0;bottom:0;height:15mm;background:var(--orange);color:#fff;font-size:3.9mm;font-weight:700;display:flex;align-items:center;justify-content:center;text-align:center;padding:0 10mm}'''
    page('poster-a4', 210, 297, body, css=css, unit='mm', out_png=OUTB + 'print/poster-a4.png', pdf=OUTB + 'print/poster-a4.pdf', dsf=2480 / (210 / 25.4 * 96))

# ------------------------------------------------------------------ social images
def social():
    status = f'''<div class="m">{mark("430px")}</div><h1 class="hi">{C['headline_hi']}</h1><p class="hi">नए फ़ोन और एक्सेसरी, एक ही दुकान पर</p>
<div class="ch hi"><span>मोबाइल</span><span>एक्सेसरी</span><span>स्किन कटिंग</span><span>रिपेयरिंग</span></div>
<div class="nm">BRAND<i>HOOP</i></div><div class="sb">MOBILE POINT · <span class="hi">नीम का थाना</span></div>
<div class="bar"><b>कॉल / WhatsApp: {C['phone']} · {C['phone2']}</b></div>'''
    page('status', 1080, 1920, status, css='''body{background:radial-gradient(130% 90% at 80% 0%,var(--navy2),var(--navy) 62%);color:#fff;text-align:center}
.m{padding-top:130px}h1{font-size:84px;font-weight:800;line-height:1.2;margin:70px 60px 0}p{font-size:42px;font-weight:600;color:var(--orange2);margin-top:26px}
.ch{display:flex;gap:18px;justify-content:center;flex-wrap:wrap;margin:60px 50px 0}.ch span{border:3px solid var(--orange);color:#fff;border-radius:60px;padding:12px 30px;font-size:34px;font-weight:700}
.nm{position:absolute;left:0;right:0;bottom:290px;font-size:78px;font-weight:800;letter-spacing:.01em}.nm i{font-style:normal;color:var(--orange)}
.sb{position:absolute;left:0;right:0;bottom:225px;font-size:36px;font-weight:600;letter-spacing:.12em;color:var(--orange2)}
.bar{position:absolute;left:60px;right:60px;bottom:90px;background:var(--orange);border-radius:30px;padding:30px;font-size:40px;color:#fff}''', out_png=OUTB + 'print/whatsapp-status.png')
    post = f'''<div class="m">{mark("360px")}</div><div class="t"><h1 class="hi">नए फ़ोन<br>और एक्सेसरी</h1><p class="hi">एक ही दुकान पर</p><div class="ch hi"><span>स्किन कटिंग</span><span>रिपेयरिंग</span><span>EMI</span></div></div>
<div class="ft"><div class="nm">BRAND<i>HOOP</i> <small>MOBILE POINT</small></div><div class="hi">{C['phone']} · {C['phone2']}<br>गेट नं. 5, कमला मोदी मार्केट, नीम का थाना</div></div>'''
    page('instagram-post', 1080, 1350, post, css='''body{background:var(--paper)}
.m{position:absolute;left:70px;top:150px}.t{position:absolute;left:520px;top:150px;width:490px}
h1{font-size:72px;font-weight:800;line-height:1.15;color:var(--navy)}p{font-size:46px;font-weight:700;color:var(--orange);margin-top:22px}
.ch{display:flex;flex-direction:column;gap:14px;margin-top:40px;align-items:flex-start}.ch span{background:var(--navy);color:#fff;border-radius:40px;padding:10px 26px;font-size:30px;font-weight:700}
.ft{position:absolute;left:0;right:0;bottom:0;height:260px;background:var(--navy);color:#fff;padding:50px 70px}.nm{font-size:56px;font-weight:800}.nm i{font-style:normal;color:var(--orange)}.nm small{font-size:26px;font-weight:600;letter-spacing:.14em;color:var(--orange2);margin-left:10px}
.ft .hi{font-size:34px;font-weight:600;margin-top:26px;color:#dfe3f2}''', out_png=OUTB + 'print/instagram-post.png')
    page('profile', 1080, 1080, f'<div class="c">{mark("420px")}</div>', css='body{background:var(--paper)}.c{position:absolute;inset:0;display:flex;align-items:center;justify-content:center}', out_png=OUTB + 'print/profile-picture.png')
    page('facebook-cover', 1640, 624, f'<div class="l">{hlogo("760px", "dark")}</div><div class="r hi"><b>{C["headline_hi"]}</b><span>{C["tag_hi"]}</span></div>', css='''body{background:radial-gradient(120% 160% at 90% 0%,var(--navy2),var(--navy) 62%);color:#fff}
.l{position:absolute;left:90px;top:120px}.r{position:absolute;left:90px;bottom:58px;right:90px}.r b{display:block;font-size:46px;font-weight:800}.r span{display:block;font-size:30px;font-weight:600;color:var(--orange2);margin-top:8px}''', out_png=OUTB + 'print/facebook-cover.png')
    page('google-cover', 1080, 608, f'<div class="c">{hlogo("700px", "dark")}</div><div class="a hi">{C["addr_hi"].replace(", राजस्थान 332713", "")}</div>', css='''body{background:radial-gradient(120% 160% at 90% 0%,var(--navy2),var(--navy) 62%);color:#fff}
.c{position:absolute;left:0;right:0;top:130px;display:flex;justify-content:center}.a{position:absolute;left:0;right:0;bottom:60px;text-align:center;font-size:32px;font-weight:700;color:var(--orange2)}''', out_png=OUTB + 'print/google-profile-cover.png')
    for k, ic in SVC_ICON.items():
        slug = k.lower().replace(' ', '-')
        hi = {'Phones': 'फ़ोन', 'Accessories': 'एक्सेसरी', 'Skin cutting': 'स्किन कटिंग', 'Repair': 'रिपेयर', 'EMI': 'EMI', 'Shop tour': 'दुकान', 'Customers': 'ग्राहक'}[k]
        page(f'highlight-{slug}', 1080, 1920, f'<div class="c"><div class="o"><svg viewBox="0 0 24 24" width="300" height="300" fill="none" stroke="#fff" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">{ic}</svg></div></div>',
             css='''body{background:radial-gradient(130% 90% at 80% 0%,var(--navy2),var(--navy) 62%)}.c{position:absolute;inset:0;display:flex;align-items:center;justify-content:center}
.o{width:560px;height:560px;border-radius:50%;background:var(--orange);display:flex;align-items:center;justify-content:center;box-shadow:0 0 0 22px rgba(216,102,42,.25)}''', out_png=OUTB + f'print/highlight-{slug}.png')

# ------------------------------------------------------------------ shop board 3:1, letterhead, counter card, og image
def misc():
    board = f'''<div class="m">{mark("760px")}</div><div class="t"><div class="nm">BRAND<i>HOOP</i></div><div class="sb">MOBILE POINT</div><div class="hi sv">{C['tag_hi']}</div>
<div class="hi ad">{C['addr_hi'].replace(', राजस्थान 332713', '')}</div></div><div class="ph"><span class="hi">कॉल / WhatsApp</span><b>{C['phone']}<br>{C['phone2']}</b></div><div class="st"></div>'''
    page('shop-board', 3600, 1200, board, css='''body{background:radial-gradient(100% 140% at 85% 0%,var(--navy2),var(--navy) 62%);color:#fff}
.m{position:absolute;left:150px;top:200px}.t{position:absolute;left:1000px;top:150px}
.nm{font-size:300px;font-weight:800;line-height:1;letter-spacing:.005em}.nm i{font-style:normal;color:var(--orange)}.sb{font-size:120px;font-weight:600;letter-spacing:.18em;color:var(--orange2);margin-top:10px}
.sv{font-size:96px;font-weight:700;margin-top:60px}.ad{font-size:64px;font-weight:600;color:#cfd5ea;margin-top:34px}
.ph{position:absolute;right:120px;bottom:130px;text-align:right}.ph span{display:block;font-size:56px;font-weight:700;color:var(--orange2)}.ph b{font-size:112px;font-weight:800;line-height:1.1}
.st{position:absolute;left:0;right:0;bottom:0;height:60px;background:var(--orange)}''', out_png=OUTB + 'print/shop-board-3x1.png', pdf=OUTB + 'print/shop-board-3x1.pdf')
    lh = f'''<div class="h">{hlogo("86mm")}</div><div class="w">{mark("120mm", 'solid', body_color='#1F2744', detail_color='#F6F6F6')}</div>
<div class="ft"><span>{C['phone']} · {C['phone2']}</span><span class="hi">{C['addr_hi']}</span><span>{C['web_short']}</span></div>'''
    page('letterhead-a4', 210, 297, lh, css='''body{background:#fff}.h{position:absolute;left:18mm;top:14mm}.h svg{height:auto}.w{position:absolute;right:-20mm;top:92mm;opacity:.05}
.ft{position:absolute;left:0;right:0;bottom:0;height:14mm;background:var(--navy);color:#fff;display:flex;gap:10mm;align-items:center;justify-content:center;font-size:3.2mm;font-weight:600;border-top:1.2mm solid var(--orange)}''', unit='mm', out_png=OUTB + 'print/letterhead-a4.png', pdf=OUTB + 'print/letterhead-a4.pdf', dsf=1240 / (210 / 25.4 * 96))
    cc = f'''<div class="l">{mark("70mm")}</div><div class="r"><h1 class="hi">ऐप खोलें<br>सारे फ़ोन देखें</h1><div class="q">{qr(C['web'], P['navy'], '62mm')}</div><p class="hi">कैमरा खोलें, QR स्कैन करें, फिर कॉल या WhatsApp करें: <b>{C['phone']}</b></p></div>'''
    page('counter-card-a5', 210, 148, cc, css='''body{background:var(--paper)}.l{position:absolute;left:18mm;top:30mm}.r{position:absolute;left:102mm;top:12mm;right:12mm}
h1{font-size:10mm;font-weight:800;color:var(--navy);line-height:1.2}.q{margin:5mm 0 3mm}p{font-size:4mm;font-weight:600;color:var(--slate)}p b{color:var(--orange)}
body:after{content:"";position:absolute;left:0;right:0;bottom:0;height:7mm;background:var(--orange)}''', unit='mm', out_png=OUTB + 'print/counter-card-a5.png', pdf=OUTB + 'print/counter-card-a5.pdf', dsf=1748 / (210 / 25.4 * 96))
    og = f'''<div class="l">{hlogo("700px", "dark")}</div><div class="r hi"><b>{C['headline_hi']}</b><span>{C['tag_hi']}</span><em>{C['addr_hi'].replace(', राजस्थान 332713', '')}</em></div>'''
    page('og-image', 1200, 630, og, css='''body{background:radial-gradient(120% 150% at 90% 0%,var(--navy2),var(--navy) 62%);color:#fff}.l{position:absolute;left:70px;top:70px}
.r{position:absolute;left:70px;bottom:62px;right:70px}.r b{display:block;font-size:54px;font-weight:800}.r span{display:block;font-size:30px;font-weight:600;color:var(--orange2);margin-top:10px}.r em{display:block;font-style:normal;font-size:26px;font-weight:600;color:#cfd5ea;margin-top:12px}
body:after{content:"";position:absolute;left:0;right:0;bottom:0;height:14px;background:var(--orange)}''', out_png='site/og-image.png')


# ------------------------------------------------------------------ A5 counter card in the Tech Grid style (trim 148 x 210 mm, plus a copy with 3 mm bleed)
APP_URL = 'https://pallavsharmaofficial.github.io/brandhoop/app/'
TAG_CARD_HI = 'नया फोन हो या रिपेयरिंग का काम, हर ज़रूरत का एक ही मुकाम'
def counter_tech():
    for name, b in (('counter-card-a5-trim', 0), ('counter-card-a5-bleed', 3)):
        w, h = 148 + 2 * b, 210 + 2 * b
        body = f"""<div class="art"></div><div class="in" style="left:{b}mm;top:{b}mm">
<div class="lg">{hlogo('68mm', 'dark')}</div>
<h1 class="hi"><span>ऐप खोलो,</span><span class="o">ख़ुद सब देख लो</span></h1>
<div class="chip hi">फ़ोन और एक्सेसरीज़ · सब कुछ यहीं</div>
<div class="qc"><div class="qr">{qr(APP_URL, P['navy'], '65mm')}</div><div class="cap hi">QR स्कैन करो → ऐप खुलेगा</div></div>
<div class="tg hi">{TAG_CARD_HI}</div>
<div class="ad hi">{C['addr_hi']}</div>
<div class="ph"><span class="hi">कॉल / WhatsApp</span> <b>{C['phone']}</b><i>·</i><b>{C['phone2']}</b></div></div>
<div class="bar" style="height:{4 + b}mm"></div>"""
        css = f"""body{{background:linear-gradient(165deg,#1F2744 0%,#141A33 55%,#0B0F1C 100%);color:#fff}}
.art{{position:absolute;inset:0;background:repeating-linear-gradient(0deg,rgba(255,255,255,.055) 0 .25mm,transparent .25mm 8mm),repeating-linear-gradient(90deg,rgba(255,255,255,.055) 0 .25mm,transparent .25mm 8mm)}}
.art:after{{content:"";position:absolute;inset:0;background:url(../../../site/brand/cards/lineart.png) center top/160mm auto repeat;opacity:.05}}
.in{{position:absolute;width:148mm;height:210mm}}
.lg{{position:absolute;left:0;right:0;top:11mm;display:flex;justify-content:center}}
h1{{position:absolute;left:0;right:0;top:43mm;text-align:center;font-size:14mm;line-height:1.18;font-weight:800}}h1 span{{display:block}}h1 .o{{color:var(--orange2)}}
.chip{{position:absolute;left:0;right:0;top:79mm;margin:0 auto;width:max-content;border:.5mm solid var(--orange);color:#fff;border-radius:6mm;padding:1.4mm 5mm;font-size:4.2mm;font-weight:700;background:rgba(216,102,42,.16)}}
.qc{{position:absolute;left:0;right:0;top:93mm;margin:0 auto;width:79mm;background:#fff;border-radius:6mm;padding:6mm 6mm 4mm;box-shadow:0 2mm 8mm rgba(0,0,0,.4);border:1.2mm solid var(--orange)}}
.qr{{display:block;width:65mm;height:65mm}}.qr svg{{display:block}}
.cap{{margin-top:3mm;text-align:center;font-size:4.6mm;font-weight:800;color:var(--navy)}}
.tg{{position:absolute;left:10mm;right:10mm;top:184mm;text-align:center;font-size:4.1mm;font-weight:700;color:#fff}}
.ad{{position:absolute;left:8mm;right:8mm;top:192mm;text-align:center;font-size:3.1mm;font-weight:600;color:#C5CCE4}}
.ph{{position:absolute;left:0;right:0;top:197.5mm;text-align:center;font-size:3.2mm;font-weight:600;color:#C5CCE4;white-space:nowrap}}.ph b{{color:#fff;font-size:3.8mm;font-weight:800}}.ph i{{margin:0 2mm;font-style:normal;color:var(--orange2)}}
.bar{{position:absolute;left:0;right:0;bottom:0;background:var(--orange)}}"""
        page(name, w, h, body, css=css, unit='mm', out_png=OUTB + f'print/cards/{name}-300dpi.png', pdf=OUTB + f'print/cards/{name}.pdf', dsf=3.125)


# ------------------------------------------------------------------ counter poster for the free Phone Care page (A4, and A5 scaled from it)
CARE_URL = 'https://pallavsharmaofficial.github.io/brandhoop/care/'
def care_poster():
    for name, w, h, k in (('care-poster-a4', 210, 297, 1.0), ('care-poster-a5', 148, 210, 148 / 210)):
        pts = ['फ़ोन कितना तेज़ है, तुरंत जानिए', 'बैटरी, स्क्रीन, टच, स्पीकर, कैमरा की जाँच', 'फ़ोन तेज़ करने के आसान, सही तरीके', 'कोई ऐप डालने की ज़रूरत नहीं']
        lis = ''.join(f'<li><i>✓</i><span class="hi">{t}</span></li>' for t in pts)
        body = f"""<div class="art"></div><div class="wrap" style="transform:scale({k});transform-origin:0 0;width:210mm;height:297mm">
<div class="lg">{hlogo('80mm', 'dark')}</div>
<h1 class="hi"><span>फ़ोन धीमा है?</span><span class="o">बैटरी जल्दी ख़त्म?</span></h1>
<div class="chip hi">1 मिनट में मुफ़्त जाँच · फिर बार-बार काम आएगा</div>
<div class="qc"><div class="qr">{qr(CARE_URL, P['navy'], '78mm')}</div><div class="cap hi">QR स्कैन करो → जाँच खुलेगी</div></div>
<ul class="pts">{lis}</ul>
<div class="ft"><b>Brandhoop Mobile Point</b><span class="hi">गेट नं. 5, कमला मोदी मार्केट, नीम का थाना</span><span><b>{C['phone']}</b> · <b>{C['phone2']}</b></span></div>
<div class="bar"></div></div>"""
        css = """body{background:linear-gradient(165deg,#1F2744 0%,#141A33 55%,#0B0F1C 100%);color:#fff}
.art{position:absolute;inset:0;background:repeating-linear-gradient(0deg,rgba(255,255,255,.055) 0 .3mm,transparent .3mm 9mm),repeating-linear-gradient(90deg,rgba(255,255,255,.055) 0 .3mm,transparent .3mm 9mm)}
.art:after{content:"";position:absolute;inset:0;background:url(../../site/brand/cards/lineart.png) center top/230mm auto repeat;opacity:.05}
.wrap{position:absolute;left:0;top:0}.lg{position:absolute;left:0;right:0;top:14mm;display:flex;justify-content:center}
h1{position:absolute;left:0;right:0;top:57mm;text-align:center;font-size:18mm;line-height:1.15;font-weight:800}h1 span{display:block}h1 .o{color:var(--orange2)}
.chip{position:absolute;left:0;right:0;top:101mm;margin:0 auto;width:max-content;border:.6mm solid var(--orange);border-radius:8mm;padding:2mm 7mm;font-size:5.4mm;font-weight:700;background:rgba(216,102,42,.16)}
.qc{position:absolute;left:0;right:0;top:115mm;margin:0 auto;width:104mm;background:#fff;border-radius:8mm;padding:8mm 8mm 4mm;border:1.6mm solid var(--orange);box-shadow:0 3mm 10mm rgba(0,0,0,.4)}
.qr{width:78mm;height:78mm;margin:0 auto}.qr svg{display:block}.cap{margin-top:4mm;text-align:center;font-size:6mm;font-weight:800;color:var(--navy)}
.pts{position:absolute;left:34mm;right:20mm;top:226mm;list-style:none;margin:0;padding:0;font-size:5mm;font-weight:600}.pts li{display:flex;gap:4mm;align-items:center;margin:1.2mm 0}.pts i{font-style:normal;color:var(--orange2);font-weight:800}
.ft{position:absolute;left:0;right:0;bottom:12mm;text-align:center;font-size:4.2mm;line-height:1.5;color:#C5CCE4}.ft b{color:#fff}.ft span{display:block}
.bar{position:absolute;left:0;right:0;bottom:0;height:6mm;background:var(--orange)}"""
        page(name, w, h, body, css=css, unit='mm', out_png=OUTB + f'print/{name}.png', pdf=OUTB + f'print/{name}.pdf', dsf=(w / 25.4 * 300) / (w / 25.4 * 96))


# ------------------------------------------------------------------ launch-day print set: auto-rickshaw posters, four more counter cards, daily-rate story cards
SITE_URL = 'https://pallavsharmaofficial.github.io/brandhoop/'
MAPS_URL = 'https://www.google.com/maps/place/Brandhoop+Mobile+Point/@27.7415504,75.7817561,17z/data=!3m1!4b1!4m6!3m5!1s0x396d275817d19c4f:0x92f9965c781103ad!8m2!3d27.7415504!4d75.7817561!16s%2Fg%2F11g1lxn9kc'
def wa_link(text): return f"https://wa.me/{C['phone_raw']}?text=" + __import__('urllib.parse', fromlist=['quote']).quote(text)

BG_CSS = """body{background:linear-gradient(165deg,#1F2744 0%,#141A33 55%,#0B0F1C 100%);color:#fff}
.art{position:absolute;inset:0;background:repeating-linear-gradient(0deg,rgba(255,255,255,.055) 0 .25mm,transparent .25mm 8mm),repeating-linear-gradient(90deg,rgba(255,255,255,.055) 0 .25mm,transparent .25mm 8mm)}
.art:after{content:"";position:absolute;inset:0;background:url(../../site/brand/cards/lineart.png) center top/160mm auto repeat;opacity:.05}"""

def rickshaw_posters():
    # 3 ft x 2 ft (900 x 600 mm): read from a few metres away, so few words, huge numbers, one QR.
    base = """.art:after{background-size:520mm auto}
.lg{position:absolute;left:36mm;top:26mm}.q{position:absolute;right:36mm;bottom:70mm;background:#fff;border-radius:16mm;padding:14mm 14mm 7mm;border:5mm solid var(--orange)}
.q .c{margin-top:4mm;text-align:center;font-weight:800;color:var(--navy);font-size:15mm;line-height:1.12}.q svg{display:block;width:190mm;height:190mm}
h1{position:absolute;left:36mm;top:124mm;margin:0;font-weight:800;line-height:1.08;width:580mm}h1 span{display:block}h1 .o{color:var(--orange2)}
.sub{position:absolute;left:38mm;top:%s;font-size:27mm;font-weight:700;color:#E3E7F6;width:580mm;line-height:1.22}
.ph{position:absolute;left:36mm;bottom:52mm;font-size:56mm;font-weight:800;line-height:1.04;letter-spacing:.01em}.ph span{display:block}.ph .t{font-size:21mm;color:var(--orange2);font-weight:700;margin-bottom:2mm}
.ad{position:absolute;left:38mm;bottom:19mm;font-size:20mm;font-weight:700;color:#C5CCE4}.bar{position:absolute;left:0;right:0;bottom:0;height:12mm;background:var(--orange)}"""
    sets = [
        ('rickshaw-poster-1', '<span>नया फ़ोन</span><span class="o">लेना है?</span>', 80, '290mm', 'vivo · OPPO · सारे नए 5G फ़ोन<br>सही दाम · EMI · रिपेयर', SITE_URL + 'app/', 'QR स्कैन करो<br>सारे फ़ोन और रेट'),
        ('rickshaw-poster-2', '<span>फ़ोन धीमा है?</span><span class="o">बैटरी जल्दी ख़त्म?</span>', 58, '262mm', 'मुफ़्त जाँच · रिपेयर · स्किन कटिंग<br>ग्लास · कवर · चार्जर', SITE_URL + 'care/', 'QR स्कैन करो<br>फ़ोन की मुफ़्त जाँच')]
    for name, h1, fs, subtop, sub, url, cap in sets:
        body = f"""<div class="art"></div><div class="lg">{hlogo('205mm', 'dark')}</div><h1 class="hi" style="font-size:{fs}mm">{h1}</h1><div class="sub hi">{sub}</div>
<div class="ph"><span class="t hi">कॉल / WhatsApp</span><span>{C['phone']}</span><span>{C['phone2']}</span></div>
<div class="ad hi">गेट नं. 5, कमला मोदी मार्केट, नीम का थाना</div><div class="q">{qr(url, P['navy'], '190mm')}<div class="c hi">{cap}</div></div><div class="bar"></div>"""
        page(name, 900, 600, body, css=BG_CSS + base % subtop, unit='mm', out_png=OUTB + f'print/{name}.png', pdf=OUTB + f'print/{name}.pdf', dsf=100 / 96)

CARDS = [  # name, line1, line2, chip, points, qr url, caption, extra css class
    ('counter-card-emi', 'फ़ोन अभी लीजिए,', 'पैसे किस्तों में', 'Bajaj Finserv EMI · सिर्फ़ दुकान पर', ['तीन कागज़ चाहिए: पैन कार्ड, आधार कार्ड, बैंक पासबुक', 'फ़ेस स्कैन ज़रूरी है, वह दुकान पर ही होता है', 'मंज़ूरी और दर फ़ाइनेंस कंपनी तय करती है'], wa_link('Hi Brandhoop, EMI info please'), 'QR स्कैन → WhatsApp पर EMI पूछिए'),
    ('counter-card-repair', 'फ़ोन टूटा या अटकता है?', 'यहीं देखा जाएगा', 'रिपेयर · स्क्रीन ग्लास · स्किन कटिंग', ['मोबाइल रिपेयरिंग', 'टेम्पर्ड ग्लास और कवर', 'स्किन कटिंग, नए डिज़ाइन में'], wa_link('Hi Brandhoop, my phone needs a check'), 'QR स्कैन → WhatsApp पर पूछिए'),
    ('counter-card-accessories', 'फ़ोन के साथ', 'ज़रूरी सामान', 'ग्लास · कवर · चार्जर · ईयरबड्स', ['कॉम्बो: ग्लास + कवर &nbsp; ₹ ________', 'फ़ास्ट चार्जर + केबल &nbsp; ₹ ________', 'ईयरबड्स / पावर बैंक &nbsp; ₹ ________'], SITE_URL + 'app/#/shop?cat=caseCover', 'QR स्कैन → ऐप में सारे एक्सेसरी'),
    ('counter-card-google', 'हमें ढूँढिए', 'गूगल मैप पर', 'रास्ता · फ़ोटो · रिव्यू', ['नीम का थाना, कमला मोदी मार्केट, गेट नं. 5', 'दुकान अच्छी लगे तो गूगल पर रिव्यू दीजिए', 'रिव्यू में अपना सच्चा अनुभव लिखिए'], 'https://maps.google.com/?cid=10590661322633970605', 'QR स्कैन → गूगल मैप खुलेगा')]

def counter_cards_more():
    for name, l1, l2, chip, pts, url, cap in CARDS:
        for suffix, b in (('trim', 0), ('bleed', 3)):
            w, h = 148 + 2 * b, 210 + 2 * b
            lis = ''.join(f'<li><i>✓</i><span class="hi">{t}</span></li>' for t in pts)
            body = f"""<div class="art"></div><div class="in" style="left:{b}mm;top:{b}mm"><div class="lg">{hlogo('68mm', 'dark')}</div>
<h1 class="hi"><span>{l1}</span><span class="o">{l2}</span></h1><div class="chip hi">{chip}</div>
<div class="qc"><div class="qr">{qr(url, P['navy'], '58mm')}</div><div class="cap hi">{cap}</div></div>
<ul class="pts">{lis}</ul><div class="ft hi">{C['addr_hi']}</div><div class="ph"><span class="hi">कॉल / WhatsApp</span> <b>{C['phone']}</b><i>·</i><b>{C['phone2']}</b></div></div><div class="bar" style="height:{4 + b}mm"></div>"""
            css = BG_CSS.replace('160mm auto', '160mm auto') + """.in{position:absolute;width:148mm;height:210mm}.lg{position:absolute;left:0;right:0;top:11mm;display:flex;justify-content:center}
h1{position:absolute;left:8mm;right:8mm;top:38mm;text-align:center;font-size:12.5mm;line-height:1.18;font-weight:800}h1 span{display:block}h1 .o{color:var(--orange2)}
.chip{position:absolute;left:0;right:0;top:72mm;margin:0 auto;width:max-content;max-width:132mm;text-align:center;border:.5mm solid var(--orange);border-radius:6mm;padding:1.4mm 5mm;font-size:4.2mm;font-weight:700;background:rgba(216,102,42,.16)}
.qc{position:absolute;left:0;right:0;top:86mm;margin:0 auto;width:72mm;background:#fff;border-radius:6mm;padding:6mm 7mm 3.5mm;border:1.2mm solid var(--orange)}.qr{width:58mm;height:58mm}.qr svg{display:block}
.cap{margin-top:2.6mm;text-align:center;font-size:3.7mm;font-weight:800;color:var(--navy);line-height:1.25}
.pts{position:absolute;left:14mm;right:10mm;top:166mm;list-style:none;margin:0;padding:0;font-size:3.9mm;font-weight:600}.pts li{display:flex;gap:3mm;align-items:flex-start;margin:1.1mm 0}.pts i{font-style:normal;color:var(--orange2);font-weight:800}
.ft{position:absolute;left:8mm;right:8mm;top:192mm;text-align:center;font-size:3.1mm;font-weight:600;color:#C5CCE4}
.ph{position:absolute;left:0;right:0;top:197.5mm;text-align:center;font-size:3.2mm;font-weight:600;color:#C5CCE4;white-space:nowrap}.ph b{color:#fff;font-size:3.8mm;font-weight:800}.ph i{margin:0 2mm;font-style:normal;color:var(--orange2)}
.bar{position:absolute;left:0;right:0;bottom:0;background:var(--orange)}"""
            page(f'{name}-{suffix}', w, h, body, css=css, unit='mm', out_png=OUTB + f'print/cards/{name}-{suffix}-300dpi.png', pdf=OUTB + f'print/cards/{name}-{suffix}.pdf', dsf=3.125)

def price_cards():
    names = {r[0]: r[1] for r in _phones.PHONES}
    for brand, key in (('vivo', 'vivo'), ('OPPO', 'oppo')):
        ids = [pid for pid in _sd.DATA if pid.startswith(key + '-')]
        ids.sort(key=lambda i: min(p for _, p in _sd.DATA[i]['prices']))
        n = 3 if len(ids) > 9 or brand == 'OPPO' else 4
        groups = [ids[i::n] if False else None for i in range(0)]
        per = -(-len(ids) // -(-len(ids) // 3))             # even groups of at most 3 so every row stays large
        chunks = [ids[i:i + per] for i in range(0, len(ids), per)]
        date_hi = _sd.DATA[ids[0]]['updated'][1]
        for ci, chunk in enumerate(chunks):
            rows = ''
            for pid in chunk:
                d = _sd.DATA[pid]
                chips = ''.join(f'<span><i>{l.replace(" GB", "").replace(" + ", "/")}</i> ₹{p:,}</span>' for l, p in d['prices'])
                rows += f'<div class="r"><div class="n">{H.escape(names[pid])}</div><div class="v">{chips}</div></div>'
            body = f"""<div class="art"></div><div class="hd">{hlogo('420px', 'dark')}<div class="t hi">{brand} फ़ोन · आज के रेट</div><div class="d hi">दुकान की कीमत · {date_hi} तक{' · भाग ' + str(ci + 1) + '/' + str(len(chunks)) if len(chunks) > 1 else ''}</div></div>
<div class="rows">{rows}</div><div class="note hi">कीमत बदल सकती है। आज का पक्का रेट, गिफ़्ट और EMI के लिए कॉल या WhatsApp कीजिए।</div>
<div class="ft"><div class="qq">{qr(SITE_URL + 'app/', P['navy'], '230px')}<span class="hi">ऐप में सारे<br>फ़ोन देखें</span></div><div class="ad"><b>{C['phone']} · {C['phone2']}</b><span class="hi">{C['addr_hi'].replace(', राजस्थान 332713', '')}</span></div></div><div class="bar"></div>"""
            css = BG_CSS.replace('mm', 'px').replace('.25px', '2px').replace('8px', '64px').replace('160px auto', '1200px auto') + """.hd{position:absolute;left:70px;right:70px;top:70px}.t{font-size:78px;font-weight:800;margin-top:34px;color:#fff}.d{font-size:36px;color:var(--orange2);font-weight:700;margin-top:6px}
.rows{position:absolute;left:60px;right:60px;top:470px;display:flex;flex-direction:column;gap:22px}.r{background:rgba(255,255,255,.08);border:2px solid rgba(255,255,255,.14);border-radius:28px;padding:22px 30px}
.n{font-size:58px;font-weight:800}.v{display:flex;flex-wrap:wrap;gap:10px 14px;margin-top:12px}.v span{background:#fff;color:var(--navy);border-radius:44px;padding:10px 24px;font-size:40px;font-weight:800}.v i{font-style:normal;color:var(--orange);margin-right:8px}
.note{position:absolute;left:70px;right:70px;bottom:440px;font-size:30px;color:#C5CCE4;line-height:1.35}.ft{position:absolute;left:60px;right:60px;bottom:70px;display:flex;gap:28px;align-items:center}
.qq{background:#fff;border-radius:22px;padding:14px;text-align:center;color:var(--navy);font-weight:800;font-size:22px;line-height:1.2}.qq svg{display:block}.ad{font-size:30px;line-height:1.5;color:#C5CCE4}.ad b{display:block;color:#fff;font-size:44px}
.bar{position:absolute;left:0;right:0;bottom:0;height:26px;background:var(--orange)}"""
            page(f'price-card-{key}-{ci + 1}', 1080, 1920, body, css=css, out_png=OUTB + f'print/price-cards/price-card-{key}-{ci + 1}.png')


# ------------------------------------------------------------------ launch-day plan, 3 A4 pages (merged into one PDF by tools/brand/build_plan.sh)
def launch_plan():
    css = """body{background:#fff;color:#14182B;font-size:3.35mm;line-height:1.38}.pg{position:absolute;inset:0;padding:9mm 11mm}
h1{font-size:7.6mm;margin:0;color:#1F2744}h1 small{display:block;font-size:3.6mm;color:#566170;font-weight:600;margin-top:1mm}h2{font-size:4.7mm;margin:4mm 0 1.4mm;color:#1F2744;border-bottom:.5mm solid #D8662A;padding-bottom:.8mm}
table{width:100%;border-collapse:collapse}td,th{border:.25mm solid #cfd4e0;padding:1.3mm 1.8mm;vertical-align:top;text-align:left}th{background:#1F2744;color:#fff;font-size:3.2mm}tr:nth-child(even) td{background:#f6f6f8}
.t{white-space:nowrap;font-weight:800;color:#A9481C}.f{color:#566170;font-size:3mm}.box{display:inline-block;width:3.2mm;height:3.2mm;border:.35mm solid #1F2744;margin-right:1.6mm;vertical-align:-.4mm}
.hd{display:flex;justify-content:space-between;align-items:center;border-bottom:1mm solid #D8662A;padding-bottom:3mm;margin-bottom:3mm}.pn{position:absolute;right:11mm;bottom:6mm;font-size:3mm;color:#566170}
.n{background:#FBE3D2;border-radius:2mm;padding:2mm 3mm;margin:2mm 0;font-size:3.1mm}ul{margin:1mm 0 1mm 4.5mm;padding:0}li{margin:.4mm 0}.sm{font-size:3mm}.q{font-style:normal;background:#f1f3f9;border-radius:1.5mm;padding:1mm 2mm;display:inline-block;margin:.4mm 0}"""
    hd = lambda t, sub: f"""<div class="hd"><div><h1 class="hi">{t}<small>{sub}</small></h1></div><div>{hlogo('52mm', 'light')}</div></div>"""
    p1 = f"""<div class="pg">{hd('आज का प्लान: आज से ही असर दिखे', 'तारीख़ ___ · सबसे पहले प्रिंट का काम, क्योंकि वही सबसे देर लेता है')}
<table class="hi"><tr><th>समय</th><th>काम</th><th>कौन</th><th>तैयार फ़ाइल / सामान</th></tr>
<tr><td class="t">पहला आधा घंटा</td><td><b>प्रिंट प्रेस को ऑर्डर दीजिए (सबसे पहले)</b><br>विज़िटिंग कार्ड, 6 काउंटर कार्ड, 2 ऑटो-रिक्शा पोस्टर। आज की डिलीवरी पूछिए और रेट के कोटेशन लीजिए।</td><td>नरेश / पल्लव</td><td class="f">ज़िप: print-files (नीचे पन्ना 3 की शीट)</td></tr>
<tr><td class="t">साथ-साथ</td><td><b>अभी, घर या दुकान के प्रिंटर से A4 निकालिए</b><br>फ़ोन केयर पोस्टर और ऐप वाला कार्ड काउंटर पर लगा दीजिए, ताकि प्रेस का इंतज़ार किए बिना QR आज ही लग जाए।</td><td>नरेश</td><td class="f">care-poster-a4.pdf, counter-card-a5-trim.pdf</td></tr>
<tr><td class="t">घंटा 1</td><td><b>दुकान सजाइए (1 घंटा)</b><br><span class="box"></span>काउंटर साफ़, फ़ालतू सामान हटाया &nbsp; <span class="box"></span>शीशे, डिस्प्ले पोंछे &nbsp; <span class="box"></span>फ़ोन ब्रांड के हिसाब से लगाए (vivo / OPPO) &nbsp; <span class="box"></span>शेल्फ़ पर प्राइस-स्ट्रिप चिपकाईं &nbsp; <span class="box"></span>QR कार्ड काउंटर पर &nbsp; <span class="box"></span>सारी लाइटें चालू &nbsp; <span class="box"></span>बाहर का बोर्ड और शटर साफ़</td><td>नरेश + स्टाफ़</td><td class="f">shop-kit: प्राइस-स्ट्रिप, काउंटर साइन</td></tr>
<tr><td class="t">घंटा 2</td><td><b>गूगल के लिए नई फ़ोटो (12 फ़ोटो, 30 मिनट)</b><br>सूची पन्ना 3 पर। दिन की रोशनी में, आड़ी (landscape), बिना फ़िल्टर। Google Maps ऐप में दुकान खोलकर "फ़ोटो जोड़ें"।</td><td>पल्लव / कोई एक</td><td class="f">फ़ोन कैमरा, साफ़ लेंस</td></tr>
<tr><td class="t">घंटा 2.5–4</td><td><b>दो मुख्य रील बनाइए</b><br>रील 1: दुकान + नए फ़ोन। रील 2: "फ़ोन धीमा? 1 मिनट में जाँच"। पूरी स्क्रिप्ट पन्ना 2 पर। एक-दो टेक काफ़ी हैं, परफ़ेक्ट मत ढूँढिए।</td><td>पल्लव (कैमरा) + नरेश (बोलना)</td><td class="f">फ़ोन, ट्राइपॉड/टेक, छोटा माइक अगर हो</td></tr>
<tr><td class="t">घंटा 4–5</td><td><b>एडिट और पोस्ट</b><br>CapCut या Instagram Edits में काटिए, अक्षर जोड़िए, 1080×1920 में निकालिए। Instagram + Facebook + YouTube Shorts पर एक ही रील डालिए।</td><td>पल्लव</td><td class="f">रील का कैप्शन पन्ना 2 पर</td></tr>
<tr><td class="t">घंटा 5–5.5</td><td><b>ऑनलाइन पहचान एक साथ अपडेट</b><br><span class="box"></span>Instagram बायो, प्रोफ़ाइल फ़ोटो, हाइलाइट &nbsp; <span class="box"></span>Facebook पेज &nbsp; <span class="box"></span>Google प्रोफ़ाइल: फ़ोटो + पोस्ट + सेवाएँ + फ़ोन &nbsp; <span class="box"></span>WhatsApp Business प्रोफ़ाइल</td><td>पल्लव + नरेश</td><td class="f">profile-picture, facebook-cover, google-profile-cover, highlight-*.png</td></tr>
<tr><td class="t">शाम से पहले</td><td><b>WhatsApp स्टेटस पर "आज के रेट" कार्ड डालिए (7 कार्ड)</b><br>अपने सभी कॉन्टैक्ट्स को एक बार। ग्रुप में तभी भेजिए जब ग्रुप के एडमिन की इजाज़त हो।</td><td>नरेश</td><td class="f">price-cards/price-card-vivo-1…4, oppo-1…3</td></tr>
<tr><td class="t">शाम</td><td><b>प्रेस से सामान उठाइए और लगाइए</b><br>काउंटर कार्ड, विज़िटिंग कार्ड। ऑटो-रिक्शा वालों से बात कीजिए: कौन-सा रूट, कितने ऑटो, कितने दिन (जगह के रेट पूछकर तय कीजिए)।</td><td>नरेश</td><td class="f">—</td></tr>
<tr><td class="t">आज रात</td><td><b>पाँच खुश ग्राहकों से Google रिव्यू माँगिए</b> (QR वाला कार्ड दिखाकर)। रिव्यू ख़रीदिए मत और न बदले में कुछ दीजिए। जवाब हर रिव्यू का दीजिए।</td><td>नरेश</td><td class="f">counter-card-google</td></tr></table>
<div class="n hi"><b>आज से असर कैसे दिखेगा:</b> WhatsApp स्टेटस (आज ही), गूगल की नई फ़ोटो (कुछ घंटों में), रील (24 से 48 घंटे में पहुँच बनती है), काउंटर QR (आते हर ग्राहक पर), ऑटो पोस्टर (अगले एक-दो दिन में)। असर नापने के लिए हर ग्राहक से पूछिए "कैसे पता चला?" और कॉपी में गिनती रखिए।</div>
<div class="n hi"><b>ईमानदारी का नियम:</b> रेट के हर पोस्ट पर तारीख़ लिखी है। नकली डिस्काउंट, नकली रेटिंग या "सिर्फ़ N बचे" मत लिखिए। EMI के बारे में सिर्फ़ वही लिखिए जो हमारे कार्ड पर है।</div><div class="pn">पन्ना 1/3</div></div>"""
    rows = lambda items: ''.join(f"<tr><td class='t'>{a}</td><td>{b}</td><td>{c}</td></tr>" for a, b, c in items)
    r1 = [('0–2 सेकंड', 'दुकान का बाहर से शॉट, फिर अंदर आते हुए', 'ऑन-स्क्रीन: "नीम का थाना में नया फ़ोन लेना है? 👇"'),
          ('2–8 सेकंड', 'बोर्ड, फिर दरवाज़े से अंदर, नरेश जी कैमरे की तरफ़ देखकर', '"ये है ब्रांडहूप मोबाइल पॉइंट, कमला मोदी मार्केट, गेट नंबर 5, नीम का थाना।"'),
          ('8–16 सेकंड', 'फ़ोन की दीवार पर धीमा पैन, vivo और OPPO के डिब्बों का क्लोज़-अप', '"vivo और OPPO के नए 5G फ़ोन, एक ही जगह।"'),
          ('16–22 सेकंड', 'काउंटर पर रेट-कार्ड/प्राइस-स्ट्रिप दिखाना, फ़ोन उठाकर हाथ में', '"हर फ़ोन का रेट साफ़। EMI की सुविधा दुकान पर।"'),
          ('22–28 सेकंड', 'काउंटर का QR कार्ड, फिर पते वाला आख़िरी फ़्रेम', '"QR स्कैन करो, ऐप में सारे फ़ोन और रेट देखो। आज ही आइए!"')]
    r2 = [('0–2 सेकंड', 'हाथ में धीमा फ़ोन, अटकती स्क्रीन', 'ऑन-स्क्रीन: "फ़ोन धीमा है? 1 मिनट में जाँचो"'),
          ('2–10 सेकंड', 'पोस्टर का QR स्कैन करना, फ़ोन केयर पेज खुलना', '"बस ये QR स्कैन करो। फ़ोन की मुफ़्त जाँच शुरू।"'),
          ('10–18 सेकंड', 'स्क्रीन-रिकॉर्डिंग: जाँच चलना, स्कोर आना, एक-दो हार्डवेयर टेस्ट', '"रफ़्तार, टच, स्पीकर, कैमरा, सब यहीं जाँच लो।"'),
          ('18–24 सेकंड', 'सफ़ाई के चरण वाली स्क्रीन, चेकबॉक्स पर टिक', '"फिर बताए गए आसान चरण करो, फ़ोन तेज़ होगा। कोई क्लीनर ऐप मत डालना।"'),
          ('24–29 सेकंड', 'दुकान का अंदर का शॉट, नए फ़ोन पर हाथ', '"फ़ोन बहुत पुराना हो गया? बजट बताओ, सही नया फ़ोन यहीं।"')]
    p2 = f"""<div class="pg">{hd('Instagram: 2 मुख्य रील + पेज अपडेट', 'सब कुछ फ़ोन से हो जाता है। असली आवाज़ और असली दुकान सबसे अच्छी लगती है')}
<h2 class="hi">बायो (कॉपी करके चिपकाइए)</h2><div class="n hi">ब्रांडहूप मोबाइल पॉइंट 📱 नीम का थाना<br>नए फ़ोन · एक्सेसरी · रिपेयर · स्किन कटिंग · EMI<br>📍 गेट नं. 5, कमला मोदी मार्केट<br>📞 86197 67291 · 72399 38540<br>👇 सारे फ़ोन और आज के रेट</div>
<div class="sm hi">लिंक: pallavsharmaofficial.github.io/brandhoop · प्रोफ़ाइल फ़ोटो: profile-picture.png · 7 हाइलाइट कवर: highlight-*.png (Phones, Accessories, Skin cutting, Repair, EMI, Shop tour, Customers)</div>
<h2 class="hi">रील 1 · दुकान टूर और नए फ़ोन (लगभग 28 सेकंड)</h2><table class="hi"><tr><th style="width:20mm">समय</th><th>क्या दिखाएँ</th><th>क्या बोलें / लिखें</th></tr>{rows(r1)}</table>
<h2 class="hi">रील 2 · फ़ोन धीमा? 1 मिनट में जाँच (लगभग 29 सेकंड)</h2><table class="hi"><tr><th style="width:20mm">समय</th><th>क्या दिखाएँ</th><th>क्या बोलें / लिखें</th></tr>{rows(r2)}</table>
<h2 class="hi">कैप्शन और हैशटैग</h2>
<div class="n hi"><b>रील 1:</b> नीम का थाना में नया फ़ोन? ब्रांडहूप मोबाइल पॉइंट, कमला मोदी मार्केट, गेट नं. 5। vivo और OPPO के नए 5G फ़ोन, साफ़ रेट, EMI की सुविधा। 📞 86197 67291 · 72399 38540<br><b>रील 2:</b> फ़ोन धीमा या बैटरी जल्दी ख़त्म? दुकान के QR से मुफ़्त जाँच कीजिए और फ़ोन तेज़ रखने के आसान तरीके पाइए। 📍 ब्रांडहूप मोबाइल पॉइंट, नीम का थाना<br><span class="f">#NeemKaThana #नीमकाथाना #Rajasthan #MobileShop #vivo #OPPO #NewPhone #PhoneCare #BrandhoopMobilePoint &nbsp;(8 से 10 हैशटैग काफ़ी)</span></div>
<ul class="hi sm"><li>गाना: Instagram की अपनी रॉयल्टी-फ़्री लाइब्रेरी से लीजिए। अपनी आवाज़ सबसे अच्छी है, पहले 2 सेकंड में बोलना शुरू कीजिए।</li><li>पोस्ट का समय: शाम 6 से 9 बजे। पोस्ट के बाद पहले घंटे में हर कमेंट और मैसेज का जवाब दीजिए।</li><li>स्टोरी: रेट कार्ड डालिए और "लिंक" स्टिकर पर दुकान की वेबसाइट लगाइए। स्टोरी में लोकेशन टैग ज़रूर लगाइए।</li><li>पहले 9 पोस्ट: 2 रील + 7 रेट-कार्ड, ताकि पेज भरा-भरा दिखे।</li><li>पूरे हफ़्ते की रील: vivo T5 Pro अनबॉक्सिंग · OPPO Reno 16 हाथ में · स्किन कटिंग का काम · एक्सेसरी कॉम्बो · "5 फ़ोन ₹20,000 के आसपास"।</li></ul><div class="pn">पन्ना 2/3</div></div>"""
    photos = ['दुकान का बाहर से दिन में पूरा सामने का शॉट', 'बोर्ड का क्लोज़-अप (नाम पढ़ने लायक)', 'दरवाज़ा/प्रवेश', 'अंदर का चौड़ा शॉट (दरवाज़े से)', 'अंदर का चौड़ा शॉट (काउंटर के पीछे से)', 'फ़ोन की दीवार (vivo / OPPO अलग-अलग क्लोज़-अप)', 'काउंटर और QR कार्ड', 'एक्सेसरी की दीवार', 'रिपेयर/स्किन कटिंग का कोना', 'नरेश जी काउंटर पर (मुस्कुराते हुए)', 'पोस्टर/बैनर जहाँ लगे हैं', 'दुकान का आसपास का बाज़ार (पहचान के लिए)']
    ph = ''.join(f'<li><span class="box"></span>{x}</li>' for x in photos)
    prt = [('विज़िटिंग कार्ड', '3.5×2 इंच (89×51 mm) + 3 mm ब्लीड', 'visiting-card-print-with-3mm-bleed.pdf', '300–350 GSM मैट, मैट लैमिनेशन', 'आप तय करें (आम तौर पर 500 से 1000)'),
           ('काउंटर कार्ड ×6', 'A5 148×210 mm + 3 mm ब्लीड', 'counter-card-a5-bleed, -emi, -repair, -accessories, -google, care-poster-a5', '300 GSM, ग्लॉस या लैमिनेशन', 'हर एक की 2 कॉपी, स्टैंड/फ़्रेम में'),
           ('ऑटो-रिक्शा पोस्टर ×2', '3×2 फ़ीट (900×600 mm) आड़ा', 'rickshaw-poster-1.pdf, rickshaw-poster-2.pdf', 'फ़्लेक्स या स्टिकर, किनारे सिले/आइलेट', 'जितने ऑटो, उतने। पहले 2 ऑटो से शुरू'),
           ('A4 पोस्टर', 'A4', 'care-poster-a4.pdf, poster-a4.pdf', 'सादा या 130 GSM', '2–3 कॉपी: काउंटर, शटर, बाहर')]
    pt = ''.join(f"<tr><td><b>{a}</b></td><td>{b}</td><td class='f'>{c}</td><td>{d}</td><td>{e}</td></tr>" for a, b, c, d, e in prt)
    p3 = f"""<div class="pg">{hd('Facebook · Google · WhatsApp · प्रिंट शीट', 'एक बार सेट करें, फिर हर रील और कार्ड यहीं-वहीं चलता रहेगा')}
<h2 class="hi">Facebook पेज</h2><ul class="hi"><li>नाम: <span class="q">Brandhoop Mobile Point · नीम का थाना</span> &nbsp; श्रेणी: Mobile Phone Shop</li><li>About: "नीम का थाना, कमला मोदी मार्केट (गेट नं. 5) में नए फ़ोन, एक्सेसरी, रिपेयर, स्किन कटिंग और EMI की सुविधा। 📞 86197 67291 · 72399 38540"</li><li>प्रोफ़ाइल फ़ोटो: profile-picture.png · कवर: facebook-cover.png · बटन: "WhatsApp संदेश भेजें" और "अभी कॉल करें"</li><li>पहली पोस्ट: रील 1, फिर 7 रेट-कार्ड एक एल्बम में। पेज का लिंक रील के कमेंट में डालिए और WhatsApp स्टेटस से शेयर कीजिए।</li></ul>
<h2 class="hi">Google प्रोफ़ाइल (दुकान की लिस्टिंग)</h2><ul class="hi"><li>पता, दोनों फ़ोन नंबर और खुलने का समय जाँचिए। वेबसाइट: pallavsharmaofficial.github.io/brandhoop</li><li>श्रेणी: Mobile phone shop (अतिरिक्त: Mobile phone repair shop, Mobile phone accessory store) &nbsp; सेवाएँ और "Products" में vivo/OPPO फ़ोन "कीमत से शुरू" के साथ जोड़िए।</li><li>"अपडेट" पोस्ट: रेट-कार्ड की फ़ोटो + "फ़ोन देखने आइए"। हर हफ़्ते एक पोस्ट।</li><li>रिव्यू के लिए QR वाला काउंटर कार्ड दिखाइए और हर रिव्यू का जवाब दीजिए।</li></ul>
<div class="sm hi"><b>12 नई फ़ोटो की सूची:</b></div><ul class="hi sm" style="columns:2;margin-top:0">{ph}</ul>
<h2 class="hi">WhatsApp Business</h2><ul class="hi"><li>प्रोफ़ाइल: नाम, पता, खुलने का समय, वेबसाइट, "जवाब देने का संदेश" (छोटा स्वागत संदेश) चालू कीजिए। कैटलॉग में 4–5 सबसे ज़्यादा बिकने वाले फ़ोन डालिए।</li><li>रोज़ एक स्टेटस: एक फ़ोन या रेट कार्ड। ब्रॉडकास्ट सिर्फ़ उन्हीं को, जिन्होंने हामी भरी हो।</li></ul>
<h2 class="hi">प्रिंट शीट (प्रेस को यही दिखाइए)</h2><table class="hi"><tr><th>चीज़</th><th>साइज़</th><th>फ़ाइल</th><th>काग़ज़/माध्यम</th><th>मात्रा</th></tr>{pt}</table>
<div class="n hi sm">कोटेशन तीन जगह से लीजिए और रेट आप ख़ुद तय करके तुलना कीजिए। PDF में रंग RGB में हैं, प्रेस CMYK में बदलेगा तो नारंगी थोड़ा हल्का छपेगा। पहले एक कार्ड का प्रूफ़ ज़रूर देखिए। विज़िटिंग कार्ड में ब्लीड वाली फ़ाइल दीजिए, काटने के निशान प्रेस ख़ुद लगाएगा।</div><div class="pn">पन्ना 3/3</div></div>"""
    for i, body in enumerate((p1, p2, p3), 1):
        page(f'launch-plan-{i}', 210, 297, body, css=css, unit='mm', out_png=None, pdf=OUTB + f'print/plan/launch-plan-{i}.pdf')

# ------------------------------------------------------------------ app and web icons
def icons():
    tile = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">{mark_defs("ia")}<rect width="1024" height="1024" fill="{P["paper"]}"/><g transform="translate(512 512) scale(1.5) translate(-521 -412)">{mark_inner("color", "ia")}</g></svg>'
    page('icon-1024', 1024, 1024, tile.replace('<svg ', '<svg style="width:1024px;height:1024px;display:block" ', 1), out_png='assets/branding/icon-1024.png')
    fg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">{mark_defs("ib")}<g transform="translate(512 512) scale(1.12) translate(-521 -412)">{mark_inner("color", "ib")}</g></svg>'
    page('icon-foreground', 1024, 1024, fg.replace('<svg ', '<svg style="width:1024px;height:1024px;display:block" ', 1), css='body{background:transparent}', out_png='assets/branding/icon-foreground.png')
    mono = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024"><g transform="translate(512 512) scale(1.12) translate(-521 -412)">{mark_inner("solid", "ic", "#FFFFFF", "#000000")}</g></svg>'
    page('icon-mono-src', 1024, 1024, mono.replace('<svg ', '<svg style="width:1024px;height:1024px;display:block" ', 1), css='body{background:transparent}', out_png='tools/brand/build/icon-mono-src.png')
    mask = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">{mark_defs("id")}<rect width="1024" height="1024" fill="{P["paper"]}"/><g transform="translate(512 512) scale(1.2) translate(-521 -412)">{mark_inner("color", "id")}</g></svg>'
    page('icon-maskable', 1024, 1024, mask.replace('<svg ', '<svg style="width:1024px;height:1024px;display:block" ', 1), out_png='tools/brand/build/icon-maskable-1024.png')
    page('splash-light', 768, 768, f'<div class="c">{logo_light("560px")}</div>', css='body{background:transparent}.c{position:absolute;inset:0;display:flex;align-items:center;justify-content:center}', out_png='assets/branding/splash-light.png')
    page('splash-dark', 768, 768, f'<div class="c">{logo_dark("560px")}</div>', css='body{background:transparent}.c{position:absolute;inset:0;display:flex;align-items:center;justify-content:center}', out_png='assets/branding/splash-dark.png')
    page('mark-512', 512, 512, f'<div class="c">{mark("360px")}</div>', css='body{background:transparent}.c{position:absolute;inset:0;display:flex;align-items:center;justify-content:center}', out_png='assets/branding/logo-mark.png')
    page('logo-h-512', 1200, 380, f'<div class="c">{hlogo("1100px", "light")}</div>', css='body{background:transparent}.c{position:absolute;inset:0;display:flex;align-items:center;justify-content:center}', out_png='assets/branding/logo-horizontal.png')


# ------------------------------------------------------------------ logo PNGs (transparent) for people who cannot open SVG
def logo_pngs():
    items = [('brandhoop-logo', logo_light, 1600, 1730), ('brandhoop-logo-on-dark', logo_dark, 1600, 1730)]
    for n, fn, w, h in items:
        page('png-' + n, w, h, f'<div class="c">{fn(str(w - 40) + "px")}</div>', css='body{background:transparent}.c{position:absolute;inset:0;display:flex;align-items:center;justify-content:center}', out_png=OUTB + f'logo/{n}.png')
    page('png-brandhoop-logo-horizontal', 2000, 640, f'<div class="c">{hlogo("1900px", "light")}</div>', css='body{background:transparent}.c{position:absolute;inset:0;display:flex;align-items:center;justify-content:center}', out_png=OUTB + 'logo/brandhoop-logo-horizontal.png')
    page('png-brandhoop-logo-horizontal-on-dark', 2000, 640, f'<div class="c">{hlogo("1900px", "dark")}</div>', css='body{background:transparent}.c{position:absolute;inset:0;display:flex;align-items:center;justify-content:center}', out_png=OUTB + 'logo/brandhoop-logo-horizontal-on-dark.png')
    page('png-brandhoop-mark', 1200, 1200, f'<div class="c">{mark("900px")}</div>', css='body{background:transparent}.c{position:absolute;inset:0;display:flex;align-items:center;justify-content:center}', out_png=OUTB + 'logo/brandhoop-mark.png')

if __name__ == '__main__':
    cards(); poster(); social(); misc(); counter_tech(); care_poster(); rickshaw_posters(); counter_cards_more(); price_cards(); launch_plan(); icons(); logo_pngs()
    (BUILD / 'manifest.json').write_text(json.dumps(MANIFEST, ensure_ascii=False, indent=1))
    print(len(MANIFEST), 'pages')

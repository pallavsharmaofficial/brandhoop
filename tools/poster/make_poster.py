#!/usr/bin/env python3
"""Draws the Diwali WhatsApp-status poster and a plain QR code.

    pip install segno
    python3 tools/poster/make_poster.py            # writes site/qr/*.html and *.svg
    node tools/poster/shoot.js                     # turns the html into PNGs (needs playwright)

Only facts the shop has given are on the poster: the name and address, Diwali
offers and gifts on phones, Bajaj Finserv EMI, UPI/cards/cash. Add the phone
number with --phone once it is known.
"""
import argparse, pathlib, io
import segno

ap = argparse.ArgumentParser()
ap.add_argument('--url', default='https://pallavsharmaofficial.github.io/brandhoop/')
ap.add_argument('--phone', default='')
args = ap.parse_args()

out = pathlib.Path(__file__).resolve().parents[2] / 'site' / 'qr'
out.mkdir(parents=True, exist_ok=True)

qr = segno.make(args.url, error='h')
rows = [list(r) for r in qr.matrix]
n = len(rows)
cells = ''.join(f'M{x} {y}h1v1h-1z' for y, r in enumerate(rows) for x, v in enumerate(r) if v)
svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {n} {n}" shape-rendering="crispEdges">'
       f'<path d="{cells}" fill="#1A237E"/></svg>')
(out / 'brandhoop-qr.svg').write_text(svg)

phone = f'<div class="phone">📞 {args.phone}</div>' if args.phone else ''
html = f'''<!doctype html><html><head><meta charset="utf-8"><style>
*{{box-sizing:border-box;margin:0}}
body{{width:1080px;height:1920px;font-family:"Inter","FreeSans","Noto Sans Devanagari","DejaVu Sans",sans-serif;
  background:radial-gradient(900px 700px at 80% 8%,#FFB300 0%,rgba(255,179,0,0) 60%),
             radial-gradient(800px 800px at 0% 100%,#FF6F00 0%,rgba(255,111,0,0) 55%),
             linear-gradient(180deg,#1A237E 0%,#283593 55%,#311B92 100%);
  color:#fff;display:flex;flex-direction:column;align-items:center;padding:64px 60px 54px;position:relative;overflow:hidden}}
.spark{{position:absolute;border-radius:50%;background:#FFE082;opacity:.85}}
.greet{{font-size:58px;font-weight:700;color:#FFE082;letter-spacing:1px;text-align:center;line-height:1.25}}
.greet small{{display:block;font-size:42px;font-weight:600;color:#fff;opacity:.95}}
.diya{{margin:18px 0 4px;flex-shrink:0}}
.name{{font-size:76px;font-weight:900;text-align:center;line-height:1.1;margin-top:6px}}
.name2{{font-size:46px;font-weight:600;color:#FFE082;margin-top:10px;text-align:center}}
.offer{{margin-top:30px;background:#FF8F00;color:#1b1b1b;border-radius:34px;padding:24px 36px;text-align:center;
  font-size:50px;font-weight:800;line-height:1.25;box-shadow:0 14px 40px rgba(0,0,0,.35)}}
.offer small{{display:block;font-size:38px;font-weight:700;margin-top:6px}}
.card{{margin-top:30px;background:#fff;color:#1A237E;border-radius:44px;padding:34px 40px 22px;text-align:center;
  box-shadow:0 20px 60px rgba(0,0,0,.4)}}
.card svg{{width:430px;height:430px;display:block;margin:0 auto;flex-shrink:0}}
.scan{{font-size:42px;font-weight:800;margin-top:20px;line-height:1.25}}
.scan small{{display:block;font-size:36px;font-weight:600;color:#3949AB;margin-top:4px}}
.url{{font-size:27px;color:#5C6BC0;margin-top:14px;letter-spacing:.3px}}
.emi{{margin-top:28px;font-size:38px;font-weight:700;text-align:center;line-height:1.3}}
.emi small{{display:block;font-size:32px;font-weight:600;color:#FFE082}}
.foot{{margin-top:auto;padding-top:20px;text-align:center;font-size:30px;line-height:1.45;opacity:.95}}
.foot b{{font-size:34px}}
.phone{{font-size:46px;font-weight:800;color:#FFE082;margin-top:10px}}
</style></head><body>
<div class="spark" style="left:90px;top:210px;width:16px;height:16px"></div>
<div class="spark" style="left:960px;top:330px;width:22px;height:22px"></div>
<div class="spark" style="left:150px;top:560px;width:12px;height:12px"></div>
<div class="spark" style="left:930px;top:700px;width:14px;height:14px"></div>
<div class="greet">शुभ दीपावली<small>Happy Diwali</small></div>
<svg class="diya" width="190" height="150" viewBox="0 0 190 150">
  <path d="M95 6 C74 36 70 58 95 74 C120 58 116 36 95 6Z" fill="#FFCA28"/>
  <path d="M95 30 C86 46 86 58 95 66 C104 58 104 46 95 30Z" fill="#FF6F00"/>
  <path d="M14 84 H176 C170 124 140 142 95 142 C50 142 20 124 14 84Z" fill="#FF8F00"/>
  <path d="M14 84 H176 C174 92 170 98 166 102 H24 C20 98 16 92 14 84Z" fill="#FFB300"/>
</svg>
<div class="name">Brandhoop<br>Mobile Point</div>
<div class="name2">ब्रांडहूप मोबाइल पॉइंट</div>
<div class="offer">Diwali offers &amp; gifts on mobile phones
  <small>मोबाइल फ़ोन पर दिवाली ऑफ़र और उपहार</small></div>
<div class="card">{svg}
  <div class="scan">Scan to see phones &amp; offers<small>फ़ोन और ऑफ़र देखने के लिए स्कैन करें</small></div>
  <div class="url">{args.url.replace('https://','')}</div></div>
<div class="emi">UPI · Cards · Cash · Bajaj Finserv EMI at the shop
  <small>बजाज फिनसर्व EMI सिर्फ़ दुकान पर (फ़ेस स्कैन ज़रूरी)</small></div>
<div class="foot"><b>Abhay Colony, Neem Ka Thana, Rajasthan 332713</b><br>
Across the road from Study Point Library<br>स्टडी पॉइंट लाइब्रेरी के सामने{phone}</div>
</body></html>'''
(out / 'diwali-poster.html').write_text(html)

plain = f'''<!doctype html><html><head><meta charset="utf-8"><style>
*{{margin:0}}body{{width:1200px;height:1200px;background:#fff;display:flex;align-items:center;justify-content:center}}
svg{{width:1000px;height:1000px}}</style></head><body>{svg}</body></html>'''
(out / 'brandhoop-qr.html').write_text(plain)
print('wrote', out)

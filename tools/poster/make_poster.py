#!/usr/bin/env python3
"""Draws the Diwali WhatsApp-status poster and a plain QR code.

    pip install segno
    python3 tools/poster/make_poster.py --phone "+91 86197 67291"
    node tools/poster/shoot.js            # html -> png (needs playwright)

The phones on the poster show real screenshots of the live app
(site/qr/app-en.jpg and app-hi.jpg). To refresh them, open the app in a
390 x 844 browser window at 3x and save the home screen over those files.
Only facts the shop has given are written on the poster.
"""
import argparse, pathlib, random

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

# Warm out-of-focus lights and a string of festival bulbs, drawn once with a fixed seed.
rnd = random.Random(11)
bokeh = ''.join(
    f'<i class="b" style="left:{rnd.randint(-40,1040)}px;top:{rnd.randint(380,1250)}px;'
    f'width:{(s:=rnd.randint(26,120))}px;height:{s}px;opacity:{rnd.uniform(.10,.30):.2f};'
    f'background:{rnd.choice(["#FFB300","#FF8F00","#FFD54F","#FF6F00"])}"></i>' for _ in range(34))
bulbs = ''
cols = ['#FFD54F', '#FF8F00', '#FF5252', '#FFB300', '#FFEE58']
for i in range(13):
    x = 40 + i * 83
    y = 60 + 38 * (1 - ((i - 6) / 6) ** 2) * -1 + 38  # gentle sag
    c = cols[i % len(cols)]
    bulbs += (f'<circle cx="{x}" cy="{y+26}" r="34" fill="{c}" opacity=".22"/>'
              f'<circle cx="{x}" cy="{y+26}" r="15" fill="{c}"/>'
              f'<rect x="{x-5}" y="{y}" width="10" height="12" rx="2" fill="#6D4C41"/>')
wire = ' '.join(f'{40+i*83},{60+38*(1-((i-6)/6)**2)*-1+38}' for i in range(13))

phone = f'<div class="phone">📞 {args.phone}</div>' if args.phone else ''
html = f'''<!doctype html><html><head><meta charset="utf-8"><style>
*{{box-sizing:border-box;margin:0}}
body{{width:1080px;height:1920px;font-family:"Inter","FreeSans","Noto Sans Devanagari","DejaVu Sans",sans-serif;color:#fff;position:relative;overflow:hidden;
  background:radial-gradient(760px 760px at 50% 38%,rgba(255,179,0,.55) 0%,rgba(255,143,0,0) 62%),
             radial-gradient(900px 600px at 0% 100%,#BF360C 0%,rgba(191,54,12,0) 60%),
             linear-gradient(180deg,#1A1464 0%,#2A1B7A 45%,#4A148C 100%)}}
.b{{position:absolute;border-radius:50%;filter:blur(7px)}}
svg.lights{{position:absolute;left:0;top:0}}
.head{{position:absolute;top:150px;left:0;right:0;text-align:center}}
.greet{{font-size:92px;font-weight:800;color:#FFE082;line-height:1.1;text-shadow:0 4px 24px rgba(255,160,0,.55)}}
.greet2{{font-size:42px;font-weight:600;letter-spacing:6px;color:#fff;margin-top:6px;text-transform:uppercase}}
.name{{font-size:62px;font-weight:900;margin-top:14px;line-height:1.1}}
.name2{{font-size:38px;font-weight:600;color:#FFE082;margin-top:4px}}
.stage{{position:absolute;top:455px;left:0;right:0;height:760px}}
.dev{{position:absolute;width:372px;height:790px;border-radius:58px;background:#0c0c10;padding:14px;
  box-shadow:0 40px 80px rgba(0,0,0,.55),0 0 0 3px #2b2b33 inset,0 0 70px rgba(255,179,0,.35)}}
.dev .scr{{width:100%;height:100%;border-radius:46px;overflow:hidden;background:#f7f4f0;position:relative}}
.dev img{{width:100%;height:100%;object-fit:cover;object-position:top;display:block}}
.dev:before{{content:"";position:absolute;top:22px;left:50%;width:92px;height:24px;margin-left:-46px;border-radius:14px;background:#0c0c10;z-index:3}}
.d1{{left:120px;top:30px;transform:rotate(-6deg)}}
.d2{{left:590px;top:30px;transform:rotate(6deg)}}
.diya{{position:absolute;left:468px;top:560px;z-index:5;filter:drop-shadow(0 0 28px rgba(255,179,0,.9))}}
.offer{{position:absolute;top:1215px;left:50px;right:50px;background:linear-gradient(90deg,#FF6F00,#FFA000);color:#1b1b1b;border-radius:38px;padding:18px 24px;text-align:center;
  font-size:41px;font-weight:800;line-height:1.2;box-shadow:0 14px 40px rgba(0,0,0,.4)}}
.offer small{{display:block;font-size:34px;font-weight:700;margin-top:4px}}
.bottom{{position:absolute;left:50px;right:50px;top:1405px;height:420px;display:flex;gap:30px;align-items:stretch}}
.qr{{width:380px;background:#fff;color:#1A237E;border-radius:40px;padding:24px 24px 16px;text-align:center;box-shadow:0 20px 60px rgba(0,0,0,.45);flex:none}}
.qr svg{{width:316px;height:316px;display:block;margin:0 auto}}
.qr b{{display:block;font-size:34px;margin-top:10px;line-height:1.15}}
.qr span{{display:block;font-size:26px;color:#3949AB;font-weight:600}}
.info{{flex:1;display:flex;flex-direction:column;justify-content:center;gap:12px;font-size:32px;line-height:1.3}}
.ph{{font-size:50px;font-weight:900;color:#FFE082;line-height:1.1;margin-bottom:2px}}
.pill{{display:inline-block;background:rgba(255,255,255,.14);border-radius:18px;padding:10px 16px}}
.pill small{{display:block;font-size:26px;color:#FFE082;font-weight:600}}
.addr{{font-size:27px;opacity:.95}}
</style></head><body>
{bokeh}
<svg class="lights" width="1080" height="190" viewBox="0 0 1080 190"><polyline points="{wire}" fill="none" stroke="#5D4037" stroke-width="4"/>{bulbs}</svg>
<div class="head">
  <div class="greet">शुभ दीपावली</div><div class="greet2">Happy Diwali</div>
  <div class="name">Brandhoop Mobile Point</div><div class="name2">ब्रांडहूप मोबाइल पॉइंट</div>
</div>
<div class="stage">
  <div class="dev d1"><div class="scr"><img src="app-en.jpg"></div></div>
  <div class="dev d2"><div class="scr"><img src="app-hi.jpg"></div></div>
  <svg class="diya" width="144" height="116" viewBox="0 0 190 150">
    <path d="M95 6 C74 36 70 58 95 74 C120 58 116 36 95 6Z" fill="#FFCA28"/>
    <path d="M95 30 C86 46 86 58 95 66 C104 58 104 46 95 30Z" fill="#FF6F00"/>
    <path d="M14 84 H176 C170 124 140 142 95 142 C50 142 20 124 14 84Z" fill="#FF8F00"/>
    <path d="M14 84 H176 C174 92 170 98 166 102 H24 C20 98 16 92 14 84Z" fill="#FFB300"/></svg>
</div>
<div class="offer">Diwali offers &amp; gifts on mobile phones
  <small>मोबाइल फ़ोन पर दिवाली ऑफ़र और उपहार</small></div>
<div class="bottom">
  <div class="qr">{svg}<b>Scan to shop</b><span>स्कैन करके देखें</span></div>
  <div class="info">
    {phone.replace('class="phone"','class="ph"') if phone else ''}
    <div class="pill">UPI · Cards · Cash<small>UPI · कार्ड · नकद</small></div>
    <div class="pill">Bajaj Finserv EMI at the shop only<small>बजाज फिनसर्व EMI सिर्फ़ दुकान पर (फ़ेस स्कैन ज़रूरी)</small></div>
    <div class="addr">Abhay Colony, Neem Ka Thana 332713 · Across from Study Point Library<br>अभय कॉलोनी, नीम का थाना · स्टडी पॉइंट लाइब्रेरी के सामने</div>
  </div>
</div>
</body></html>'''
(out / 'diwali-poster.html').write_text(html)

plain = f'''<!doctype html><html><head><meta charset="utf-8"><style>
*{{margin:0}}body{{width:1200px;height:1200px;background:#fff;display:flex;align-items:center;justify-content:center}}
svg{{width:1000px;height:1000px}}</style></head><body>{svg}</body></html>'''
(out / 'brandhoop-qr.html').write_text(plain)
print('wrote', out)

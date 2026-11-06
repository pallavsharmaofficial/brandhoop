#!/usr/bin/env python3
"""Draws the Diwali posters: a WhatsApp status (1080 x 1920) and an A4 print
poster (2480 x 3508 at 300 dpi, plus a PDF), both with the QR code.

    pip install segno pillow
    python3 tools/poster/make_poster.py --phone "+91 86197 67291"
    node tools/poster/shoot.js           # html -> png (needs playwright)

Pictures used (all in site/): gallery/diya-night.jpg and gallery/diwali-diyas.jpg
are free-licence Pexels photos (docs/CREDITS.md), gallery/diwali-gifts.jpg is the
shop's own photo, qr/app-home-hi.jpg and qr/app-shop-hi.jpg are screenshots of
the live app. Only facts the shop has given are written on the posters.
"""
import argparse, pathlib, random

import segno

ap = argparse.ArgumentParser()
ap.add_argument('--url', default='https://pallavsharmaofficial.github.io/brandhoop/')
ap.add_argument('--phone', default='')
args = ap.parse_args()

out = pathlib.Path(__file__).resolve().parents[2] / 'site' / 'qr'
out.mkdir(parents=True, exist_ok=True)
SHOW_URL = args.url.replace('https://', '').rstrip('/')

qr = segno.make(args.url, error='h')
rows = [list(r) for r in qr.matrix]
n = len(rows)
cells = ''.join(f'M{x} {y}h1v1h-1z' for y, r in enumerate(rows) for x, v in enumerate(r) if v)
svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {n} {n}" shape-rendering="crispEdges">'
       f'<path d="{cells}" fill="#1A237E"/></svg>')
(out / 'brandhoop-qr.svg').write_text(svg)

def bulbs(width, count, y0=44, sag=34):
    cols = ['#FFD54F', '#FF8F00', '#FF5252', '#FFB300', '#FFEE58']
    step = width / (count - 1)
    pts, art = [], ''
    for i in range(count):
        x = i * step
        y = y0 + sag * (1 - ((i - (count - 1) / 2) / ((count - 1) / 2)) ** 2) * -1 + sag
        pts.append(f'{x:.0f},{y:.0f}')
        c = cols[i % len(cols)]
        art += (f'<circle cx="{x:.0f}" cy="{y+28:.0f}" r="36" fill="{c}" opacity=".25"/>'
                f'<circle cx="{x:.0f}" cy="{y+28:.0f}" r="15" fill="{c}"/>'
                f'<rect x="{x-5:.0f}" y="{y:.0f}" width="10" height="13" rx="2" fill="#6D4C41"/>')
    return (f'<svg width="{width}" height="{y0+110}" viewBox="0 0 {width} {y0+110}" style="position:absolute;left:0;top:0;z-index:4">'
            f'<polyline points="{" ".join(pts)}" fill="none" stroke="#5D4037" stroke-width="4"/>{art}</svg>')

FONT = '"Inter","FreeSans","Noto Sans Devanagari","DejaVu Sans",sans-serif'
phone_html = f'<div class="ph">📞 {args.phone}</div>' if args.phone else ''

# ---------------------------------------------------------------- status 9:16
status = f'''<!doctype html><html><head><meta charset="utf-8"><style>
*{{box-sizing:border-box;margin:0}}
body{{width:1080px;height:1920px;font-family:{FONT};color:#fff;position:relative;overflow:hidden;background:#140c3c url(../gallery/diya-night.jpg) center 78%/cover}}
.veil{{position:absolute;inset:0;background:linear-gradient(180deg,rgba(26,20,100,.92) 0%,rgba(30,18,90,.72) 34%,rgba(30,12,60,.80) 62%,rgba(20,8,50,.96) 100%)}}
.head{{position:absolute;top:150px;left:0;right:0;text-align:center;z-index:3}}
.greet{{font-size:96px;font-weight:800;color:#FFE082;line-height:1.1;text-shadow:0 4px 28px rgba(255,160,0,.6)}}
.greet2{{font-size:40px;font-weight:600;letter-spacing:7px;margin-top:4px;text-transform:uppercase}}
.name{{font-size:60px;font-weight:900;margin-top:12px;line-height:1.1}}
.name2{{font-size:36px;font-weight:600;color:#FFE082;margin-top:2px}}
.card{{position:absolute;background:#fff;color:#1b1b1b;padding:14px 14px 0;border-radius:10px;box-shadow:0 26px 60px rgba(0,0,0,.6);z-index:3}}
.card img{{display:block;width:100%;object-fit:cover}}
.card p{{font-size:27px;font-weight:700;text-align:center;padding:10px 0 12px;line-height:1.2}}
.c1{{left:34px;top:500px;width:520px;transform:rotate(-4deg)}}
.c1 img{{height:410px}}
.dev{{position:absolute;left:610px;top:430px;width:380px;height:800px;border-radius:60px;background:#0c0c10;padding:14px;z-index:3;transform:rotate(4deg);
  box-shadow:0 40px 80px rgba(0,0,0,.65),0 0 0 3px #2b2b33 inset,0 0 80px rgba(255,179,0,.35)}}
.dev .scr{{width:100%;height:100%;border-radius:48px;overflow:hidden;background:#f7f4f0}}
.dev img{{width:100%;height:100%;object-fit:cover;object-position:top;display:block}}
.dev:before{{content:"";position:absolute;top:24px;left:50%;width:96px;height:25px;margin-left:-48px;border-radius:14px;background:#0c0c10;z-index:3}}
.offer{{position:absolute;top:1235px;left:46px;right:46px;background:linear-gradient(90deg,#FF6F00,#FFA000);color:#1b1b1b;border-radius:38px;padding:18px 22px;text-align:center;font-size:42px;font-weight:800;line-height:1.2;box-shadow:0 14px 40px rgba(0,0,0,.45);z-index:3}}
.offer small{{display:block;font-size:33px;font-weight:700;margin-top:3px}}
.bottom{{position:absolute;left:46px;right:46px;top:1410px;height:420px;display:flex;gap:28px;z-index:3}}
.qr{{width:380px;background:#fff;color:#1A237E;border-radius:40px;padding:24px 24px 16px;text-align:center;box-shadow:0 20px 60px rgba(0,0,0,.5);flex:none}}
.qr svg{{width:316px;height:316px;display:block;margin:0 auto}}
.qr b{{display:block;font-size:34px;margin-top:10px;line-height:1.15}}
.qr span{{display:block;font-size:26px;color:#3949AB;font-weight:600}}
.info{{flex:1;display:flex;flex-direction:column;justify-content:center;gap:10px;font-size:31px;line-height:1.28}}
.ph{{font-size:50px;font-weight:900;color:#FFE082;line-height:1.1}}
.pill{{display:inline-block;background:rgba(255,255,255,.16);border-radius:18px;padding:9px 16px}}
.pill small{{display:block;font-size:25px;color:#FFE082;font-weight:600}}
.url{{font-size:27px;font-weight:700;color:#FFE082;word-break:break-all}}
.addr{{font-size:26px;opacity:.95}}
</style></head><body><div class="veil"></div>
{bulbs(1080,13)}
<div class="head"><div class="greet">शुभ दीपावली</div><div class="greet2">Happy Diwali</div>
  <div class="name">Brandhoop Mobile Point</div><div class="name2">ब्रांडहूप मोबाइल पॉइंट</div></div>
<div class="card c1"><img src="../gallery/diwali-gifts.jpg"><p>फ़ोन के साथ दिवाली गिफ़्ट सेट<br>Diwali gift sets with phones</p></div>
<div class="dev"><div class="scr"><img src="app-home-hi.jpg"></div></div>
<div class="offer">Diwali offers &amp; gifts on mobile phones
  <small>मोलभाव के लिए कॉल करें · Call to bargain</small></div>
<div class="bottom">
  <div class="qr">{svg}<b>Scan to shop</b><span>स्कैन करके देखें</span></div>
  <div class="info">{phone_html}
    <div class="url">{SHOW_URL}</div>
    <div class="pill">UPI · Cards · Cash · Bajaj Finserv EMI at the shop<small>बजाज फिनसर्व EMI सिर्फ़ दुकान पर (फ़ेस स्कैन ज़रूरी)</small></div>
    <div class="addr">Abhay Colony, Neem Ka Thana · opp. Study Point Library<br>अभय कॉलोनी, नीम का थाना · स्टडी पॉइंट लाइब्रेरी के सामने</div>
  </div></div>
</body></html>'''
(out / 'diwali-poster.html').write_text(status)

# --------------------------------------------------------------- A4 print
print_html = f'''<!doctype html><html><head><meta charset="utf-8"><style>
*{{box-sizing:border-box;margin:0}}
body{{width:1240px;height:1754px;font-family:{FONT};color:#1b1b1b;position:relative;overflow:hidden;background:#fff}}
.top{{position:absolute;left:0;top:0;width:1240px;height:600px;background:#1a1464 url(../gallery/diwali-diyas.jpg) center/cover}}
.top:after{{content:"";position:absolute;inset:0;background:linear-gradient(180deg,rgba(26,20,100,.55) 0%,rgba(26,20,100,.25) 40%,rgba(26,20,100,.94) 100%)}}
.hd{{position:absolute;left:0;right:0;top:130px;text-align:center;color:#fff;z-index:3}}
.g1{{font-size:150px;font-weight:900;color:#FFE082;line-height:1.05;text-shadow:0 6px 30px rgba(0,0,0,.55)}}
.g2{{font-size:46px;font-weight:700;letter-spacing:10px;text-transform:uppercase;text-shadow:0 3px 14px rgba(0,0,0,.6)}}
.nm{{position:absolute;left:0;right:0;top:432px;text-align:center;color:#fff;z-index:3}}
.nm b{{font-size:84px;font-weight:900;line-height:1.05;display:block;text-shadow:0 4px 18px rgba(0,0,0,.6)}}
.nm span{{font-size:46px;font-weight:700;color:#FFE082}}
.offer{{position:absolute;top:600px;left:0;right:0;height:170px;background:linear-gradient(90deg,#FF6F00,#FFA000);display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center}}
.offer b{{font-size:70px;font-weight:900;line-height:1.1}}
.offer span{{font-size:42px;font-weight:700}}
.mid{{position:absolute;top:800px;left:50px;right:50px;height:490px;display:flex;gap:36px;align-items:center}}
.card{{background:#fff;padding:14px 14px 0;border-radius:10px;box-shadow:0 18px 44px rgba(0,0,0,.35);width:540px;flex:none;transform:rotate(-2deg)}}
.card img{{display:block;width:100%;height:370px;object-fit:cover}}
.card p{{font-size:30px;font-weight:700;text-align:center;padding:10px 0 12px;line-height:1.2}}
.pts{{flex:1;display:flex;flex-direction:column;gap:20px}}
.pt{{font-size:37px;font-weight:800;line-height:1.15;color:#1A237E;padding-left:66px;position:relative}}
.pt:before{{content:"✓";position:absolute;left:0;top:-2px;width:50px;height:50px;border-radius:50%;background:#FF8F00;color:#fff;font-size:32px;text-align:center;line-height:50px}}
.pt small{{display:block;font-size:30px;font-weight:600;color:#555;margin-top:2px}}
.bot{{position:absolute;left:0;right:0;top:1330px;height:424px;background:linear-gradient(180deg,#1A237E,#311B92);color:#fff}}
.qr{{position:absolute;left:50px;top:-56px;width:420px;background:#fff;border-radius:30px;padding:22px 22px 16px;text-align:center;box-shadow:0 18px 50px rgba(0,0,0,.45)}}
.qr svg{{width:356px;height:356px;display:block;margin:0 auto}}
.qr b{{display:block;font-size:32px;color:#1A237E;margin-top:8px}}
.info{{position:absolute;left:510px;right:40px;top:26px;display:flex;flex-direction:column;gap:8px}}
.scan{{font-size:46px;font-weight:900;line-height:1.1;color:#FFE082}}
.scan small{{display:block;font-size:30px;color:#fff;font-weight:700}}
.ph{{font-size:64px;font-weight:900;line-height:1.05}}
.url{{font-size:30px;font-weight:700;color:#FFE082;word-break:break-all}}
.addr{{font-size:26px;line-height:1.3}}
.pill{{background:rgba(255,255,255,.16);border-radius:16px;padding:8px 16px;font-size:28px;font-weight:700;line-height:1.2}}
</style></head><body>
<div class="top"></div>
{bulbs(1240,15)}
<div class="hd"><div class="g1">शुभ दीपावली</div><div class="g2">Happy Diwali</div></div>
<div class="nm"><b>Brandhoop Mobile Point</b><span>ब्रांडहूप मोबाइल पॉइंट · नीम का थाना</span></div>
<div class="offer"><b>मोबाइल फ़ोन पर दिवाली ऑफ़र और गिफ़्ट</b><span>Diwali offers &amp; gifts on mobile phones</span></div>
<div class="mid">
  <div class="card"><img src="../gallery/diwali-gifts.jpg"><p>फ़ोन के साथ दिवाली गिफ़्ट सेट · Diwali gift sets with phones</p></div>
  <div class="pts">
    <div class="pt">मोलभाव के लिए कॉल करें<small>Call to bargain: today’s best price</small></div>
    <div class="pt">फ़ोन के साथ गिफ़्ट और ऑफ़र<small>Gifts and offers with phones</small></div>
    <div class="pt">बजाज फिनसर्व EMI सिर्फ़ दुकान पर<small>Bajaj Finserv EMI at the shop (face scan needed)</small></div>
    <div class="pt">UPI · कार्ड · नकद<small>UPI · Cards · Cash</small></div>
  </div>
</div>
<div class="bot">
  <div class="qr">{svg}<b>स्कैन करें · Scan</b></div>
  <div class="info">
    <div class="scan">स्कैन करके सभी फ़ोन और ऑफ़र देखें<small>Scan to see all phones and offers</small></div>
    {phone_html}
    <div class="url">{SHOW_URL}</div>
    <div class="addr"><b>अभय कॉलोनी, नीम का थाना, राजस्थान 332713</b> · स्टडी पॉइंट लाइब्रेरी के सामने<br>Abhay Colony, Neem Ka Thana · across the road from Study Point Library</div>
  </div>
</div>
</body></html>'''
(out / 'diwali-poster-a4.html').write_text(print_html)

plain = f'''<!doctype html><html><head><meta charset="utf-8"><style>
*{{margin:0}}body{{width:1200px;height:1200px;background:#fff;display:flex;align-items:center;justify-content:center}}
svg{{width:1000px;height:1000px}}</style></head><body>{svg}</body></html>'''
(out / 'brandhoop-qr.html').write_text(plain)

(out / 'whatsapp-status-message.txt').write_text(f'''🪔 शुभ दीपावली! ब्रांडहूप मोबाइल पॉइंट, नीम का थाना 🪔

📱 मोबाइल फ़ोन पर दिवाली ऑफ़र और गिफ़्ट 🎁
💰 कीमतें बदलती रहती हैं, इसलिए मोलभाव के लिए कॉल करें और आज की सबसे अच्छी कीमत पाएँ
✅ बजाज फिनसर्व EMI (सिर्फ़ दुकान पर, फ़ेस स्कैन) · UPI · कार्ड · कैश

👇 सारे फ़ोन और ऑफ़र यहाँ देखें:
{args.url}

📞 {args.phone or ''}
📍 अभय कॉलोनी, स्टडी पॉइंट लाइब्रेरी के सामने, नीम का थाना

—

🪔 Happy Diwali from Brandhoop Mobile Point, Neem Ka Thana! 🪔
📱 Diwali offers and gifts on mobile phones 🎁
💰 Phone prices change often. Call to bargain and get today’s best price.
✅ Bajaj Finserv EMI (at the shop only, face scan) · UPI · Cards · Cash
👇 See all phones and offers: {args.url}
📞 {args.phone or ''}
''')
print('wrote', out)

#!/usr/bin/env python3
"""Builds a 20-second vertical (1080x1920) shop ad from real photos.

    python3 tools/ad/make_ad.py <work dir> <photo-phone-wall.jpg> <photo-accessories.jpg> <app-a.png> <app-b.png> <out.mp4>

No prices appear in the video (the app shows launch prices, not the shop's price),
no festival text, no people. Needs ffmpeg and Playwright (node).
"""
import pathlib, subprocess, sys, json
from PIL import Image

work = pathlib.Path(sys.argv[1]); work.mkdir(parents=True, exist_ok=True)
wall, acc, app_a, app_b, out = sys.argv[2:7]
ROOT = pathlib.Path(__file__).resolve().parents[2]
FONT = '"Inter","FreeSans","Noto Sans Devanagari","DejaVu Sans",sans-serif'
ICON = (ROOT / 'assets/branding/icon-512.png').as_uri()
QR = (ROOT / 'site/qr/brandhoop-qr.png').as_uri()

CSS = f'''*{{box-sizing:border-box;margin:0}} body{{width:1080px;height:1920px;font-family:{FONT};color:#fff;position:relative;overflow:hidden}}
.bg{{position:absolute;inset:0;background:linear-gradient(160deg,#1A237E,#283593 55%,#3949ab)}}
.top{{position:absolute;top:70px;left:0;right:0;text-align:center;font-size:40px;font-weight:700;letter-spacing:.02em}}
.top span{{background:rgba(20,12,70,.72);padding:14px 34px;border-radius:50px}}
.cap{{position:absolute;left:0;right:0;bottom:0;padding:70px 60px 110px;background:linear-gradient(180deg,rgba(20,12,70,0),rgba(20,12,70,.92) 40%)}}
.cap h2{{font-size:68px;line-height:1.2;font-weight:800}} .cap p{{font-size:42px;margin-top:16px;opacity:.95}}
.acc{{color:#FFB74D}}'''

pages = {}
pages['intro'] = f'''<div class="bg"></div><div style="position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;padding:60px">
<img src="{ICON}" style="width:300px;height:300px;border-radius:70px;margin-bottom:60px"><div style="font-size:92px;font-weight:800;line-height:1.1">Brandhoop<br>Mobile Point</div>
<div style="font-size:54px;margin-top:34px;color:#FFB74D;font-weight:700">नीम का थाना</div>
<div style="font-size:46px;margin-top:70px;opacity:.95;line-height:1.5">नए फ़ोन और एक्सेसरी<br>एक ही दुकान पर</div></div>'''
pages['cap1'] = '<div class="top"><span>Brandhoop Mobile Point · नीम का थाना</span></div><div class="cap"><h2>नए फ़ोन देखें</h2><p>vivo, OPPO, realme, Nothing और भी</p></div>'
pages['cap2'] = '<div class="top"><span>Brandhoop Mobile Point · नीम का थाना</span></div><div class="cap"><h2>एक्सेसरी भी यहीं</h2><p>चार्जर · ईयरफ़ोन · पावर बैंक · कवर · स्मार्टवॉच</p></div>'


def phone(img):
    return f'''<div class="bg"></div><div class="top" style="top:80px"><span>शॉप का ऐप</span></div>
<div style="position:absolute;left:230px;top:200px;width:620px;height:1340px;background:#0c0c10;border-radius:84px;padding:22px;box-shadow:0 40px 90px rgba(0,0,0,.5)">
<div style="width:576px;height:1296px;border-radius:64px;overflow:hidden;background:#f7f5f2"><img src="{img}" style="width:576px;height:1246px;object-fit:cover;object-position:top"></div></div>
<div class="cap" style="padding-top:40px"><h2>ऐप में 69 फ़ोन<br>और 53 तरह की एक्सेसरी</h2><p>पसंद चुनें, फिर कॉल या WhatsApp करें</p></div>'''


def stitch(src, name, price_from, price_to):
    im = Image.open(src).convert('RGB'); W, H = im.size
    bar_y = 1545
    out_im = Image.new('RGB', (W, H), im.getpixel((5, 1200)))
    out_im.paste(im.crop((0, 0, W, 725)), (0, 0))
    mid = im.crop((0, price_to, W, bar_y)); out_im.paste(mid, (0, 725))
    out_im.paste(im.crop((0, bar_y, W, H)), (0, bar_y))
    p = work / name; out_im.save(p); return p.as_uri()

# price rows are launch prices, so cut them out of the screenshots
a_uri = stitch(app_a, 'appA.png', 725, 848)
b_uri = stitch(app_b, 'appB.png', 725, 880)
pages['appA'] = phone(a_uri)
pages['appB'] = phone(b_uri)
pages['cta'] = f'''<div class="bg"></div><div style="position:absolute;inset:0;padding:90px 70px;text-align:center">
<div style="font-size:60px;font-weight:800;line-height:1.25">फ़ोन की कीमतें<br>बदलती रहती हैं</div>
<div style="font-size:50px;margin-top:34px;color:#FFB74D;font-weight:700;line-height:1.3">आज की सबसे अच्छी कीमत<br>और ऑफ़र के लिए कॉल करें</div>
<div style="margin:46px auto 0;background:#FF8F00;color:#000;border-radius:30px;padding:26px 20px;font-size:76px;font-weight:800;width:900px">86197 67291</div>
<div style="font-size:38px;margin-top:20px;opacity:.95">WhatsApp पर भी बात करें</div>
<img src="{QR}" style="width:430px;height:430px;background:#fff;border-radius:26px;padding:18px;margin-top:40px">
<div style="font-size:36px;margin-top:14px;opacity:.95">ऐप खोलने के लिए स्कैन करें</div>
<div style="font-size:36px;margin-top:34px;line-height:1.45;opacity:.95">Bajaj Finance EMI सिर्फ़ दुकान पर (फेस स्कैन ज़रूरी)<br>गेट नं. 5, कमला मोदी मार्केट, नीम का थाना</div></div>'''

for k, v in pages.items():
    (work / f'{k}.html').write_text(f'<!doctype html><meta charset="utf-8"><style>{CSS}</style><body>{v}</body>', encoding='utf-8')
(work / 'shoot.js').write_text('''const { chromium } = require('playwright'); const path=require('path'); const fs=require('fs');
(async()=>{const b=await chromium.launch({args:['--no-sandbox']}); const ctx=await b.newContext({viewport:{width:1080,height:1920}});
for(const f of fs.readdirSync(__dirname).filter(n=>n.endsWith('.html'))){const p=await ctx.newPage(); await p.goto('file://'+path.join(__dirname,f)); await p.waitForTimeout(400);
 const transparent=f.startsWith('cap'); if(transparent) await p.evaluate(()=>{document.documentElement.style.background='transparent';document.body.style.background='transparent'});
 await p.screenshot({path:path.join(__dirname,f.replace('.html','.png')),omitBackground:transparent}); await p.close();}
await b.close();})();''')
subprocess.run(['node', str(work / 'shoot.js')], check=True, cwd=work, env={**__import__('os').environ, 'NODE_PATH': subprocess.run(['npm', 'root', '-g'], capture_output=True, text=True).stdout.strip()})

FPS = 30


def photo_clip(src, cap, name, dur, box, x0, x1):
    """box = (y0, y1) fractions of the photo height kept; pan across x from x0 to x1 (fractions of width)."""
    im = Image.open(src); W, H = im.size
    ch = int((box[1] - box[0]) * H); cw = int(ch * 1080 / 1350); y = int(box[0] * H)
    xs, xe = int(x0 * (W - cw)), int(x1 * (W - cw))
    n = int(dur * FPS)
    fc = (f"[0:v]split[a][b];[a]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=40:5,eq=brightness=-0.25[bg];"
          f"[b]crop={cw}:{ch}:x='{xs}+({xe}-{xs})*n/{n}':y={y},scale=1080:1350[fg];[bg][fg]overlay=0:285[v1];[v1][1:v]overlay=0:0,format=yuv420p[v]")
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-loop', '1', '-framerate', str(FPS), '-t', str(dur), '-i', src, '-loop', '1', '-framerate', str(FPS), '-t', str(dur), '-i', str(work / f'{cap}.png'),
                    '-filter_complex', fc, '-map', '[v]', '-r', str(FPS), '-c:v', 'libx264', '-crf', '19', str(work / f'{name}.mp4')], check=True)


def still_clip(png, name, dur, zoom=0.04):
    n = int(dur * FPS)
    vf = f"scale=2160:3840,zoompan=z='1+{zoom}*on/{n}':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d={n}:s=1080x1920:fps={FPS},format=yuv420p"
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-loop', '1', '-i', str(work / f'{png}.png'), '-vf', vf, '-t', str(dur), '-c:v', 'libx264', '-crf', '19', str(work / f'{name}.mp4')], check=True)

still_clip('intro', 'c1', 3.5)
photo_clip(wall, 'cap1', 'c2', 5.0, (0.10, 0.52), 0.15, 0.85)
photo_clip(acc, 'cap2', 'c3', 5.0, (0.08, 0.50), 0.0, 0.75)
still_clip('appA', 'c4', 3.0, 0.02)
still_clip('appB', 'c5', 3.0, 0.02)
still_clip('cta', 'c6', 5.0, 0.0)

durs = [3.5, 5.0, 5.0, 3.0, 3.0, 5.0]; X = 0.5
inputs = []; [inputs.extend(['-i', str(work / f'c{i+1}.mp4')]) for i in range(6)]
chain = ''; last = '[0:v]'; t = durs[0]
for i in range(1, 6):
    off = t - X
    chain += f'{last}[{i}:v]xfade=transition=fade:duration={X}:offset={off:.2f}[x{i}];'; last = f'[x{i}]'; t = off + durs[i]
subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', *inputs, '-f', 'lavfi', '-t', f'{t:.2f}', '-i', 'anullsrc=r=44100:cl=stereo', '-filter_complex', chain.rstrip(';'),
                '-map', last, '-map', '6:a', '-c:v', 'libx264', '-crf', '20', '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-b:a', '64k', '-movflags', '+faststart', '-shortest', out], check=True)
print('wrote', out, f'{t:.1f}s')

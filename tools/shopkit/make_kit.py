#!/usr/bin/env python3
"""Builds the printable shop kit (HTML), from the same catalogue the app uses.

    python3 tools/shopkit/make_kit.py        # writes tools/shopkit/build/*.html
    node tools/shopkit/shoot.js              # turns them into site/shop-kit/*.pdf and .png

Price strips carry NO shop price: the owner writes today's price by hand. They
show the launch price only as a small reference. Each strip has a WhatsApp QR
that opens a chat with the shop already saying which model the customer asked about.
"""
import html, pathlib, re, sys, urllib.parse
import segno

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(ROOT / 'tools' / 'catalog'))
import phones, accessories  # noqa: E402

OUT = HERE / 'build'
OUT.mkdir(exist_ok=True)
PHONE = '918619767291'
APP = 'https://pallavsharmaofficial.github.io/brandhoop/app/'
SITE = 'https://pallavsharmaofficial.github.io/brandhoop/'
FONT = '"Inter","FreeSans","Noto Sans Devanagari","DejaVu Sans",sans-serif'
esc = html.escape


def qr_svg(text, px):
    q = segno.make(text, error='l', micro=False)
    n = q.symbol_size(border=2)[0]
    d = []
    for y, row in enumerate(q.matrix_iter(border=2)):
        for x, v in enumerate(row):
            if v:
                d.append(f'M{x},{y}h1v1h-1z')
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {n} {n}" width="{px}" height="{px}" shape-rendering="crispEdges">'
            f'<rect width="{n}" height="{n}" fill="#fff"/><path d="{"".join(d)}" fill="#111"/></svg>')


def wa(text):
    return f'https://wa.me/{PHONE}?text=' + urllib.parse.quote(text)


def inr(n):
    s = str(int(n))
    if len(s) > 3:
        head, tail = s[:-3], s[-3:]
        parts = []
        while len(head) > 2:
            parts.insert(0, head[-2:]); head = head[:-2]
        if head: parts.insert(0, head)
        s = ','.join(parts + [tail])
    return '₹' + s


def compact(label):
    m = re.match(r'(\d+) GB \+ (\d+) GB', label)
    return f'{m.group(1)}+{m.group(2)}' if m else label


STRIP_CSS = f'''
@page {{ size: A4; margin: 7mm 6mm; }}
* {{ box-sizing: border-box; }}
body {{ margin: 0; font-family: {FONT}; color: #151515; }}
h1.pg {{ font-size: 10pt; margin: 0 0 2mm; color: #555; font-weight: 600; }}
.grid {{ display: grid; grid-template-columns: 1fr 1fr; gap: 0; }}
.strip {{ height: 34.5mm; border: .25mm dashed #999; padding: 2mm 2.5mm; display: grid;
  grid-template-columns: 1fr 34mm 21mm; gap: 2mm; align-items: center; break-inside: avoid; overflow: hidden; }}
.brand {{ font-size: 6.5pt; letter-spacing: .08em; text-transform: uppercase; color: #D8662A; font-weight: 700; }}
.name {{ font-size: 12.5pt; font-weight: 800; line-height: 1.12; margin: .4mm 0 1mm; }}
.name.long {{ font-size: 11pt; }}
.spec {{ font-size: 7pt; color: #333; line-height: 1.25; }}
.ref {{ font-size: 6.3pt; color: #777; margin-top: 1mm; line-height: 1.25; }}
.ref b {{ color: #b3261e; }}
.price {{ border-left: .25mm solid #ccc; padding-left: 2mm; height: 100%; display: flex; flex-direction: column; justify-content: center; }}
.price small {{ font-size: 6.5pt; color: #555; }}
.price .box {{ font-size: 14pt; font-weight: 800; margin-top: 2mm; border-bottom: .35mm solid #151515; height: 9mm; display: flex; align-items: flex-end; }}
.price .two {{ font-size: 8.5pt; font-weight: 700; margin-top: 1.4mm; border-bottom: .3mm solid #151515; height: 6mm; display: flex; align-items: flex-end; }}
.qr {{ text-align: center; font-size: 5.6pt; color: #444; line-height: 1.15; }}
.qr svg {{ width: 19mm; height: 19mm; display: block; margin: 0 auto 0.6mm; }}
'''


def phone_strips():
    order = {b: i for i, b in enumerate(['vivo', 'OPPO', 'Nothing', 'realme', 'Redmi', 'POCO', 'iQOO', 'Samsung', 'Motorola', 'OnePlus', 'Infinix', 'Tecno', 'Google', 'Apple', 'Nokia'])}
    rows = sorted(phones.PHONES, key=lambda r: (order.get(r[2], 99), min([v[1] for v in r[4] if v[1]] or [10 ** 9])))
    cells = []
    for pid, name, brand, launch, variants, hl, _q, _m in rows:
        known = [v[1] for v in variants if v[1]]
        keypad = pid in phones.KEYPAD
        spec = ' · '.join(h[1] for h in hl[:2])
        vs = ' · '.join(compact(v[0]) for v in variants if v[0] not in ('Standard', 'Base model', 'Single SIM')) if not keypad else ''
        line1 = esc(spec) if spec else ''
        line2 = (f'<div class="spec">{esc(vs)} GB</div>' if vs and re.search(r'\d\+\d', vs) else '')
        if known:
            ref = f'लॉन्च कीमत {inr(min(known))} से' + (f' ({launch})' if launch else '')
            if pid in phones.RAISED:
                ref += ' · <b>कीमत बढ़ चुकी है, आज की लिखें</b>'
        else:
            ref = 'कीमत दुकान से पूछें'
        q = qr_svg(wa(f'Hi Brandhoop, I want today\'s best price and offers for {name}'), 80)
        long = ' long' if len(name) > 17 else ''
        cells.append(f'''<div class="strip"><div><div class="brand">{esc(brand)}</div><div class="name{long}">{esc(name)}</div>
<div class="spec">{line1}</div>{line2}<div class="ref">{ref}</div></div>
<div class="price"><small>आज की कीमत · Today’s price</small><div class="box">₹</div></div>
<div class="qr">{q}WhatsApp पर<br>यही मॉडल पूछें</div></div>''')
    return cells


def acc_strips():
    cells = []
    cat_hi = {'earphones': 'ईयरफ़ोन', 'charger': 'चार्जर', 'cable': 'केबल', 'powerBank': 'पावर बैंक', 'caseCover': 'कवर / केस', 'screenGuard': 'स्क्रीन गार्ड',
              'smartwatch': 'स्मार्टवॉच', 'speaker': 'स्पीकर', 'memory': 'मेमोरी', 'holder': 'स्टैंड / होल्डर'}
    for pid, en, hi, cat, _key, fit in accessories.ACC:
        q = qr_svg(wa(f'Hi Brandhoop, I want today\'s price for {en}'), 80)
        note = 'आपके फ़ोन मॉडल के हिसाब से · मॉडल बताएँ' if fit else ''
        cells.append(f'''<div class="strip"><div><div class="brand">{esc(cat_hi.get(cat, cat))}</div><div class="name long">{esc(hi)}</div>
<div class="spec">{esc(en)}</div><div class="ref">{note}</div></div>
<div class="price"><small>कीमत · Price</small><div class="two">Basic ₹</div><div class="two">Better ₹</div></div>
<div class="qr">{q}WhatsApp पर<br>पूछें</div></div>''')
    return cells


def page(title, css, body):
    return f'<!doctype html><html lang="hi"><meta charset="utf-8"><title>{esc(title)}</title><style>{css}</style><body>{body}</body></html>'


def write(name, content):
    (OUT / name).write_text(content, encoding='utf-8')
    print('wrote', name)


# ------------------------------------------------------------------ strips
write('price-strips-phones.html', page('Phone price strips', STRIP_CSS,
      '<h1 class="pg">Brandhoop Mobile Point · फ़ोन प्राइस स्ट्रिप · काटकर शेल्फ़ के किनारे चिपकाएँ, कीमत पेन से लिखें</h1><div class="grid">' + ''.join(phone_strips()) + '</div>'))
write('price-strips-accessories.html', page('Accessory price strips', STRIP_CSS,
      '<h1 class="pg">Brandhoop Mobile Point · एक्सेसरी प्राइस स्ट्रिप · काटकर चिपकाएँ, कीमत पेन से लिखें</h1><div class="grid">' + ''.join(acc_strips()) + '</div>'))

# ------------------------------------------------------------------ counter signs (A4 portrait, one per page)
SIGN_CSS = f'''
@page {{ size: A4; margin: 0; }}
* {{ box-sizing: border-box; }}
body {{ margin: 0; font-family: {FONT}; color: #151515; }}
.p {{ width: 210mm; height: 297mm; padding: 14mm 15mm; page-break-after: always; position: relative; overflow: hidden; background: #fff; }}
.top {{ background: linear-gradient(135deg,#1F2744,#D8662A); color: #fff; border-radius: 6mm; padding: 8mm 9mm; }}
.top .s {{ font-size: 11pt; opacity: .9; letter-spacing: .05em; }}
.top h1 {{ margin: 2mm 0 0; font-size: 34pt; line-height: 1.1; }}
.top p {{ margin: 3mm 0 0; font-size: 14pt; opacity: .95; }}
.draft {{ position: absolute; top: 6mm; right: 8mm; font-size: 9pt; color: #b3261e; border: .4mm solid #b3261e; padding: 1mm 3mm; border-radius: 2mm; background: #fff; }}
.row {{ display: flex; align-items: center; gap: 4mm; border: .5mm solid #D8662A; border-radius: 4mm; padding: 5mm 6mm; margin-top: 6mm; font-size: 17pt; font-weight: 700; }}
.row .ln {{ flex: 1; border-bottom: .5mm solid #151515; height: 9mm; }}
.row.t {{ font-size: 15pt; }}
.chk {{ display: inline-block; width: 7mm; height: 7mm; border: .5mm solid #151515; border-radius: 1.2mm; margin-right: 3mm; vertical-align: -1mm; flex: none; }}
.sm {{ font-size: 12pt; font-weight: 500; color: #444; }}
.foot {{ position: absolute; left: 15mm; right: 15mm; bottom: 12mm; display: flex; align-items: center; gap: 6mm; border-top: .4mm solid #ccc; padding-top: 5mm; font-size: 12pt; }}
.foot svg {{ width: 28mm; height: 28mm; flex: none; }}
.foot b {{ font-size: 15pt; }}
.note {{ margin-top: 6mm; font-size: 11.5pt; color: #333; line-height: 1.5; }}
table {{ width: 100%; border-collapse: collapse; margin-top: 6mm; font-size: 14pt; }}
td, th {{ border: .5mm solid #D8662A; padding: 4mm; text-align: left; }}
th {{ background: #FBE3D2; }}
td.w {{ height: 15mm; }}
'''
QR_APP = qr_svg(APP, 200)
QR_WA = qr_svg(wa('Hi Brandhoop, I want today\'s best price and offers'), 200)
FOOT = f'<div class="foot">{QR_WA}<div><b>WhatsApp / कॉल: +91 86197 67291</b><br>Brandhoop Mobile Point · गेट नं. 5, कमला मोदी मार्केट, नीम का थाना<br>ऐप और सारे फ़ोन: pallavsharmaofficial.github.io/brandhoop</div></div>'


def sign(kicker, title, sub, body, draft=''):
    d = f'<div class="draft">{draft}</div>' if draft else ''
    return f'<div class="p">{d}<div class="top"><img src="../../../site/brand/logo/brandhoop-logo-horizontal-on-dark.svg" style="height:60px;float:right;margin:0 0 6px 12px" alt=""><div class="s">{kicker}</div><h1>{title}</h1><p>{sub}</p></div>{body}{FOOT}</div>'


combo_rows = ''.join(f'<div class="row"><span class="chk"></span>₹ <span class="ln"></span> तक का फ़ोन + <span class="sm">ग्लास + कवर + चार्जर</span> = ₹ <span class="ln"></span></div>' for _ in range(3))
pages = [
    sign('Brandhoop Mobile Point', 'कॉम्बो ऑफ़र', 'फ़ोन के साथ ज़रूरी सामान एक ही कीमत पर',
         combo_rows + '<div class="note">मालिक लिखें: कौन-सी कीमत पर कौन-सा कॉम्बो। फ़ोन के साथ ग्लास लगवाना मुफ़्त रखना हो तो नीचे लिख दें।<br><span class="chk"></span>ग्लास फ़िटिंग फ़ोन के साथ मुफ़्त</div>', 'कीमतें खाली हैं · मालिक भरें'),
    sign('कीमत बढ़ने से पहले', 'आज की कीमत पक्की', 'थोड़ा टोकन दें, फ़ोन उसी कीमत पर रुक जाएगा',
         '<div class="row t">टोकन: ₹ <span class="ln"></span> &nbsp; कीमत पक्की: <span class="ln"></span> दिन</div>'
         '<div class="row t">टोकन वापस होगा? &nbsp;<span class="chk"></span>हाँ &nbsp;<span class="chk"></span>नहीं &nbsp;<span class="ln"></span></div>'
         '<div class="note">यह सिर्फ़ ड्राफ़्ट है। शर्तें (टोकन कितना, कितने दिन, वापसी होगी या नहीं) दुकान के मालिक तय करें और साफ़ लिखकर ही यह बोर्ड लगाएँ। जो वादा आप निभा न सकें, वह न लिखें।</div>', 'ड्राफ़्ट · शर्तें मालिक तय करें'),
    sign('Brandhoop Mobile Point', 'हमारी सेवाएँ', 'जो सेवा आप देते हैं उस पर निशान लगाएँ, कीमत लिखें',
         '<table><tr><th>सेवा</th><th>कीमत</th></tr>' + ''.join(f'<tr><td><span class="chk"></span>{s}</td><td class="w"></td></tr>' for s in
          ['मोबाइल रिपेयरिंग', 'मोबाइल स्किन कटिंग', 'मोबाइल ग्लास / स्क्रीन गार्ड', 'मोबाइल कवर', 'चार्जर, डाटा केबल', 'पुराने मोबाइल दो, नए मोबाइल लो', 'फ़ोन EMI / लोन पर']) + '</table>', 'मालिक भरें'),
    sign('सस्ता और भरोसेमंद', 'पुराने फ़ोन (Pre-owned)', 'हर फ़ोन की जाँच और ग्रेड, साथ में वारंटी',
         '<table><tr><th>ग्रेड</th><th>हालत</th><th>वारंटी</th></tr>'
         '<tr><td>A</td><td>लगभग नए जैसा</td><td class="w"></td></tr><tr><td>B</td><td>हल्के निशान, पूरा चालू</td><td class="w"></td></tr>'
         '<tr><td>C</td><td>साफ़ घिसाव, पूरा चालू</td><td class="w"></td></tr></table>'
         '<div class="note">वारंटी में कितने दिन और क्या शामिल है, मालिक खुद लिखें। हर फ़ोन पर ग्रेड का स्टिकर और कीमत लगाएँ। नए फ़ोन के डिब्बों से इन्हें अलग अलमारी में रखें।</div>', 'मालिक भरें'),
    sign('भुगतान और EMI', 'आसान भुगतान', 'अपने हिसाब से चुनें',
         '<div class="row t"><span class="chk"></span>लोन पर फ़ोन: पैन कार्ड, आधार कार्ड, बैंक पासबुक (सिर्फ़ 3 document)</div>'
         '<div class="row t"><span class="chk"></span>Bajaj Finserv · IDFC First Bank · HDFC Bank</div>'
         '<div class="row t"><span class="chk"></span>Bajaj Finserv EMI: सिर्फ़ दुकान पर (फेस स्कैन ज़रूरी)</div>'
         '<div class="row t"><span class="chk"></span>0% डाउन पेमेंट: कार्ड ग्राहकों के लिए (शर्तें दुकान पर पूछें)</div>'
         '<div class="row t"><span class="chk"></span>UPI: PhonePe, Google Pay, Paytm</div>'
         '<div class="row t"><span class="chk"></span>कार्ड और बाकी विकल्प: ऑनलाइन भी उपलब्ध</div>'
         '<div class="row t"><span class="chk"></span>पुराना फ़ोन एक्सचेंज: दुकान पर बात करें</div>'
         '<div class="note">जो सुविधा दुकान पर सच में है, सिर्फ़ उसी पर निशान लगाएँ। Bajaj EMI की किस्त और ब्याज यहाँ तभी लिखें जब दुकान से पक्की जानकारी मिल जाए।</div>', 'मालिक निशान लगाएँ'),
    sign('ऐप खोलें', 'सारे फ़ोन फ़ोन पर देखें', 'QR स्कैन करें · कीमत और ऑफ़र WhatsApp पर पूछें',
         f'<div style="display:flex;justify-content:center;margin-top:12mm"><div style="text-align:center">{QR_APP.replace("width=\"200\" height=\"200\"", "width=\"110mm\" height=\"110mm\"")}<div style="font-size:16pt;font-weight:700;margin-top:4mm">ऐप खोलने के लिए स्कैन करें</div></div></div>'),
]
write('counter-signs.html', page('Counter signs', SIGN_CSS, ''.join(pages)))

# ------------------------------------------------------------------ floor plan (schematic, not to scale)
def room(x0, y0, after):
    W, H = 306, 510
    g = []
    g.append(f'<rect x="{x0}" y="{y0}" width="{W}" height="{H}" fill="#F6F6F6" stroke="#151515" stroke-width="4"/>')
    g.append(f'<rect x="{x0+90}" y="{y0+H-3}" width="126" height="7" fill="#F6F6F6"/>')  # open door
    g.append(f'<text x="{x0+W/2}" y="{y0+H+26}" text-anchor="middle" font-size="15" fill="#555">▲ प्रवेश · Entrance</text>')
    # phone wall (right)
    g.append(f'<rect x="{x0+W-20}" y="{y0+30}" width="20" height="{H-90}" fill="#D8662A"/>')
    if not after:
        g.append(f'<rect x="{x0+0}" y="{y0}" width="{W}" height="16" fill="#e8b4b0"/><text x="{x0+W/2}" y="{y0+12}" text-anchor="middle" font-size="11" fill="#7a1d17">छत तक डिब्बे</text>')
        g.append(f'<rect x="{x0+20}" y="{y0+30}" width="100" height="56" fill="#d9d2c4" stroke="#555"/><text x="{x0+70}" y="{y0+62}" text-anchor="middle" font-size="12">स्किन, कवर, ढेर</text>')
        g.append(f'<rect x="{x0+114}" y="{y0+110}" width="100" height="270" fill="#7bc26b" stroke="#2f6b25" stroke-width="2"/><text x="{x0+164}" y="{y0+250}" text-anchor="middle" font-size="14" fill="#fff" transform="rotate(-90 {x0+164} {y0+250})">काउंटर (घास की मैट)</text>')
        for (cx, cy) in [(x0+135, y0+140), (x0+190, y0+170), (x0+140, y0+330), (x0+195, y0+300), (x0+170, y0+220)]:
            g.append(f'<circle cx="{cx}" cy="{cy}" r="9" fill="#e53935"/>')
        g.append(f'<text x="{x0+164}" y="{y0+396}" text-anchor="middle" font-size="11" fill="#b3261e">● काउंटर पर बिखरा सामान</text>')
        g.append(f'<rect x="{x0+4}" y="{y0+395}" width="14" height="34" fill="#c9a" stroke="#555"/><circle cx="{x0+40}" cy="{y0+455}" r="16" fill="#8B94A0" stroke="#555"/><rect x="{x0+60}" y="{y0+430}" width="26" height="32" fill="#333"/>')
        g.append(f'<text x="{x0+22}" y="{y0+488}" font-size="11" fill="#b3261e">जार + बैग प्रवेश पर</text>')
        for (cx, cy) in [(x0+50, y0+300), (x0+70, y0+330), (x0+45, y0+360), (x0+85, y0+280)]:
            g.append(f'<circle cx="{cx}" cy="{cy}" r="9" fill="#8d6e63"/>')
        g.append(f'<text x="{x0+62}" y="{y0+262}" text-anchor="middle" font-size="11" fill="#555">भीड़, रास्ता तंग</text>')
        g.append(f'<text x="{x0+62}" y="{y0+196}" text-anchor="middle" font-size="12" fill="#555">रास्ता ~3 फ़ुट</text>')
    else:
        g.append(f'<rect x="{x0}" y="{y0+60}" width="9" height="350" fill="#00897b"/><text x="{x0+22}" y="{y0+240}" font-size="13" fill="#00695c" transform="rotate(-90 {x0+22} {y0+240})">②  स्लैटवॉल: एक्सेसरी कैटेगरी से</text>')
        g.append(f'<circle cx="{x0+22}" cy="{y0+82}" r="13" fill="#D8662A"/><text x="{x0+22}" y="{y0+87}" text-anchor="middle" font-size="14" fill="#fff" font-weight="700">2</text>')
        g.append(f'<rect x="{x0+30}" y="{y0+36}" width="84" height="64" fill="#cfd8dc" stroke="#555" stroke-width="2"/><text x="{x0+72}" y="{y0+70}" text-anchor="middle" font-size="12">स्किन / रिपेयर</text>')
        g.append(f'<rect x="{x0+122}" y="{y0+30}" width="104" height="44" fill="#bbdefb" stroke="#1565c0" stroke-width="2"/><text x="{x0+174}" y="{y0+57}" text-anchor="middle" font-size="12">काँच शोकेस</text>')
        g.append(f'<rect x="{x0+234}" y="{y0+30}" width="52" height="60" fill="#ffe0b2" stroke="#ef6c00" stroke-width="2"/><text x="{x0+260}" y="{y0+64}" text-anchor="middle" font-size="11">पुराने फ़ोन</text>')
        g.append(f'<rect x="{x0+114}" y="{y0+130}" width="100" height="250" fill="#e0e0e0" stroke="#555" stroke-width="2"/><text x="{x0+164}" y="{y0+250}" text-anchor="middle" font-size="14" fill="#333" transform="rotate(-90 {x0+164} {y0+250})">काउंटर: ऊपर साफ़</text>')
        g.append(f'<rect x="{x0+114}" y="{y0+336}" width="100" height="44" fill="#ffd54f" stroke="#f9a825" stroke-width="2"/><text x="{x0+164}" y="{y0+363}" text-anchor="middle" font-size="12">बिलिंग + कॉम्बो कार्ड</text>')
        g.append(f'<rect x="{x0+216}" y="{y0+130}" width="{W-20-216}" height="250" fill="#eceff1" stroke="#90a4ae" stroke-dasharray="4 3"/><text x="{x0+258}" y="{y0+250}" text-anchor="middle" font-size="12" fill="#546e7a" transform="rotate(-90 {x0+258} {y0+250})">बंद अलमारी: स्टोर</text>')
        g.append(f'<line x1="{x0+22}" y1="{y0+420}" x2="{x0+112}" y2="{y0+420}" stroke="#2e7d32" stroke-width="4"/><text x="{x0+66}" y="{y0+442}" text-anchor="middle" font-size="12" fill="#2e7d32">खुला रास्ता ≥ 3 फ़ुट</text>')
        g.append(f'<path d="M{x0+150} {y0+500} Q{x0+60} {y0+440} {x0+60} {y0+260} T{x0+75} {y0+120}" fill="none" stroke="#D8662A" stroke-width="3" stroke-dasharray="7 5" marker-end="url(#ar)"/>')
        for n, (cx, cy) in {1: (x0+150, y0+470), 3: (x0+W-30, y0+250), 4: (x0+164, y0+322), 5: (x0+174, y0+88), 6: (x0+72, y0+118), 7: (x0+260, y0+104), 8: (x0+258, y0+390), 9: (x0+66, y0+398)}.items():
            g.append(f'<circle cx="{cx}" cy="{cy}" r="13" fill="#D8662A"/><text x="{cx}" y="{cy+5}" text-anchor="middle" font-size="14" fill="#fff" font-weight="700">{n}</text>')
    g.append(f'<text x="{x0+W-10}" y="{y0+H-70}" text-anchor="end" font-size="12" fill="#fff" transform="rotate(-90 {x0+W-6} {y0+H-70})" dominant-baseline="hanging"></text>')
    g.append(f'<text x="{x0+W-5}" y="{y0+250}" text-anchor="middle" font-size="12" fill="#fff" transform="rotate(-90 {x0+W-5} {y0+250})">फ़ोन की दीवार</text>')
    return ''.join(g)


legend = [
    ('1', 'खुला प्रवेश: बैग, पानी का जार और डिब्बे हटाएँ'),
    ('2', 'बाईं दीवार पर स्लैटवॉल या पेगबोर्ड: चार्जर, ऑडियो, कवर, पावर के खाने'),
    ('3', 'फ़ोन की दीवार: डमी फ़ोन आगे, डिब्बे पीछे, हर मॉडल पर प्राइस स्ट्रिप'),
    ('4', 'काउंटर ऊपर से खाली: बिलिंग, कॉम्बो कार्ड और ग्लास/केबल का छोटा स्टैंड'),
    ('5', 'पीछे की दीवार पर काँच का शोकेस: स्मार्टवॉच और ईयरबड्स, आँखों की ऊँचाई पर'),
    ('6', 'स्किन कटिंग / रिपेयर का छोटा डेस्क, ग्राहकों से अलग'),
    ('7', 'पुराने फ़ोन की अलग अलमारी, ग्रेड स्टिकर और कीमत के साथ'),
    ('8', 'काउंटर के नीचे बंद स्टोर: छत तक रखे डिब्बे यहाँ उतारें'),
    ('9', 'ग्राहकों के लिए कम से कम 3 फ़ुट खुला रास्ता'),
    ('•', 'रोशनी: खुली ट्यूब की जगह गर्म सफ़ेद LED पट्टी, छत हल्की रंग की'),
]
fp = f"""<!doctype html><html lang="hi"><meta charset="utf-8"><title>Shop plan</title><style>
@page {{ size: A4 landscape; margin: 6mm; }}
body {{ margin: 0; font-family: {FONT}; color: #151515; width: 1180px; padding: 14px 16px; }}
h1 {{ margin: 0 0 2px; font-size: 26px; }} .sub {{ color: #444; font-size: 14px; margin-bottom: 4px; }}
.warn {{ color: #b3261e; font-size: 13px; margin: 2px 0 6px; }}
.lg {{ display: grid; grid-template-columns: 1fr 1fr; gap: 3px 28px; font-size: 14.5px; margin-top: 6px; }}
.lg div b {{ display: inline-block; width: 22px; height: 22px; line-height: 22px; text-align: center; border-radius: 11px; background: #D8662A; color: #fff; margin-right: 8px; }}
</style><body><h1>दुकान का नया नक्शा · Shop layout</h1>
<div class="sub">बाएँ: अभी जैसा दिखता है (फ़ोटो के हिसाब से) · दाएँ: सुझाया गया बदलाव</div>
<div class="warn">यह अंदाज़े का नक्शा है, नाप के हिसाब से नहीं बना। कमरा लगभग 9 फ़ुट चौड़ा और 15 फ़ुट लंबा माना है। असली नाप लेकर जगहें थोड़ी आगे-पीछे कर लें।</div>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1180 640" width="1180" height="640">
<defs><marker id="ar" markerWidth="10" markerHeight="10" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#D8662A"/></marker></defs>
<text x="20" y="22" font-size="19" font-weight="700" fill="#b3261e">अभी (Before)</text>{room(20, 40, False)}
<text x="620" y="22" font-size="19" font-weight="700" fill="#2e7d32">बाद में (After)</text>{room(620, 40, True)}
<text x="560" y="300" text-anchor="middle" font-size="40" fill="#D8662A">→</text></svg>
<div class="lg">{''.join(f'<div><b>{n}</b>{esc(t)}</div>' for n, t in legend)}</div></body></html>"""
write('floor-plan.html', fp)

# ------------------------------------------------------------------ Hindi checklist
steps = [
    ('कल सुबह: खर्च कुछ नहीं, 2-3 घंटे', [
        'काउंटर के ऊपर से सब कुछ हटाएँ। सिर्फ़ बिलिंग मशीन, एक फ़ोन स्टैंड और कॉम्बो कार्ड रहने दें',
        'काउंटर से बैग, काली थैली, पानी की बोतल, लाल चटाई और FORWARD के कार्टन हटाएँ। पानी का जार और कपड़ा दरवाज़े से अंदर करें',
        'कंधे की ऊँचाई से ऊपर रखे सारे डिब्बे उतारकर बंद अलमारी में रखें',
        'पुराने फ़ोन और पार्ट्स एक अलग अलमारी में रखें। नए फ़ोन के पास न रखें',
        'स्किन के रोल और सैंपल कार्ड एक कोने में (स्किन कटिंग मशीन के पास) लेबल के साथ रखें',
        'लटकी हुई पाउच और केबल एक ही जगह (एक कोने) में टाँगें',
        'फ़ोन की दीवार पर हर मॉडल का 1 या 2 डिब्बा आगे रखें, बाकी पीछे',
    ]),
    ('कल: प्रिंट और चिपकाना', [
        'price-strips-phones.pdf प्रिंट करें, काटें और हर मॉडल की शेल्फ़ पर चिपकाएँ',
        'हर स्ट्रिप पर आज की असली कीमत पेन से लिखें (लिखने के बाद ही चिपकाएँ)',
        'price-strips-accessories.pdf प्रिंट करके एक्सेसरी की शेल्फ़ पर लगाएँ',
        'counter-signs.pdf में से कॉम्बो ऑफ़र, सेवाएँ और भुगतान वाली शीट भरकर काउंटर पर लगाएँ',
        'QR वाली शीट काउंटर और दरवाज़े पर लगाएँ',
    ]),
    ('इस हफ़्ते: थोड़ा खर्च', [
        'खुली ट्यूब की जगह गर्म सफ़ेद LED पट्टी लगवाएँ (शेल्फ़ के किनारे पीछे छिपाकर)',
        'काउंटर की घास की मैट हटाकर सादी मैट या काँच की टॉप',
        'छत का बीच का हिस्सा हल्का रंग करवाएँ',
        'कैटेगरी के खाने बनाएँ: चार्जिंग, ऑडियो, सुरक्षा (ग्लास/कवर), पावर, स्मार्ट',
        'पुराने फ़ोन के लिए ग्रेड A/B/C स्टिकर बनवाएँ',
        'दुकान के नाम और QR वाला Brandhoop बैनर लगाएँ',
    ]),
    ('इस महीने: बड़े बदलाव', [
        'दीवार पर स्लैटवॉल या पेगबोर्ड लगवाएँ और बाकी सामान उसी पर टाँगें',
        'फ़ोन की दीवार पर डमी फ़ोन (एक्रेलिक स्टैंड) लगवाएँ, असली डिब्बे पीछे रखें',
        'दरवाज़े के पास काँच का शोकेस बनवाएँ: स्मार्टवॉच, ईयरबड्स, महँगे फ़ोन',
        'काउंटर को एक ही तरफ़ रखकर ग्राहकों के लिए कम से कम 3 फ़ुट रास्ता खुला रखें',
    ]),
    ('रोज़ 10 मिनट', [
        'काउंटर साफ़ करें, कीमतें देखें (बदली हों तो स्ट्रिप बदलें)',
        'जो बिका, उसकी जगह नया डिब्बा आगे लाएँ',
        'हर शाम गिनें: कौन-सा सामान कम बचा है, कौन-सा बहुत पड़ा है',
    ]),
    ('काम पूरा होने के बाद', [
        '6 फ़ोटो खींचकर भेजें: दरवाज़े से अंदर, फ़ोन की दीवार, एक्सेसरी की दीवार, काउंटर, शोकेस, पूरी दुकान (ग्राहकों के बिना)',
        'हम वेबसाइट और ऐप पर असली दुकान की साफ़ फ़ोटो लगा देंगे',
        'ऐप के एडमिन पैनल में हर फ़ोन की असली कीमत, गिफ़्ट और फ़ोटो भरें (admin पेज देखें)',
    ]),
]
cl_css = f"""@page {{ size: A4; margin: 12mm 14mm; }} body {{ margin:0; font-family:{FONT}; color:#151515; }}
h1 {{ font-size: 22pt; margin: 0 0 1mm; }} .s {{ color:#555; font-size: 10.5pt; margin-bottom: 4mm; }}
h2 {{ font-size: 13.5pt; margin: 5mm 0 1.5mm; color:#1F2744; border-bottom:.4mm solid #D8662A; padding-bottom:.8mm; }}
li {{ list-style:none; margin: 0 0 1.4mm; font-size: 11.5pt; line-height:1.35; display:flex; gap:3mm; }}
li:before {{ content:''; flex:none; width:4.5mm; height:4.5mm; border:.4mm solid #151515; border-radius:1mm; margin-top:.7mm; }}
ul {{ margin:0; padding:0; }} section {{ break-inside: avoid; }}"""
body = ''.join(f'<section><h2>{esc(t)}</h2><ul>' + ''.join(f'<li>{esc(i)}</li>' for i in items) + '</ul></section>' for t, items in steps)
write('checklist-hi.html', page('Checklist', cl_css, '<h1>दुकान सुधार चेकलिस्ट</h1><div class="s">Brandhoop Mobile Point · एक-एक काम करें और डिब्बे में निशान लगाएँ</div>' + body))
print('ok')

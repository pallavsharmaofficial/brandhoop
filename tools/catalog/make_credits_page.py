#!/usr/bin/env python3
"""Writes site/credits.html from the photo records: Pexels (acc_images.json and
the fixed list below) and Wikimedia Commons (commons_credits.json)."""
import html, json, pathlib
HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
acc = json.loads((HERE / 'acc_images.json').read_text())['pexels']
commons = json.loads((HERE / 'commons_credits.json').read_text()) if (HERE / 'commons_credits.json').exists() else []
fixed = {
    'Diya lamp at night (Yash Rai)': 31372002, 'Diyas beside flowers': 6213685, 'Black smartphone on a table': 215582,
}
names = {
    'wired': 'Wired earphones', 'tws': 'Wireless earbuds', 'hp_bt': 'Wireless headphones', 'hp_wired': 'Wired headphones', 'wall': 'Wall charger',
    'wireless': 'Wireless charger', 'cable': 'Charging cable', 'powerbank': 'Power bank and cables', 'case_clear': 'Transparent phone cases',
    'glass': 'Tempered glass screen guard', 'smartwatch': 'Smartwatch', 'band': 'Fitness band / watch', 'speaker': 'Speaker', 'memory': 'Memory cards',
    'pendrive': 'Pen drive', 'stand': 'Phone stand', 'carholder': 'Car phone holder', 'tripod_tall': 'Tripod', 'tripod_flex': 'Flexible tripod',
}
li = lambda t, u, extra='': f'<li>{html.escape(t)}{extra}: <a href="{html.escape(u)}">link</a></li>'
pex = [li(t, f'https://www.pexels.com/photo/{i}/') for t, i in fixed.items()] + [li(names[k], f'https://www.pexels.com/photo/{i}/') for k, i in acc.items() if k in names]
com = [li(c['file'], c['page'], f' by {html.escape(c["author"])}, {html.escape(c["license"])}') for c in commons]
page = f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Photo credits · Brandhoop</title><link rel="icon" type="image/png" href="favicon.png">
<style>body{{font:17px/1.6 system-ui,"Noto Sans Devanagari",sans-serif;max-width:720px;margin:0 auto;padding:24px 20px 60px;color:#1d1d1f}}
h1{{color:#283593}}h2{{color:#283593;font-size:20px;margin-top:28px}}a{{color:#283593}}li{{margin:5px 0}}@media(prefers-color-scheme:dark){{body{{background:#141418;color:#ececf0}}h1,h2,a{{color:#9FA8DA}}}}</style></head>
<body><p><a href="./">&larr; Brandhoop</a></p><h1>Photo credits</h1>
<h2>Wikimedia Commons (phone photos)</h2>
<p>Photographs of real phone models, cropped and resized, used under their open licences (CC0, CC BY or CC BY-SA 4.0). Follow each link for the author and the licence text. Changed pictures are shared under the same licence.</p>
<ul>{''.join(com) or '<li>None yet.</li>'}</ul>
<h2>Pexels (accessory and festival photos)</h2>
<p>Free-to-use photographs under the <a href="https://www.pexels.com/license/">Pexels licence</a>, credited here anyway. Accessory pictures are for illustration only.</p>
<ul>{''.join(pex)}</ul>
<h2>The shop</h2>
<p>The picture of the gift sets and phone boxes and the OPPO A6x and Enco Buds boxes are the shop’s own. The Dhanteras greeting is an OPPO festival greeting. OPPO and the other brand names are trademarks of their owners, used only to describe products the shop sells.</p>
</body></html>'''
(ROOT / 'site' / 'credits.html').write_text(page)
print('credits page:', len(commons), 'commons,', len(pex), 'pexels')

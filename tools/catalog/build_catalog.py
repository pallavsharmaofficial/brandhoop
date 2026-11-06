#!/usr/bin/env python3
"""Rebuilds the products in assets/live/shop.json from phones.py and
accessories.py. Settings, offers, gallery and features in the file are kept.

    python3 tools/catalog/build_catalog.py

Run it only to regenerate the starting catalogue. Once the owner edits products
in the admin panel, edit there instead; running this again replaces products.
"""
import json, pathlib, sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
import phones, accessories  # noqa: E402

RAW = 'https://raw.githubusercontent.com/pallavsharmaofficial/brandhoop/main/'
shop_path = ROOT / 'assets' / 'live' / 'shop.json'
shop = json.loads(shop_path.read_text())
acc_files = json.loads((HERE / 'acc_images.json').read_text())['files']
FEATURED = {'oppo-a6x-5g', 'redmi-15-5g', 'samsung-galaxy-m36-5g', 'iphone-17', 'samsung-galaxy-a56-5g', 'redmi-note-15-pro-5g', 'realme-p4-power-5g', 'oneplus-nord-ce5'}
USER_PHOTOS = {'oppo-a6x-5g': 'site/products/oppo-a6x-5g.jpg'}

def have(path):
    return (ROOT / path).exists()

products = []
for pid, name, brand, launch, variants, highlights, _q, _must in phones.PHONES:
    known = any(v[1] for v in variants)
    p = {
        'id': pid, 'name': {'en': name, 'hi': ''}, 'brand': brand,
        'category': 'featurePhone' if pid in phones.KEYPAD else 'smartphone',
        'callForBest': True, 'featured': pid in FEATURED, 'emiEligible': pid not in phones.KEYPAD,
        'variants': [{'id': f'v{i+1}', 'label': l, 'color': '', 'price': (pr or 0), 'mrp': (pr or 0), 'stock': 1} for i, (l, pr) in enumerate(variants)],
    }
    if known:
        mon, _, yr = launch.partition(' ')
        en = f'Launch price ({launch})' if launch else 'Launch price'
        hi = f'लॉन्च कीमत ({phones.M.get(mon, mon)} {yr})' if launch else 'लॉन्च कीमत'
        p['refPriceLabel'] = {'en': en, 'hi': hi}
        when_en = f' in {launch}' if launch else ''
        p['description'] = {
            'en': f'Launched in India{when_en} at the launch price shown. Prices have changed since and differ from shop to shop. Call or WhatsApp for today’s best price, gifts and offers.',
            'hi': 'भारत में दिखाई गई लॉन्च कीमत पर आया। तब से कीमतें बदल चुकी हैं और दुकान के हिसाब से अलग होती हैं। आज की सबसे अच्छी कीमत, गिफ़्ट और ऑफ़र के लिए कॉल या व्हाट्सऐप करें।',
        }
    else:
        p['description'] = {'en': 'Ask the shop for today’s price, gifts and offers.', 'hi': 'आज की कीमत, गिफ़्ट और ऑफ़र दुकान से पूछें।'}
    if highlights:
        p['highlights'] = [{'en': e, 'hi': h} for e, h in highlights]
    photo = USER_PHOTOS.get(pid) or (f'site/products/{pid}.jpg' if have(f'site/products/{pid}.jpg') else None)
    if photo:
        p['imageUrls'] = [RAW + photo]
        if pid not in USER_PHOTOS:
            p['tags'] = ['commons-photo']
    products.append(p)

for pid, en, hi, cat, key, fit in accessories.ACC:
    p = {
        'id': pid, 'name': {'en': en, 'hi': hi}, 'brand': 'Accessories', 'category': cat, 'callForBest': True,
        'description': {'en': 'Ask the shop for today’s price, gifts and offers. Available for most phones.', 'hi': 'आज की कीमत, गिफ़्ट और ऑफ़र दुकान से पूछें। ज़्यादातर फ़ोन के लिए उपलब्ध।'},
        'variants': [{'id': 'v1', 'label': 'Standard', 'color': '', 'price': 0, 'mrp': 0, 'stock': 1}],
        'tags': (['fit'] if fit else []),
    }
    if key and key in acc_files:
        p['imageUrls'] = [RAW + acc_files[key]]
        p['tags'].append('illustration')
    products.append(p)

shop['products'] = products
shop_path.write_text(json.dumps(shop, ensure_ascii=False, indent=2) + '\n')
print(len(products), 'products:', sum(1 for p in products if p['category'] in ('smartphone', 'featurePhone')), 'phones,', sum(1 for p in products if p['id'].startswith('acc-')), 'accessories,',
      sum(1 for p in products if p.get('imageUrls')), 'with photos')

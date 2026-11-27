#!/usr/bin/env python3
"""Rebuilds the products in assets/live/shop.json from phones.py and
accessories.py. Settings, offers, gallery and features in the file are kept.

    python3 tools/catalog/build_catalog.py

Run it only to regenerate the starting catalogue. Once the owner edits products
in the admin panel, edit there instead; running this again replaces products.
"""
import json, os, pathlib, sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
import phones, accessories, shop_data  # noqa: E402
sys.path.insert(0, str(ROOT / 'tools' / 'models3d'))
import attach  # noqa: E402  (3D models and extra photos collected by tools/models3d)

RAW = 'https://raw.githubusercontent.com/pallavsharmaofficial/brandhoop/main/'
shop_path = ROOT / 'assets' / 'live' / 'shop.json'
shop = json.loads(shop_path.read_text())
acc_files = json.loads((HERE / 'acc_images.json').read_text())['files']
FEATURED = set(shop_data.DATA)   # every phone the owner has priced is shown on the home screen
USER_PHOTOS = {'oppo-a6x-5g': 'site/products/oppo-a6x-5g.jpg'}

def have(path):
    return (ROOT / path).exists()

products = []
for pid, name, brand, launch, variants, highlights, _q, _must in phones.PHONES:
    sd = shop_data.DATA.get(pid)
    if shop_data.ONLY_SHOP_PHONES and not sd:
        continue   # not priced by the owner yet: kept in phones.py, left out of the shop
    if sd:
        variants, highlights = sd['prices'], sd.get('highlights') or highlights
    known = any(v[1] for v in variants)
    p = {
        'id': pid, 'name': {'en': name, 'hi': ''}, 'brand': brand,
        'category': 'featurePhone' if pid in phones.KEYPAD else 'smartphone',
        'callForBest': True, 'featured': pid in FEATURED, 'emiEligible': pid not in phones.KEYPAD,
        'variants': [{'id': f'v{i+1}', 'label': l, 'color': '', 'price': (pr or 0), 'mrp': (pr or 0), 'stock': 1} for i, (l, pr) in enumerate(variants)],
    }
    if sd:
        p['refPriceLabel'] = {'en': f'Shop price, updated {sd["updated"][0]}', 'hi': f'दुकान की कीमत, {sd["updated"][1]} तक'}
        p['description'] = {'en': f'Shop price as of {sd["updated"][0]}. Prices can change, so call or WhatsApp to confirm today’s price, gifts, offers and EMI.',
                            'hi': f'{sd["updated"][1]} तक की दुकान की कीमत। कीमत बदल सकती है, इसलिए आज की कीमत, गिफ़्ट, ऑफ़र और EMI के लिए कॉल या WhatsApp करें।'}
        p['specs'] = dict(sd.get('specs', {}))
    elif known:
        mon, _, yr = launch.partition(' ')
        en = f'Launch price ({launch})' if launch else 'Launch price'
        hi = f'लॉन्च कीमत ({phones.M.get(mon, mon)} {yr})' if launch else 'लॉन्च कीमत'
        if pid in phones.RAISED:
            en += ' – raised since, call for today’s price'
            hi += ' – तब से बढ़ी है, आज की कीमत के लिए कॉल करें'
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

# The owner edits the shop from the admin panel (prices, new phones, photos). A rebuild must never undo that:
#  * a generated product the owner changed after the date in shop_data.UPDATED keeps the owner's version;
#  * a product the owner added (an id that is not in phones.py or accessories.py) is kept at the top.
import datetime
MON = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
def updated_on(p):
    import re
    m = re.search(r'updated (\d+) (\w{3}) (\d{4})', (p.get('refPriceLabel') or {}).get('en', ''))
    return datetime.date(int(m.group(3)), MON.index(m.group(2)) + 1, int(m.group(1))) if m else None
base_date_of = lambda pid: datetime.datetime.strptime(shop_data.DATA[pid]['updated'][0], '%d %b %Y').date() if pid in shop_data.DATA else None
existing = {p['id']: p for p in shop.get('products', [])}
generated = {p['id'] for p in products}
known_ids = {row[0] for row in phones.PHONES} | {row[0] for row in accessories.ACC}
kept = 0
for i, p in enumerate(products):
    old_p = existing.get(p['id'])
    d = updated_on(old_p) if old_p else None
    bd = base_date_of(p['id'])
    if old_p and d and bd and d > bd and not os.environ.get('CATALOG_FORCE'):
        products[i] = old_p; kept += 1
# 3D models and photos from tools/models3d are part of the catalogue: a rebuild must not drop them.
n3d, nph = attach.apply(products)
if n3d or nph:
    print(f'3D models: {n3d} products, extra photos: {nph} products')
owner_added = [p for pid, p in existing.items() if pid not in generated and pid not in known_ids]
products = owner_added + products
if kept or owner_added:
    print(f'kept the owner\'s edits: {kept} changed products, {len(owner_added)} added products')
shop['products'] = products
shop_path.write_text(json.dumps(shop, ensure_ascii=False, indent=2) + '\n')
print(len(products), 'products:', sum(1 for p in products if p['category'] in ('smartphone', 'featurePhone')), 'phones,', sum(1 for p in products if p['id'].startswith('acc-')), 'accessories,',
      sum(1 for p in products if p.get('imageUrls')), 'with photos')

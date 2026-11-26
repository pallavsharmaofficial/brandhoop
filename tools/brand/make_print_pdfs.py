#!/usr/bin/env python3
"""Flattens the visiting-card PNGs from export_cards.js to RGB (600 dpi) and builds the two print PDFs (front + back)."""
from PIL import Image
D = 'site/brand/print/cards/'
def rgb(n): return Image.open(D + f'visiting-card-{n}-600dpi.png').convert('RGB')
for n in ('front', 'back', 'front-bleed', 'back-bleed'):
    rgb(n).save(D + f'visiting-card-{n}-600dpi.png', dpi=(600, 600), optimize=True)
rgb('front-bleed').save(D + 'visiting-card-print-with-3mm-bleed.pdf', 'PDF', resolution=600, save_all=True, append_images=[rgb('back-bleed')])
rgb('front').save(D + 'visiting-card-print-trim-size.pdf', 'PDF', resolution=600, save_all=True, append_images=[rgb('back')])
print('print files ok')

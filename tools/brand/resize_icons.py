#!/usr/bin/env python3
"""Cuts the app-icon sizes from the 1024 renders made by make_assets.py (run after shoot.js)."""
import numpy as np
from PIL import Image
A = 'assets/branding/'
big = Image.open(A + 'icon-1024.png').convert('RGBA')
for n in (512, 192, 96, 48, 32, 16):
    big.resize((n, n), Image.LANCZOS).save(A + f'icon-{n}.png')
mk = Image.open('tools/brand/build/icon-maskable-1024.png').convert('RGBA')
mk.resize((512, 512), Image.LANCZOS).save(A + 'icon-maskable-512.png')
mk.resize((512, 512), Image.LANCZOS).save('web/icons/Icon-maskable-512.png')
mk.resize((192, 192), Image.LANCZOS).save('web/icons/Icon-maskable-192.png')
big.resize((512, 512), Image.LANCZOS).save('web/icons/Icon-512.png')
big.resize((192, 192), Image.LANCZOS).save('web/icons/Icon-192.png')
for f in ('web/favicon.png', 'site/favicon.png'):
    big.resize((48, 48), Image.LANCZOS).save(f)
m = np.array(Image.open('tools/brand/build/icon-mono-src.png').convert('RGBA')).astype(float)
lum = (m[..., 0] * 0.3 + m[..., 1] * 0.59 + m[..., 2] * 0.11) / 255
out = np.zeros(m.shape, np.uint8); out[..., :3] = 255; out[..., 3] = ((m[..., 3] / 255) * lum * 255).astype(np.uint8)
Image.fromarray(out, 'RGBA').save(A + 'icon-monochrome.png')
print('icons ok')

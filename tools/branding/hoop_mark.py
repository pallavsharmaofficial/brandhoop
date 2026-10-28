"""The Brandhoop mark: an open saffron hoop around a phone.

The same shape the app draws in lib/widgets/brand_mark.dart, so the launcher
icon and the in-app logo are one picture. launchkit calls `mark` with the ink
(the phone) and the accent (the hoop); on the Android themed icon both are the
same colour, which is why the phone is an outline and not a filled block.
"""
import math


def mark(draw, cx, cy, half, ink, accent, small=False, label=''):
    stroke = max(2, round(half * (0.26 if small else 0.17)))
    radius = half
    box = [cx - radius, cy - radius, cx + radius, cy + radius]
    # An open hoop: it starts at the upper right and goes round almost all the way.
    start_deg, end_deg = -20, 309
    draw.arc(box, start_deg, end_deg, fill=accent, width=stroke)
    # Round the two ends, which Pillow's arc leaves square.
    mid = radius - stroke / 2
    for deg in (start_deg, end_deg):
        x = cx + mid * math.cos(math.radians(deg))
        y = cy + mid * math.sin(math.radians(deg))
        draw.ellipse([x - stroke / 2, y - stroke / 2, x + stroke / 2, y + stroke / 2], fill=accent)

    # The phone, as an outline so it still reads in a single flat colour.
    w, h = half * 0.64, half * 1.08
    line = max(2, round(half * (0.17 if small else 0.12)))
    draw.rounded_rectangle([cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2],
                           radius=half * 0.16, outline=ink, width=line)
    if not small:
        d = half * 0.06
        draw.ellipse([cx - d, cy + h / 2 - half * 0.2 - d, cx + d, cy + h / 2 - half * 0.2 + d], fill=ink)

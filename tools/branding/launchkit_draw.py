"""Shared drawing for the icon script that launchkit writes into every app.

A launch needs the same pile of PNGs each time: the store icon, the Android
adaptive pieces, a splash mark, the web icons, a social card, the Play feature
graphic. What differs between apps is the mark and two colours, so everything
else lives here and make_icon.py is only a few lines of choices.

This file is copied into each app so the app stays self-contained and anyone
who clones it can regenerate the art. Change make_icon.py for one app; change
the launchkit copy of this file, then re-copy it, for all of them.

A mark is a function that draws into a box. To add one, write

    def mark(draw, cx, cy, half, ink, accent, small=False, label=''):

in a .py file and pass its path to make_icon.py with --mark. `half` is half the
side of the box the mark must stay inside, `ink` and `accent` are RGBA tuples,
`small` asks for the optical size used at 48 pixels and under, and `label` is
the app's initial.
"""
import importlib.util
import os
import sys

try:
    from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont
except ImportError:
    sys.exit('Pillow is needed to draw the icons: python3 -m pip install pillow')

WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
SHADOW = (0, 0, 0, 90)


# --- colour -----------------------------------------------------------------

def parse_hex(value):
    text = value.strip().lstrip('#')
    if len(text) == 3:
        text = ''.join(c * 2 for c in text)
    if len(text) != 6:
        raise ValueError('%r is not a colour like #RRGGBB' % value)
    return tuple(int(text[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a[:3], b[:3]))


def luminance(colour):
    def channel(c):
        c = c / 255
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (channel(c) for c in colour[:3])
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    """WCAG contrast ratio, 1 to 21. A mark under about 3 does not read."""
    hi, lo = sorted((luminance(a), luminance(b)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)


class Brand:
    """Everything the drawing needs to know about one app."""

    def __init__(self, name, tagline, primary, ground_end, accent, ink,
                 light_bg, dark_bg, mark='monogram', font=None, initial=None):
        self.name = name
        self.tagline = tagline
        self.primary = parse_hex(primary)
        self.ground_end = parse_hex(ground_end)
        self.accent = parse_hex(accent)
        self.ink = parse_hex(ink)
        self.light_bg = parse_hex(light_bg)
        self.dark_bg = parse_hex(dark_bg)
        self.mark = load_mark(mark)
        self.font = font
        self.initial = (initial or name[:1] or 'A').upper()

    @property
    def splash_light_ink(self):
        # A mark on the pale splash must be dark enough to see; fall back to a
        # shade of the primary when the primary itself is too light.
        if contrast(self.primary, self.light_bg) >= 3:
            return self.primary
        return mix(self.primary, BLACK, 0.45)

    @property
    def splash_dark_ink(self):
        return mix(self.primary, WHITE, 0.8)


# --- marks ------------------------------------------------------------------

MARKS = {}


def register(name):
    def add(fn):
        MARKS[name] = fn
        return fn
    return add


def load_mark(spec):
    """A mark by name, or from a .py file that defines `mark`."""
    if spec in MARKS:
        return MARKS[spec]
    if os.path.isfile(spec):
        loader = importlib.util.spec_from_file_location('custom_mark', spec)
        module = importlib.util.module_from_spec(loader)
        loader.loader.exec_module(module)
        if not hasattr(module, 'mark'):
            raise ValueError('%s defines no function called mark' % spec)
        return module.mark
    raise ValueError('no mark called %r; the built-in ones are: %s, or give a '
                     'path to a .py file' % (spec, ', '.join(sorted(MARKS))))


def typeface(path, size):
    if path:
        return ImageFont.truetype(path, size, layout_engine=ImageFont.Layout.BASIC)
    face = ImageFont.load_default(size)
    if not isinstance(face, ImageFont.FreeTypeFont):
        # Without FreeType the built-in font is a fixed bitmap that ignores the
        # size, and a 10 pixel letter on a 1024 pixel icon is worse than none.
        sys.exit('This Pillow cannot size its built-in font. Set FONT in '
                 'make_icon.py to a .ttf file.')
    return face


@register('monogram')
def monogram(draw, cx, cy, half, ink, accent, small=False, label='A'):
    """The app's initial in a rounded frame. The default because it is the one
    mark that is already specific to the app before anyone has designed one."""
    stroke = round(half * (0.17 if small else 0.11))
    draw.rounded_rectangle([cx - half, cy - half, cx + half, cy + half],
                           radius=half * 0.30, outline=ink, width=stroke)
    face = typeface(None, round(half * 1.3))
    # The built-in face has one weight, which is too thin once the icon is
    # shrunk to a favicon, so the small size thickens the letter with a stroke.
    draw.text((cx, cy - half * (0.02 if small else 0.10)), label[:1],
              font=face, fill=ink, anchor='mm',
              stroke_width=round(half * 0.045) if small else 0, stroke_fill=ink)
    if not small:
        draw.rounded_rectangle(
            [cx - half * 0.34, cy + half * 0.52, cx + half * 0.34, cy + half * 0.62],
            radius=half * 0.05, fill=accent)


@register('ring')
def ring(draw, cx, cy, half, ink, accent, small=False, label=''):
    """A ring around a dot: a focus, a target, an eye."""
    stroke = round(half * (0.26 if small else 0.18))
    draw.ellipse([cx - half, cy - half, cx + half, cy + half],
                 outline=ink, width=stroke)
    r = half * (0.46 if small else 0.38)
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=accent)


@register('wave')
def wave(draw, cx, cy, half, ink, accent, small=False, label=''):
    """Rounded bars of different heights: sound, activity, a rhythm."""
    heights = (0.65, 1.0, 0.7) if small else (0.45, 0.8, 1.0, 0.65, 0.35)
    count = len(heights)
    gap = 0.45
    width = 2 * half / (count + (count - 1) * gap)
    for i, h in enumerate(heights):
        x0 = cx - half + i * width * (1 + gap)
        y0, y1 = cy - h * half, cy + h * half
        draw.rounded_rectangle([x0, y0, x0 + width, y1], radius=width / 2,
                               fill=accent if i == count // 2 else ink)


@register('tiles')
def tiles(draw, cx, cy, half, ink, accent, small=False, label=''):
    """Four rounded tiles with one picked out: a dashboard, a set, a choice."""
    gap = half * (0.20 if small else 0.14)
    side = (2 * half - gap) / 2
    for row in range(2):
        for col in range(2):
            x0 = cx - half + col * (side + gap)
            y0 = cy - half + row * (side + gap)
            draw.rounded_rectangle([x0, y0, x0 + side, y0 + side],
                                   radius=side * 0.28,
                                   fill=accent if (row, col) == (0, 1) else ink)


@register('spark')
def spark(draw, cx, cy, half, ink, accent, small=False, label=''):
    """A four-point star with a small companion: something new, something smart."""
    waist = 0.26 if small else 0.2
    points = [(0, -1), (waist, -waist), (1, 0), (waist, waist),
              (0, 1), (-waist, waist), (-1, 0), (-waist, -waist)]
    draw.polygon([(cx + x * half, cy + y * half) for x, y in points], fill=ink)
    r = half * (0.2 if small else 0.15)
    px, py = cx + half * 0.6, cy - half * 0.6
    draw.ellipse([px - r, py - r, px + r, py + r], fill=accent)


# --- compositions -----------------------------------------------------------

def rgba(colour, alpha=255):
    return tuple(colour[:3]) + (alpha,)


def ground(width, height, start, end):
    """A diagonal wash from `start` at the top left to `end` at the bottom right."""
    across = Image.linear_gradient('L').rotate(90).resize((width, height))
    down = Image.linear_gradient('L').resize((width, height))
    mask = ImageChops.add(across, down, scale=2)
    return Image.composite(Image.new('RGB', (width, height), end),
                           Image.new('RGB', (width, height), start), mask)


def supersample(size, draw_at, factor=2):
    """Draws at a multiple of the final size and settles down to it, because
    Pillow's shapes have hard edges and the icon needs soft ones."""
    return draw_at(size * factor).resize((size, size), Image.LANCZOS)


def app_icon(brand, size=1024, small=False):
    def draw_at(s):
        image = ground(s, s, brand.primary, brand.ground_end).convert('RGBA')
        half = s * (0.31 if small else 0.27)
        if not small:
            # A soft shadow so the mark lifts off the ground.
            shadow = Image.new('RGBA', (s, s), (0, 0, 0, 0))
            brand.mark(ImageDraw.Draw(shadow), s / 2, s / 2 + s * 0.014, half,
                       SHADOW, SHADOW, small=small, label=brand.initial)
            image = Image.alpha_composite(
                image, shadow.filter(ImageFilter.GaussianBlur(s * 0.014)))
        brand.mark(ImageDraw.Draw(image), s / 2, s / 2, half, rgba(brand.ink),
                   rgba(brand.accent), small=small, label=brand.initial)
        return image.convert('RGB')
    return supersample(size, draw_at, 4 if small else 2)


def _alone(brand, size, half, ink, accent):
    def draw_at(s):
        image = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        brand.mark(ImageDraw.Draw(image), s / 2, s / 2, s * half, rgba(ink),
                   rgba(accent), label=brand.initial)
        return image
    return supersample(size, draw_at)


def foreground(brand, size=1024):
    """Android adaptive foreground: the mark alone, inside the safe circle."""
    return _alone(brand, size, 0.215, brand.ink, brand.accent)


def monochrome(brand, size=1024):
    """Android themed icons want one flat colour on transparent."""
    return _alone(brand, size, 0.215, WHITE, WHITE)


def splash(brand, size=768, dark=False):
    """The launch mark on transparent. It stays well inside the middle third,
    which is all that Android 12 shows, cropped to a circle."""
    if dark:
        return _alone(brand, size, 0.22, brand.splash_dark_ink, brand.accent)
    return _alone(brand, size, 0.22, brand.splash_light_ink, brand.accent)


def maskable(brand, size=512):
    """Web install icon: the mark smaller, so a circular mask cannot clip it."""
    def draw_at(s):
        image = ground(s, s, brand.primary, brand.ground_end).convert('RGBA')
        brand.mark(ImageDraw.Draw(image), s / 2, s / 2, s * 0.215,
                   rgba(brand.ink), rgba(brand.accent), label=brand.initial)
        return image.convert('RGB')
    return supersample(size, draw_at)


def fitted(draw, text, path, size, limit, floor):
    """The largest face from `size` down to `floor` that keeps `text` within
    `limit` pixels. It raises rather than shrinking for ever, so a long name
    cannot quietly end up unreadable or off the card."""
    while size >= floor:
        face = typeface(path, size)
        if draw.textlength(text, font=face) <= limit:
            return face
        size -= 2
    raise ValueError('%r does not fit in %d pixels even at size %d; shorten it '
                     'in make_icon.py' % (text, limit, floor))


def _banner(brand, width, height, mark_x, half, text_x, name_size, tag_size):
    image = ground(width, height, brand.primary, brand.ground_end).convert('RGBA')
    brand.mark(ImageDraw.Draw(image), width * mark_x, height / 2, half,
               rgba(brand.ink), rgba(brand.accent), label=brand.initial)
    draw = ImageDraw.Draw(image)
    x = width * text_x
    limit = width - x - width * 0.05
    name = fitted(draw, brand.name, brand.font, name_size, limit, 36)
    draw.text((x, height * 0.50), brand.name, font=name, fill=brand.ink, anchor='ls')
    draw.rounded_rectangle([x, height * 0.56, x + width * 0.09, height * 0.56 + 6],
                           radius=3, fill=brand.accent)
    tag = fitted(draw, brand.tagline, brand.font, tag_size, limit, 18)
    draw.text((x, height * 0.72), brand.tagline, font=tag,
              fill=mix(brand.ink, brand.primary, 0.2), anchor='ls')
    return image.convert('RGB')


def social_card(brand, width=1200, height=630):
    """The card that shows when the site's link is shared.

    It is set in Latin only. Pillow here may be built without Raqm, and
    unshaped Devanagari or Arabic puts the marks in the wrong place, which is
    worse than not setting the name at all.
    """
    return _banner(brand, width, height, 0.19, height * 0.27, 0.37, 112, 40)


def feature_graphic(brand, width=1024, height=500):
    """The banner Play shows at the top of the listing: 1024 x 500, RGB, no alpha."""
    return _banner(brand, width, height, 0.19, height * 0.28, 0.37, 96, 34)


def preview_sheet(brand, size=256):
    """Every built-in mark on the app's own ground, for choosing between them."""
    names = sorted(MARKS)
    pad = 24
    label = typeface(None, 20)
    sheet = Image.new('RGB', (pad + len(names) * (size + pad), size + 2 * pad + 28),
                      (245, 245, 245))
    draw = ImageDraw.Draw(sheet)
    for i, name in enumerate(names):
        chosen = Brand(brand.name, brand.tagline, '#%02x%02x%02x' % brand.primary,
                       '#%02x%02x%02x' % brand.ground_end,
                       '#%02x%02x%02x' % brand.accent, '#%02x%02x%02x' % brand.ink,
                       '#%02x%02x%02x' % brand.light_bg,
                       '#%02x%02x%02x' % brand.dark_bg, mark=name,
                       font=brand.font, initial=brand.initial)
        x = pad + i * (size + pad)
        sheet.paste(app_icon(chosen, size), (x, pad))
        draw.text((x, pad + size + 8), name, font=label, fill=(40, 40, 40))
    return sheet


# --- the whole set ----------------------------------------------------------

def save(image, root, *parts):
    path = os.path.join(root, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    image.save(path)
    return os.path.join(*parts)


def write_all(brand, root='.'):
    """Writes every image the launch needs and returns the paths it wrote."""
    out = []
    branding = ('assets', 'branding')
    out.append(save(app_icon(brand, 1024), root, *branding, 'icon-1024.png'))
    out.append(save(foreground(brand), root, *branding, 'icon-foreground.png'))
    out.append(save(monochrome(brand), root, *branding, 'icon-monochrome.png'))
    out.append(save(maskable(brand), root, *branding, 'icon-maskable-512.png'))
    out.append(save(app_icon(brand, 512), root, *branding, 'icon-512.png'))
    out.append(save(app_icon(brand, 192), root, *branding, 'icon-192.png'))
    out.append(save(app_icon(brand, 96), root, *branding, 'icon-96.png'))
    out.append(save(splash(brand), root, *branding, 'splash-light.png'))
    out.append(save(splash(brand, dark=True), root, *branding, 'splash-dark.png'))
    # Optical sizing: below about sixty pixels the fine detail turns to mesh,
    # so the small renders ask the mark for its simplified form.
    for small in (16, 32, 48):
        out.append(save(app_icon(brand, small, small=True), root, *branding,
                        'icon-%d.png' % small))

    out.append(save(social_card(brand), root, 'site', 'og-image.png'))
    out.append(save(app_icon(brand, 48, small=True), root, 'site', 'favicon.png'))

    out.append(save(feature_graphic(brand), root, 'store', 'play', 'feature-graphic.png'))
    out.append(save(app_icon(brand, 512), root, 'store', 'play', 'icon-512.png'))

    # The web icons are written here, not by flutter_launcher_icons, because a
    # plain downscale of the 1024 pixel icon loses the small optical size.
    if os.path.isdir(os.path.join(root, 'web')):
        out.append(save(app_icon(brand, 48, small=True), root, 'web', 'favicon.png'))
        for name, image in (('Icon-192.png', app_icon(brand, 192)),
                            ('Icon-512.png', app_icon(brand, 512)),
                            ('Icon-maskable-192.png', maskable(brand, 192)),
                            ('Icon-maskable-512.png', maskable(brand, 512))):
            out.append(save(image, root, 'web', 'icons', name))
    return out

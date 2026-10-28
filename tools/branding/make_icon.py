"""Draws the Brandhoop icon and the images the stores and the web need.

The drawing itself is in launchkit_draw.py next to this file; what is chosen
here is only the colours, the words on the cards and which mark to draw. The
colours were worked out from the two you gave launchkit: the ink is whichever
of white and near-black reads better on the primary, and the ground fades from
the primary to a shade of it so the mark has something to sit on.

    python3 tools/branding/make_icon.py                 # draw everything
    python3 tools/branding/make_icon.py --preview       # every mark, side by side
    python3 tools/branding/make_icon.py --mark wave     # try another mark
    python3 tools/branding/make_icon.py --mark path/to/mark.py

Then let the tools turn its output into the Android and iOS icons and splash
screens. They need `flutter pub add --dev flutter_launcher_icons
flutter_native_splash` once, and their settings are already in
flutter_launcher_icons.yaml and flutter_native_splash.yaml:

    dart run flutter_launcher_icons
    dart run flutter_native_splash:create

Needs Pillow: python3 -m pip install pillow
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import launchkit_draw as draw  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

# The brand. Hex strings, so the same values can go in the manifest and the site.
PRIMARY = '#283593'
ACCENT = '#FF8F00'
INK = '#FFFFFF'
GROUND_END = '#182058'
# The launch screen's two backgrounds. flutter_native_splash.yaml and
# web/manifest.json carry the same values; change them in all three places.
LIGHT_BG = '#F2F3F9'
DARK_BG = '#070A1A'

# The words on the social card and the Play feature graphic. Keep them Latin:
# Pillow here may be built without Raqm, and unshaped Indic or Arabic text puts
# the marks in the wrong place.
WORDMARK = 'Brandhoop'
TAGLINE = 'Your mobile shop in Neem Ka Thana, in your pocket'

# The mark: a name from `--preview`, or the path to a .py file defining `mark`.
MARK = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'hoop_mark.py')

# A .ttf to set the wordmark in, so the cards match the app. None uses the
# font that ships inside Pillow.
FONT = None


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    parser.add_argument('--mark', default=MARK)
    parser.add_argument('--preview', action='store_true',
                        help='write build/branding-preview.png and stop')
    args = parser.parse_args()

    try:
        brand = draw.Brand(WORDMARK, TAGLINE, PRIMARY, GROUND_END, ACCENT, INK,
                           LIGHT_BG, DARK_BG, mark=args.mark, font=FONT)
        if args.preview:
            path = os.path.join(ROOT, 'build', 'branding-preview.png')
            os.makedirs(os.path.dirname(path), exist_ok=True)
            draw.preview_sheet(brand).save(path)
            print('wrote %s' % path)
            return
        if 'Replace this' in TAGLINE:
            # The tagline lands on the feature graphic and the social card,
            # which are what people see first; the placeholder must not ship.
            sys.exit('Set TAGLINE in %s before drawing the cards.' % __file__)
        written = draw.write_all(brand, ROOT)
    except ValueError as why:
        # A mark that does not exist, or a name too long for its card: both
        # are choices made in this file, so say so rather than show a trace.
        sys.exit('make_icon: %s' % why)
    print('wrote %d images: assets/branding, site/og-image.png, site/favicon.png, '
          'store/play and the web icons' % len(written))


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Fails while the launch material still holds launchkit's placeholders or
breaks a limit that Play enforces.

launchkit leaves text in store/, site/ and test/ that says what has to be
written (LAUNCHKIT-UNEDITED) or which claim has to be made true for this app
(LAUNCHKIT-MAKE-TRUE). Left in place, that text would be uploaded as the
listing or published as the privacy policy, so the release workflow runs this
before it builds and it exits non-zero until every marker is gone.

    python3 tools/store/check_store.py            # from the repository root
    python3 tools/store/check_store.py --root ../some-app

It reads only the standard library, so CI needs nothing installed for it.
"""
import argparse
import pathlib
import struct
import sys

MARKERS = ('LAUNCHKIT-UNEDITED', 'LAUNCHKIT-MAKE-TRUE')

# The limits Play enforces on listing text, and the same numbers play.py checks
# at upload time. Finding them here is cheaper than finding them there.
LISTING_LIMITS = {
    'title.txt': 30,
    'short_description.txt': 80,
    'full_description.txt': 4000,
}
WHATSNEW_LIMIT = 500

# Everything that carries marker text, relative to the root.
MARKED_FILES = (
    'site/privacy.html',
    'site/terms.html',
    'store/README.md',
    'test/store_screenshots_test.dart',
)

PNG_SIGNATURE = b'\x89PNG\r\n\x1a\n'
RGB_WITH_ALPHA = (4, 6)  # greyscale+alpha, RGBA


class Report:
    def __init__(self):
        self.errors = []
        self.warnings = []

    def error(self, path, message):
        self.errors.append((path, message))

    def warn(self, path, message):
        self.warnings.append((path, message))


def png_info(path):
    """(width, height, has_alpha), or None if the file is not a PNG."""
    with open(path, 'rb') as handle:
        head = handle.read(33)
    if len(head) < 26 or head[:8] != PNG_SIGNATURE:
        return None
    width, height = struct.unpack('>II', head[16:24])
    return width, height, head[25] in RGB_WITH_ALPHA


def find_marker(path):
    """(line number, marker) of the first placeholder in a text file."""
    try:
        text = path.read_text(encoding='utf-8')
    except (OSError, UnicodeDecodeError):
        return None
    for number, line in enumerate(text.splitlines(), 1):
        for marker in MARKERS:
            if marker in line:
                return number, marker
    return None


def check_markers(root, report):
    candidates = [root / name for name in MARKED_FILES]
    candidates += [p for p in sorted((root / 'store').rglob('*'))
                   if p.is_file() and p.suffix in ('.txt', '.md', '') and
                   p.name not in ('.gitkeep', '.DS_Store')]
    seen = set()
    for path in candidates:
        if path in seen or not path.is_file():
            continue
        seen.add(path)
        hit = find_marker(path)
        if hit:
            line, marker = hit
            report.error(path.relative_to(root),
                         'still has %s on line %d: write it, then delete the marker'
                         % (marker, line))


def locale_dirs(root, report):
    play = root / 'store' / 'play'
    if not play.is_dir():
        report.error('store/play', 'missing: there is no listing to upload')
        return []
    found = []
    for folder in sorted(p for p in play.iterdir() if p.is_dir()):
        if not (folder / 'title.txt').exists():
            # play.py decides what is a locale by the presence of title.txt, so
            # a folder without one is skipped without a word.
            report.error(folder.relative_to(root),
                         'has no title.txt, so play.py would silently skip this locale')
            continue
        found.append(folder)
    if not found:
        report.error('store/play', 'has no locale folder with a title.txt')
    return found


def check_listing(root, folder, report):
    for name, limit in LISTING_LIMITS.items():
        path = folder / name
        relative = path.relative_to(root)
        if not path.exists():
            report.error(relative, 'missing')
            continue
        text = path.read_text(encoding='utf-8').strip()
        if not text:
            report.error(relative, 'is empty')
        elif len(text) > limit:
            report.error(relative, '%d characters; Play allows %d' % (len(text), limit))
    title = folder / 'title.txt'
    short = folder / 'short_description.txt'
    if title.exists() and short.exists() and \
            title.read_text('utf-8').strip() == short.read_text('utf-8').strip():
        report.warn(folder.relative_to(root), 'title and short description are identical')


def check_whatsnew(root, locales, report):
    folder = root / 'store' / 'whatsnew'
    for locale in locales:
        path = folder / ('whatsnew-' + locale)
        relative = path.relative_to(root)
        if not path.exists():
            report.warn(relative, 'missing: this locale will ship with no release notes')
            continue
        text = path.read_text(encoding='utf-8').strip()
        if not text:
            report.error(relative, 'is empty')
        elif len(text) > WHATSNEW_LIMIT:
            report.error(relative, '%d characters; Play allows %d'
                         % (len(text), WHATSNEW_LIMIT))
    if folder.is_dir():
        for path in sorted(folder.glob('whatsnew-*')):
            if path.name.replace('whatsnew-', '') not in locales:
                report.warn(path.relative_to(root), 'has no listing for that locale')


def check_graphics(root, report):
    icon = root / 'store' / 'play' / 'icon-512.png'
    feature = root / 'store' / 'play' / 'feature-graphic.png'
    for path, size, alpha_ok in ((icon, (512, 512), True),
                                 (feature, (1024, 500), False)):
        relative = path.relative_to(root)
        if not path.exists():
            report.error(relative, 'missing: run tools/branding/make_icon.py')
            continue
        info = png_info(path)
        if info is None:
            report.error(relative, 'is not a PNG')
        elif info[:2] != size:
            report.error(relative, 'is %d x %d; Play wants %d x %d' % (info[:2] + size))
        elif info[2] and not alpha_ok:
            report.error(relative, 'has an alpha channel; Play wants 24-bit')

    shots = sorted((root / 'store' / 'screenshots').glob('*.png'))
    if len(shots) < 2:
        report.error('store/screenshots',
                     '%d phone screenshots; Play needs at least 2' % len(shots))
    if len(shots) > 8:
        report.warn('store/screenshots',
                    '%d screenshots; play.py uploads only the first 8' % len(shots))
    for path in shots[:8]:
        relative = path.relative_to(root)
        info = png_info(path)
        if info is None:
            report.error(relative, 'is not a PNG')
            continue
        width, height, alpha = info
        short, long = sorted((width, height))
        if short < 320 or long > 3840:
            report.error(relative, 'is %d x %d; each side must be 320 to 3840' % (width, height))
        elif long > 2 * short:
            report.error(relative, 'is %d x %d; the long side may be at most twice the short'
                         % (width, height))
        if alpha:
            report.error(relative, 'has an alpha channel; Play wants 24-bit PNG screenshots')


def check_site(root, report):
    for name in ('site/privacy.html', 'site/terms.html'):
        if not (root / name).is_file():
            report.error(name, 'missing: Play requires a privacy policy at a public URL')


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    parser.add_argument('--root', default='.', help='the app repository (default: .)')
    args = parser.parse_args()
    root = pathlib.Path(args.root).resolve()

    report = Report()
    check_markers(root, report)
    folders = locale_dirs(root, report)
    for folder in folders:
        check_listing(root, folder, report)
    check_whatsnew(root, [f.name for f in folders], report)
    check_graphics(root, report)
    check_site(root, report)

    for path, message in report.warnings:
        print('warn  %s: %s' % (path, message))
    for path, message in report.errors:
        print('FAIL  %s: %s' % (path, message))
    if report.errors:
        print('\n%d problem(s). Nothing should be uploaded until they are gone.'
              % len(report.errors))
        sys.exit(1)
    print('store/ and site/ are clean: %d locale(s), listing within limits.' % len(folders))


if __name__ == '__main__':
    main()

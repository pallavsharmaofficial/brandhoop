#!/usr/bin/env python3
"""Looks for clearly licensed photos of each phone on Wikimedia Commons and lists
them in tools/models3d/photos_manifest.json (author, licence, page URL). Nothing is
downloaded here; pick the good ones by eye and run process_photos.py on them.

    python3 tools/models3d/search_commons.py [--force] [product-id ...]

A hit counts only if the file title/description contains every word of the model
name, so a sibling model is never listed as the phone itself.
"""
import json, pathlib, re, sys, time, urllib.error, urllib.parse, urllib.request, html

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = pathlib.Path(__file__).with_name('photos_manifest.json')
API = 'https://commons.wikimedia.org/w/api.php'
OK = re.compile(r'^(cc0|pd|public domain|cc[- ]by(?![- ]nc)(?![- ]nd)|cc[- ]by-sa)', re.I)


def api(**kw):
    """One API call. Waits and retries on 429/5xx; raises if it still fails, so a
    failed search is never saved as "no photos"."""
    kw.update(format='json')
    req = urllib.request.Request(API + '?' + urllib.parse.urlencode(kw), headers={'User-Agent': 'brandhoop-catalog/1.0'})
    err = None
    for i in range(7):
        try:
            time.sleep(1.2)
            return json.load(urllib.request.urlopen(req, timeout=30))
        except urllib.error.HTTPError as e:
            err = e
            if e.code not in (429, 500, 502, 503, 504): raise
            time.sleep(int(e.headers.get('Retry-After') or 0) or 20 * (i + 1))
        except Exception as e:  # noqa
            err = e; time.sleep(5 * (i + 1))
    raise err


def toks(name): return re.findall(r'[a-z0-9]+', re.sub(r'\b5G\b', '', name, flags=re.I).lower())


def main():
    force = '--force' in sys.argv; only = [a for a in sys.argv[1:] if not a.startswith('--')]
    shop = json.load(open(ROOT / 'assets/live/shop.json'))
    man = json.load(open(OUT)) if OUT.exists() else {}
    for p in shop['products']:
        if p['category'] not in ('smartphone', 'tablet', 'featurePhone') or (only and p['id'] not in only): continue
        if p['id'] in man and not force: continue
        name = p['name']['en']; want = toks(name); hits = {}
        for q in (re.sub(r'\s*5G\s*$', '', name), name):
            r = api(action='query', generator='search', gsrsearch=q, gsrnamespace=6, gsrlimit=20, prop='imageinfo',
                    iiprop='url|extmetadata|size|mime')
            for pg in (r.get('query', {}).get('pages', {}) or {}).values():
                ii = (pg.get('imageinfo') or [{}])[0]; md = ii.get('extmetadata', {})
                title = pg['title']; text = (title + ' ' + html.unescape(re.sub('<[^>]+>', ' ', md.get('ImageDescription', {}).get('value', '')))).lower()
                words = set(re.findall(r'[a-z0-9]+', text))
                lic = md.get('LicenseShortName', {}).get('value', '')
                if not set(want) <= words or not OK.match(lic) or not ii.get('mime', '').startswith('image/'): continue
                hits[title] = {'file': title[5:], 'author': html.unescape(re.sub('<[^>]+>', '', md.get('Artist', {}).get('value', ''))).strip(),
                               'license': lic, 'licenseUrl': md.get('LicenseUrl', {}).get('value', ''),
                               'page': 'https://commons.wikimedia.org/wiki/' + urllib.parse.quote(title.replace(' ', '_')),
                               'url': ii.get('url', ''), 'width': ii.get('width'), 'height': ii.get('height')}
        man[p['id']] = {'name': name, 'searched': time.strftime('%Y-%m-%d'), 'photos': list(hits.values())}
        print(p['id'], len(hits)); [print('   ', h['license'], h['file'], '|', h['author'][:30]) for h in hits.values()]
    OUT.write_text(json.dumps(man, ensure_ascii=False, indent=1))


main()

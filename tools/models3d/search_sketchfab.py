#!/usr/bin/env python3
"""Searches Sketchfab (public API, no token) for CC0 / CC BY downloadable 3D
models of every phone in assets/live/shop.json and writes candidates into
tools/models3d/manifest.json. Products already in the manifest are skipped
(pass --force to search again), so nothing is searched twice.

    python3 tools/models3d/search_sketchfab.py [--force] [product-id ...]

Only licences that allow commercial use and changes are kept: cc0 and by.
A candidate is "exact" only if every word of the phone's model name is in the
Sketchfab title and the title adds no variant word of its own (so "V80 Lite"
is not the V80). Anything else is "similar": it needs a person's approval
("approved": true in the manifest) and is then attached as representative.
"""
import json, pathlib, re, sys, time, urllib.parse, urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
MAN = pathlib.Path(__file__).with_name('manifest.json')
API = 'https://api.sketchfab.com/v3/search'
PHONE_CATS = {'smartphone', 'tablet', 'featurePhone'}
OK_LICENSES = ('cc0', 'by')
LICENSE_URL = {'cc0': 'https://creativecommons.org/publicdomain/zero/1.0/',
               'by': 'https://creativecommons.org/licenses/by/4.0/'}
VARIANT_WORDS = {'lite', 'pro', 'fe', 'plus', 'max', 'ultra', 'mini', 'neo', 'edge', 'x', 'e', 's', 'c', 'y', 't', 'turbo', 'flip', 'fold'}


def get(url):
    err = None
    for i in range(3):
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'brandhoop-catalog/1.0'})
            return json.load(urllib.request.urlopen(req, timeout=30))
        except Exception as e:  # noqa
            err = e; time.sleep(2 * (i + 1))
    raise err


def tokens(name):
    return re.findall(r'[a-z0-9]+', re.sub(r'\b5G\b', '', name, flags=re.I).lower())


def queries(name):
    n = re.sub(r'\s*5G\s*$', '', name, flags=re.I).strip()
    bare = re.sub(r'^(vivo|oppo)\s+', '', n, flags=re.I)
    out = []
    for x in (n, name, bare + ' phone'):
        if x.lower() not in [o.lower() for o in out]: out.append(x)
    return out


def slug(label):
    l = (label or '').lower()
    if 'cc0' in l or 'public domain' in l: return 'cc0'
    return 'by' if l.strip() == 'cc attribution' else ''


def verdict(name, title):
    want = set(tokens(name)); have = set(re.findall(r'[a-z0-9]+', title.lower()))
    return 'exact' if want <= have and not ((have & VARIANT_WORDS) - want) else 'similar'


def search(name):
    found = {}
    for q in queries(name):
        for lic in OK_LICENSES:
            url = API + '?' + urllib.parse.urlencode({'type': 'models', 'q': q, 'downloadable': 'true', 'license': lic, 'count': 24})
            for r in get(url).get('results', []): found[r['uid']] = r
    return list(found.values())


def main():
    force = '--force' in sys.argv
    only = [a for a in sys.argv[1:] if not a.startswith('--')]
    shop = json.load(open(ROOT / 'assets/live/shop.json'))
    man = json.load(open(MAN)) if MAN.exists() else {}
    for p in shop['products']:
        if p['category'] not in PHONE_CATS or (only and p['id'] not in only): continue
        if p['id'] in man and not force: print('cached', p['id']); continue
        name = p['name']['en']; cands = []
        for r in search(name):
            lic = slug((r.get('license') or {}).get('label', ''))
            if lic not in OK_LICENSES: continue
            cands.append({'uid': r['uid'], 'title': r['name'], 'author': (r.get('user') or {}).get('displayName', ''),
                          'license': lic, 'licenseLabel': r['license']['label'], 'licenseUrl': LICENSE_URL[lic],
                          'url': r.get('viewerUrl', ''), 'faces': r.get('faceCount'), 'verdict': verdict(name, r['name'])})
        cands.sort(key=lambda c: (c['verdict'] != 'exact', c['faces'] or 0))
        man[p['id']] = {'name': name, 'searched': time.strftime('%Y-%m-%d'), 'candidates': cands,
                        'status': 'candidates' if cands else 'none'}
        print(p['id'], '->', len(cands), 'candidates;', sum(c['verdict'] == 'exact' for c in cands), 'exact')
        for c in cands[:6]: print('   ', c['verdict'], c['license'], '|', c['title'], '|', c['author'], '|', c['uid'], '|', c['faces'])
    MAN.write_text(json.dumps(man, ensure_ascii=False, indent=1))


main()

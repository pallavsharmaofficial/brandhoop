#!/usr/bin/env python3
"""Download -> optimise -> poster -> manifest, for the models a person has chosen.

    python3 tools/models3d/search_sketchfab.py            # 1. find candidates (cached)
    # 2. look at tools/models3d/manifest.json and, for each phone, put the uid of the right
    #    candidate in "choice". Never choose a sibling model for an exact slot: a sibling
    #    needs "representative": true as well, and it is then shown as "Representative model".
    python3 tools/models3d/pipeline.py [--force] [product-id ...]    # 3. build
    python3 tools/models3d/attach.py                      # 4. write shop.json

Needs: the Sketchfab token (the session proxy adds it, or export SKETCHFAB_TOKEN),
npm install in tools/models3d, Playwright's Chromium.
"""
import json, pathlib, subprocess, sys, time, contextlib, socket

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
MAN = HERE / 'manifest.json'
RAW = 'https://raw.githubusercontent.com/pallavsharmaofficial/brandhoop/main/'
LICENSE_NAME = {'by': 'CC BY 4.0', 'cc0': 'CC0 1.0'}


def run(*a, **k): return subprocess.run(a, check=True, cwd=k.get('cwd', ROOT), capture_output=True, text=True)


def main():
    force = '--force' in sys.argv
    only = [a for a in sys.argv[1:] if not a.startswith('--')]
    man = json.loads(MAN.read_text())
    todo = [pid for pid, e in man.items() if e.get('choice') and (not only or pid in only) and (force or 'model3d' not in e)]
    if not todo: print('nothing to do'); return
    s = socket.socket(); s.bind(('127.0.0.1', 0)); port = s.getsockname()[1]; s.close()
    srv = subprocess.Popen([sys.executable, '-m', 'http.server', str(port)], cwd=ROOT / 'site', stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(1)
    try:
        for pid in todo:
            e = man[pid]
            c = next((c for c in e['candidates'] if c['uid'] == e['choice']), None)
            if not c: print('no such candidate for', pid); continue
            exact = c['verdict'] == 'exact' and not e.get('representative')
            if c['verdict'] != 'exact' and not e.get('representative'):
                print('skip', pid, ': a sibling model needs "representative": true (a person must approve it)'); continue
            run(sys.executable, 'tools/models3d/download_sketchfab.py', pid, c['uid'])
            r = run('node', 'tools/models3d/optimize.mjs', pid)
            kb = json.loads(r.stdout.strip().splitlines()[-1])['sizeKb']
            run('node', 'tools/models3d/render_poster.cjs', pid, f'http://127.0.0.1:{port}')
            e['model3d'] = {
                'glb': f'{RAW}site/models/{pid}.glb', 'poster': f'{RAW}site/models/{pid}.webp',
                'title': c['title'], 'author': c['author'], 'license': LICENSE_NAME[c['license']], 'licenseUrl': c['licenseUrl'],
                'attributionRequired': c['license'] == 'by', 'sourceName': 'Sketchfab', 'sourceUrl': c['url'],
                'exact': exact, 'sizeKb': kb,
            }
            e['status'] = 'attached' if exact else 'representative'
            MAN.write_text(json.dumps(man, ensure_ascii=False, indent=1))
            print('ok', pid, kb, 'KB', 'exact' if exact else 'representative')
    finally:
        srv.terminate()


main()

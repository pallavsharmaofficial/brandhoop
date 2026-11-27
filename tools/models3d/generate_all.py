#!/usr/bin/env python3
"""Illustrative 3D models for phones that have no real downloadable model.

    python3 tools/models3d/build_specs.py              # sizes, colours, camera layout -> specs/<id>.json
    python3 tools/models3d/generate_all.py [id ...]    # build, optimise, poster, manifest entry
    python3 tools/models3d/attach.py                   # write model3d into shop.json

Needs a static server on site/ is NOT required: the poster step starts its own. The models are
generated from numbers (see generate_phone.mjs), so they are ours (CC0). They are marked
generated: true and exact: false, and the product page says so.
"""
import json, pathlib, socket, subprocess, sys, time

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
MAN = HERE / 'manifest.json'
RAW = 'https://raw.githubusercontent.com/pallavsharmaofficial/brandhoop/main/'


def run(*a): return subprocess.run(a, check=True, cwd=ROOT, capture_output=True, text=True)


def main():
    only = [a for a in sys.argv[1:] if not a.startswith('--')]
    ids = sorted(p.stem for p in (HERE / 'specs').glob('*.json') if not only or p.stem in only)
    man = json.loads(MAN.read_text()) if MAN.exists() else {}
    s = socket.socket(); s.bind(('127.0.0.1', 0)); port = s.getsockname()[1]; s.close()
    srv = subprocess.Popen([sys.executable, '-m', 'http.server', str(port)], cwd=ROOT / 'site', stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(1)
    try:
        for pid in ids:
            spec = json.loads((HERE / 'specs' / f'{pid}.json').read_text())
            run('node', 'tools/models3d/generate_phone.mjs', pid)
            kb = json.loads(run('node', 'tools/models3d/optimize.mjs', pid).stdout.strip().splitlines()[-1])['sizeKb']
            run('node', 'tools/models3d/render_poster.cjs', pid, f'http://127.0.0.1:{port}')
            e = man.setdefault(pid, {'name': spec['name'], 'candidates': []})
            if e.get('status') in ('attached', 'representative'): print('keeps its real model:', pid); continue
            e['status'] = 'generated'
            e['model3d'] = {
                'glb': f'{RAW}site/models/{pid}.glb', 'poster': f'{RAW}site/models/{pid}.webp',
                'title': f"{spec['name']}, illustrative model", 'author': 'Brandhoop', 'license': 'CC0 1.0',
                'licenseUrl': 'https://creativecommons.org/publicdomain/zero/1.0/', 'attributionRequired': False,
                'sourceName': 'Brandhoop', 'sourceUrl': '', 'exact': False, 'generated': True, 'sizeKb': kb,
            }
            MAN.write_text(json.dumps(man, ensure_ascii=False, indent=1))
            print('ok', pid, kb, 'KB', spec['confidence'])
    finally:
        srv.terminate()


main()

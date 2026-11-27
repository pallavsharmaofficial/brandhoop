#!/usr/bin/env python3
"""Downloads the glb of an accepted candidate into tools/models3d/raw/ (git-ignored).

    python3 tools/models3d/download_sketchfab.py <product-id> <uid>

The Sketchfab API token is never read by this script: the session's network
proxy adds the Authorization header. Outside that setup export SKETCHFAB_TOKEN.
"""
import json, os, pathlib, sys, urllib.request

HERE = pathlib.Path(__file__).resolve().parent
pid, uid = sys.argv[1], sys.argv[2]
H = {'User-Agent': 'brandhoop-catalog/1.0'}
if os.environ.get('SKETCHFAB_TOKEN'): H['Authorization'] = 'Token ' + os.environ['SKETCHFAB_TOKEN']
info = json.load(urllib.request.urlopen(urllib.request.Request(f'https://api.sketchfab.com/v3/models/{uid}/download', headers=H), timeout=30))
(HERE / 'raw').mkdir(exist_ok=True)
out = HERE / 'raw' / f'{pid}.glb'
out.write_bytes(urllib.request.urlopen(urllib.request.Request(info['glb']['url'], headers={'User-Agent': H['User-Agent']}), timeout=120).read())
print('saved', out, out.stat().st_size // 1024, 'KB')

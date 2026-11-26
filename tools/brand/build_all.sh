#!/usr/bin/env bash
# Rebuilds every logo, print, social and icon file, then the Android/iOS icon resources.
# Run from the repo root:  bash tools/brand/build_all.sh
set -euo pipefail
python3 tools/brand/logo.py
python3 tools/brand/make_assets.py
(cd tools/brand && node shoot.js)
python3 tools/brand/resize_icons.py
python3 tools/brand/make_brand_page.py
dart run flutter_launcher_icons
dart run flutter_native_splash:create

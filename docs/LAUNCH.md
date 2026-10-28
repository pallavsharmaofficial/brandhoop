# Launching Brandhoop

How this repository gets onto Google Play and stays there. The launch layer
was added by launchkit on 28 October 2026; the ordered list of what still needs a
human is `docs/PLAY_SETUP.md`, and nothing below claims a step is done until
you have done it.

## What the launch layer gives this repository

| What | Where |
|---|---|
| The icon, the Android adaptive pieces, the splash mark, the web icons, the social card and the Play feature graphic, all drawn in code | `tools/branding/make_icon.py`, using `tools/branding/launchkit_draw.py` |
| What the Android and iOS icon and splash tools read | `flutter_launcher_icons.yaml`, `flutter_native_splash.yaml` |
| The Play listing text, per locale (en-IN, hi-IN) | `store/play/<locale>/` |
| Release notes, per locale | `store/whatsnew/` |
| Screenshots | `store/screenshots/` |
| The answers to the forms Google will not let a machine fill in | `store/README.md` |
| A check that none of the above still contains placeholder text | `tools/store/check_store.py` |
| A privacy policy and terms, to be made true | `site/privacy.html`, `site/terms.html` |
| Signed release builds in CI, and the upload | `.github/workflows/release-play.yml`, which calls the reusable workflow in launchkit |

The package name is `in.pallavsharma.brandhoop`. Play fixes it at the first upload and it can
never be changed after that.

## Checks before each release

```bash
flutter analyze
flutter test
python3 tools/store/check_store.py
flutter build appbundle --release
```

The release workflow runs the first three before it builds, so a listing that
still says LAUNCHKIT-UNEDITED, or a privacy page with an unchecked claim in it,
stops the release instead of reaching Play.

If the web app is published too, build it with
`flutter build web --release --base-href "/brandhoop/app/"`.

## Shipping an update

1. Raise `version:` in `pubspec.yaml`. It is `0.1.0+1` now. The number
   after the `+` must be higher than any build Play has already seen; the name
   before it is what people read.
2. Write what changed in `store/whatsnew/whatsnew-<locale>`, for every locale.
3. Push a `v*` tag for an internal build, or run **Release to Google Play**
   from the Actions tab and choose the track. `docs/PLAY_SETUP.md` explains
   the tracks and the staged rollout.

## Changing the icon

```bash
python3 tools/branding/make_icon.py --preview     # every mark, side by side
python3 tools/branding/make_icon.py --mark wave   # draw with another mark
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

`flutter_launcher_icons` also rewrites one setting in
`ios/Runner.xcodeproj/project.pbxproj`
(`ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` becomes
`AppIcon`). Put it back to `YES` before committing.

Change the colours, the tagline or the typeface at the top of `make_icon.py`.
The cards are set in Latin only: Pillow may be built without Raqm, and unshaped
Devanagari or Arabic puts the marks in the wrong place.

## Updating launchkit's own files in this repository

`tools/branding/launchkit_draw.py`, `tools/store/check_store.py` and the
caller workflow are copies. To take a newer version, run launchkit's
`scaffold/new_app.py` again with the same arguments and
`--force --only tools/branding/launchkit_draw.py` (or the file you want). It
saves the old file next to the new one as `.bak` first.

## Release blockers for Brandhoop

Do not submit to Play until every line is done.

1. The app is in **demo mode with mock payments and a fixed OTP** (`123456`).
   Complete stage 1 of `docs/ROADMAP.md` first, then build with
   `--dart-define=BRANDHOOP_DEMO=false`.
2. Replace the sample catalogue and the placeholder shop details (`README.md`).
3. Update `site/privacy.html` and `store/README.md` for the backend and payment
   provider, and re-answer the Play data safety form.
4. Confirm the developer name in `site/privacy.html` (the last yellow mark), then
   `python3 tools/store/check_store.py` must pass.
5. Re-take `store/screenshots/` from the real-data build, without the demo banner.
6. Publish `site/` (for example with GitHub Pages) so the privacy URL loads.
7. Check the merged Android manifest permissions against the privacy page.
8. The screenshots in the repo were taken from the web build of the demo. Do not
   upload them as they are.

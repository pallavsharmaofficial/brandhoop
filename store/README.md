# Store listing

Everything a Play submission needs, so the Console is copy and paste. Each
answer below that is still a placeholder is a decision only you can make: write
it, delete the placeholder, and `python3 tools/store/check_store.py` will stop
complaining.

| File | Where it goes |
|---|---|
| `play/en-IN/title.txt` | Play Console, Main store listing, App name (30 characters) |
| `play/en-IN/short_description.txt` | Short description (80 characters) |
| `play/en-IN/full_description.txt` | Full description (4,000 characters) |
| `play/<locale>/*` | The same three fields for each other locale: en-IN, hi-IN |
| `whatsnew/whatsnew-<locale>` | Release notes (500 characters), sent with every upload |

`play.py listing` and `play.py graphics` from launchkit push all of these to
Play for an app that already exists; the Console does the same by hand.

## Graphics

| Asset | Size | Source |
|---|---|---|
| App icon | 512 x 512 | `store/play/icon-512.png`, drawn by `tools/branding/make_icon.py` |
| Feature graphic | 1024 x 500, 24-bit, no alpha | `store/play/feature-graphic.png`, same script |
| Phone screenshots | 2 to 8, 24-bit PNG, no alpha, 1080 x 1920 | `store/screenshots/` |

Screenshots are the one asset the icon script cannot draw. Take them from the
real app, or generate them from a widget test: `test/store_screenshots_test.dart`
is a skeleton for that, and it records the rules Play enforces. Look at every
one before uploading: a screenshot that shows a feature the listing does not
mention, or the reverse, is a policy problem.

## Play data safety

Answered from what this build does (local storage only, no server, no SDK that
collects data). **Re-answer every line the day a payment provider or a shop
server is added**, because then orders and contact details leave the phone.

- **Does the app collect or share any of the required user data types?**
  Not in this build. Name, mobile number, addresses, orders and EMI details are
  saved on the phone only and never transmitted. Say "no" to collection and
  sharing. With a backend this becomes yes: personal info (name, phone,
  address), financial info (purchase history, EMI status; card numbers are
  never stored), and app activity.
- **Is all of the user data collected encrypted in transit?**
  Not applicable now, since nothing leaves the device. With a backend: yes, HTTPS only.
- **Can users ask for their data to be deleted?**
  Now: clear storage or uninstall. With a backend: add an in-app delete-account
  action and give the web link Play asks for.
- **Permissions the app declares** (merged manifest, checked by `docs/PLAY_SETUP.md`):
  - `INTERNET`, used only to open directions, calls and WhatsApp links. Re-check
    after adding any plugin.
- **Network requests the app makes.** None of its own. Links open other apps.

## App content declarations

- **Privacy policy URL:** `https://pallavsharmaofficial.github.io/brandhoop/privacy.html`. It must load, with no
  sign-in, before you save the declaration.
- **Ads:** No.
- **Target audience:** 18 and over. Do not include children.
- **App category:** Shopping.
- **Access to the whole app:** Sign-in is by mobile number and one-time code.
  Give the reviewer a demo account only while demo mode is on. For a release
  with real OTP, supply a test number that the SMS provider whitelists.

## Content rating questionnaire

Shopping app. No violence, sexual content, gambling or user-generated content
shared between users. It does let users spend real money (once payments are
live), which the questionnaire asks about under purchases. Answer "yes" there.

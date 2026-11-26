# Phone Doctor (for the shop) and Phone Care (for customers)

## Phone Care: `site/care/` (give this to customers by QR)
A free page that runs on the customer's own phone. Nothing is uploaded.
* **Quick check:** processor speed, screen smoothness (jank), battery level and drain since the last visit, approximate RAM, internet speed.
  These are what a browser can really measure. The score is a rough guide, not a lab test.
* **Hardware tests:** screen colours (dead pixels), touch grid and multi-touch, ghost touch, speaker (left/right), microphone, cameras, vibration,
  sensors, GPS, screen lock. Camera, microphone and location ask permission only when that test is pressed.
* **Clean-up steps:** restart, free storage, remove unused apps, clear cache of heavy apps, clear Chrome's cache, updates, battery drain, lighter home screen,
  animation speed. Each step has the phone-brand path and a "try to open the setting" button (an Android settings link; it may not open on every phone,
  the written steps always work). Progress and a weekly calendar reminder (.ics) bring customers back.
* **Suggestions from the shop** appear between sections only where the result fits (slow phone, battery, screen/touch, hardware, storage), with the Brandhoop app and WhatsApp.
* **What it cannot do:** a web page cannot clear other apps' cache, free RAM or read the phone's real free storage or battery health.
  Android does not allow that without system permissions, and "booster" apps that claim to are usually harmful. The page says so.
  A native app version (with real battery, storage and RAM readings, still without special permissions) is the next step if wanted.
* Poster: `site/brand/print/care-poster-a4.pdf` and `care-poster-a5.pdf` (QR to `/care/`).

## Phone Doctor: admin app, 🩺 button (for Naresh)
Runs checks and fixes on a customer's phone from Naresh's phone over Wi-Fi, with no computer.
Browsers cannot speak ADB, so a small helper runs in **Termux** on Naresh's phone (`tools/doctor/bridge.py`, served at `/doctor/bridge.py`):
1. Install Termux from F-Droid. In Termux: `pkg update -y && pkg install -y python android-tools curl && curl -fsSL https://pallavsharmaofficial.github.io/brandhoop/doctor/install.sh | sh`. Then run `bhdoctor`; it prints a token.
2. In the admin app open 🩺 फ़ोन डॉक्टर, put the token in the settings, tick the customer's consent.
3. Customer's phone (Android 11 or newer, same Wi-Fi): Settings, About phone, tap Build number 7 times, Developer options, Wireless debugging on. "Pair device with pairing code" shows IP:port and a code; enter them (pair), then enter the IP:port on the main Wireless debugging screen (connect).
4. Pick the complaint (hang, battery, heat, storage, ads or scam apps, hardware, slow internet, full check), read the results, fix with one tap after the customer agrees,
   make a report (print or WhatsApp) and record the job and the money earned (kept on Naresh's phone only).

The 22 tools: phone identity, battery health (cycles, capacity, temperature), battery-hungry apps, RAM, storage, CPU/lag, heat, installed apps and sideloads, preloaded junk finder
with disable, scam-app audit (accessibility services, device admins, overlays, sideloaded), sensors, display, Wi-Fi and internet, crash log, animation speed, cache clean, app optimise,
permission viewer with revoke, force-stop, install the Brandhoop app, screenshot, reboot.

### Safety and rules
* The helper listens on 127.0.0.1 only, needs its token, accepts only the shop's website, and runs only the fixed commands in `bridge.py` (never text from the page). Package names are validated.
* Anything that changes the customer's phone needs the customer's consent in the app and `confirm` in the request. Disabled apps can be enabled again; "uninstall" is for the current user.
* Every action is logged in `~/brandhoop-doctor.log` in Termux (time, phone model, action).
* There are no tools to unlock phones, remove Google or screen locks (FRP), or change IMEI, and there will not be. Do not copy a customer's photos, messages or files without being asked.
* Chrome may ask once for "local network" permission so the page can talk to Termux on the same phone. Allow it.
* Parsers (`site/admin/doctor/parse.js`) were tested on realistic Android 13 output and on garbage input; real phones differ, so a check that cannot read something says so instead of guessing.

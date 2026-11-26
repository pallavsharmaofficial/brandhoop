#!/usr/bin/env python3
"""Brandhoop Phone Doctor bridge.

Runs inside Termux on the SHOP OWNER'S phone. It lets the admin web app (opened in Chrome on the same phone) run a fixed list of
diagnostic and repair commands on a CUSTOMER'S phone over Wi-Fi, using Android's Wireless debugging (Android 11 or newer) and the `adb` tool from
Termux's `android-tools` package. No computer is needed.

What it will and will not do
  * Listens on 127.0.0.1 only. Needs the secret token printed at start-up in every request, and only the shop's website may call it (CORS).
  * Runs commands only from the fixed table CMDS below, never text sent by the page. Package names, permissions and numbers are validated.
  * Anything that changes the customer's phone is marked `danger` and is refused unless the request says confirm=true.
  * Every action is written to ~/brandhoop-doctor.log (time, phone model, action) so the shop can show what was done.
  * It has no commands for unlocking phones, removing Google or screen locks, or changing IMEI, and it never will.

Start it:   python3 bridge.py            (prints the token)
Needs:      pkg install python android-tools
"""
import base64, http.server, json, os, re, secrets, shutil, subprocess, sys, tempfile, time, urllib.request

VERSION = '1'
PORT = int(os.environ.get('BH_PORT', '8765'))
ADB = os.environ.get('BH_ADB', 'adb')
HOME = os.path.expanduser('~')
LOG = os.environ.get('BH_LOG', os.path.join(HOME, 'brandhoop-doctor.log'))
TOKEN_FILE = os.environ.get('BH_TOKEN_FILE', os.path.join(HOME, '.brandhoop-bridge-token'))
ORIGINS = {'https://pallavsharmaofficial.github.io'} | {o for o in os.environ.get('BH_EXTRA_ORIGINS', '').split(',') if o}
APK_URL = 'https://pallavsharmaofficial.github.io/brandhoop/download/brandhoop.apk'
MAX_OUT = 400_000

RE_HOSTPORT = re.compile(r'^\d{1,3}(\.\d{1,3}){3}:\d{2,5}$')
RE_CODE = re.compile(r'^\d{6}$')
RE_SERIAL = re.compile(r'^[A-Za-z0-9._:\-]{3,64}$')
RE_PKG = re.compile(r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+$')
RE_PERM = re.compile(r'^android\.permission\.[A-Z0-9_]+$|^com\.android\.[A-Za-z0-9_.]+$')


def sh(s):
    return ['shell', s]


def pkg(a):
    p = str(a.get('pkg', ''))
    if not RE_PKG.match(p): raise ValueError('पैकेज का नाम सही नहीं')
    return p


def perm(a):
    p = str(a.get('perm', ''))
    if not RE_PERM.match(p): raise ValueError('अनुमति का नाम सही नहीं')
    return p


def anim(a):
    v = str(a.get('value', ''))
    if v not in ('0', '0.5', '1', '1.5'): raise ValueError('एनिमेशन की गति 0, 0.5, 1 या 1.5 हो सकती है')
    return sh(f'settings put global window_animation_scale {v}; settings put global transition_animation_scale {v}; settings put global animator_duration_scale {v}')


# id -> (builder(args) -> adb args after "-s serial", timeout seconds, danger)
CMDS = {
    'info': (lambda a: sh('for p in ro.product.manufacturer ro.product.model ro.build.version.release ro.build.version.sdk ro.build.version.security_patch ro.product.cpu.abi ro.build.display.id; do echo "$p=$(getprop $p)"; done; head -1 /proc/meminfo; uptime; wm size; wm density'), 20, False),
    'battery': (lambda a: sh("dumpsys battery; echo ===CYCLE===; cat /sys/class/power_supply/battery/cycle_count 2>/dev/null; echo ===FULL===; cat /sys/class/power_supply/battery/charge_full 2>/dev/null; echo ===DESIGN===; cat /sys/class/power_supply/battery/charge_full_design 2>/dev/null; echo ===CAP===; dumpsys batterystats 2>/dev/null | grep -m1 -i 'Capacity:'"), 30, False),
    'battery_apps': (lambda a: sh("dumpsys batterystats --charged 2>/dev/null | sed -n '/Estimated power use/,/^$/p' | head -60; echo ===PKGS===; pm list packages -U"), 40, False),
    'ram': (lambda a: sh("dumpsys meminfo 2>/dev/null | grep -E 'Total RAM|Free RAM|Used RAM|Lost RAM|ZRAM'; echo ===PSS===; dumpsys meminfo 2>/dev/null | sed -n '/Total PSS by process/,/^$/p' | head -16"), 40, False),
    'storage': (lambda a: sh('df -k /data; echo ===SD===; df -k /sdcard 2>/dev/null'), 20, False),
    'cpu': (lambda a: sh('dumpsys cpuinfo 2>/dev/null | head -40'), 30, False),
    'heat': (lambda a: sh('dumpsys thermalservice 2>/dev/null | head -80; echo ===BATT===; dumpsys battery | grep -E "temperature|level"'), 30, False),
    'apps': (lambda a: sh('pm list packages -3 -i'), 30, False),
    'bloat': (lambda a: sh('pm list packages -s; echo ===USER===; pm list packages -3; echo ===DISABLED===; pm list packages -d'), 30, False),
    'audit': (lambda a: sh('echo ===ACCESS===; settings get secure enabled_accessibility_services; echo ===LISTENERS===; settings get secure enabled_notification_listeners; echo ===ADMINS===; dumpsys device_policy 2>/dev/null | grep -iE "admin=|ComponentInfo" | head -20; echo ===OVERLAY===; cmd appops query-op SYSTEM_ALERT_WINDOW allow 2>/dev/null | head -40; echo ===INSTALLERS===; pm list packages -3 -i'), 40, False),
    'perms': (lambda a: sh(f"dumpsys package {pkg(a)} | grep -E 'granted=true' | head -80"), 30, False),
    'sensors': (lambda a: sh("dumpsys sensorservice 2>/dev/null | grep -E '^0x' | head -60"), 30, False),
    'display': (lambda a: sh("wm size; wm density; dumpsys display 2>/dev/null | grep -iE 'refreshRate|fps' | head -12"), 20, False),
    'network': (lambda a: sh("dumpsys wifi 2>/dev/null | grep -E 'RSSI|rssi|Link speed|linkSpeed|Frequency|frequency' | head -12; echo ===PING===; ping -c 4 -W 2 8.8.8.8 2>&1 | tail -4"), 40, False),
    'crashes': (lambda a: sh("logcat -d -b crash -v brief -t 500 2>/dev/null; echo ===ANR===; logcat -d -b main -v brief -t 4000 2>/dev/null | grep -E 'ANR in' | head -30"), 40, False),
    'anim_get': (lambda a: sh('settings get global window_animation_scale; settings get global transition_animation_scale; settings get global animator_duration_scale'), 15, False),
    # --- these change the customer's phone ---
    'anim_set': (anim, 15, True),
    'stop': (lambda a: ['shell', 'am', 'force-stop', pkg(a)], 15, True),
    'cache': (lambda a: ['shell', 'pm', 'trim-caches', '128G'], 120, True),
    'dexopt': (lambda a: ['shell', 'cmd', 'package', 'compile', '-m', 'speed-profile', '-a'], 900, True),
    'revoke': (lambda a: ['shell', 'pm', 'revoke', pkg(a), perm(a)], 15, True),
    'disable': (lambda a: ['shell', 'pm', 'disable-user', '--user', '0', pkg(a)], 15, True),
    'enable': (lambda a: ['shell', 'pm', 'enable', pkg(a)], 15, True),
    'uninstall': (lambda a: ['shell', 'pm', 'uninstall', '--user', '0', pkg(a)], 60, True),
    'reboot': (lambda a: ['reboot'], 15, True),
}
SPECIAL = {'screenshot': False, 'install_brandhoop': True}   # id -> danger


def audit(model, text):
    try:
        with open(LOG, 'a', encoding='utf-8') as f:
            f.write(time.strftime('%Y-%m-%d %H:%M:%S') + f'  {model or "-"}  {text}\n')
    except OSError:
        pass


def run(argv, timeout=30, binary=False):
    t0 = time.time()
    try:
        r = subprocess.run(argv, capture_output=True, timeout=timeout)
        out = r.stdout if binary else r.stdout.decode('utf-8', 'replace')[:MAX_OUT]
        err = r.stderr.decode('utf-8', 'replace')[:20_000]
        return {'ok': r.returncode == 0, 'out': out, 'err': err, 'ms': int((time.time() - t0) * 1000)}
    except subprocess.TimeoutExpired:
        return {'ok': False, 'out': '', 'err': 'समय ख़त्म: फ़ोन ने जवाब नहीं दिया', 'ms': int((time.time() - t0) * 1000)}
    except FileNotFoundError:
        return {'ok': False, 'out': '', 'err': 'adb नहीं मिला। Termux में चलाइए: pkg install android-tools', 'ms': 0}


def devices():
    r = run([ADB, 'devices', '-l'], 15)
    out = []
    for line in r['out'].splitlines()[1:]:
        m = re.match(r'^(\S+)\s+(device|unauthorized|offline)\b(.*)$', line.strip())
        if m:
            model = re.search(r'model:(\S+)', m.group(3))
            out.append({'serial': m.group(1), 'state': m.group(2), 'model': model.group(1).replace('_', ' ') if model else ''})
    return out


class H(http.server.BaseHTTPRequestHandler):
    server_version = 'BrandhoopBridge/' + VERSION

    def log_message(self, *a):
        pass

    def cors(self):
        o = self.headers.get('Origin', '')
        if o in ORIGINS:
            self.send_header('Access-Control-Allow-Origin', o)
            self.send_header('Vary', 'Origin')
            self.send_header('Access-Control-Allow-Headers', 'content-type, x-bridge-token')
            self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            self.send_header('Access-Control-Allow-Private-Network', 'true')

    def send(self, code, obj):
        body = json.dumps(obj, ensure_ascii=False).encode()
        self.send_response(code)
        self.cors()
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self.cors()
        self.send_header('Content-Length', '0')
        self.end_headers()

    def authed(self):
        o = self.headers.get('Origin', '')
        if o and o not in ORIGINS:
            self.send(403, {'ok': False, 'err': 'ये वेबसाइट अनुमति-सूची में नहीं है'})
            return False
        if not secrets.compare_digest(self.headers.get('X-Bridge-Token', ''), self.server.token):
            self.send(401, {'ok': False, 'err': 'टोकन ग़लत है। Termux में छपा टोकन डालिए।'})
            return False
        return True

    def body(self):
        n = int(self.headers.get('Content-Length', '0') or 0)
        if n > 20_000: raise ValueError('बहुत बड़ा अनुरोध')
        return json.loads(self.rfile.read(n) or b'{}')

    def do_GET(self):
        if self.path == '/health':
            return self.send(200, {'ok': True, 'version': VERSION, 'adb': bool(shutil.which(ADB)), 'commands': sorted(list(CMDS) + list(SPECIAL))})
        if not self.authed(): return
        if self.path == '/devices':
            return self.send(200, {'ok': True, 'devices': devices()})
        self.send(404, {'ok': False, 'err': 'नहीं मिला'})

    def do_POST(self):
        if not self.authed(): return
        try:
            b = self.body()
            if self.path == '/pair':
                hp, code = str(b.get('hostport', '')), str(b.get('code', ''))
                if not RE_HOSTPORT.match(hp) or not RE_CODE.match(code): return self.send(400, {'ok': False, 'err': 'IP:पोर्ट और 6 अंक का कोड सही डालिए'})
                r = run([ADB, 'pair', hp, code], 25)
                ok = 'Successfully paired' in r['out'] + r['err']
                audit('', 'pair ' + ('ok' if ok else 'failed'))
                return self.send(200, {'ok': ok, 'out': (r['out'] + r['err']).strip()})
            if self.path == '/connect':
                hp = str(b.get('hostport', ''))
                if not RE_HOSTPORT.match(hp): return self.send(400, {'ok': False, 'err': 'IP:पोर्ट सही डालिए'})
                r = run([ADB, 'connect', hp], 25)
                ok = re.search(r'connected to|already connected', r['out'] + r['err']) is not None
                audit('', 'connect ' + ('ok' if ok else 'failed'))
                return self.send(200, {'ok': ok, 'out': (r['out'] + r['err']).strip(), 'devices': devices()})
            if self.path == '/disconnect':
                run([ADB, 'disconnect'], 15)
                audit('', 'disconnect')
                return self.send(200, {'ok': True})
            if self.path == '/run':
                cid, serial, a = str(b.get('id', '')), str(b.get('device', '')), b.get('args') or {}
                if not RE_SERIAL.match(serial) or serial not in [d['serial'] for d in devices() if d['state'] == 'device']:
                    return self.send(400, {'ok': False, 'err': 'ये फ़ोन जुड़ा हुआ नहीं है। पहले जोड़िए।'})
                model = next((d['model'] for d in devices() if d['serial'] == serial), '')
                danger = CMDS[cid][2] if cid in CMDS else SPECIAL.get(cid)
                if danger is None: return self.send(400, {'ok': False, 'err': 'ऐसा कोई काम नहीं है'})
                if danger and b.get('confirm') is not True:
                    return self.send(400, {'ok': False, 'err': 'ये काम फ़ोन में बदलाव करता है। ग्राहक की सहमति लेकर "पक्का" दबाइए।', 'needsConfirm': True})
                if cid == 'screenshot':
                    r = run([ADB, '-s', serial, 'exec-out', 'screencap', '-p'], 30, binary=True)
                    audit(model, 'screenshot')
                    return self.send(200, {'ok': r['ok'] and len(r['out']) > 100, 'png': base64.b64encode(r['out']).decode() if r['ok'] else '', 'err': r['err']})
                if cid == 'install_brandhoop':
                    with tempfile.TemporaryDirectory() as d:
                        path = os.path.join(d, 'brandhoop.apk')
                        try:
                            with urllib.request.urlopen(APK_URL, timeout=60) as resp, open(path, 'wb') as f: shutil.copyfileobj(resp, f)
                        except Exception as e:
                            return self.send(200, {'ok': False, 'err': 'ऐप डाउनलोड नहीं हुआ: ' + str(e)})
                        r = run([ADB, '-s', serial, 'install', '-r', path], 180)
                    audit(model, 'install_brandhoop ' + ('ok' if 'Success' in r['out'] else 'failed'))
                    return self.send(200, {'ok': 'Success' in r['out'], 'out': r['out'].strip(), 'err': r['err']})
                build, timeout, _ = CMDS[cid]
                argv = build(a)
                r = run([ADB, '-s', serial] + argv, timeout)
                audit(model, cid + (' ' + str(a.get('pkg', '')) if a.get('pkg') else ''))
                return self.send(200, r)
            self.send(404, {'ok': False, 'err': 'नहीं मिला'})
        except (ValueError, KeyError) as e:
            self.send(400, {'ok': False, 'err': str(e)})
        except Exception as e:  # never crash the server on a bad request
            self.send(500, {'ok': False, 'err': 'भीतरी गड़बड़ी: ' + str(e)})


def main():
    if os.path.exists(TOKEN_FILE):
        token = open(TOKEN_FILE).read().strip()
    else:
        token = secrets.token_hex(4).upper()
        with open(TOKEN_FILE, 'w') as f: f.write(token)
        os.chmod(TOKEN_FILE, 0o600)
    srv = http.server.ThreadingHTTPServer(('127.0.0.1', PORT), H)
    srv.token = token
    print(f'\nBrandhoop Phone Doctor bridge v{VERSION}\nचल रहा है: http://127.0.0.1:{PORT}\nटोकन: {token}   (एडमिन ऐप में यही डालना है)\nबंद करने के लिए Ctrl+C\n', flush=True)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == '__main__':
    main()

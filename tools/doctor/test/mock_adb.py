#!/usr/bin/env python3
"""A pretend `adb` for testing the bridge and the admin app without a phone. Output formats follow real Android 13 devices."""
import sys, base64
A = sys.argv[1:]
PNG = base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==' + 'A' * 0)
S = {}
S['info'] = """ro.product.manufacturer=Xiaomi
ro.product.model=Redmi Note 12
ro.build.version.release=13
ro.build.version.sdk=33
ro.build.version.security_patch=2023-06-01
ro.product.cpu.abi=arm64-v8a
ro.build.display.id=TKQ1.221114.001 release-keys
MemTotal:        5811512 kB
 14:02:11 up 12 days,  3:41,  0 users,  load average: 6.12, 5.80, 5.40
Physical size: 1080x2400
Physical density: 440
"""
S['battery'] = """Current Battery Service state:
  AC powered: false
  USB powered: true
  Wireless powered: false
  Max charging current: 500000
  Charge counter: 3053000
  status: 2
  health: 2
  present: true
  level: 87
  scale: 100
  voltage: 4312
  temperature: 412
  technology: Li-ion
===CYCLE===
612
===FULL===
3650000
===DESIGN===
5000000
===CAP===
  Capacity: 5000.0, Computed drain: 1520, actual drain: 1450-1580
"""
S['battery_apps'] = """  Estimated power use (mAh):
    Capacity: 5000, Computed drain: 1520, actual drain: 1450-1580
    Screen: 610 Excluded from smearing
    Uid u0a152: 245 ( cpu=230 wifi=15 ) Including smearing: 260 ( proportional=15 )
    Uid u0a188: 140 ( cpu=100 wake=40 ) Including smearing: 150
    Uid 1000: 85.3 ( cpu=85.3 ) Including smearing: 90
    Cell standby: 77.7 ( radio=77.7 ) Excluded from smearing
    Idle: 66.2 Excluded from smearing

===PKGS===
package:com.android.systemui uid:10098
package:com.facebook.katana uid:10152
package:com.cleaner.speedbooster uid:10188
"""
S['ram'] = """Total RAM: 5,811,512K (status normal)
 Free RAM: 1,023,400K (  412,100K cached pss + 311,300K cached kernel + 300,000K free)
 Used RAM: 4,102,330K (3,200,000K used pss + 902,330K kernel)
 Lost RAM:   310,000K
     ZRAM:   120,000K physical used for  480,000K in swap ( 2,097,148K total swap)
===PSS===
Total PSS by process:
    412,311K: system (pid 1234)
    301,222K: com.android.systemui (pid 2345 / activities)
    255,100K: com.facebook.katana (pid 3456)
    120,044K: com.cleaner.speedbooster (pid 7788)

"""
S['storage'] = """Filesystem       1K-blocks      Used Available Use% Mounted on
/dev/block/dm-47 113456780 108012345   5444435  96% /data
===SD===
/dev/fuse        113456780 108012345   5444435  96% /storage/emulated
"""
S['cpu'] = """Load: 7.23 / 6.55 / 6.01
CPU usage from 3256ms to 0ms ago (2026-11-26 14:02:12.000 to 2026-11-26 14:02:15.256):
  45% 3456/com.facebook.katana: 30% user + 15% kernel / faults: 3000 minor
  22% 1234/system_server: 12% user + 10% kernel
  18% 7788/com.cleaner.speedbooster: 12% user + 6% kernel
  5.1% 2345/com.android.systemui: 3.1% user + 2% kernel
175% TOTAL: 100% user + 70% kernel + 0.4% iowait
"""
S['heat'] = """IsStatusOverride: false
Thermal Status: 2
Cached temperatures:
	Temperature{mValue=44.5, mType=3, mName=skin, mStatus=2}
Current temperatures from HAL:
	Temperature{mValue=44.9, mType=3, mName=skin, mStatus=2}
	Temperature{mValue=48.0, mType=0, mName=CPU0, mStatus=2}
	Temperature{mValue=41.2, mType=2, mName=battery, mStatus=0}
===BATT===
  level: 87
  temperature: 412
"""
S['apps'] = """package:com.facebook.katana  installer=com.android.vending
package:com.cleaner.speedbooster  installer=null
package:com.whatsapp  installer=com.android.vending
package:com.example.freegame  installer=com.android.packageinstaller
"""
S['bloat'] = """package:com.android.systemui
package:com.facebook.appmanager
package:com.facebook.services
package:com.facebook.system
package:com.miui.analytics
package:com.netflix.partner.activation
package:com.google.android.gms
===USER===
package:com.facebook.katana
package:com.cleaner.speedbooster
package:com.whatsapp
===DISABLED===
package:com.facebook.system
"""
S['audit'] = """===ACCESS===
com.cleaner.speedbooster/com.cleaner.speedbooster.AccService:com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService
===LISTENERS===
null
===ADMINS===
  admin=ComponentInfo{com.sketchy.lock/com.sketchy.lock.Admin}
===OVERLAY===
com.cleaner.speedbooster
com.facebook.orca
===INSTALLERS===
package:com.facebook.katana  installer=com.android.vending
package:com.cleaner.speedbooster  installer=null
package:com.example.freegame  installer=com.android.packageinstaller
"""
S['sensors'] = """0x00000001) bmi160 Accelerometer | Bosch | ver: 1 | type: android.sensor.accelerometer(1) | perm: n/a | flags: 0x00000000
0x00000002) bmi160 Gyroscope | Bosch | ver: 1 | type: android.sensor.gyroscope(4) | perm: n/a | flags: 0x00000000
0x00000003) ltr578 Light | Liteon | ver: 1 | type: android.sensor.light(5) | perm: n/a | flags: 0x00000002
0x00000004) ltr578 Proximity | Liteon | ver: 1 | type: android.sensor.proximity(8) | perm: n/a | flags: 0x00000003
"""
S['display'] = """Physical size: 1080x2400
Physical density: 440
    mBaseDisplayInfo=DisplayInfo{"Built-in Screen", displayId 0, real 1080 x 2400, largest app 1080 x 2400, 120.00 fps, rotation 0}
"""
S['network'] = """  mWifiInfo SSID: "ShopWiFi", BSSID: aa:bb:cc:dd:ee:ff, RSSI: -71, Link speed: 72Mbps, Frequency: 2437MHz, Net ID: 3
===PING===
4 packets transmitted, 4 received, 0% packet loss, time 3004ms
rtt min/avg/max/mdev = 38.1/64.2/121.8/32.0 ms
"""
S['crashes'] = """11-26 13:10:01.123  4321  4321 E AndroidRuntime: FATAL EXCEPTION: main
11-26 13:10:01.123  4321  4321 E AndroidRuntime: Process: com.facebook.katana, PID: 4321
11-26 13:20:01.123  4400  4400 E AndroidRuntime: FATAL EXCEPTION: main
11-26 13:20:01.123  4400  4400 E AndroidRuntime: Process: com.facebook.katana, PID: 4400
11-26 13:30:01.123  4500  4500 E AndroidRuntime: Process: com.cleaner.speedbooster, PID: 4500
===ANR===
11-26 12:00:00.000  1234  1260 E ActivityManager: ANR in com.cleaner.speedbooster (com.cleaner.speedbooster/.Main)
"""
S['anim_get'] = "1.0\n1.0\n1.0\n"
S['perms'] = "      android.permission.READ_SMS: granted=true\n      android.permission.CAMERA: granted=true\n      android.permission.RECORD_AUDIO: granted=true\n"
HOST = '192.168.1.50:37123'
if A[:1] == ['devices']:
    print('List of devices attached\n' + HOST + '\tdevice product:ruby model:Redmi_Note_12 device:ruby transport_id:1\n'); sys.exit(0)
if A[:1] == ['pair']:
    if A[2] == '123456': print('Successfully paired to ' + A[1] + ' [guid=adb-ABC123-xyz]')
    else: print('Failed: Wrong password or connection was dropped.')
    sys.exit(0)
if A[:1] == ['connect']:
    print('connected to ' + A[1]); sys.exit(0)
if A[:1] == ['disconnect']:
    print('disconnected everything'); sys.exit(0)
if A[:2] == ['-s', HOST] or A[:1] == ['-s']:
    rest = A[2:]
    if rest[:1] == ['exec-out']:
        sys.stdout.buffer.write(PNG * 20); sys.exit(0)
    if rest[:1] == ['install']:
        print('Performing Streamed Install\nSuccess'); sys.exit(0)
    if rest[:1] == ['shell']:
        cmd = ' '.join(rest[1:])
        keys = [('ro.product.manufacturer', 'info'), ('===CYCLE===', 'battery'), ('Estimated power use', 'battery_apps'), ('Total RAM', 'ram'), ('df -k', 'storage'), ('dumpsys cpuinfo', 'cpu'), ('thermalservice', 'heat'),
                ('pm list packages -3 -i', 'apps') if '===INSTALLERS' not in cmd else ('===INSTALLERS', 'audit'), ('pm list packages -s', 'bloat'), ('===ACCESS===', 'audit'), ('sensorservice', 'sensors'),
                ('dumpsys display', 'display'), ('===PING===', 'network'), ('logcat', 'crashes'), ('window_animation_scale', 'anim_get'), ("granted=true", 'perms')]
        for k, v in keys:
            if k in cmd and not cmd.startswith('settings put'):
                print(S[v], end=''); sys.exit(0)
        if cmd.startswith('am force-stop') or cmd.startswith('settings put') or cmd.startswith('pm revoke') or cmd.startswith('pm trim-caches') or cmd.startswith('cmd package') or cmd.startswith('reboot'):
            print('', end=''); sys.exit(0)
        if cmd.startswith('pm disable-user'): print('Package ' + cmd.split()[-1] + ' new state: disabled-user'); sys.exit(0)
        if cmd.startswith('pm enable'): print('Package ' + cmd.split()[-1] + ' new state: enabled'); sys.exit(0)
        if cmd.startswith('pm uninstall'): print('Success'); sys.exit(0)
        print('mock: unknown command: ' + cmd); sys.exit(1)
print('mock: bad args ' + ' '.join(A)); sys.exit(1)

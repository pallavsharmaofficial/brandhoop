# Setup, deployment and testing

## 1. Deployment (Railway, account of Pallav, project `hooplock`)

One service built from `hooplock/Dockerfile` (server + website + agent APK) and one PostgreSQL.

| Variable | Value |
|---|---|
| `RAILWAY_DOCKERFILE_PATH` | `hooplock/Dockerfile` |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` |
| `JWT_SECRET` | long random string (set) |
| `PUBLIC_URL` | `https://<service domain>` (later your own domain) |
| `AGENT_SIGNATURE_CHECKSUM` | base64url SHA-256 of the agent signing certificate |
| `ADMIN_PHONE` / `ADMIN_PASSWORD` | first super admin, created once on first boot |
| `FCM_*` | optional, instant push (see 4) |
| `RAZORPAY_*` | optional, payment links + auto-unlock on online payment |
| `SMS_PROVIDER=msg91`, `MSG91_*` | optional, SMS reminders (needs DLT template) |

After first login: Profile → change mobile and password.

## 2. Signing key for the agent (important)

The phone only installs the agent if its signing certificate matches the QR checksum, and an
installed agent can only be **updated** with the same key. Lose the key = enrolled phones can never
get updates.

- The current APK in `agent-dist/` is signed with a **pilot key**, kept as Railway variables
  `AGENT_KEYSTORE_B64` and `AGENT_KEYSTORE_PASSWORD` in the hooplock project. Use it for test phones.
- Before real customers: generate your own production key on your computer and keep two offline copies:

```bash
keytool -genkeypair -keystore hooplock-release.jks -alias hooplock -keyalg RSA -keysize 3072 -validity 10000
```

  Put `keystore.properties` next to `agent-android/` (see `app/build.gradle.kts`), run
  `./gradlew assembleRelease`, copy the APK to `agent-dist/hooplock-agent.apk`, and set
  `AGENT_SIGNATURE_CHECKSUM` to the output of:

```bash
apksigner verify --print-certs hooplock-agent.apk | grep SHA-256 | awk '{print $NF}' | xxd -r -p | base64 | tr '+/' '-_' | tr -d '='
```

- Register the package `in.hooplock.agent` and this key in the Android Developer Console
  (developer verification, required for sideloaded apps in 2027).

## 3. Test checklist on real phones (before any customer)

Use 3–5 phones of different brands (Samsung, Vivo/iQOO, Oppo/Realme, Xiaomi/Redmi, Motorola).

1. Factory reset → tap welcome screen 6 times → scan QR → agent installs, consent screen shows.
2. Console shows the phone Active with IMEI, SIM number, model.
3. Warning → notice appears. Restrict → apps paused, calls/SMS work.
4. Lock → lock screen; call shop works; call any other number is blocked; 112 works; incoming calls ring.
5. Reboot while locked → still locked. Try safe mode, recovery reset, Settings reset → blocked.
6. Turn off internet, send the OFFLINE SMS unlock code → unlocks.
7. Change SIM → console history shows "SIM changed" and a location.
8. Collect EMI in console → phone unlocks within a minute.
9. Close loan → Release → restrictions gone, HoopLock can be uninstalled.

Report anything that fails per brand; OEM fixes go into `Policy.kt`.

## 4. Optional services (what we need from you)

| For | You do | Then give us |
|---|---|---|
| Instant lock/unlock (seconds, not up to 15 min) | Create a Firebase project, add an Android app `in.hooplock.agent`, create a service account with "Firebase Cloud Messaging API Admin" | Service account JSON + projectId, appId, apiKey, senderId (set as Railway variables, never in chat or git) |
| Online EMI payment with auto-unlock | Razorpay account (KYC) | Key id, secret, webhook secret; webhook URL `https://<domain>/api/webhooks/razorpay`, event `payment_link.paid` |
| SMS reminders | MSG91 + DLT template registration | Auth key, template id |
| Your own domain | Buy e.g. `hooplock.in`, point a CNAME at Railway | Domain name |
| iPhone locking (phase 3) | D-U-N-S number, Apple Business Manager, Apple Developer account | ABM access |
| Legal | Lawyer-drafted hire-purchase agreement and consent text | Final text (we put it on the phone consent screen) |

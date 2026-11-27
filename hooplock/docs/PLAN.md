# HoopLock build plan

Read `RESEARCH.md` first. This plan builds a system you own end to end: you
mint the keys, your shop (and later other shops) use them, and you manage
everything from the website and from your phone.

## 1. What we are building

```
                      ┌────────────────────────────────────────┐
  You / shop staff    │  HoopLock Console (Flutter)             │
  web + Android + iOS │  super-admin · merchant · staff roles   │
                      └──────────────┬─────────────────────────┘
                                     │ HTTPS (JWT)
                      ┌──────────────▼─────────────────────────┐
                      │  HoopLock API (TypeScript, Fastify)     │
  Razorpay webhook ──▶│  merchants · key wallet · customers ·   │──▶ SMS / WhatsApp
  (EMI paid → unlock) │  devices · EMI schedules · lock stages  │    (MSG91 / Gupshup)
                      │  · audit log · scheduler                │
                      └───────┬───────────────────────┬────────┘
                    PostgreSQL│                       │
                              │ FCM push + signed     │ NanoMDM API
                              │ commands, SMS backup  │
                      ┌───────▼────────┐     ┌────────▼─────────┐
                      │ Android agent  │     │ iOS MDM (NanoMDM)│──▶ APNs
                      │ Kotlin, Device │     │ + ABM sync       │
                      │ Owner (DPC)    │     └────────┬─────────┘
                      └────────────────┘              │
                       customer's Android      customer's iPhone (supervised)
```

### Components

| Folder | What | Tech | Why this tech |
|---|---|---|---|
| `agent-android/` | The locker app on the customer's phone | Kotlin, Android SDK only, min SDK 24 | Device Owner APIs are native only; small APK, no Flutter |
| `server/` | API, key wallet, scheduler, webhooks | TypeScript, Fastify, PostgreSQL, Prisma | One language with good libraries for FCM, Razorpay, SMS |
| `mdm-ios/` | iOS MDM protocol engine | NanoMDM (Go, open source) + ABM token sync | Proven, small; we only add our API bridge |
| `console/` | Website + phone app for you and shops | Flutter (web, Android, iOS) | Same stack as the Brandhoop app, so it merges later; one codebase for web and phone |
| `infra/` | Deployment | Docker Compose on one VPS (or Railway) | Cheap, simple; scale later |

## 2. The key system (replacing the ₹150 / ₹1,400 keys)

- A **key** is a prepaid enrollment credit in a merchant's wallet.
- You (super-admin) create merchants and add keys to their wallet (free for
  your own shop; paid for other shops later). Separate counts for Android and
  iOS keys.
- At enrollment the console creates an **enrollment token**: single use,
  expires in 30 minutes, signed by the server (Ed25519), bound to the merchant
  and sale. Shown as the provisioning QR (Android) or as a pending device
  waiting for its serial number (iOS).
- A key is **consumed only when the device actually checks in**. Failed
  installs refund automatically.
- Later: distributors (a merchant who resells keys to other shops), price
  tiers, Razorpay top-up of wallets, GST invoices.

## 3. Android agent design

**Enrollment (shop counter, 3 minutes)**
1. New phone, first welcome screen. Tap 6 times, scan the QR from the console.
2. Phone downloads the agent from `https://<your-domain>/agent/latest.apk`,
   checks its signature, makes it Device Owner.
3. Agent shows the customer the consent screen (agreement summary in Hindi and
   English, EMI amount, dates, what happens if unpaid). Customer taps agree.
4. Agent registers: IMEI, serial, model, FCM token, Android version. Server
   links it to the sale and consumes a key.
5. Agent applies the base policy (below) and hands the phone to normal setup.
   The customer then adds their own Google account and uses the phone normally.

**Base policy (always, while the loan is open)**
- Factory reset blocked; FRP set to the shop's Google account.
- Safe mode, USB debugging, adding users, USB file transfer blocked.
- Agent cannot be uninstalled, disabled or force-stopped.
- Heartbeat every 6 hours.

**Lock stages** (per RBI-style gradual approach; days configurable per merchant)

| Stage | Trigger (default) | What the customer sees |
|---|---|---|
| 0 Reminder | 3 days before due, on due date | Notification + SMS |
| 1 Warning | 7 days overdue | Full-screen notice with dues and Pay Now, can be dismissed |
| 2 Restricted | 30 days overdue, after notices | Only phone, SMS, Pay Now and a merchant-chosen allow-list of apps |
| 3 Locked | Manual by merchant after stage 2 (or 60 days) | Lock screen: dues, UPI QR, call shop, emergency call |

Emergency dialer and incoming calls work at every stage.

**Commands** (`LOCK`, `UNLOCK`, `SET_STAGE`, `MESSAGE`, `LOCATE`, `RELEASE`)
- Delivered by FCM data message. Payload signed with the server's Ed25519 key;
  agent verifies before acting and rejects replays (nonce + timestamp).
- **Offline backup:** the same signed command fits in an SMS from the shop's
  number (shortened signature). Agent listens for it.
- **No-contact rule:** if the phone has not reached the server for N days
  (merchant setting, default 15) and the loan is overdue, it moves to stage 2
  by itself. A paid-up phone never self-locks.
- **Release:** removes all restrictions, clears FRP, gives up Device Owner and
  uninstalls itself.

**Hardening**
- APK signed with a key kept offline; package name and key registered in the
  Android Developer Console (developer verification, 2027).
- Certificate pinning for the API.
- Android Key Attestation at enrollment to detect emulators/rooted devices.
- Tamper events (SIM change, time change, reboot into recovery attempts where
  detectable) reported to the server.
- Test matrix: Samsung, Xiaomi/Redmi/POCO, Vivo, Oppo, realme, OnePlus,
  Motorola, Nothing, iQOO, Infinix/Tecno, Pixel; Android 10 to 16. Chinese
  OEM skins kill background apps: test heartbeat and FCM delivery on each.

## 4. iPhone design

**One-time setup (you)**
1. Register Brandhoop Mobile Point in Apple Business Manager (D-U-N-S, GST
   proof). Get the Organisation ID.
2. Get the APNs MDM push certificate (mdmcert.download signing, or Apple
   Developer Enterprise Program).
3. Deploy NanoMDM behind `https://mdm.<your-domain>`, add it in ABM as an MDM
   server, upload the server token, set it as default for new devices.
4. Create the enrollment profile: supervised, mandatory, not removable, skip
   unneeded setup panes, show "Managed by Brandhoop" with shop phone.

**Per iPhone at the counter (5–10 minutes)**
1. iPhone still in the box or erased.
2. Staff open Apple Configurator on the shop iPhone and add the device to ABM
   (or the distributor adds it to your ABM with your Organisation ID).
3. Console: enter serial, link to the sale; server assigns it to the MDM
   server through the ABM API and consumes an iOS key.
4. Customer turns on the phone, sees the remote-management screen and the
   consent note, completes setup with their own Apple ID.

**Lock stages on iPhone**
- Stage 0–1: push notification through a tiny optional companion app, plus
  SMS/WhatsApp. (iOS does not allow a full-screen warning without Lost Mode.)
- Stage 2: restrictions profile (hide App Store, block chosen apps).
- Stage 3: `EnableLostMode` with dues, shop phone and pay link.
- Unlock: `DisableLostMode` and remove restriction profile.
- Release: remove MDM profile, release from ABM, delete data.

**Watch the 30-day window** for manually added iPhones (see research). The
console shows a countdown and alerts if a device unenrolls.

## 5. Merchant console (website + phone)

Roles: **super-admin** (you), **merchant owner**, **staff**.

- Dashboard: active devices, overdue, locked today, collected today, key balance.
- New sale wizard: customer, KYC reference, phone model, price, down payment,
  tenure, EMI date, agreement PDF to sign (e-sign later), then enrollment QR
  (Android) or serial step (iOS).
- Device page: status, stage, last seen, EMI schedule, payment history, buttons
  for remind, lock, unlock, message, locate (only when locked), release.
- Payments: Razorpay UPI payment links per instalment; webhook marks paid and
  unlocks. Cash at counter: staff record it, phone unlocks.
- Bulk actions with confirmation; every action needs a reason; owner can
  require approval for stage 3.
- Super-admin: merchants, key wallets, pricing, global audit log, agent
  version rollout.
- Hindi and English, like the Brandhoop app.

## 6. Security and data

- Separate tenants per merchant in every query (row-level security in Postgres).
- Login by mobile OTP + optional TOTP for owners; short-lived JWTs.
- All lock/unlock actions in an append-only audit table.
- Command-signing private key in a KMS or at least an encrypted file not in
  the repo; rotate yearly; agents trust two keys (current and next).
- Store only: customer name, mobile, KYC reference (not the document), device
  IDs, EMI data, consent records, last location only while locked.
- Daily encrypted database backups off the VPS.

## 7. Phases

| Phase | Weeks | Output | Done when |
|---|---|---|---|
| **0. Paperwork** (start now, in parallel) | 1–3 | D-U-N-S, Apple Business Manager, APNs cert, domain, VPS, lawyer-drafted hire-purchase agreement + consent text, Razorpay account | Accounts approved, agreement signed off |
| **1. Android MVP** | 1–6 | Agent (enroll, base policy, lock/unlock, release), API, minimal console (web), FCM | 20 test phones across brands enroll, lock, unlock, release; factory reset and flashing attempts fail |
| **2. Payments + stages** | 7–9 | EMI schedules, Razorpay links + webhook auto-unlock, stages 0–3, SMS/WhatsApp reminders, scheduler | A paid instalment unlocks a phone in under 1 minute |
| **3. iPhone** | 10–13 | NanoMDM, ABM sync, Lost Mode lock/unlock, release | 5 test iPhones, incl. the 30-day window test |
| **4. Phone app + polish** | 14–16 | Console on Android/iOS, Hindi, audit, reports, offline SMS commands, no-contact rule | Your shop runs only on HoopLock, old vendor stopped |
| **5. Sell to other shops** | 17+ | Multi-merchant onboarding, wallet top-up, distributor tier, invoices | First outside shop live |
| **6. Upgrades** | later | Samsung Knox Guard integration; apply to Google Device Lock Program; merge console into the Brandhoop app | |

Pilot rule: keep the old vendor for new sales until phase 2 has run on your own
shop's phones for at least one full EMI cycle.

## 8. Money

**One-time / yearly**

| Item | Cost |
|---|---|
| Domain + SSL | ~₹1,000/yr (SSL free) |
| VPS (4 GB) or Railway | ₹1,500–3,000/month |
| Apple Developer Program (companion app, console on iOS) | US$99/yr |
| Apple Developer Enterprise (only if you become an MDM vendor yourself) | US$299/yr, optional |
| Google Play / Android Developer Console | already have |
| Test phones (used, mixed brands) | ₹40,000–60,000 one-time |
| Lawyer for agreement | ₹10,000–25,000 one-time |
| SMS/WhatsApp | ~₹0.15–0.80 per message |

**Per device**: well under ₹10 all-in for Android, about the same for iPhone.

**Break-even example** (your shop only): 100 Android + 10 iPhone sales a month
saves 100 × ₹150 + 10 × ₹1,400 = **₹29,000/month**, against ~₹3,000/month
running cost. Selling keys to other shops at ₹60–99 (Android) and ₹500–800
(iPhone) undercuts the market and adds revenue.

## 9. Risks and what we do about them

| Risk | Mitigation |
|---|---|
| RBI final text differs from reports | Stage days and rules are settings, not code; review the circular in phase 0 |
| Play Protect warns about the agent | Developer verification, clean signing key, no hidden behaviour, submit for review if flagged |
| An OEM breaks QR provisioning or kills the agent | Brand test matrix, per-OEM fixes, Knox Guard for Samsung |
| Phone flashed with EDL/firmware tools | FRP to shop account makes it unusable after flash; record IMEI for blacklist report if stolen |
| iPhone 30-day removal window | Distributor ADE where possible, alerts, short first cycle |
| Apple terminates ABM | Hire-purchase ownership, release devices promptly, never manage non-credit phones |
| Customer complaints | Clear consent, notices, emergency access, fast unlock, audit log as evidence |
| Your server down = can't unlock | Offline SMS unlock, backups, uptime alerts to your phone |

## 10. Next step

Start phase 0 now, and phase 1 with the Android agent: it is 80% of your sales
and saves the most per month. The first code commit will add `server/` and
`agent-android/` skeletons with the enrollment flow.

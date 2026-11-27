# HoopLock

EMI device locking for phones sold on credit by Brandhoop Mobile Point and other shops. Android now,
iPhone through Apple MDM once Apple Business Manager is ready. Managed from a website and a phone app (same Flutter code). Built from scratch as
its own project; it can merge into the Brandhoop app later.

| Folder | What | Status |
|---|---|---|
| `server/` | API (TypeScript, Fastify, PostgreSQL): shops, staff, key wallet, credit sales, EMI schedules, signed lock commands, SMS offline codes, location, payments, auto-unlock, reminders, gradual lock scheduler, audit log, Razorpay webhook, iPhone MDM bridge | Working, 19 end-to-end tests |
| `agent-android/` | Locker app on the customer's phone (Kotlin, Device Owner, installed by QR) | Builds; unit-tested crypto; **needs testing on real phones** |
| `console/` | Shop website + Android/iOS app (Flutter) | Working against the server |
| `agent-dist/` | The signed agent APK the provisioning QR downloads | Pilot build |
| `mdm-ios/` | iPhone locking via Apple MDM (NanoMDM): Lost Mode lock/unlock, locate, release | Server side done and tested against a fake MDM; needs Apple Business Manager + push certificate |
| `deploy/` | docker-compose for any VPS (app, PostgreSQL, HTTPS, optional NanoMDM) | Alternative to Railway |
| `docs/` | `RESEARCH.md`, `PLAN.md`, `SETUP.md`, `PROTOCOL.md` | |

## What a shop can do

- Home: total / active / inactive / uninstalled / locked phones, key balance, overdue money.
- New Android sale: customer, phone, EMI plan → QR code. Scan it on the new phone's welcome screen
  (tap 6 times) and the phone enrolls itself; one key is used.
- Customer list with USERS / NEXT EMI / HIGH RISK tabs, search by name, mobile or IMEI.
- Customer page: device and SIM details, EMI card, actions: **lock, unlock, warning, restrict apps,
  message, locate, collect EMI, reminder, payment link, release**. ONLINE (push) or OFFLINE (a signed
  SMS code you send from your phone; works without internet on the customer's phone).
- Location tab with map and history. Phones send location when locked, when the SIM is changed, or
  when you press Locate (every request is logged with a reason).
- Reminders, agreement and EMI schedule, full history.
- Owner: shop settings (numbers a locked phone may call, UPI id, lock rules), staff, activity log.
- Super admin (you): all shops, add keys, open any shop.

## What the customer's phone does

| Level | What happens |
|---|---|
| Always (whole loan) | Factory reset, safe mode, USB debugging, new users and date changes blocked; locker cannot be uninstalled; optional factory-reset protection to the shop's Google account |
| Warning | Full-screen notice with dues, can be closed |
| Restricted | All apps paused except phone, SMS and HoopLock |
| Locked | Only the lock screen: dues, UPI QR to pay from another phone, **call the shop's numbers**, **emergency call**. Any other outgoing call is blocked. Incoming calls still ring |
| No contact | If the phone stays offline past an EMI date + N days, it restricts itself |
| Released | Everything removed, Device Owner given up, customer can uninstall |

## Run locally

```bash
cd server && npm install && npm test
```

```bash
cd server && DATABASE_URL=postgres://... ADMIN_PHONE=9xxxxxxxxx ADMIN_PASSWORD=... npm run dev
```

```bash
cd console && flutter build web --no-web-resources-cdn
```

See `docs/SETUP.md` for deployment, signing keys and the phone test checklist.

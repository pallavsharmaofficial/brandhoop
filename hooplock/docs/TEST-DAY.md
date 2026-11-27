# Test day and go-live (for Pallav)

Everything below is ready. Total time: about 1 hour of testing, then 20 minutes to go live.

## What you need on the table

- 1–2 **spare Android phones** (Android 8+, ideally different brands) that may be **factory reset**, each with a SIM.
- Wi-Fi or a hotspot for the phones during setup.
- Your laptop or phone with a browser, logged in to GitHub.
- The shop owner's phone (for the shop app).

## Part A — test server (5 minutes, free, nothing to install)

1. Open this link while logged in to GitHub and press **Create codespace**:
   https://codespaces.new/pallavsharmaofficial/brandhoop?ref=claude/keen-ptolemy-7q2r65&devcontainer_path=.devcontainer/hooplock/devcontainer.json
2. Wait 3–5 minutes. A file **HOOPLOCK-TEST-SERVER.txt** appears (also printed in the terminal) with
   the **server address** (`https://….app.github.dev`) and the **admin login and password**.
3. Check the **Ports** tab: port 8080 must show **Public**. If it says Private: right-click it →
   Port visibility → Public.
4. Keep the codespace tab open during the test (it stops after 30 minutes without activity;
   GitHub → Settings → Codespaces → Default idle timeout can be raised to 240 minutes).

## Part B — connect the shop app (2 minutes)

1. On a phone or laptop open https://pallavsharmaofficial.github.io/hooplock/app/
2. Sign-in screen → **Connect to real server** → paste the server address → **Connect**.
3. Sign in with the admin login from step A2.
4. Shops (store icon, top right) → **New shop**: Brand Hoop Neem Ka Thana, owner's mobile and a
   password, 10 Android keys.
5. Sign out, sign in as the owner. **Shop settings**: owner mobile (callable from locked phones), UPI
   id. **Profile**: change password.

## Part C — real phone test (30–40 minutes per phone)

| # | Do | Expect |
|---|---|---|
| 1 | App: **+ Android** → customer = yourself, mobile = the test phone's SIM, any price/EMI, first EMI date **last month** (so an EMI is overdue) → Save & show QR | Big QR, 30-minute timer |
| 2 | Test phone: factory reset → on the first Welcome screen tap 6 times → connect Wi-Fi → scan QR | "Setting up your device", downloads HoopLock |
| 3 | Wait 2–3 minutes | Consent screen with shop name → **I agree** → finish setup |
| 4 | App: customer list | Customer **Active**, IMEI and SIM filled in, key balance −1 |
| 5 | **Warning** | Full-screen notice on the phone (see "Timing" below) |
| 6 | **Restrict Apps** | Apps greyed/paused; Phone and Messages still work |
| 7 | **Lock Device** with a message | Lock screen: message, dues, UPI QR, Call shop, Emergency |
| 8 | On the locked phone: Call shop | Rings your shop number |
| 9 | Dial any other number from the dialer | Call is blocked |
| 10 | Emergency call | Emergency dialer opens (do not actually call 112) |
| 11 | Restart the locked phone | Still locked after boot |
| 12 | Settings → Reset / try safe mode | Not allowed |
| 13 | Turn mobile data and Wi-Fi **off** on the test phone. App → **OFFLINE** → Unlock → Open SMS app → send | Phone unlocks from the SMS |
| 14 | Data back on. **Lock**, then **Collect EMI** for the overdue amount | Phone unlocks by itself |
| 15 | Swap or remove the SIM, wait a few minutes | HISTORY shows "SIM changed"; LOCATION shows a point |
| 16 | **Locate** with a reason | Location appears on the map |
| 17 | Collect the rest of the loan → **Release** | Restrictions gone, HoopLock says "All EMIs paid" and can be uninstalled |

**Timing:** without Firebase push, the phone checks the server every 15 minutes. To see a change
immediately during the test, tap **"I have paid — check again"** on the phone's lock screen or open the
HoopLock app on the phone and tap the same button, or use the OFFLINE SMS code. Reboot also syncs.

Note any step that fails, with the phone's brand and Android version.

## Part D — go live (after the test passes)

A codespace is **not** for real customers: it stops when idle, and customers' phones must be able to
reach the server every day. Choose one permanent server:

**Option 1 — Oracle Cloud Always Free (₹0)**
1. Sign up at cloud.oracle.com (card only for verification; choose region Mumbai or Hyderabad).
2. Create instance: Ubuntu 22.04/24.04, shape **VM.Standard.A1.Flex** (1 OCPU, 6 GB) or
   E2.1.Micro, download the SSH key.
3. Networking → the instance's subnet → Security list → add ingress rules TCP **80** and **443**
   from 0.0.0.0/0. (On the server also run: `sudo iptables -I INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT`.)
4. SSH in and run:

```bash
curl -fsSL https://raw.githubusercontent.com/pallavsharmaofficial/brandhoop/claude/keen-ptolemy-7q2r65/hooplock/deploy/install.sh | sudo ADMIN_PHONE=9xxxxxxxxx bash
```

5. It prints the permanent server address (`https://<ip>.sslip.io`, or your domain if you passed
   `DOMAIN=`) and the admin password.

**Option 2 — Railway** (about $5/month): pick a plan, tell Claude "deploy", done from the session.

**Option 3 — any VPS** (Hostinger/DigitalOcean, ₹400–800/month, Ubuntu): same command as Option 1.

Then: in the shop app → Back to practice mode → Connect to real server → the permanent address.
Create the shop again (the test server's data does not move), and start selling.

## Before the first real customer

- [ ] Test (Part C) passed on at least one phone of each brand you sell most.
- [ ] Permanent server running (Part D); its `.env` file backed up.
- [ ] Agreement text ready (hire purchase + consent); a signed copy for every sale.
- [ ] Owner has read the guide: https://pallavsharmaofficial.github.io/hooplock/
- [ ] The **signing key** files are stored safely (Google Drive + one offline copy). Without them,
      enrolled phones can never get an update of the locker app.
- [ ] Optional, recommended soon: Firebase for instant lock/unlock, Razorpay for online EMI payments.

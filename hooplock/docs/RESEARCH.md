# HoopLock research: how EMI device locking works

Research date: 27 November 2026. Prices come from vendor and marketplace pages
and are not verified quotes. The RBI section is based on news reports of the
6 August 2026 Amendment Directions. Read the RBI's own text before going live.
None of this is legal advice.

## 1. What the market sells

A shop sells a phone on credit. Before handing it over, staff install a
"locker" on the phone with a one-time **key** (an activation credit). If the
customer stops paying, the shop locks the phone from a web panel or app. When
the loan is paid off, the shop releases the phone and the locker removes itself.

| Product | Android key | iPhone | Notes |
|---|---|---|---|
| EmiVault | from ₹60 per activation | not listed | Android 7+, no monthly fee |
| SafetyPay AIRLOCK PRO | ₹199 (MRP ₹350) | not listed | Wholesale listing |
| IndiaMART sellers | ₹179 per key | "iPhone superkeys", no public price | Resellers of other brands |
| ZEN EMI Locker | quote only | quote only | Subscription by portfolio size |
| InstenLock | quote only | yes, supervised mode | Says iPhones must be prepared before first setup |
| **What you pay today** | **₹150** | **~₹1,400** | |

The ₹150 and ₹1,400 are almost all margin. Every one of these vendors runs the
same well-known Android and Apple mechanisms described below. The real cost per
device is server time, a push message and maybe an SMS: a few rupees.

Why iPhone keys cost ~10x more: fewer vendors can do it, it needs an Apple
Business Manager organisation, an MDM push certificate and staff training, and
some sellers use grey methods. None of that is expensive once it is set up.

## 2. Android: how the lock actually works

### The method every Indian locker uses: Device Owner (custom DPC)

Android lets one app become the **Device Owner**: the most powerful management
mode, built for company phones. A Device Owner app can:

- Lock the phone to its own screen (`setLockTaskPackages` / lock task mode) while
  still allowing the emergency dialer.
- Block factory reset, safe mode, USB debugging, adding users, and USB file
  transfer (`DISALLOW_FACTORY_RESET`, `DISALLOW_SAFE_BOOT`,
  `DISALLOW_DEBUGGING_FEATURES`, `DISALLOW_ADD_USER`, `DISALLOW_USB_FILE_TRANSFER`).
- Set a **Factory Reset Protection** account (`setFactoryResetProtectionPolicy`,
  Android 11+), so even a phone flashed or reset from recovery asks for the
  shop's Google account before it can be set up.
- Stop itself from being uninstalled or disabled.
- Grant itself permissions silently (location for theft recovery, SMS for
  offline commands).
- Remove itself cleanly when the loan is closed (`clearDeviceOwnerApp`).

**The catch: Device Owner can only be set on a freshly reset phone,** during the
first setup screen. That is fine for a shop: the phone is new and still in the
box. Staff tap the welcome screen 6 times, a QR scanner opens, they scan the
enrollment QR, and the phone downloads and installs the agent from your server.
Works on Android 7.0+ with Google services (every phone sold in India).

What the QR contains: the agent APK download URL, its signature checksum, Wi-Fi
details (optional) and an enrollment token. The token is the "key".

### Why not the other Android options

| Option | Verdict |
|---|---|
| **Android Management API** (Google's free MDM API) | **Not allowed.** Google's permissible-usage policy explicitly bans device-financing solutions that restrict a device based on payment status, including B2C/retail. Google can revoke access. |
| **Play Store app** | Play policy does not allow apps that lock users out for payment. The agent is distributed from your own HTTPS server through the QR, like every other locker. |
| **Device Admin** (old API, no reset needed) | Deprecated, weak, easy to remove. Some cheap lockers still use it; avoid. |
| **Google Device Lock Controller** | Built into Android 14/15+, no reset needed, survives everything. Only for approved partners (Trustonic was approved in May 2025). Worth applying to later, not something to build on now. |
| **Samsung Knox Guard** | Works below the OS on Samsung phones, no reset needed, survives flashing. Commercial licence per device; price only from Samsung partners. Good add-on for Samsung later. |

### Sideloading rule coming in 2027

Google requires apps installed outside Play to be registered by a **verified
developer**: enforced from 30 September 2026 in Brazil, Indonesia, Singapore and
Thailand, and globally "in 2027". Because you are already a verified
publisher, register the agent's package name and signing key in the Android
Developer Console as soon as it is built. Unregistered lockers from small
vendors may stop installing in India in 2027; that is an opportunity.

## 3. iPhone: how the lock actually works

Apple gives no app the power to lock a phone. The only real method is
**supervision + MDM** (Mobile Device Management), which Apple built for company
iPhones.

1. The shop has an **Apple Business Manager** (ABM) account. Free. Needs a legal
   business entity and a D-U-N-S number (free from D&B).
2. The customer's new iPhone is added to the shop's ABM, using the
   **Apple Configurator** app on any iPhone (iOS 16+; no Mac needed) or Apple
   Configurator 2 on a Mac. The phone must be erased / not yet set up.
3. In ABM, the device is assigned to your MDM server. During setup the iPhone
   enrols into your MDM automatically, becomes **supervised**, and the
   management profile cannot be removed by the user. Erasing the phone just
   re-enrols it.
4. Your MDM server can then send:
   - `EnableLostMode`: full-screen message with your text and phone number;
     the phone is unusable except emergency calls. Supervised only. This is
     the main "lock".
   - `DeviceLock` with message and phone number (passcode lock screen).
   - Restrictions: block erase-all-content, block account changes, block
     adding/removing MDM, etc.
   - Location while in Lost Mode.
5. When paid off: disable Lost Mode, remove the MDM profile and **release the
   device from ABM**. Then it is a normal personal iPhone.

What you need to run your own iOS MDM:

| Item | Cost | Notes |
|---|---|---|
| Apple Business Manager | Free | Legal entity + D-U-N-S |
| APNs MDM push certificate | Free | Needs a CSR signed by an "MDM vendor". Options: the free mdmcert.download signing service used by open-source MDMs, or join the Apple Developer Enterprise Program (US$299/yr) and request MDM CSR signing to become a vendor yourself |
| MDM server | open source | NanoMDM (Go, actively used, small) as the protocol engine, our own API on top |
| A public HTTPS server | ~₹1,500/month VPS | Same server as the Android backend |

Real cost per iPhone: close to zero. ₹1,400 can drop to the cost of your time.

### iPhone risks to know

- **30-day provisional period.** iPhones added to ABM manually (with Apple
  Configurator) can be removed from management by the user in Settings for 30
  days after setup. After that it is permanent. Mitigation: a short first EMI
  cycle, keep the box/bill until day 30, and Lost Mode alerts if the profile
  disappears. Phones bought from Apple or an authorised distributor already
  in your ABM (Automated Device Enrolment) do not have this window. Ask your
  iPhone distributor if they can add devices to your ABM with your
  Organisation ID: some Apple authorised distributors in India can.
- **Apple's ABM terms are for devices the organisation owns or controls.**
  Structure the sale as **hire purchase**: the shop keeps ownership until the
  last EMI. That matches the terms and the RBI's "device financed by this
  loan" rule. Get a lawyer to word it.
- Apple can review and terminate an ABM account. Keep it clean: release every
  device on payoff, never manage phones the shop did not sell on credit.

## 4. Law in India (read before building anything)

### RBI Amendment Directions, 6 August 2026, effective 1 January 2027

As reported (Moneylife, Inc42, The Federal, Business Today):

- Banks and NBFCs may **not** lock or disable phones, tablets or laptops to
  recover loans, **except** when the loan was taken to buy that very device.
- The loan agreement must say clearly, up front, that the device can be
  restricted on default, with the borrower's explicit consent.
- No restriction until the loan is overdue (reports say **30 days past due**;
  some say staged limits at 60 and 90 days) and notices have been sent.
- A **gradual** approach: warnings first, partial restrictions before a full
  lock.
- Essential functions stay available at every level (emergency calls at
  least; reports say incoming calls too).
- **No access to personal data** on the device.
- Restore functions quickly after the borrower pays (one report says within
  1 hour).
- Use manufacturer- or OS-certified technology where available.
- Give up control of the device once the loan is fully repaid.

These rules bind regulated lenders (banks, NBFCs). A shop selling on its own
hire-purchase credit is not an RBI-regulated lender, but **design to the RBI
rules anyway**: courts and consumer forums will judge you against them, and
any NBFC partner will require it. Lending in your own name at scale may also
trigger state money-lending laws; take legal advice (see the existing
`docs/PAYMENTS.md` rule 5).

### Digital Personal Data Protection Act 2023

Collect only what the loan needs (name, mobile, KYC reference, IMEI/serial,
EMI schedule), with clear notice and consent, delete on closure plus the
retention period, and never read messages, photos, contacts or call logs.

### How HoopLock follows these

| Rule | Design choice |
|---|---|
| Consent | Customer signs the hire-purchase agreement and taps "I agree" on the phone during setup; both stored with timestamps |
| Only device loans | Every device is linked to one sale and one EMI schedule |
| Notices first | Automatic SMS/WhatsApp/on-phone reminders before due date, on due date, and at each stage |
| Gradual | Stage 0 reminder, 1 full-screen warning (dismissable), 2 restricted (apps blocked, calls work), 3 full lock |
| Essentials | Emergency dialer, incoming calls, a "call shop" and "pay now" button always work |
| No personal data | The agent has no access to messages, photos or contacts; location only when locked and only for theft |
| Fast restore | Payment webhook unlocks automatically within seconds; target under 5 minutes, offline SMS unlock as backup |
| Release | One button on payoff: unlock, remove agent / MDM, release from ABM, delete data |
| Audit | Every lock, unlock and policy change logged with who, when and why |

## 5. Sources

- Google Device Lock Controller: [Android Police](https://www.androidpolice.com/2020/11/09/google-has-an-app-to-lock-you-out-of-your-financed-phone-if-you-stop-paying-for-it/), [Trustonic](https://www.trustonic.com/?p=19867), [Android Enterprise community](https://www.androidenterprise.community/android-enterprise-general-discussions-3/how-to-be-partner-of-google-s-device-lock-controller-dlc-1257)
- Android Management API ban on financing: [Google permissible usage](https://developers.google.com/android/management/permissible-usage), [forum thread](https://www.androidenterprise.community/android-enterprise-general-discussions-3/device-financing-at-scale-10-000-devices-compliant-restricted-mode-on-delinquency-using-android-enterprise-device-owner-1599)
- Android developer verification: [Android Developers Blog, March 2026](https://android-developers.googleblog.com/2026/03/android-developer-verification-rolling-out-to-all-developers.html), [developer.android.com](https://developer.android.com/developer-verification/guides)
- Samsung Knox Guard: [Knox Guard docs](https://docs.samsungknox.com/admin/knox-guard/get-started/get-started-with-knox-guard/), [Hardened mode blog](https://www.samsungknox.com/en/blog/safeguard-financed-devices-with-knox-guard-hardened-security-mode)
- iPhone supervision/MDM: [InstenLock](https://www.instenlock.in/), [ManageEngine on Activation Lock](https://www.manageengine.com/mobile-device-management/help/profile_management/ios/mdm_activation_lock.html), [Apple Business Manager guide](https://support.apple.com/en-ie/guide/apple-business-manager-m/axmd344cdd9d/1/web/1)
- Market prices: [EmiVault](https://emivault.com/), [Wholesalebrother SafetyPay](https://www.wholesalebrother.com/products/safetypay-emi-loker-airlock-pro), [IndiaMART](https://m.indiamart.com/quick-explain-enterprises/mobile-locker.html), [Zen EMI Locker](https://zenemilocker.com/emi-safe-alternative)
- RBI: [Business Today, Aug 2026](https://www.businesstoday.in/personal-finance/banking/story/can-banks-lock-your-smartphone-for-missing-an-emi-rbi-says-yes-but-only-in-these-cases-547781-2026-08-07), [Moneylife](https://www.moneylife.in/article/missed-loan-emi-banks-cannot-remotely-disable-your-phone-or-laptop-says-rbi/81303.html), [Inc42](https://inc42.com/buzz/rbi-bars-lenders-from-locking-borrowers-devices-except-for-gadget-loans/), [The Federal](https://thefederal.com/category/business/rbi-bars-banks-from-disabling-mobile-devices-of-defaulting-borrowers-252766), [Business Today, Sept 2025 draft](https://www.businesstoday.in/personal-finance/news/story/rbi-smartphone-emi-default-rules-lenders-lock-devices-consent-privacy-493776-2025-09-12)

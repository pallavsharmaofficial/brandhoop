# Brandhoop

The app of **Brandhoop Mobile Point**, Abhay Colony, Neem Ka Thana, Rajasthan 332713
(across the road from Study Point Library). Customers browse, reserve and buy
phones and accessories from anywhere, and can walk into the shop any time.
Shop staff, managers and the owner use the **same app**; what they see depends
on their role. Hindi and English throughout.

Goal behind the app: grow the shop's monthly profit to ₹5 lakh.
`docs/GROWTH_PLAN.md` shows the arithmetic and says plainly what is assumed.

## Status

A complete working app on **local, demo data**. Nothing is sent to a server and
**no real money moves**: payments, OTP and Autopay are mocked. Do not publish it
to customers until `docs/ROADMAP.md` stage 1 (real payments and a backend) is done.

| Works now | Not yet |
|---|---|
| Catalogue, search, cart, wishlist, offers and coupons | Real payment gateway, real SMS OTP |
| Checkout: UPI, card, netbanking, COD, cash at store, token reserve | Bajaj Finance dealer integration |
| Bajaj and card EMI plans, calculator, Autopay mandates (mocked) | Shared backend, push notifications |
| Orders, invoices, returns, refunds, IMEI on delivery | Photos for products |
| Counter POS, stock, leads, repairs, EMI desk, offers, staff, reports | Android APK build (no SDK in the build machine) |
| Profit ledger and the road to ₹5 lakh dashboard (owner only) | |
| Roles: customer, staff, manager, owner | |

## Try it

```bash
flutter pub get
flutter run -d chrome            # or any device
flutter test                     # 113 tests
```

Demo mode is on by default (`--dart-define=BRANDHOOP_DEMO=false` turns it off).
Sign in with any listed number and the code `123456`:

| Role | Mobile |
|---|---|
| Owner | 9000000001 |
| Manager | 9000000002 |
| Staff | 9000000003 |
| Customer (Ravi Meena, has a live Bajaj EMI) | 9000000011 |

Mock payment failures to try: UPI `fail@upi`, card `4000000000000002`.

## Before it shows real shop details

Phone, WhatsApp, UPI id and GSTIN are empty on purpose, and the call and
WhatsApp buttons stay hidden until they are set (Admin, More, Store settings).
Opening hours (10:00–21:00), map position, EMI rates, the FAQ and the return
policy are placeholders. EMI rates in particular must come from the Bajaj
Finance dealer agreement (`emiRatesConfirmed`).

## Where to read next

- `docs/ARCHITECTURE.md` how the code is organised
- `docs/ROLES.md` who can do what
- `docs/PAYMENTS.md` Bajaj, UPI, cards, Autopay and the compliance caveats
- `docs/BACKEND.md` the Firebase plan, schema and rules
- `docs/GROWTH_PLAN.md` the ₹5 lakh plan, `docs/MARKETING.md` how to get customers
- `docs/ROADMAP.md` what is left, `docs/LAUNCH.md` and `docs/PLAY_SETUP.md` shipping

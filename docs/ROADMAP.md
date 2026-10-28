# Roadmap

Honest order of work from "complete demo" to "real shop app".

## Stage 0: done
The whole app on local data: customer and back office, EMI and Autopay flows,
profit ledger, Hindi and English, roles, 113 tests, launch layer.

## Stage 1: before any customer uses it (blocking)
1. **Real data.** Replace the sample catalogue with the shop's stock, prices and
   photos. Fill phone, WhatsApp, UPI id, GSTIN, real hours and map position.
2. **Backend.** Firebase Auth (phone OTP), Firestore, Storage per `docs/BACKEND.md`.
   Without it, each phone holds its own separate shop.
3. **Payments.** Razorpay (or similar) for UPI, cards, netbanking and UPI AutoPay.
   Webhook-confirmed, never trusting the app (`docs/PAYMENTS.md`).
4. **Bajaj Finance.** Become a dealer partner, get the real scheme list and
   rates, set `emiRatesConfirmed`.
5. **Policies.** Real return and warranty text, GST invoice format checked by the
   shop's accountant, privacy policy updated for the backend.
6. **Build and test on real phones.** Android SDK, release signing, a pilot with
   staff and a few friendly customers.

## Stage 2: grow
Accessory suggestions at checkout and the POS, and phone-plus-accessory bundles. Push notifications (order status, EMI due), shop photos and reels, referral
rewards in earnest, WhatsApp catalogue sharing, Google Business Profile links.
See `docs/MARKETING.md`.

## Stage 3: later
Instalments the shop itself collects (only after legal advice; the switch exists
and is off), supplier purchase orders, multiple counters, a staff attendance and
incentive view, iOS App Store release.

## Known limits
- No product photos: art is generated from brand and colour.
- Local storage cannot sync between phones.
- Mock gateway and OTP exist only for demonstration.

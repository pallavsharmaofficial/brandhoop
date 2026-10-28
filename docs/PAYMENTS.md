# Payments, EMI and Autopay

Today every payment in the app is a **mock** (`MockPaymentGateway`). This page
says what real integration needs. It is a plan, not legal or tax advice.

## What the app supports

| Mode | How it works in the app | What real use needs |
|---|---|---|
| UPI, card, netbanking | `PaymentGateway.charge` | A gateway account (Razorpay, Cashfree, PhonePe PG) with KYC for the shop |
| Cash at store | Order placed, staff mark it paid at the counter | Nothing |
| Cash on delivery | Only for local pincodes and under `codLimit` (₹15,000) | Delivery staff process |
| Reserve with token | ₹1,000 held for 72 hours, then expires | Gateway for the token |
| Bajaj Finance EMI | Customer applies, staff record the lender's decision, delivery after approval | A **dealer agreement** with Bajaj Finance, their real schemes and rates, their own application and KYC flow |
| Card EMI | Plan shown, charged as one EMI transaction | Bank EMI support enabled on the gateway |
| Autopay | UPI AutoPay, card and bank mandates, mocked | Gateway recurring-payments product, RBI e-mandate rules |

## Rules to keep

1. **Never store card numbers, CVV or expiry.** The app validates them on the
   phone and passes them to the gateway only. Use the gateway's hosted checkout
   or SDK so the shop stays out of PCI scope.
2. **Trust webhooks, not the app.** An order becomes paid only when a
   server-side webhook from the gateway confirms it, verified by signature.
3. **Bajaj approval is the lender's decision.** The EMI desk records what Bajaj
   says. The app must never promise approval or invent rates. Until the dealer
   agreement is signed, `emiRatesConfirmed` stays false and the app shows the
   rates as estimates.
4. **Lender-run mandates.** For Bajaj plans the lender collects through its own
   mandate; the app only mirrors the status.
5. **Shop-collected instalments are off** (`shopInstalmentsEnabled=false`).
   Lending or collecting instalments yourself can bring RBI and state
   money-lending rules into play. Get legal advice before turning it on.
6. **Refunds** go back through the gateway to the original method. Only the
   owner can issue them.
7. **UPI id and GSTIN** are empty until the shop enters its real ones.

## Steps to go live

1. Open a gateway account in the shop's or owner's name and complete KYC.
2. Write a `RazorpayGateway implements PaymentGateway` that creates a server-side
   order, opens the hosted checkout, and waits for the webhook result.
3. Add the webhook as a Cloud Function (`docs/BACKEND.md`) that verifies the
   signature and marks the order paid.
4. Ask Bajaj Finance for dealer onboarding (the shop's GST, PAN, bank, shop
   proof). Load their schemes into store settings, then set `emiRatesConfirmed`.
5. Test every mode with the gateway's test keys, including failures and
   refunds, then with ₹1 live payments.
6. Update the privacy policy: payment details are now shared with the gateway.

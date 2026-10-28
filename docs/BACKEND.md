# Backend plan (Firebase)

**Status: a plan. Nothing here has been built or tested.** The app currently runs
on local storage. The draft rules in `backend/firestore.rules` have not been run
against the emulator; do that before trusting them.

Why Firebase: phone OTP sign-in in India, realtime data that suits a shop's
live orders and stock, and a free tier that covers a single shop. Create the
Firebase project under the **personal** Google account that owns Brandhoop.

## Pieces

| Need | Service |
|---|---|
| Phone OTP sign-in | Firebase Authentication (phone provider) |
| Shared data | Cloud Firestore |
| Product photos, repair photos | Cloud Storage |
| Webhooks, roles, EMI reminders | Cloud Functions (Node, 2nd gen) |
| Notifications | Firebase Cloud Messaging |
| Crash reports (optional) | Crashlytics. If added, update the privacy policy and Play data safety |

## Collections

| Collection | Notes |
|---|---|
| `users/{uid}` | Profile, role mirror, addresses, wishlist. Role lives in the **custom claim**, not here |
| `products/{id}` | Public read, staff write. Costs are **not** here |
| `costs/{productId}` | Manager and owner only |
| `orders/{id}` | Owner of the order or staff. Payment fields written only by Functions |
| `emiPlans/{id}`, with `instalments` inside | Customer reads own; EMI desk writes status |
| `finance/{id}` | Profit ledger, owner only |
| `leads`, `repairs`, `offers`, `coupons` | Staff, with customer-visible repair status |
| `settings/store` | Public read, owner write (hours, address, schemes, limits) |

## Rules of the road

- The role is a **custom auth claim** (`role: customer|staff|manager|owner`) set by a
  Cloud Function that only the owner can call. The client never writes a role.
- Payment state (`paid`, gateway ids) is written only by the webhook Function after
  signature verification. Clients can create an order but never mark it paid.
- Stock decrements and order numbers go through a transaction or Function so two
  phones cannot sell the last unit.
- Never store card data. Never log OTPs.
- Enable App Check so only the real app can reach the project.

## Cloud Functions to write

1. `setRole` (owner only): sets the custom claim.
2. `razorpayWebhook`: verifies signature, marks order paid or failed, writes finance entry.
3. `createGatewayOrder`: server-side order creation for the gateway.
4. `expireStaleReservations`: scheduled, releases unpaid token reservations after 72 hours.
5. `emiReminders`: scheduled, notifies customers before an EMI is due.
6. `deleteAccount`: removes a user's personal data on request (needed for Play).

## Moving the app over

1. Add `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`.
2. Write `FirestoreRepositories` implementing the same repository interfaces.
3. Write `FirebaseAuthService` replacing the fixed-code service.
4. Select them in `AppServices.create` for non-demo builds. Screens do not change.
5. Update `site/privacy.html` and the Play data safety form (`store/README.md`).

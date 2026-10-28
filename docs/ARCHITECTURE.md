# Architecture

Flutter (Material 3), Dart 3, for Android, iOS and web. One app, two sides.

## Layers

```
lib/
  core/      pure Dart: money, EMI maths, validators, permissions, dates, ids
  domain/    plain value classes with toJson/fromJson (product, order, emi_plan, ...)
  data/      repositories (abstract) + local implementation over SharedPreferences, demo seed
  services/  business rules: checkout, orders, EMI, finance, leads, repairs, auth, payments
  state/     Cubits (flutter_bloc): session, cart, settings, stream cubits over repositories
  app/       theme, routes, go_router config, env
  features/  screens: customer side and features/admin
  widgets/   shared UI pieces
  l10n/      app_en.arb, app_hi.arb, generated AppLocalizations
```

Dependencies point downward only. `core` and `domain` import nothing from Flutter,
so the money and EMI logic is unit tested without a UI.

## Decisions worth knowing

- **Local first.** Repositories are interfaces. `Repositories.local` stores JSON in
  SharedPreferences. A Firestore implementation replaces it without touching
  services or screens (`docs/BACKEND.md`).
- **Services enforce rules, screens only ask.** Every staff action calls
  `requirePermission`. The router also gates `/admin/*`, but hiding a screen is
  never the only protection.
- **Costs live apart from orders.** `FinanceEntry` and `CostEntry` hold margins,
  so a customer-facing order never carries cost data.
- **Money is an integer rupee.** No doubles. `lib/core/money.dart` formats it,
  Indian digit grouping (₹1,25,000), and a compact lakh form in Hindi and English.
- **EMI maths** (`lib/core/emi.dart`): reducing balance, EMI rounded up, last
  instalment absorbs the rounding. No-cost EMI shows the shop's subvention as a cost.
- **Payments sit behind `PaymentGateway`.** The mock gateway is the only one today.
  `AuthService` is likewise an interface; the local one accepts one fixed code.
- **Roles.** `AppRole` maps to a `Permission` set in `lib/core/permissions.dart`.
  Staff can switch between customer and back-office mode (`SessionCubit`).
- **Language.** All text is in the ARB files. Enum labels are in
  `lib/l10n/labels.dart`. A test fails if the two ARBs drift apart in keys or
  placeholders. Use `context.tr.<key>`.
- **State.** Cubits only. Admin cubits take an `enabled` flag, so a customer
  never starts a stream of back-office data.

## Testing

`flutter test` runs unit tests (EMI, validators, permissions, pricing, finance,
analytics, services), a localisation parity test and widget flows over the
whole app: guest redirects, checkout, a customer's EMI plan, staff and owner
back-office views, Hindi labels.

## Editing translations

The ARBs in `lib/l10n/` are what `flutter gen-l10n` reads. Keep keys identical
in both. Do not use a straight apostrophe in a message; use ’.

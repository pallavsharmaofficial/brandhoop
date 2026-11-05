/// Build-time switches, set with `--dart-define`.
///
///   flutter run --dart-define=BRANDHOOP_DEMO=false     # the public storefront
///
/// **Demo** (the default while developing): sign-in accepts the code 123456,
/// payments are simulated, the quick-login chips and sample data appear, the
/// whole back office works on this phone, and every banner says so.
///
/// **Live**: the build customers get. There is no server yet, so it is a
/// storefront: the catalogue and offers come from `assets/live/shop.json` (and
/// the same file published on the site), there is no sign-in and no back
/// office, and an order or enquiry is sent to the shop on WhatsApp. Nothing
/// pretends to take a payment. See docs/LIVE.md.
class AppEnv {
  const AppEnv._();

  static const bool demo = bool.fromEnvironment('BRANDHOOP_DEMO', defaultValue: true);

  /// The public storefront build.
  static const bool live = !demo;
}

/// Build-time switches, set with `--dart-define`.
///
///   flutter run --dart-define=BRANDHOOP_DEMO=false
///
/// While there is no server, demo mode is on: sign-in accepts the code 123456,
/// payments are simulated, the quick-login chips and sample data appear, and
/// every banner says so. A build for real customers turns it off.
class AppEnv {
  const AppEnv._();

  static const bool demo = bool.fromEnvironment('BRANDHOOP_DEMO', defaultValue: true);
}

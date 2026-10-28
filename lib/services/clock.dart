/// Injected everywhere that needs "now", so tests can pin the date.
typedef Clock = DateTime Function();

DateTime systemClock() => DateTime.now();

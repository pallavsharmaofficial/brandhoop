/// A transparent, rule-based guess at what an old phone is worth, so a
/// customer sees a number before they walk in. Only the shop's inspection
/// gives the real value, and the screen says so.
enum PhoneAge { under6m, m6to12, y1to2, y2to3, over3y }

enum ScreenState { perfect, scratches, cracked }

enum BodyState { perfect, dents }

class ExchangeInput {
  const ExchangeInput({
    required this.originalPrice,
    required this.age,
    this.screen = ScreenState.perfect,
    this.body = BodyState.perfect,
    this.batteryWeak = false,
    this.allWorking = true,
    this.hasBill = true,
  });

  /// About what the phone cost new.
  final int originalPrice;
  final PhoneAge age;
  final ScreenState screen;
  final BodyState body;
  final bool batteryWeak;
  final bool allWorking;
  final bool hasBill;
}

class ExchangeEstimate {
  const ExchangeEstimate({required this.low, required this.high});

  final int low;
  final int high;
  int get mid => ((low + high) / 2 / 100).round() * 100;
}

class ExchangeEstimator {
  const ExchangeEstimator._();

  static double ageFactor(PhoneAge a) {
    switch (a) {
      case PhoneAge.under6m:
        return 0.62;
      case PhoneAge.m6to12:
        return 0.52;
      case PhoneAge.y1to2:
        return 0.40;
      case PhoneAge.y2to3:
        return 0.28;
      case PhoneAge.over3y:
        return 0.18;
    }
  }

  static ExchangeEstimate estimate(ExchangeInput i) {
    if (i.originalPrice <= 0) return const ExchangeEstimate(low: 0, high: 0);
    double v = i.originalPrice * ageFactor(i.age);
    switch (i.screen) {
      case ScreenState.perfect:
        break;
      case ScreenState.scratches:
        v *= 0.92;
      case ScreenState.cracked:
        v *= 0.70;
    }
    if (i.body == BodyState.dents) v *= 0.93;
    if (i.batteryWeak) v *= 0.92;
    if (!i.allWorking) v *= 0.75;
    v *= i.hasBill ? 1.0 : 0.93;
    int round(double x) => (x / 100).round() * 100;
    final int low = round(v * 0.92);
    final int high = round(v * 1.08);
    return ExchangeEstimate(low: low < 0 ? 0 : low, high: high < 0 ? 0 : high);
  }
}

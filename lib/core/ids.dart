import 'dart:math';

final Random _rng = Random();

/// Short, sortable-ish, collision-safe enough for a single shop's documents.
String newId(String prefix) {
  final String t = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final String r = _rng.nextInt(1 << 20).toRadixString(36).padLeft(4, '0');
  return '${prefix}_$t$r';
}

/// A six-digit code the customer shows at the counter to collect an order.
String newPickupCode() => (100000 + _rng.nextInt(900000)).toString();

/// A friendly referral code such as BH7K2Q (no 0/O/1/I to avoid mix-ups).
String newReferralCode() {
  const String alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  return 'BH${List<String>.generate(4, (_) => alphabet[_rng.nextInt(alphabet.length)]).join()}';
}

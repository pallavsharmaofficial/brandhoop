import 'package:intl/intl.dart';

/// Money in this app is whole rupees held in an `int`. Prices in a mobile shop
/// are whole rupees, and an int cannot drift the way a double does.
String formatRupees(num amount) {
  final NumberFormat f = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  return f.format(amount);
}

/// 500000 -> "₹5 L" / "₹5 लाख", 35000 -> "₹35K" / "₹35 हज़ार".
String formatCompactRupees(int amount, {bool hindi = false}) {
  final bool neg = amount < 0;
  final int a = amount.abs();
  String body;
  String num(double v) {
    final String s = v.toStringAsFixed(v >= 10 || v == v.roundToDouble() ? 0 : 1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  if (a >= 10000000) {
    body = '₹${num(a / 10000000)} ${hindi ? 'करोड़' : 'Cr'}';
  } else if (a >= 100000) {
    body = '₹${num(a / 100000)} ${hindi ? 'लाख' : 'L'}';
  } else if (a >= 1000) {
    body = hindi ? '₹${num(a / 1000)} हज़ार' : '₹${num(a / 1000)}K';
  } else {
    body = '₹$a';
  }
  return neg ? '-$body' : body;
}

/// Whole-percent discount from MRP to selling price, never negative.
int discountPercent(int mrp, int price) {
  if (mrp <= 0 || price >= mrp) return 0;
  return (((mrp - price) * 100) / mrp).round();
}

/// The GST contained in a GST-inclusive price.
int gstInside(int inclusive, double ratePct) {
  if (ratePct <= 0) return 0;
  return (inclusive * ratePct / (100 + ratePct)).round();
}

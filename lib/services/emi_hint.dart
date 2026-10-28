import '../core/emi.dart';
import '../domain/product.dart';
import '../domain/store_settings.dart';

/// The "EMI from ₹X a month" line on a product, and the schemes a product can use.
class EmiHint {
  const EmiHint({required this.emi, required this.months, required this.zeroInterest});

  final int emi;
  final int months;
  final bool zeroInterest;

  /// Schemes this product may be bought on: enabled, in range, and a no-cost
  /// scheme only for products the brand or shop has marked eligible.
  static List<EmiScheme> schemesFor(StoreSettings s, Product p, int price) => s.emiSchemes
      .where((EmiScheme x) =>
          p.emiEligible && x.allows(price) && (!x.noCost || p.noCostEmi))
      .toList();

  /// The lowest monthly figure over the longest tenure, preferring zero interest.
  static EmiHint? forProduct(StoreSettings s, Product p, int price) {
    final List<EmiScheme> schemes = schemesFor(s, p, price);
    if (schemes.isEmpty) return null;
    EmiHint? best;
    for (final EmiScheme x in schemes) {
      if (x.tenures.isEmpty) continue;
      final int months = x.tenures.reduce((int a, int b) => a > b ? a : b);
      final int down = (price * x.minDownPaymentPct / 100).ceil();
      final int principal = price - down;
      if (principal <= 0) continue;
      final int emi = Emi.quote(principal: principal, months: months, annualRatePct: x.annualRatePct).emi;
      final EmiHint h = EmiHint(emi: emi, months: months, zeroInterest: x.annualRatePct <= 0);
      if (best == null || h.emi < best.emi) best = h;
    }
    return best;
  }
}

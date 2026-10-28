import 'dart:math' as math;

/// Pure EMI arithmetic. Everything here is indicative: the lender's own
/// figures at approval are the ones that bind. The screens say so.
class EmiQuote {
  const EmiQuote({
    required this.principal,
    required this.months,
    required this.annualRatePct,
    required this.emi,
    required this.totalPayable,
    required this.instalments,
  });

  final int principal;
  final int months;
  final double annualRatePct;

  /// What the customer sees as "per month" (rounded up to a whole rupee).
  final int emi;

  /// Sum of every instalment.
  final int totalPayable;

  /// Each instalment; the last one absorbs the rounding so the sum is exact.
  final List<int> instalments;

  int get totalInterest => totalPayable - principal;
  bool get isZeroInterest => annualRatePct <= 0;
}

class Emi {
  const Emi._();

  /// Reducing-balance EMI as an unrounded double.
  static double exactMonthly({
    required int principal,
    required int months,
    required double annualRatePct,
  }) {
    if (months <= 0) throw ArgumentError.value(months, 'months', 'must be > 0');
    if (principal <= 0) return 0;
    if (annualRatePct <= 0) return principal / months;
    final double r = annualRatePct / 12 / 100;
    final double growth = math.pow(1 + r, months).toDouble();
    return principal * r * growth / (growth - 1);
  }

  static EmiQuote quote({
    required int principal,
    required int months,
    required double annualRatePct,
  }) {
    final double exact = exactMonthly(
      principal: principal,
      months: months,
      annualRatePct: annualRatePct,
    );
    final int emi = exact.ceil();
    final int total = annualRatePct <= 0
        ? principal
        : (exact * months).round();
    final List<int> parts = <int>[
      for (int i = 0; i < months - 1; i++) emi,
    ];
    parts.add(total - emi * (months - 1));
    return EmiQuote(
      principal: principal,
      months: months,
      annualRatePct: annualRatePct,
      emi: emi,
      totalPayable: total,
      instalments: parts,
    );
  }

  /// What a "no-cost" EMI costs whoever bears the interest: the interest the
  /// lender would have charged at [lenderRatePct]. A shop tracks this as a cost
  /// of the sale, because the customer pays only the price.
  static int subventionCost({
    required int principal,
    required int months,
    required double lenderRatePct,
  }) {
    if (principal <= 0) return 0;
    final EmiQuote q = quote(
      principal: principal,
      months: months,
      annualRatePct: lenderRatePct,
    );
    return math.max(0, q.totalPayable - principal);
  }

  /// The same date on the following month, clamped to that month's length
  /// (31 Jan + 1 month = 28/29 Feb), for building due dates.
  static DateTime addMonths(DateTime from, int months) {
    final int total = from.month - 1 + months;
    final int year = from.year + total ~/ 12;
    final int month = total % 12 + 1;
    final int lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, math.min(from.day, lastDay));
  }
}

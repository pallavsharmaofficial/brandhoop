import 'dart:math' as math;

import '../core/emi.dart';
import '../core/money.dart';
import '../domain/emi_plan.dart';
import '../domain/finance.dart';
import '../domain/order.dart';
import '../domain/payment.dart';
import '../domain/product.dart';
import '../domain/store_settings.dart';

/// Turns a delivered order into the shop's real profit. Pure: no storage, so it
/// can be tested to the rupee.
class ProfitCalculator {
  const ProfitCalculator._();

  static const String phones = 'phones';
  static const String accessories = 'accessories';
  static const String protection = 'protection';
  static const String repairs = 'repairs';

  static String groupKey(ProductGroup g) {
    switch (g) {
      case ProductGroup.phones:
        return phones;
      case ProductGroup.accessories:
        return accessories;
      case ProductGroup.protection:
        return protection;
    }
  }

  static FinanceEntry forOrder({
    required Order order,
    required Map<String, CostEntry> costs,
    required StoreSettings settings,
    EmiPlan? plan,
    DateTime? at,
  }) {
    final int discount = order.couponDiscount + order.coinsUsed;
    final int gross = order.lines.fold(0, (int s, OrderLine l) => s + l.total);
    final int revenue = gross - discount;

    int cost = 0;
    int gst = 0;
    final Map<String, int> byGroup = <String, int>{};
    int allocated = 0;
    for (int i = 0; i < order.lines.length; i++) {
      final OrderLine l = order.lines[i];
      // The discount is shared across lines by their share of the bill; the
      // last line takes the rounding so the shares add up exactly.
      final int share = i == order.lines.length - 1
          ? discount - allocated
          : (gross == 0 ? 0 : (discount * l.total / gross).round());
      allocated += share;
      final int lineRevenue = l.total - share;
      final int unitCost = costs[l.productId]?.costOf(l.variantId) ?? 0;
      // A product whose cost the owner never entered earns nothing in the
      // books rather than a made-up profit.
      final int lineCost = unitCost > 0 ? unitCost * l.qty : lineRevenue;
      final int margin = lineRevenue - lineCost;
      final int gstOnMargin = settings.profitExcludesGst && margin > 0
          ? gstInside(margin, l.gstRatePct)
          : 0;
      cost += lineCost;
      gst += gstOnMargin;
      final String g = groupKey(l.category.group);
      byGroup[g] = (byGroup[g] ?? 0) + (margin - gstOnMargin);
    }

    int fees = 0;
    for (final PaymentRecord p in order.payments) {
      if (p.kind != PaymentKind.payment || p.status != PaymentStatus.paid) {
        continue;
      }
      switch (p.method) {
        case PaymentMethod.upi:
          fees += (p.amount * settings.upiFeePct / 100).round();
        case PaymentMethod.card:
        case PaymentMethod.netbanking:
          fees += (p.amount * settings.cardFeePct / 100).round();
        case PaymentMethod.cash:
        case PaymentMethod.bajajEmi:
        case PaymentMethod.cardEmi:
          break;
      }
    }
    if (plan != null && plan.noCost) {
      final EmiScheme? s = settings.scheme(plan.schemeId);
      fees += Emi.subventionCost(
        principal: plan.principal,
        months: plan.months,
        lenderRatePct: s?.lenderRatePct ?? 15,
      );
    }

    // Fees come off the groups in proportion to what each earned.
    final int positive = byGroup.values
        .where((int v) => v > 0)
        .fold(0, (int s, int v) => s + v);
    if (fees > 0) {
      if (positive > 0) {
        int taken = 0;
        final List<String> keys =
            byGroup.keys.where((String k) => byGroup[k]! > 0).toList();
        for (int i = 0; i < keys.length; i++) {
          final String k = keys[i];
          final int part = i == keys.length - 1
              ? fees - taken
              : (fees * byGroup[k]! / positive).round();
          taken += part;
          byGroup[k] = byGroup[k]! - part;
        }
      } else if (byGroup.isNotEmpty) {
        final String k = byGroup.keys.first;
        byGroup[k] = byGroup[k]! - fees;
      }
    }

    final int profit = byGroup.values.fold(0, (int s, int v) => s + v);
    return FinanceEntry(
      id: order.id,
      kind: 'sale',
      at: at ?? order.deliveredAt ?? order.updatedAt,
      revenue: revenue,
      cost: cost,
      gst: gst,
      fees: fees,
      profit: profit,
      profitByGroup: byGroup,
    );
  }

  static FinanceEntry forRepair({
    required String ticketId,
    required int price,
    required int partsCost,
    required DateTime at,
    required StoreSettings settings,
  }) {
    final int margin = price - partsCost;
    final int gst = settings.profitExcludesGst && margin > 0
        ? gstInside(margin, 18)
        : 0;
    return FinanceEntry(
      id: ticketId,
      kind: 'repair',
      at: at,
      revenue: price,
      cost: partsCost,
      gst: gst,
      fees: 0,
      profit: margin - gst,
      profitByGroup: <String, int>{repairs: margin - gst},
    );
  }
}

/// How the month is going against the target.
class TargetProgress {
  const TargetProgress({
    required this.target,
    required this.monthToDate,
    required this.daysElapsed,
    required this.daysInMonth,
    required this.projected,
    required this.requiredPerDay,
    required this.dailyAverage,
    required this.byGroup,
  });

  final int target;
  final int monthToDate;
  final int daysElapsed;
  final int daysInMonth;

  /// Run-rate: month to date, scaled to the whole month.
  final int projected;

  /// What each remaining day (today included) must earn to still hit the target.
  final int requiredPerDay;
  final int dailyAverage;
  final Map<String, int> byGroup;

  double get percent =>
      target <= 0 ? 0 : (monthToDate / target).clamp(0.0, 1.0).toDouble();
  bool get onTrack => projected >= target;
  int get remaining => math.max(0, target - monthToDate);
  int get daysLeft => daysInMonth - daysElapsed + 1;
}

class TargetTracker {
  const TargetTracker._();

  static TargetProgress compute({
    required List<FinanceEntry> entries,
    required DateTime now,
    required int target,
  }) {
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final Map<String, int> byGroup = <String, int>{};
    int mtd = 0;
    for (final FinanceEntry e in entries) {
      final DateTime l = e.at.toLocal();
      if (l.year != now.year || l.month != now.month) continue;
      mtd += e.profit;
      e.profitByGroup.forEach((String k, int v) {
        byGroup[k] = (byGroup[k] ?? 0) + v;
      });
    }
    final int elapsed = math.max(1, now.day);
    final int left = daysInMonth - now.day + 1;
    return TargetProgress(
      target: target,
      monthToDate: mtd,
      daysElapsed: elapsed,
      daysInMonth: daysInMonth,
      projected: (mtd / elapsed * daysInMonth).round(),
      requiredPerDay: math.max(0, ((target - mtd) / math.max(1, left)).ceil()),
      dailyAverage: (mtd / elapsed).round(),
      byGroup: byGroup,
    );
  }
}

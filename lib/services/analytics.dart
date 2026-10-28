import '../domain/app_user.dart';
import '../domain/finance.dart';
import '../domain/lead.dart';
import '../domain/order.dart';
import '../domain/product.dart';
import '../domain/emi_plan.dart';

/// Numbers behind the dashboard and reports. Pure functions over lists, so the
/// screens stay thin and the arithmetic is tested.
class Analytics {
  const Analytics._();

  static bool _sameDay(DateTime a, DateTime b) {
    final DateTime x = a.toLocal();
    return x.year == b.year && x.month == b.month && x.day == b.day;
  }

  /// Orders that left the shop (delivered), whenever they were placed.
  static Iterable<Order> sold(Iterable<Order> orders) =>
      orders.where((Order o) => o.status == OrderStatus.delivered && o.deliveredAt != null);

  static Iterable<Order> soldBetween(Iterable<Order> orders, DateTime from, DateTime to) =>
      sold(orders).where((Order o) {
        final DateTime d = o.deliveredAt!.toLocal();
        return !d.isBefore(from) && d.isBefore(to);
      });

  /// Revenue of orders delivered on [day].
  static int revenueOn(Iterable<Order> orders, DateTime day) => sold(orders)
      .where((Order o) => _sameDay(o.deliveredAt!, day))
      .fold(0, (int s, Order o) => s + o.total - o.deliveryFee);

  /// One bar per day for the last [days] days, oldest first.
  static List<DayStats> daily({
    required List<FinanceEntry> entries,
    required List<Order> orders,
    required DateTime now,
    int days = 14,
  }) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    return <DayStats>[
      for (int i = days - 1; i >= 0; i--)
        () {
          final DateTime d = today.subtract(Duration(days: i));
          final int profit = entries
              .where((FinanceEntry e) => _sameDay(e.at, d))
              .fold(0, (int s, FinanceEntry e) => s + e.profit);
          return DayStats(day: d, revenue: revenueOn(orders, d), profit: profit);
        }(),
    ];
  }

  /// Units sold per product over [from, to), best first.
  static List<({String name, int units, int revenue})> topProducts(
    Iterable<Order> orders,
    DateTime from,
    DateTime to, {
    int limit = 8,
  }) {
    final Map<String, ({String name, int units, int revenue})> m = <String, ({String name, int units, int revenue})>{};
    for (final Order o in soldBetween(orders, from, to)) {
      for (final OrderLine l in o.lines) {
        final ({String name, int units, int revenue})? cur = m[l.productId];
        m[l.productId] = (
          name: l.name,
          units: (cur?.units ?? 0) + l.qty,
          revenue: (cur?.revenue ?? 0) + l.total,
        );
      }
    }
    final List<({String name, int units, int revenue})> list = m.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    return list.take(limit).toList();
  }

  /// Share of phone sales that also carried an accessory or a protection plan.
  static double attachRate(Iterable<Order> sales) {
    int phones = 0;
    int attached = 0;
    for (final Order o in sales) {
      if (!o.lines.any((OrderLine l) => l.category.needsImei)) continue;
      phones++;
      if (o.lines.any((OrderLine l) => l.category.group != ProductGroup.phones)) attached++;
    }
    return phones == 0 ? 0 : attached / phones;
  }

  static double protectionRate(Iterable<Order> sales) {
    int phones = 0;
    int protected = 0;
    for (final Order o in sales) {
      if (!o.lines.any((OrderLine l) => l.category.needsImei)) continue;
      phones++;
      if (o.lines.any((OrderLine l) => l.category == ProductCategory.protection)) protected++;
    }
    return phones == 0 ? 0 : protected / phones;
  }

  static int phoneUnits(Iterable<Order> sales) => sales.fold(
        0,
        (int s, Order o) => s + o.lines.where((OrderLine l) => l.category.needsImei).fold(0, (int a, OrderLine l) => a + l.qty),
      );

  /// Customers whose last phone purchase was at least [months] months ago.
  static List<({AppUser user, DateTime lastPhone, int lifetime})> upgradeDue(
    List<Order> orders,
    List<AppUser> users,
    DateTime now, {
    int months = 18,
  }) {
    final Map<String, DateTime> last = <String, DateTime>{};
    final Map<String, int> spend = <String, int>{};
    for (final Order o in sold(orders)) {
      spend[o.customerId] = (spend[o.customerId] ?? 0) + o.total;
      if (!o.lines.any((OrderLine l) => l.category.needsImei)) continue;
      final DateTime d = o.deliveredAt!;
      final DateTime? cur = last[o.customerId];
      if (cur == null || d.isAfter(cur)) last[o.customerId] = d;
    }
    final DateTime cutoff = DateTime(now.year, now.month - months, now.day);
    final List<({AppUser user, DateTime lastPhone, int lifetime})> out = <({AppUser user, DateTime lastPhone, int lifetime})>[];
    for (final AppUser u in users) {
      final DateTime? d = last[u.id];
      if (d != null && !d.isAfter(cutoff)) out.add((user: u, lastPhone: d, lifetime: spend[u.id] ?? 0));
    }
    out.sort((a, b) => a.lastPhone.compareTo(b.lastPhone));
    return out;
  }

  /// Total each customer has bought, biggest first.
  static Map<String, int> lifetimeSpend(List<Order> orders) {
    final Map<String, int> m = <String, int>{};
    for (final Order o in sold(orders)) {
      m[o.customerId] = (m[o.customerId] ?? 0) + o.total;
    }
    return m;
  }

  /// Share of sales in the period that came from a customer who had bought before.
  static double repeatRate(List<Order> orders, DateTime from, DateTime to) {
    final List<Order> all = sold(orders).toList()
      ..sort((Order a, Order b) => a.deliveredAt!.compareTo(b.deliveredAt!));
    final Set<String> seen = <String>{};
    int inPeriod = 0;
    int repeat = 0;
    for (final Order o in all) {
      final DateTime d = o.deliveredAt!.toLocal();
      final bool known = seen.contains(o.customerId);
      seen.add(o.customerId);
      if (d.isBefore(from) || !d.isBefore(to)) continue;
      inPeriod++;
      if (known) repeat++;
    }
    return inPeriod == 0 ? 0 : repeat / inPeriod;
  }

  /// Leads created in the period and the share that ended in a sale.
  static ({int total, int converted}) leadFunnel(List<Lead> leads, DateTime from, DateTime to) {
    final Iterable<Lead> l = leads.where((Lead x) => !x.createdAt.toLocal().isBefore(from) && x.createdAt.toLocal().isBefore(to));
    return (total: l.length, converted: l.where((Lead x) => x.status == LeadStatus.converted).length);
  }

  /// Instalments past due across all live plans.
  static ({int count, int amount}) overdueEmi(List<EmiPlan> plans, DateTime now) {
    int c = 0;
    int a = 0;
    for (final EmiPlan p in plans) {
      if (p.status != EmiPlanStatus.active) continue;
      for (final Instalment i in p.instalments) {
        if (i.statusAt(now) == InstalmentStatus.overdue) {
          c++;
          a += i.amount;
        }
      }
    }
    return (count: c, amount: a);
  }

  /// Variants at or below [threshold] units.
  static List<({Product product, ProductVariant variant})> lowStock(List<Product> products, {int threshold = 3}) {
    final List<({Product product, ProductVariant variant})> out = <({Product product, ProductVariant variant})>[];
    for (final Product p in products) {
      if (!p.active) continue;
      for (final ProductVariant v in p.variants) {
        if (v.stock <= threshold) out.add((product: p, variant: v));
      }
    }
    out.sort((a, b) => a.variant.stock.compareTo(b.variant.stock));
    return out;
  }
}

class DayStats {
  const DayStats({required this.day, required this.revenue, required this.profit});
  final DateTime day;
  final int revenue;
  final int profit;
}

/// The monthly levers behind the 5 lakh target at the end of the 12-month plan
/// (docs/GROWTH_PLAN.md). They are the arithmetic of the target, not forecasts:
/// the owner should replace them with what the shop can really reach.
class GrowthTargets {
  const GrowthTargets._();

  static const int phonesPerMonth = 220;
  static const double attachRate = 0.70;
  static const double protectionRate = 0.40;
  static const double leadConversion = 0.35;
  static const double repeatRate = 0.40;
  static const int repairsPerMonth = 220;
}

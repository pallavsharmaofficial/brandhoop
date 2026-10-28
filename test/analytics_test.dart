import 'package:brandhoop/domain/app_user.dart';
import 'package:brandhoop/domain/finance.dart';
import 'package:brandhoop/domain/lead.dart';
import 'package:brandhoop/domain/localized_text.dart';
import 'package:brandhoop/domain/order.dart';
import 'package:brandhoop/domain/product.dart';
import 'package:brandhoop/services/analytics.dart';
import 'package:flutter_test/flutter_test.dart';

OrderLine line(String id, ProductCategory c, int price, {int qty = 1}) => OrderLine(
      productId: id,
      variantId: '$id-v1',
      name: id,
      variantLabel: 'v',
      category: c,
      qty: qty,
      unitPrice: price,
      unitMrp: price,
    );

Order order(String id, String cust, DateTime at, List<OrderLine> lines, {OrderStatus status = OrderStatus.delivered}) {
  final int total = lines.fold(0, (int s, OrderLine l) => s + l.total);
  return Order(
    id: id,
    number: id,
    customerId: cust,
    customerName: cust,
    customerPhone: '9000000011',
    lines: lines,
    fulfilment: Fulfilment.walkIn,
    subtotal: total,
    total: total,
    status: status,
    createdAt: at,
    updatedAt: at,
    deliveredAt: status == OrderStatus.delivered ? at : null,
  );
}

void main() {
  final DateTime now = DateTime(2026, 10, 20, 12);

  test('attach and protection rates count phone sales only', () {
    final List<Order> sales = <Order>[
      order('a', 'c1', now, <OrderLine>[line('p', ProductCategory.smartphone, 15000), line('g', ProductCategory.screenGuard, 149)]),
      order('b', 'c2', now, <OrderLine>[line('p', ProductCategory.smartphone, 15000), line('w', ProductCategory.protection, 499)]),
      order('c', 'c3', now, <OrderLine>[line('p', ProductCategory.smartphone, 15000)]),
      order('d', 'c4', now, <OrderLine>[line('g', ProductCategory.screenGuard, 149)]),
    ];
    expect(Analytics.attachRate(sales), closeTo(2 / 3, 0.0001));
    expect(Analytics.protectionRate(sales), closeTo(1 / 3, 0.0001));
    expect(Analytics.phoneUnits(sales), 3);
    expect(Analytics.attachRate(const <Order>[]), 0);
  });

  test('only delivered orders count as sold', () {
    final List<Order> os = <Order>[
      order('a', 'c1', now, <OrderLine>[line('p', ProductCategory.smartphone, 10000)]),
      order('b', 'c1', now, <OrderLine>[line('p', ProductCategory.smartphone, 10000)], status: OrderStatus.cancelled),
      order('c', 'c1', now, <OrderLine>[line('p', ProductCategory.smartphone, 10000)], status: OrderStatus.placed),
    ];
    expect(Analytics.sold(os), hasLength(1));
    expect(Analytics.revenueOn(os, DateTime(2026, 10, 20)), 10000);
    expect(Analytics.revenueOn(os, DateTime(2026, 10, 19)), 0);
  });

  test('daily series is oldest first and sums per day', () {
    final List<FinanceEntry> es = <FinanceEntry>[
      FinanceEntry(id: '1', kind: 'sale', at: DateTime(2026, 10, 20, 10), revenue: 0, cost: 0, gst: 0, fees: 0, profit: 700),
      FinanceEntry(id: '2', kind: 'sale', at: DateTime(2026, 10, 20, 15), revenue: 0, cost: 0, gst: 0, fees: 0, profit: 300),
      FinanceEntry(id: '3', kind: 'sale', at: DateTime(2026, 10, 18), revenue: 0, cost: 0, gst: 0, fees: 0, profit: 50),
    ];
    final List<DayStats> d = Analytics.daily(entries: es, orders: const <Order>[], now: now, days: 3);
    expect(d.map((DayStats x) => x.day.day), <int>[18, 19, 20]);
    expect(d.map((DayStats x) => x.profit), <int>[50, 0, 1000]);
  });

  test('top products rank by revenue', () {
    final List<Order> os = <Order>[
      order('a', 'c1', now, <OrderLine>[line('cheap', ProductCategory.caseCover, 100, qty: 5), line('dear', ProductCategory.smartphone, 9000)]),
    ];
    final top = Analytics.topProducts(os, DateTime(2026, 10, 1), DateTime(2026, 11, 1));
    expect(top.first.name, 'dear');
    expect(top.last.units, 5);
  });

  test('upgrade due lists customers whose last phone is old enough', () {
    final AppUser old = AppUser(id: 'old', phone: '9000000011', createdAt: now);
    final AppUser fresh = AppUser(id: 'fresh', phone: '9000000012', createdAt: now);
    final AppUser accOnly = AppUser(id: 'acc', phone: '9000000013', createdAt: now);
    final List<Order> os = <Order>[
      order('a', 'old', DateTime(2025, 1, 5), <OrderLine>[line('p', ProductCategory.smartphone, 12000)]),
      order('b', 'fresh', DateTime(2026, 9, 1), <OrderLine>[line('p', ProductCategory.smartphone, 12000)]),
      order('c', 'acc', DateTime(2024, 1, 1), <OrderLine>[line('g', ProductCategory.screenGuard, 100)]),
    ];
    final due = Analytics.upgradeDue(os, <AppUser>[old, fresh, accOnly], now);
    expect(due.map((r) => r.user.id), <String>['old']);
    expect(due.single.lifetime, 12000);
  });

  test('repeat rate counts only customers who bought before', () {
    final List<Order> os = <Order>[
      order('a', 'c1', DateTime(2026, 9, 1), <OrderLine>[line('p', ProductCategory.caseCover, 100)]),
      order('b', 'c1', DateTime(2026, 10, 5), <OrderLine>[line('p', ProductCategory.caseCover, 100)]),
      order('c', 'c2', DateTime(2026, 10, 6), <OrderLine>[line('p', ProductCategory.caseCover, 100)]),
    ];
    expect(Analytics.repeatRate(os, DateTime(2026, 10, 1), DateTime(2026, 11, 1)), 0.5);
  });

  test('lead funnel', () {
    Lead l(String id, LeadStatus s, DateTime at) => Lead(id: id, type: LeadType.enquiry, status: s, name: 'n', phone: '9000000011', createdAt: at, updatedAt: at);
    final f = Analytics.leadFunnel(
      <Lead>[l('1', LeadStatus.converted, now), l('2', LeadStatus.fresh, now), l('3', LeadStatus.converted, DateTime(2026, 8, 1))],
      DateTime(2026, 10, 1),
      DateTime(2026, 11, 1),
    );
    expect(f.total, 2);
    expect(f.converted, 1);
  });

  test('low stock lists the thinnest first and skips inactive products', () {
    Product p(String id, int stock, {bool active = true}) => Product(
          id: id,
          name: LocalizedText(id),
          brand: 'b',
          category: ProductCategory.caseCover,
          variants: <ProductVariant>[ProductVariant(id: '$id-v1', label: 'v', price: 1, mrp: 1, stock: stock)],
          active: active,
          createdAt: now,
        );
    final r = Analytics.lowStock(<Product>[p('a', 2), p('b', 0), p('c', 9), p('d', 1, active: false)]);
    expect(r.map((x) => x.product.id), <String>['b', 'a']);
  });
}

import 'package:brandhoop/core/emi.dart';
import 'package:brandhoop/domain/emi_plan.dart';
import 'package:brandhoop/domain/finance.dart';
import 'package:brandhoop/domain/order.dart';
import 'package:brandhoop/domain/payment.dart';
import 'package:brandhoop/domain/product.dart';
import 'package:brandhoop/services/finance_calc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

OrderLine line(String pid, int price, {int qty = 1, ProductCategory c = ProductCategory.smartphone}) =>
    OrderLine(
      productId: pid,
      variantId: '$pid-v1',
      name: pid,
      variantLabel: 'v',
      category: c,
      qty: qty,
      unitPrice: price,
      unitMrp: price,
    );

Order order(
  List<OrderLine> lines, {
  int discount = 0,
  PaymentMethod method = PaymentMethod.upi,
}) {
  final int sub = lines.fold(0, (int s, OrderLine l) => s + l.total);
  return Order(
    id: 'o1',
    number: 'BH-2610-0001',
    customerId: 'c',
    customerName: 'C',
    customerPhone: '9000000011',
    lines: lines,
    fulfilment: Fulfilment.pickup,
    subtotal: sub,
    couponDiscount: discount,
    total: sub - discount,
    payments: <PaymentRecord>[
      PaymentRecord(
        id: 'p',
        method: method,
        amount: sub - discount,
        status: PaymentStatus.paid,
        at: t0,
      ),
    ],
    status: OrderStatus.delivered,
    createdAt: t0,
    updatedAt: t0,
    deliveredAt: t0,
  );
}

Map<String, CostEntry> costs(Map<String, int> unit) => <String, CostEntry>{
      for (final MapEntry<String, int> e in unit.entries)
        e.key: CostEntry(productId: e.key, costs: <String, int>{'${e.key}-v1': e.value}),
    };

void main() {
  group('ProfitCalculator', () {
    test('margin is taken after the GST on the margin', () {
      final FinanceEntry e = ProfitCalculator.forOrder(
        order: order(<OrderLine>[line('p1', 15000)]),
        costs: costs(<String, int>{'p1': 14000}),
        settings: settings(),
      );
      expect(e.revenue, 15000);
      expect(e.cost, 14000);
      expect(e.gst, 153);
      expect(e.fees, 0);
      expect(e.profit, 847);
      expect(e.profitByGroup, <String, int>{'phones': 847});
    });

    test('card payments cost the gateway fee', () {
      final FinanceEntry e = ProfitCalculator.forOrder(
        order: order(<OrderLine>[line('p1', 15000)], method: PaymentMethod.card),
        costs: costs(<String, int>{'p1': 14000}),
        settings: settings(),
      );
      expect(e.fees, 300);
      expect(e.profit, 847 - 300);
    });

    test('a discount comes out of the margin', () {
      final FinanceEntry e = ProfitCalculator.forOrder(
        order: order(<OrderLine>[line('p1', 15000)], discount: 200),
        costs: costs(<String, int>{'p1': 14000}),
        settings: settings(),
      );
      expect(e.revenue, 14800);
      expect(e.profit, 800 - 122);
    });

    test('a discount over several lines adds up exactly', () {
      final FinanceEntry e = ProfitCalculator.forOrder(
        order: order(<OrderLine>[
          line('p1', 10000),
          line('a1', 333, c: ProductCategory.caseCover),
          line('a2', 777, c: ProductCategory.charger),
        ], discount: 101),
        costs: costs(<String, int>{'p1': 9000, 'a1': 100, 'a2': 300}),
        settings: settings().copyWith(profitExcludesGst: false),
      );
      expect(e.revenue, 11110 - 101);
      expect(e.cost, 9000 + 100 + 300);
      expect(e.profit, e.revenue - e.cost);
      expect(e.profitByGroup.values.reduce((int a, int b) => a + b), e.profit);
    });

    test('a product with no cost entered earns nothing rather than a guess', () {
      final FinanceEntry e = ProfitCalculator.forOrder(
        order: order(<OrderLine>[line('p1', 15000)]),
        costs: const <String, CostEntry>{},
        settings: settings(),
      );
      expect(e.profit, 0);
    });

    test('a loss is not reduced by GST', () {
      final FinanceEntry e = ProfitCalculator.forOrder(
        order: order(<OrderLine>[line('p1', 9000)]),
        costs: costs(<String, int>{'p1': 10000}),
        settings: settings(),
      );
      expect(e.profit, -1000);
      expect(e.gst, 0);
    });

    test('a no-cost EMI is charged the interest the lender would have taken', () {
      final EmiPlan plan = EmiPlan(
        id: 'e',
        orderId: 'o1',
        orderNumber: 'BH-2610-0001',
        customerId: 'c',
        customerName: 'C',
        customerPhone: '9000000011',
        provider: EmiProvider.bajaj,
        schemeId: 'bajaj_nocost',
        productSummary: 'p',
        price: 15000,
        downPayment: 5000,
        principal: 10000,
        months: 6,
        annualRatePct: 0,
        emi: 1667,
        noCost: true,
        createdAt: t0,
      );
      final FinanceEntry e = ProfitCalculator.forOrder(
        order: order(<OrderLine>[line('p1', 15000)]),
        costs: costs(<String, int>{'p1': 14000}),
        settings: settings(),
        plan: plan,
      );
      final int sub = Emi.subventionCost(principal: 10000, months: 6, lenderRatePct: 15);
      expect(sub, greaterThan(400));
      expect(e.fees, sub);
      expect(e.profit, 847 - sub);
    });

    test('a repair books its own profit', () {
      final FinanceEntry e = ProfitCalculator.forRepair(
        ticketId: 'r1',
        price: 1200,
        partsCost: 500,
        at: t0,
        settings: settings(),
      );
      expect(e.kind, 'repair');
      expect(e.profit, 700 - gstInsideFor(700));
      expect(e.profitByGroup, <String, int>{'repairs': e.profit});
    });
  });

  group('TargetTracker', () {
    FinanceEntry entry(DateTime at, int profit, [String group = 'phones']) => FinanceEntry(
          id: '${at.microsecondsSinceEpoch}$profit',
          kind: 'sale',
          at: at,
          revenue: 0,
          cost: 0,
          gst: 0,
          fees: 0,
          profit: profit,
          profitByGroup: <String, int>{group: profit},
        );

    test('counts only this month and projects the month', () {
      final DateTime now = DateTime(2026, 10, 10, 12);
      final TargetProgress p = TargetTracker.compute(
        entries: <FinanceEntry>[
          entry(DateTime(2026, 10, 2), 10000),
          entry(DateTime(2026, 10, 9), 5000, 'accessories'),
          entry(DateTime(2026, 9, 30), 99999),
        ],
        now: now,
        target: 500000,
      );
      expect(p.monthToDate, 15000);
      expect(p.daysElapsed, 10);
      expect(p.daysInMonth, 31);
      expect(p.projected, 46500);
      expect(p.dailyAverage, 1500);
      expect(p.daysLeft, 22);
      expect(p.requiredPerDay, ((500000 - 15000) / 22).ceil());
      expect(p.percent, closeTo(0.03, 0.0001));
      expect(p.onTrack, isFalse);
      expect(p.byGroup, <String, int>{'phones': 10000, 'accessories': 5000});
    });

    test('is on track when the run rate beats the target', () {
      final TargetProgress p = TargetTracker.compute(
        entries: <FinanceEntry>[entry(DateTime(2026, 10, 1), 400000)],
        now: DateTime(2026, 10, 15),
        target: 500000,
      );
      expect(p.onTrack, isTrue);
      expect(p.remaining, 100000);
    });

    test('never asks for a negative amount once the target is passed', () {
      final TargetProgress p = TargetTracker.compute(
        entries: <FinanceEntry>[entry(DateTime(2026, 10, 1), 600000)],
        now: DateTime(2026, 10, 20),
        target: 500000,
      );
      expect(p.requiredPerDay, 0);
      expect(p.percent, 1.0);
    });

    test('the first of the month does not divide by zero', () {
      final TargetProgress p = TargetTracker.compute(
        entries: const <FinanceEntry>[],
        now: DateTime(2026, 10, 1),
        target: 500000,
      );
      expect(p.projected, 0);
      expect(p.requiredPerDay, (500000 / 31).ceil());
    });
  });
}

int gstInsideFor(int margin) => (margin * 18 / 118).round();

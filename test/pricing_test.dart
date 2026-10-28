import 'package:brandhoop/domain/cart.dart';
import 'package:brandhoop/domain/localized_text.dart';
import 'package:brandhoop/domain/offer.dart';
import 'package:brandhoop/domain/order.dart';
import 'package:brandhoop/domain/product.dart';
import 'package:brandhoop/domain/store_settings.dart';
import 'package:brandhoop/services/payment_rules.dart';
import 'package:brandhoop/services/pricing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

Offer coupon({
  String code = 'DIWALI10',
  DiscountKind kind = DiscountKind.percent,
  int value = 10,
  int minOrder = 0,
  int maxDiscount = 0,
  List<ProductGroup> groups = const <ProductGroup>[],
  bool active = true,
  DateTime? ends,
}) =>
    Offer(
      id: 'o_$code',
      kind: OfferKind.coupon,
      title: const LocalizedText('Offer'),
      code: code,
      discountKind: kind,
      value: value,
      minOrder: minOrder,
      maxDiscount: maxDiscount,
      groups: groups,
      startsAt: DateTime(2026),
      endsAt: ends ?? DateTime(2027),
      active: active,
    );

Quote quote(
  List<CartLine> cart, {
  Fulfilment f = Fulfilment.pickup,
  String? pin,
  List<Offer> offers = const <Offer>[],
  String? code,
  int coins = 0,
  int balance = 0,
  StoreSettings? s,
}) {
  final Product p = phone();
  final Product a = accessory();
  return Pricing.quote(
    cart: cart,
    catalogue: <String, Product>{p.id: p, a.id: a},
    settings: s ?? settings(),
    fulfilment: f,
    pincode: pin,
    offers: offers,
    couponCode: code,
    coinsToUse: coins,
    coinBalance: balance,
    now: t0,
  );
}

void main() {
  const CartLine phoneLine = CartLine(productId: 'p1', variantId: 'p1-v1');
  const CartLine caseLine = CartLine(productId: 'a1', variantId: 'a1-v1', qty: 2);

  test('totals come from the catalogue, not the cart', () {
    final Quote q = quote(<CartLine>[phoneLine, caseLine]);
    expect(q.subtotal, 15000 + 1000);
    expect(q.mrpTotal, 17000 + 1400);
    expect(q.savings, 2400);
    expect(q.total, 16000);
    expect(q.isValid, isTrue);
    expect(q.hasPhone, isTrue);
  });

  test('flags unavailable products and short stock', () {
    final Quote q = quote(<CartLine>[
      const CartLine(productId: 'gone', variantId: 'x'),
      const CartLine(productId: 'p1', variantId: 'p1-v1', qty: 9),
    ]);
    expect(q.isValid, isFalse);
    expect(q.issues.map((LineIssue i) => i.problem), <LineProblem>[
      LineProblem.unavailable,
      LineProblem.insufficientStock,
    ]);
    expect(q.issues.last.available, 5);
  });

  group('delivery', () {
    test('pickup is free', () {
      expect(quote(<CartLine>[phoneLine]).deliveryFee, 0);
    });
    test('local pincode uses the local fee', () {
      final Quote q =
          quote(<CartLine>[phoneLine], f: Fulfilment.delivery, pin: '332713');
      expect(q.deliveryFee, 0);
      final Quote q2 = quote(
        <CartLine>[phoneLine],
        f: Fulfilment.delivery,
        pin: '332713',
        s: settings().copyWith(localDeliveryFee: 40),
      );
      expect(q2.deliveryFee, 40);
    });
    test('courier fee applies under the free threshold only', () {
      final Quote small = quote(<CartLine>[
        const CartLine(productId: 'a1', variantId: 'a1-v1'),
      ], f: Fulfilment.delivery, pin: '302001');
      expect(small.deliveryFee, 99);
      final Quote big =
          quote(<CartLine>[phoneLine], f: Fulfilment.delivery, pin: '302001');
      expect(big.deliveryFee, 0);
    });
  });

  group('coupons', () {
    test('percent with cap', () {
      final Quote q = quote(
        <CartLine>[phoneLine],
        offers: <Offer>[coupon(value: 10, maxDiscount: 500)],
        code: 'diwali10',
      );
      expect(q.couponDiscount, 500);
      expect(q.total, 14500);
    });
    test('flat never exceeds what it applies to', () {
      final Quote q = quote(
        <CartLine>[const CartLine(productId: 'a1', variantId: 'a1-v1')],
        offers: <Offer>[coupon(kind: DiscountKind.flat, value: 900)],
        code: 'DIWALI10',
      );
      expect(q.couponDiscount, 500);
      expect(q.total, 0);
    });
    test('group restriction only discounts matching lines', () {
      final Quote q = quote(
        <CartLine>[phoneLine, caseLine],
        offers: <Offer>[
          coupon(value: 50, groups: <ProductGroup>[ProductGroup.accessories]),
        ],
        code: 'DIWALI10',
      );
      expect(q.couponDiscount, 500);
    });
    test('reports why a coupon does not work', () {
      expect(
        quote(<CartLine>[phoneLine], code: 'NOPE').couponError,
        CouponError.notFound,
      );
      expect(
        quote(<CartLine>[phoneLine],
            offers: <Offer>[coupon(active: false)],
            code: 'DIWALI10').couponError,
        CouponError.notActive,
      );
      expect(
        quote(<CartLine>[phoneLine],
            offers: <Offer>[coupon(ends: DateTime(2026, 10, 1))],
            code: 'DIWALI10').couponError,
        CouponError.notActive,
      );
      expect(
        quote(<CartLine>[phoneLine],
            offers: <Offer>[coupon(minOrder: 20000)],
            code: 'DIWALI10').couponError,
        CouponError.minOrder,
      );
      expect(
        quote(<CartLine>[phoneLine],
            offers: <Offer>[
              coupon(groups: <ProductGroup>[ProductGroup.accessories]),
            ],
            code: 'DIWALI10').couponError,
        CouponError.notApplicable,
      );
    });
  });

  group('coins', () {
    test('only work on accessories and are capped', () {
      // Accessories total 1000, cap is 10% = 100.
      final Quote q = quote(<CartLine>[phoneLine, caseLine], coins: 500, balance: 500);
      expect(q.coinsUsed, 100);
      expect(q.total, 16000 - 100);
    });
    test('cannot exceed the balance and never go negative', () {
      expect(
        quote(<CartLine>[caseLine], coins: 500, balance: 30).coinsUsed,
        30,
      );
      expect(quote(<CartLine>[caseLine], coins: -5, balance: 30).coinsUsed, 0);
    });
    test('a phone alone cannot be paid for with coins', () {
      expect(
        quote(<CartLine>[phoneLine], coins: 500, balance: 500).coinsUsed,
        0,
      );
    });
  });

  group('payment rules', () {
    List<PayChoice> choices(Quote q, Fulfilment f, String? pin, [StoreSettings? s]) =>
        PaymentRules.available(
          settings: s ?? settings(),
          quote: q,
          fulfilment: f,
          pincode: pin,
        );

    test('pickup of a phone offers cash, reserve and both EMIs', () {
      final Quote q = quote(<CartLine>[phoneLine]);
      final List<PayChoice> c = choices(q, Fulfilment.pickup, null);
      expect(c, containsAll(<PayChoice>[
        PayChoice.upi,
        PayChoice.card,
        PayChoice.netbanking,
        PayChoice.cashAtStore,
        PayChoice.reserve,
        PayChoice.bajajEmi,
        PayChoice.cardEmi,
      ]));
      expect(c, isNot(contains(PayChoice.cashOnDelivery)));
    });

    test('cash on delivery only in town and under the limit', () {
      final Quote q = quote(<CartLine>[phoneLine], f: Fulfilment.delivery, pin: '332713');
      expect(choices(q, Fulfilment.delivery, '332713'),
          contains(PayChoice.cashOnDelivery));
      expect(choices(q, Fulfilment.delivery, '302001'),
          isNot(contains(PayChoice.cashOnDelivery)));
      final StoreSettings low = settings().copyWith(codLimit: 5000);
      expect(choices(q, Fulfilment.delivery, '332713', low),
          isNot(contains(PayChoice.cashOnDelivery)));
    });

    test('accessories alone cannot be financed or reserved', () {
      final Quote q = quote(<CartLine>[caseLine]);
      final List<PayChoice> c = choices(q, Fulfilment.pickup, null);
      expect(c, isNot(contains(PayChoice.bajajEmi)));
      expect(c, isNot(contains(PayChoice.cardEmi)));
      expect(c, isNot(contains(PayChoice.reserve)));
    });

    test('switching a lender off removes its option', () {
      final Quote q = quote(<CartLine>[phoneLine]);
      final List<PayChoice> c = choices(
        q,
        Fulfilment.pickup,
        null,
        settings().copyWith(bajajEnabled: false),
      );
      expect(c, isNot(contains(PayChoice.bajajEmi)));
      expect(c, contains(PayChoice.cardEmi));
    });

    test('down payment is clamped to the scheme and the price', () {
      final EmiScheme s = settings().scheme('bajaj_nocost')!; // 10% minimum
      expect(PaymentRules.minDownPayment(s, 15000), 1500);
      expect(PaymentRules.clampDown(s, 15000, 0), 1500);
      expect(PaymentRules.clampDown(s, 15000, 99999), 14999);
      expect(PaymentRules.clampDown(s, 15000, 3000), 3000);
    });
  });
}

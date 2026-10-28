import 'package:equatable/equatable.dart';

import '../domain/cart.dart';
import '../domain/offer.dart';
import '../domain/order.dart';
import '../domain/product.dart';
import '../domain/store_settings.dart';

class PricedLine extends Equatable {
  const PricedLine({
    required this.product,
    required this.variant,
    required this.qty,
  });

  final Product product;
  final ProductVariant variant;
  final int qty;

  int get total => variant.price * qty;
  int get mrpTotal => variant.mrp * qty;

  @override
  List<Object?> get props => <Object?>[product, variant, qty];
}

enum LineProblem { unavailable, insufficientStock }

class LineIssue extends Equatable {
  const LineIssue(this.line, this.problem, this.available);

  final CartLine line;
  final LineProblem problem;
  final int available;

  @override
  List<Object?> get props => <Object?>[line, problem, available];
}

enum CouponError { notFound, notActive, minOrder, notApplicable }

class Quote extends Equatable {
  const Quote({
    required this.lines,
    required this.issues,
    required this.subtotal,
    required this.mrpTotal,
    required this.couponDiscount,
    required this.coinsUsed,
    required this.deliveryFee,
    required this.total,
    this.coupon,
    this.couponError,
  });

  final List<PricedLine> lines;
  final List<LineIssue> issues;
  final int subtotal;
  final int mrpTotal;
  final int couponDiscount;
  final int coinsUsed;
  final int deliveryFee;
  final int total;
  final Offer? coupon;
  final CouponError? couponError;

  /// Everything the customer saves against MRP, coupon and coins included.
  int get savings => (mrpTotal - subtotal) + couponDiscount + coinsUsed;
  bool get isEmpty => lines.isEmpty;
  bool get isValid => lines.isNotEmpty && issues.isEmpty;
  bool get hasPhone => lines.any((PricedLine l) => l.product.isPhone);

  /// The part of the cart a lender may finance (EMI-eligible products).
  int get financeable => lines
      .where((PricedLine l) => l.product.emiEligible)
      .fold(0, (int s, PricedLine l) => s + l.total);

  bool get allNoCostEligible =>
      lines.isNotEmpty &&
      lines
          .where((PricedLine l) => l.product.emiEligible)
          .every((PricedLine l) => l.product.noCostEmi) &&
      financeable > 0;

  @override
  List<Object?> get props => <Object?>[
        lines, issues, subtotal, mrpTotal, couponDiscount, coinsUsed,
        deliveryFee, total, coupon, couponError,
      ];
}

class Pricing {
  const Pricing._();

  /// Prices a cart against the live catalogue. The stored cart holds only ids
  /// and quantities, so a stale price in the app can never reach an order.
  static Quote quote({
    required List<CartLine> cart,
    required Map<String, Product> catalogue,
    required StoreSettings settings,
    required Fulfilment fulfilment,
    String? pincode,
    List<Offer> offers = const <Offer>[],
    String? couponCode,
    int coinsToUse = 0,
    int coinBalance = 0,
    required DateTime now,
  }) {
    final List<PricedLine> lines = <PricedLine>[];
    final List<LineIssue> issues = <LineIssue>[];
    for (final CartLine c in cart) {
      final Product? p = catalogue[c.productId];
      final ProductVariant? v = p?.variant(c.variantId);
      if (p == null || v == null || !p.active) {
        issues.add(LineIssue(c, LineProblem.unavailable, 0));
        continue;
      }
      if (v.stock < c.qty) {
        issues.add(LineIssue(c, LineProblem.insufficientStock, v.stock));
      }
      lines.add(PricedLine(product: p, variant: v, qty: c.qty));
    }

    final int subtotal = lines.fold(0, (int s, PricedLine l) => s + l.total);
    final int mrpTotal = lines.fold(0, (int s, PricedLine l) => s + l.mrpTotal);

    // Coupon
    Offer? coupon;
    CouponError? couponError;
    int couponDiscount = 0;
    final String code = (couponCode ?? '').trim().toUpperCase();
    if (code.isNotEmpty) {
      final Iterable<Offer> match =
          offers.where((Offer o) => o.isCoupon && o.code.toUpperCase() == code);
      if (match.isEmpty) {
        couponError = CouponError.notFound;
      } else {
        final Offer o = match.first;
        if (!o.isLive(now)) {
          couponError = CouponError.notActive;
        } else if (subtotal < o.minOrder) {
          couponError = CouponError.minOrder;
        } else {
          final int eligible = lines
              .where((PricedLine l) =>
                  o.groups.isEmpty || o.groups.contains(l.product.category.group))
              .fold(0, (int s, PricedLine l) => s + l.total);
          if (eligible == 0) {
            couponError = CouponError.notApplicable;
          } else {
            int d = o.discountKind == DiscountKind.percent
                ? (eligible * o.value / 100).floor()
                : o.value;
            if (o.discountKind == DiscountKind.percent &&
                o.maxDiscount > 0 &&
                d > o.maxDiscount) {
              d = o.maxDiscount;
            }
            couponDiscount = d > eligible ? eligible : d;
            coupon = o;
          }
        }
      }
    }

    // Coins: one rupee each, only against accessories, capped to a share of them.
    final int accessoriesTotal = lines
        .where((PricedLine l) => l.product.category.group != ProductGroup.phones)
        .fold(0, (int s, PricedLine l) => s + l.total);
    final int coinCap = (accessoriesTotal * settings.maxCoinsPctOfOrder / 100).floor();
    int coins = coinsToUse;
    if (coins > coinBalance) coins = coinBalance;
    if (coins > coinCap) coins = coinCap;
    if (coins < 0) coins = 0;

    final int afterDiscounts = subtotal - couponDiscount - coins;
    final int fee = deliveryFeeFor(
      settings: settings,
      fulfilment: fulfilment,
      pincode: pincode,
      payable: afterDiscounts,
    );
    return Quote(
      lines: lines,
      issues: issues,
      subtotal: subtotal,
      mrpTotal: mrpTotal,
      couponDiscount: couponDiscount,
      coinsUsed: coins,
      deliveryFee: fee,
      total: afterDiscounts + fee,
      coupon: coupon,
      couponError: couponError,
    );
  }

  static int deliveryFeeFor({
    required StoreSettings settings,
    required Fulfilment fulfilment,
    required String? pincode,
    required int payable,
  }) {
    if (fulfilment != Fulfilment.delivery) return 0;
    final bool local = pincode != null && settings.isLocalPincode(pincode);
    if (local) return settings.localDeliveryFee;
    return payable >= settings.freeDeliveryAbove ? 0 : settings.courierFee;
  }
}

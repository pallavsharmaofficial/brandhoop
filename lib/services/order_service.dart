import '../core/ids.dart';
import '../core/permissions.dart';
import '../core/validators.dart';
import '../data/repositories.dart';
import '../domain/app_user.dart';
import '../domain/emi_plan.dart';
import '../domain/order.dart';
import '../domain/payment.dart';
import '../domain/product.dart';
import '../domain/store_settings.dart';
import 'checkout_service.dart';
import 'clock.dart';
import 'emi_service.dart';
import 'finance_service.dart';
import 'guard.dart';
import 'payment_gateway.dart';

class WalkInLine {
  const WalkInLine({
    required this.productId,
    required this.variantId,
    this.qty = 1,
    this.imeis = const <String>[],
  });

  final String productId;
  final String variantId;
  final int qty;
  final List<String> imeis;
}

class WalkInPayment {
  const WalkInPayment({
    required this.method,
    required this.amount,
    this.reference = '',
  });

  final PaymentMethod method;
  final int amount;
  final String reference;
}

class WalkInRequest {
  const WalkInRequest({
    required this.phone,
    this.name = '',
    required this.lines,
    this.discount = 0,
    this.payments = const <WalkInPayment>[],
    this.emi,
    this.note = '',
  });

  final String phone;
  final String name;
  final List<WalkInLine> lines;

  /// A flat rupee discount the counter gives.
  final int discount;
  final List<WalkInPayment> payments;

  /// A Bajaj Finance sale at the counter. The sale then waits for approval.
  final EmiSelection? emi;
  final String note;
}

/// Everything that happens to an order after it has been placed.
class OrderService {
  OrderService({
    required this.repos,
    required this.gateway,
    required this.checkout,
    required this.emi,
    required this.finance,
    this.clock = systemClock,
  });

  /// A counter clerk may discount a sale up to this share without a manager.
  static const int maxStaffDiscountPct = 5;

  final Repositories repos;
  final PaymentGateway gateway;
  final CheckoutService checkout;
  final EmiService emi;
  final FinanceService finance;
  final Clock clock;

  Future<Order> _save(Order o) async {
    await repos.orders.save(o);
    return o;
  }

  Order _withEvent(Order o, OrderStatus s, {String? by, String note = ''}) {
    final DateTime now = clock();
    return o.copyWith(
      status: s,
      updatedAt: now,
      events: <OrderEvent>[
        ...o.events,
        OrderEvent(status: s, at: now, by: by, note: note),
      ],
    );
  }

  // ---- Customer ----------------------------------------------------------

  /// Pays what is still waiting online on an order, perhaps with a different
  /// instrument than last time.
  Future<({Order order, GatewayFailure? failure})> retryPayment(
    Order order,
    PayInstrument instrument,
  ) async {
    if (order.status != OrderStatus.pendingPayment) {
      throw ShopException('nothingToPay');
    }
    return checkout.chargePending(order, instrument);
  }

  Future<Order> cancelByCustomer(Order order, {String reason = ''}) async {
    if (!OrderFlow.customerMayCancel(order)) throw ShopException('cannotCancel');
    return _cancel(order, reason: reason, by: order.customerId);
  }

  Future<Order> requestReturn(Order order, {String reason = ''}) async {
    if (!OrderFlow.customerMayReturn(order, clock())) {
      throw ShopException('returnWindowClosed');
    }
    return _save(_withEvent(
      order,
      OrderStatus.returnRequested,
      by: order.customerId,
      note: reason,
    ));
  }

  // ---- Staff -------------------------------------------------------------

  Future<Order> updateStatus(
    AppUser? actor,
    Order order,
    OrderStatus to, {
    String note = '',
  }) async {
    requirePermission(actor, Permission.manageOrders);
    if (!OrderFlow.next(order).contains(to)) throw ShopException('badTransition');
    switch (to) {
      case OrderStatus.cancelled:
        return _cancel(order, reason: note, by: actor!.id);
      case OrderStatus.delivered:
        return _deliver(actor!, order, note);
      case OrderStatus.returned:
        return _returned(actor!, order, note);
      case OrderStatus.pendingPayment:
      case OrderStatus.placed:
      case OrderStatus.confirmed:
      case OrderStatus.packed:
      case OrderStatus.outForDelivery:
      case OrderStatus.readyForPickup:
      case OrderStatus.returnRequested:
        return _save(_withEvent(order, to, by: actor!.id, note: note));
    }
  }

  /// Records the IMEI of every phone unit on the order, one list per line.
  Future<Order> setImeis(
    AppUser? actor,
    Order order,
    Map<int, List<String>> imeisByLine,
  ) async {
    requirePermission(actor, Permission.manageOrders);
    final List<OrderLine> lines = <OrderLine>[];
    final Set<String> seen = <String>{};
    for (int i = 0; i < order.lines.length; i++) {
      final OrderLine l = order.lines[i];
      final List<String>? given = imeisByLine[i];
      if (given == null) {
        lines.add(l);
        continue;
      }
      final List<String> clean =
          given.map((String s) => s.replaceAll(RegExp(r'[\s-]'), '')).toList();
      for (final String imei in clean) {
        if (!Validators.imei(imei)) throw ShopException('badImei', imei);
        if (!seen.add(imei)) throw ShopException('dupImei', imei);
      }
      lines.add(l.copyWith(imeis: clean));
    }
    return _save(order.copyWith(lines: lines, updatedAt: clock()));
  }

  Future<Order> _deliver(AppUser actor, Order order, String note) async {
    for (final OrderLine l in order.lines) {
      if (l.category.needsImei && l.imeis.length != l.qty) {
        throw ShopException('imeiRequired');
      }
    }
    if (order.emiPlanId != null) {
      final EmiPlan? p = await repos.plans.get(order.emiPlanId!);
      if (p == null || !p.isLive) throw ShopException('emiNotApproved');
    }
    if (order.balanceDue > 0) throw ShopException('balanceDue');
    final DateTime now = clock();
    Order next = _withEvent(order, OrderStatus.delivered, by: actor.id, note: note)
        .copyWith(deliveredAt: now);
    await _save(next);
    await finance.recordSale(next);
    await _rewardCustomer(next);
    return next;
  }

  /// Coins on accessories, and the referral bonus on a customer's first purchase.
  Future<void> _rewardCustomer(Order o) async {
    final StoreSettings s = await repos.settings.get();
    AppUser? u = await repos.users.get(o.customerId);
    if (u == null) return;
    final int accessories = o.lines
        .where((OrderLine l) => l.category.group != ProductGroup.phones)
        .fold(0, (int sum, OrderLine l) => sum + l.total);
    int earned = (accessories * s.coinsEarnPct / 100).floor();

    final bool firstPurchase = (await repos.orders.all())
            .where((Order x) =>
                x.customerId == o.customerId &&
                x.id != o.id &&
                x.status == OrderStatus.delivered)
            .isEmpty;
    if (firstPurchase && u.referredBy != null) {
      earned += s.referralBonusCoins;
      final AppUser? ref = await repos.users.get(u.referredBy!);
      if (ref != null) {
        await repos.users.save(ref.copyWith(coins: ref.coins + s.referralBonusCoins));
      }
    }
    if (earned > 0) {
      u = u.copyWith(coins: u.coins + earned);
      await repos.users.save(u);
    }
  }

  Future<Order> _cancel(Order order, {String reason = '', String? by}) async {
    // Put the stock back, return coins, close the EMI plan.
    for (final OrderLine l in order.lines) {
      await repos.catalog.adjustStock(l.productId, l.variantId, l.qty);
    }
    if (order.coinsUsed > 0) {
      final AppUser? u = await repos.users.get(order.customerId);
      if (u != null) {
        await repos.users.save(u.copyWith(coins: u.coins + order.coinsUsed));
      }
    }
    if (order.emiPlanId != null) {
      final EmiPlan? p = await repos.plans.get(order.emiPlanId!);
      if (p != null) await emi.cancel(p, reason: reason);
    }
    final DateTime now = clock();
    final List<PaymentRecord> records = <PaymentRecord>[];
    for (final PaymentRecord p in order.payments) {
      if (p.status == PaymentStatus.pending) {
        records.add(p.copyWith(status: PaymentStatus.failed, note: 'cancelled'));
      } else {
        records.add(p);
      }
    }
    // Whatever the customer already paid is owed back.
    final int paid = records
        .where((PaymentRecord p) =>
            p.kind == PaymentKind.payment && p.status == PaymentStatus.paid)
        .fold(0, (int s, PaymentRecord p) => s + p.amount);
    final int refunded = records
        .where((PaymentRecord p) => p.kind == PaymentKind.refund)
        .fold(0, (int s, PaymentRecord p) => s + p.amount);
    if (paid - refunded > 0) {
      final PaymentRecord origin = records.lastWhere(
        (PaymentRecord p) =>
            p.kind == PaymentKind.payment && p.status == PaymentStatus.paid,
      );
      records.add(PaymentRecord(
        id: newId('pr'),
        kind: PaymentKind.refund,
        method: origin.method == PaymentMethod.cardEmi ? PaymentMethod.card : origin.method,
        amount: paid - refunded,
        status: PaymentStatus.pending,
        at: now,
        note: reason,
      ));
    }
    return _save(
      _withEvent(order.copyWith(payments: records, cancelReason: reason),
          OrderStatus.cancelled, by: by, note: reason),
    );
  }

  Future<Order> _returned(AppUser actor, Order order, String note) async {
    for (final OrderLine l in order.lines) {
      await repos.catalog.adjustStock(l.productId, l.variantId, l.qty);
    }
    await finance.reverseSale(order, clock());
    final DateTime now = clock();
    final int paid = order.paidAmount;
    final List<PaymentRecord> records = <PaymentRecord>[
      ...order.payments,
      if (paid > 0)
        PaymentRecord(
          id: newId('pr'),
          kind: PaymentKind.refund,
          method: PaymentMethod.cash,
          amount: paid,
          status: PaymentStatus.pending,
          at: now,
          note: note,
        ),
    ];
    return _save(_withEvent(order.copyWith(payments: records), OrderStatus.returned,
        by: actor.id, note: note));
  }

  /// The counter takes money: cash for the balance, a UPI scan, a card swipe.
  /// Settles the matching pending record if there is one.
  Future<Order> recordCounterPayment(
    AppUser? actor,
    Order order, {
    required int amount,
    required PaymentMethod method,
    String reference = '',
  }) async {
    requirePermission(actor, Permission.manageOrders);
    if (amount <= 0 || amount > order.balanceDue) throw ShopException('badAmount');
    final DateTime now = clock();
    final List<PaymentRecord> records = List<PaymentRecord>.of(order.payments);
    int remaining = amount;
    for (int i = 0; i < records.length && remaining > 0; i++) {
      final PaymentRecord r = records[i];
      if (r.kind != PaymentKind.payment ||
          r.status != PaymentStatus.pending ||
          r.method != PaymentMethod.cash) {
        continue;
      }
      if (r.amount <= remaining) {
        records[i] = PaymentRecord(
          id: r.id,
          method: method,
          amount: r.amount,
          status: PaymentStatus.paid,
          reference: reference,
          at: now,
          note: r.note,
          collectedBy: actor!.id,
        );
        remaining -= r.amount;
      } else {
        // Part of a pending record: settle that part, leave the rest pending.
        records[i] = PaymentRecord(
          id: r.id,
          method: r.method,
          amount: r.amount - remaining,
          status: PaymentStatus.pending,
          at: r.at,
          note: r.note,
        );
        records.add(PaymentRecord(
          id: newId('pr'),
          method: method,
          amount: remaining,
          status: PaymentStatus.paid,
          reference: reference,
          at: now,
          collectedBy: actor!.id,
        ));
        remaining = 0;
      }
    }
    if (remaining > 0) {
      records.add(PaymentRecord(
        id: newId('pr'),
        method: method,
        amount: remaining,
        status: PaymentStatus.paid,
        reference: reference,
        at: now,
        collectedBy: actor!.id,
      ));
    }
    return _save(order.copyWith(payments: records, updatedAt: now));
  }

  /// Bajaj Finance (or the bank) has paid the shop for the financed amount.
  Future<Order> markLenderPaid(
    AppUser? actor,
    Order order, {
    String reference = '',
  }) async {
    requirePermission(actor, Permission.manageEmi);
    final DateTime now = clock();
    final List<PaymentRecord> records = <PaymentRecord>[
      for (final PaymentRecord p in order.payments)
        if (p.kind == PaymentKind.lenderDisbursement &&
            p.status == PaymentStatus.pending)
          p.copyWith(status: PaymentStatus.paid, reference: reference, at: now)
        else
          p,
    ];
    return _save(order.copyWith(payments: records, updatedAt: now));
  }

  /// The lender declined: the financed amount is the customer's to pay instead.
  Future<Order> markLenderDeclined(AppUser? actor, Order order) async {
    requirePermission(actor, Permission.manageEmi);
    final DateTime now = clock();
    int declined = 0;
    final List<PaymentRecord> records = <PaymentRecord>[];
    for (final PaymentRecord p in order.payments) {
      if (p.kind == PaymentKind.lenderDisbursement &&
          p.status == PaymentStatus.pending) {
        declined += p.amount;
        records.add(p.copyWith(status: PaymentStatus.failed, note: 'declined'));
      } else {
        records.add(p);
      }
    }
    if (declined > 0) {
      records.add(PaymentRecord(
        id: newId('pr'),
        method: PaymentMethod.cash,
        amount: declined,
        status: PaymentStatus.pending,
        at: now,
      ));
    }
    return _save(order.copyWith(payments: records, updatedAt: now));
  }

  /// Sends a pending refund back through the gateway (or marks a cash refund
  /// as handed over).
  Future<Order> issueRefund(
    AppUser? actor,
    Order order,
    String recordId,
  ) async {
    requirePermission(actor, Permission.issueRefunds);
    final DateTime now = clock();
    final List<PaymentRecord> records = <PaymentRecord>[];
    for (final PaymentRecord p in order.payments) {
      if (p.id == recordId &&
          p.kind == PaymentKind.refund &&
          p.status == PaymentStatus.pending) {
        String ref = '';
        if (p.method != PaymentMethod.cash) {
          final PaymentRecord? origin = order.payments
              .cast<PaymentRecord?>()
              .firstWhere(
                (PaymentRecord? x) =>
                    x != null &&
                    x.kind == PaymentKind.payment &&
                    x.status == PaymentStatus.paid &&
                    x.method == p.method,
                orElse: () => null,
              );
          final GatewayResult r = await gateway.refund(
            paymentRef: origin?.reference ?? '',
            amount: p.amount,
          );
          if (!r.ok) throw ShopException('refundFailed');
          ref = r.reference;
        }
        records.add(p.copyWith(status: PaymentStatus.paid, reference: ref, at: now));
      } else {
        records.add(p);
      }
    }
    return _save(order.copyWith(payments: records, updatedAt: now));
  }

  /// Cancels orders nobody paid for, and reservations nobody came for, so the
  /// stock goes back on the shelf. Returns how many it released.
  Future<int> expireStale() async {
    final DateTime now = clock();
    int n = 0;
    for (final Order o in await repos.orders.all()) {
      if (o.status == OrderStatus.pendingPayment &&
          now.difference(o.createdAt) > pendingPaymentTimeout) {
        await _cancel(o, reason: 'payment timeout');
        n++;
      } else if (o.reservedUntil != null &&
          now.isAfter(o.reservedUntil!) &&
          o.balanceDue > 0 &&
          (o.status == OrderStatus.placed ||
              o.status == OrderStatus.confirmed ||
              o.status == OrderStatus.readyForPickup)) {
        await _cancel(o, reason: 'reservation expired');
        n++;
      }
    }
    return n;
  }

  // ---- Counter sale ------------------------------------------------------

  /// A sale rung up at the counter. Everyone who buys in the shop becomes an
  /// app customer by their phone number, so they find their bill, warranty
  /// and offers when they open the app.
  Future<Order> createWalkInSale(AppUser? actor, WalkInRequest req) async {
    requirePermission(actor, Permission.createWalkInSale);
    final DateTime now = clock();
    final String? phone = Validators.mobile(req.phone);
    if (phone == null) throw ShopException('badPhone');
    if (req.lines.isEmpty) throw ShopException('emptyCart');

    final StoreSettings settings = await repos.settings.get();
    final List<OrderLine> lines = <OrderLine>[];
    final Set<String> seen = <String>{};
    for (final WalkInLine w in req.lines) {
      final Product? p = await repos.catalog.get(w.productId);
      final ProductVariant? v = p?.variant(w.variantId);
      if (p == null || v == null) throw ShopException('stockChanged');
      if (v.stock < w.qty) throw ShopException('stockChanged');
      if (p.isPhone && req.emi == null && w.imeis.length != w.qty) {
        throw ShopException('imeiRequired');
      }
      for (final String imei in w.imeis) {
        final String clean = imei.replaceAll(RegExp(r'[\s-]'), '');
        if (!Validators.imei(clean)) throw ShopException('badImei', imei);
        if (!seen.add(clean)) throw ShopException('dupImei', imei);
      }
      lines.add(OrderLine(
        productId: p.id,
        variantId: v.id,
        name: p.name.en,
        nameHi: p.name.hi,
        variantLabel: v.label,
        category: p.category,
        qty: w.qty,
        unitPrice: v.price,
        unitMrp: v.mrp,
        imeis: w.imeis.map((String s) => s.replaceAll(RegExp(r'[\s-]'), '')).toList(),
        gstRatePct: p.gstRatePct,
        warrantyMonths: p.warrantyMonths,
      ));
    }
    final int subtotal = lines.fold(0, (int s, OrderLine l) => s + l.total);
    if (req.discount < 0 || req.discount > subtotal) throw ShopException('badAmount');
    if (actor!.role == AppRole.staff &&
        req.discount * 100 > subtotal * maxStaffDiscountPct) {
      throw ShopException('discountTooHigh');
    }
    final int total = subtotal - req.discount;

    AppUser? customer = await repos.users.byPhone(phone);
    if (customer == null) {
      customer = AppUser(
        id: newId('u'),
        phone: phone,
        name: req.name.trim(),
        createdAt: now,
        referralCode: newReferralCode(),
        invited: true,
      );
      await repos.users.save(customer);
    } else if (customer.name.isEmpty && req.name.trim().isNotEmpty) {
      customer = customer.copyWith(name: req.name.trim());
      await repos.users.save(customer);
    }

    final String orderId = newId('ord');
    final String number = await repos.orders.nextNumber(now);
    final List<PaymentRecord> payments = <PaymentRecord>[
      for (final WalkInPayment p in req.payments)
        if (p.amount > 0)
          PaymentRecord(
            id: newId('pr'),
            method: p.method,
            amount: p.amount,
            status: PaymentStatus.paid,
            reference: p.reference,
            at: now,
            collectedBy: actor.id,
          ),
    ];

    EmiPlan? plan;
    PaymentMode mode = payments.length > 1 ? PaymentMode.mixed : PaymentMode.full;
    if (payments.length == 1 && payments.first.method == PaymentMethod.cash) {
      mode = PaymentMode.cashAtStore;
    }
    if (req.emi != null) {
      final EmiScheme? s = settings.scheme(req.emi!.schemeId);
      final int financeable = lines
          .where((OrderLine l) => l.category.needsImei)
          .fold(0, (int sum, OrderLine l) => sum + l.total);
      if (s == null || s.provider != EmiProvider.bajaj || financeable == 0) {
        throw ShopException('badEmiScheme');
      }
      final int paidNow = payments.fold(0, (int sum, PaymentRecord p) => sum + p.amount);
      final int principal = total - paidNow;
      if (principal <= 0 || principal > financeable) throw ShopException('badEmiScheme');
      plan = await emi.create(
        settings: settings,
        selection: EmiSelection(
          schemeId: s.id,
          months: req.emi!.months,
          downPayment: financeable - principal,
        ),
        orderId: orderId,
        orderNumber: number,
        customer: customer,
        productSummary: lines.map((OrderLine l) => l.name).join(', '),
        price: financeable,
        principal: principal,
      );
      payments.add(PaymentRecord(
        id: newId('pr'),
        kind: PaymentKind.lenderDisbursement,
        method: PaymentMethod.bajajEmi,
        amount: principal,
        status: PaymentStatus.pending,
        at: now,
      ));
      mode = PaymentMode.bajajEmi;
    }

    final bool financed = plan != null;
    final int collected = payments
        .where((PaymentRecord p) =>
            p.kind == PaymentKind.payment && p.status == PaymentStatus.paid)
        .fold(0, (int s, PaymentRecord p) => s + p.amount);
    final int lender = plan?.principal ?? 0;
    if (collected + lender != total) throw ShopException('badAmount');

    final OrderStatus status =
        financed ? OrderStatus.confirmed : OrderStatus.delivered;
    Order order = Order(
      id: orderId,
      number: number,
      customerId: customer.id,
      customerName: customer.displayName,
      customerPhone: customer.phone,
      source: OrderSource.pos,
      lines: lines,
      fulfilment: Fulfilment.walkIn,
      subtotal: subtotal,
      couponDiscount: req.discount,
      total: total,
      payments: payments,
      paymentMode: mode,
      status: status,
      events: <OrderEvent>[
        OrderEvent(status: OrderStatus.placed, at: now, by: actor.id),
        OrderEvent(status: status, at: now, by: actor.id),
      ],
      createdAt: now,
      updatedAt: now,
      pickupCode: newPickupCode(),
      emiPlanId: plan?.id,
      notes: req.note,
      deliveredAt: financed ? null : now,
    );
    for (final OrderLine l in lines) {
      await repos.catalog.adjustStock(l.productId, l.variantId, -l.qty);
    }
    await repos.orders.save(order);
    if (!financed) {
      await finance.recordSale(order);
      await _rewardCustomer(order);
    }
    return order;
  }
}

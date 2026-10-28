import '../core/ids.dart';
import '../core/validators.dart';
import '../data/repositories.dart';
import '../domain/address.dart';
import '../domain/app_user.dart';
import '../domain/cart.dart';
import '../domain/emi_plan.dart';
import '../domain/lead.dart';
import '../domain/order.dart';
import '../domain/payment.dart';
import '../domain/product.dart';
import '../domain/store_settings.dart';
import 'clock.dart';
import 'emi_service.dart';
import 'guard.dart';
import 'lead_service.dart';
import 'payment_gateway.dart';
import 'payment_rules.dart';
import 'pricing.dart';

class CheckoutRequest {
  const CheckoutRequest({
    required this.customer,
    required this.cart,
    required this.fulfilment,
    this.address,
    this.couponCode,
    this.coinsToUse = 0,
    required this.choice,
    this.emi,
    this.instrument,
    this.note = '',
  });

  final AppUser customer;
  final List<CartLine> cart;
  final Fulfilment fulfilment;
  final Address? address;
  final String? couponCode;
  final int coinsToUse;
  final PayChoice choice;
  final EmiSelection? emi;

  /// How to pay the part that is paid online now. Null when nothing is paid
  /// online (cash, or a Bajaj down payment left for the counter).
  final PayInstrument? instrument;
  final String note;
}

class CheckoutResult {
  const CheckoutResult({required this.order, this.plan, this.failure});

  final Order order;
  final EmiPlan? plan;

  /// Set when an online payment was tried and did not go through. The order
  /// exists and can be paid again from "My orders".
  final GatewayFailure? failure;

  bool get paymentFailed => failure != null;
}

/// Turns a cart into an order, whichever way the customer chose to pay.
class CheckoutService {
  CheckoutService({
    required this.repos,
    required this.gateway,
    required this.emi,
    required this.leads,
    this.clock = systemClock,
  });

  final Repositories repos;
  final PaymentGateway gateway;
  final EmiService emi;
  final LeadService leads;
  final Clock clock;

  Future<Map<String, Product>> _catalogue() async => <String, Product>{
        for (final Product p in await repos.catalog.all()) p.id: p,
      };

  /// Prices the cart exactly as [placeOrder] will, for the screens to show.
  Future<Quote> quote({
    required List<CartLine> cart,
    required Fulfilment fulfilment,
    String? pincode,
    String? couponCode,
    int coinsToUse = 0,
    int coinBalance = 0,
  }) async =>
      Pricing.quote(
        cart: cart,
        catalogue: await _catalogue(),
        settings: await repos.settings.get(),
        fulfilment: fulfilment,
        pincode: pincode,
        offers: await repos.offers.all(),
        couponCode: couponCode,
        coinsToUse: coinsToUse,
        coinBalance: coinBalance,
        now: clock(),
      );

  Future<CheckoutResult> placeOrder(CheckoutRequest req) async {
    final DateTime now = clock();
    final StoreSettings settings = await repos.settings.get();
    final AppUser customer = await repos.users.get(req.customer.id) ?? req.customer;
    if (!customer.active) throw ShopException('accountDisabled');

    if (req.fulfilment == Fulfilment.delivery) {
      final Address? a = req.address;
      if (a == null ||
          !Validators.pincode(a.pincode) ||
          Validators.mobile(a.phone) == null ||
          a.line1.trim().isEmpty ||
          a.name.trim().isEmpty) {
        throw ShopException('badAddress');
      }
    }

    final Quote q = await quote(
      cart: req.cart,
      fulfilment: req.fulfilment,
      pincode: req.address?.pincode,
      couponCode: req.couponCode,
      coinsToUse: req.coinsToUse,
      coinBalance: customer.coins,
    );
    if (q.isEmpty) throw ShopException('emptyCart');
    if (!q.isValid) throw ShopException('stockChanged');
    if (req.couponCode != null &&
        req.couponCode!.trim().isNotEmpty &&
        q.coupon == null) {
      throw ShopException('badCoupon', q.couponError?.name ?? '');
    }
    final List<PayChoice> allowed = PaymentRules.available(
      settings: settings,
      quote: q,
      fulfilment: req.fulfilment,
      pincode: req.address?.pincode,
    );
    if (!allowed.contains(req.choice)) throw ShopException('payNotAllowed');

    final String orderId = newId('ord');
    final String number = await repos.orders.nextNumber(now);
    final List<OrderLine> lines = <OrderLine>[
      for (final PricedLine l in q.lines)
        OrderLine(
          productId: l.product.id,
          variantId: l.variant.id,
          name: l.product.name.en,
          nameHi: l.product.name.hi,
          variantLabel: l.variant.label,
          category: l.product.category,
          qty: l.qty,
          unitPrice: l.variant.price,
          unitMrp: l.variant.mrp,
          gstRatePct: l.product.gstRatePct,
          warrantyMonths: l.product.warrantyMonths,
        ),
    ];

    final List<PaymentRecord> payments = <PaymentRecord>[];
    PaymentRecord rec(
      PaymentMethod m,
      int amount, {
      PaymentKind kind = PaymentKind.payment,
      String note = '',
    }) =>
        PaymentRecord(
          id: newId('pr'),
          kind: kind,
          method: m,
          amount: amount,
          status: PaymentStatus.pending,
          at: now,
          note: note,
        );

    PaymentMode mode = PaymentMode.full;
    EmiPlan? plan;
    DateTime? reservedUntil;
    final bool delivery = req.fulfilment == Fulfilment.delivery;

    switch (req.choice) {
      case PayChoice.upi:
      case PayChoice.card:
      case PayChoice.netbanking:
        final PayInstrument i = _need(req.instrument, req.choice);
        payments.add(rec(i.method, q.total));
      case PayChoice.cashOnDelivery:
        mode = PaymentMode.cashOnDelivery;
        payments.add(rec(PaymentMethod.cash, q.total));
      case PayChoice.cashAtStore:
        mode = PaymentMode.cashAtStore;
        payments.add(rec(PaymentMethod.cash, q.total));
      case PayChoice.reserve:
        mode = PaymentMode.token;
        final PayInstrument i = _need(req.instrument, req.choice);
        final int token = settings.reserveToken;
        payments.add(rec(i.method, token, note: 'token'));
        if (q.total > token) payments.add(rec(PaymentMethod.cash, q.total - token));
        reservedUntil = now.add(Duration(hours: settings.reserveHours));
      case PayChoice.bajajEmi:
        mode = PaymentMode.bajajEmi;
        final EmiSelection sel = _needEmi(req.emi);
        final EmiScheme? s = settings.scheme(sel.schemeId);
        if (s == null ||
            s.provider != EmiProvider.bajaj ||
            !s.allows(q.financeable) ||
            !s.tenures.contains(sel.months) ||
            (s.noCost && !q.allNoCostEligible)) {
          throw ShopException('badEmiScheme');
        }
        final int down = PaymentRules.clampDown(s, q.financeable, sel.downPayment);
        final int principal = q.financeable - down;
        plan = await emi.create(
          settings: settings,
          selection: EmiSelection(
            schemeId: s.id,
            months: sel.months,
            downPayment: down,
          ),
          orderId: orderId,
          orderNumber: number,
          customer: customer,
          productSummary: _summary(q),
          price: q.financeable,
          principal: principal,
        );
        payments.add(rec(
          PaymentMethod.bajajEmi,
          principal,
          kind: PaymentKind.lenderDisbursement,
        ));
        final int now0 = q.total - principal;
        if (now0 > 0) {
          if (req.instrument != null) {
            payments.add(rec(req.instrument!.method, now0));
          } else {
            payments.add(rec(PaymentMethod.cash, now0));
          }
        }
      case PayChoice.cardEmi:
        mode = PaymentMode.cardEmi;
        final PayInstrument i = _need(req.instrument, req.choice);
        final EmiSelection sel = _needEmi(req.emi);
        final EmiScheme? s = settings.scheme(sel.schemeId);
        if (s == null ||
            s.provider != EmiProvider.bank ||
            !s.allows(q.total) ||
            !s.tenures.contains(sel.months) ||
            i.method != PaymentMethod.card ||
            (s.noCost && !q.allNoCostEligible)) {
          throw ShopException('badEmiScheme');
        }
        plan = await emi.create(
          settings: settings,
          selection: EmiSelection(schemeId: s.id, months: sel.months),
          orderId: orderId,
          orderNumber: number,
          customer: customer,
          productSummary: _summary(q),
          price: q.total,
          principal: q.total,
        );
        payments.add(rec(PaymentMethod.cardEmi, q.total));
    }

    final bool hasOnlinePending = payments.any(_isOnlinePending);
    Order order = Order(
      id: orderId,
      number: number,
      customerId: customer.id,
      customerName: customer.displayName,
      customerPhone: customer.phone,
      lines: lines,
      fulfilment: req.fulfilment,
      address: delivery ? req.address : null,
      subtotal: q.subtotal,
      couponCode: q.coupon?.code,
      couponDiscount: q.couponDiscount,
      coinsUsed: q.coinsUsed,
      deliveryFee: q.deliveryFee,
      total: q.total,
      payments: payments,
      paymentMode: mode,
      status: hasOnlinePending ? OrderStatus.pendingPayment : OrderStatus.placed,
      events: <OrderEvent>[
        OrderEvent(
          status: hasOnlinePending ? OrderStatus.pendingPayment : OrderStatus.placed,
          at: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
      pickupCode: newPickupCode(),
      reservedUntil: reservedUntil,
      emiPlanId: plan?.id,
      notes: req.note,
    );

    // Hold the stock and spend the coins before any money moves.
    for (final PricedLine l in q.lines) {
      await repos.catalog.adjustStock(l.product.id, l.variant.id, -l.qty);
    }
    if (q.coinsUsed > 0) {
      await repos.users.save(customer.copyWith(coins: customer.coins - q.coinsUsed));
    }
    await repos.orders.save(order);

    GatewayFailure? failure;
    if (hasOnlinePending) {
      final PayInstrument? inst = req.instrument;
      if (inst != null) {
        final ({Order order, GatewayFailure? failure}) r =
            await chargePending(order, inst, plan: plan);
        order = r.order;
        failure = r.failure;
      }
    }

    // Leads: a Bajaj application or a reserved phone is somebody for the shop to call.
    if (req.choice == PayChoice.bajajEmi) {
      await leads.capture(
        type: LeadType.emiApplication,
        name: customer.displayName,
        phone: customer.phone,
        userId: customer.id,
        message: '${plan?.months} months, ${order.number}',
        productName: _summary(q),
        details: <String, String>{'order': order.number},
      );
    } else if (req.choice == PayChoice.reserve) {
      await leads.capture(
        type: LeadType.reserve,
        name: customer.displayName,
        phone: customer.phone,
        userId: customer.id,
        message: order.number,
        productName: _summary(q),
        details: <String, String>{'order': order.number},
      );
    }

    final EmiPlan? livePlan =
        plan == null ? null : await repos.plans.get(plan.id);
    return CheckoutResult(order: order, plan: livePlan ?? plan, failure: failure);
  }

  static bool _isOnlinePending(PaymentRecord p) =>
      p.kind == PaymentKind.payment &&
      p.status == PaymentStatus.pending &&
      (p.method == PaymentMethod.upi ||
          p.method == PaymentMethod.card ||
          p.method == PaymentMethod.netbanking ||
          p.method == PaymentMethod.cardEmi);

  PayInstrument _need(PayInstrument? i, PayChoice c) {
    if (i == null) throw ShopException('needInstrument');
    return i;
  }

  EmiSelection _needEmi(EmiSelection? s) {
    if (s == null) throw ShopException('badEmiScheme');
    return s;
  }

  String _summary(Quote q) => q.lines
      .where((PricedLine l) => l.product.emiEligible || q.financeable == 0)
      .map((PricedLine l) => l.product.name.en)
      .join(', ');

  /// Charges the online payments still waiting on [order] with [instrument].
  /// A failed attempt leaves the record pending, so the customer can try again.
  Future<({Order order, GatewayFailure? failure})> chargePending(
    Order order,
    PayInstrument instrument, {
    EmiPlan? plan,
  }) async {
    final DateTime now = clock();
    Order current = order;
    GatewayFailure? failure;
    final List<PaymentRecord> records = List<PaymentRecord>.of(order.payments);
    for (int idx = 0; idx < records.length; idx++) {
      final PaymentRecord r = records[idx];
      if (!_isOnlinePending(r)) continue;
      final bool isEmiCharge = r.method == PaymentMethod.cardEmi;
      final PaymentMethod method = isEmiCharge ? r.method : instrument.method;
      final EmiPlan? p = isEmiCharge
          ? (plan ?? (order.emiPlanId == null ? null : await repos.plans.get(order.emiPlanId!)))
          : null;
      final GatewayResult res = await gateway.charge(ChargeRequest(
        orderId: order.id,
        amount: r.amount,
        method: isEmiCharge ? PaymentMethod.cardEmi : method,
        instrument: instrument,
        description: order.number,
        customerPhone: order.customerPhone,
        emiMonths: p?.months ?? 0,
      ));
      if (res.ok) {
        records[idx] = PaymentRecord(
          id: r.id,
          kind: r.kind,
          method: method,
          amount: r.amount,
          status: PaymentStatus.paid,
          reference: res.reference,
          at: now,
          note: res.instrumentLabel,
        );
        if (isEmiCharge && p != null) {
          await emi.activateAfterCharge(p, ref: res.reference);
        }
      } else {
        failure = res.failure;
        records[idx] = PaymentRecord(
          id: r.id,
          kind: r.kind,
          method: method,
          amount: r.amount,
          status: PaymentStatus.pending,
          reference: r.reference,
          at: r.at,
          note: 'failed:${res.failure!.name}',
        );
        break;
      }
    }
    final bool stillWaiting = records.any(_isOnlinePending);
    final bool promote = !stillWaiting && current.status == OrderStatus.pendingPayment;
    current = current.copyWith(
      payments: records,
      status: promote ? OrderStatus.placed : null,
      events: promote
          ? <OrderEvent>[...current.events, OrderEvent(status: OrderStatus.placed, at: now)]
          : null,
      updatedAt: now,
    );
    await repos.orders.save(current);
    return (order: current, failure: failure);
  }
}

/// How long an order may sit unpaid before the shop lets the stock go.
const Duration pendingPaymentTimeout = Duration(minutes: 30);

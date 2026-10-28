import 'package:brandhoop/core/permissions.dart';
import 'package:brandhoop/domain/app_user.dart';
import 'package:brandhoop/domain/cart.dart';
import 'package:brandhoop/domain/emi_plan.dart';
import 'package:brandhoop/domain/finance.dart';
import 'package:brandhoop/domain/lead.dart';
import 'package:brandhoop/domain/order.dart';
import 'package:brandhoop/domain/payment.dart';
import 'package:brandhoop/domain/product.dart';
import 'package:brandhoop/services/checkout_service.dart';
import 'package:brandhoop/services/emi_service.dart';
import 'package:brandhoop/services/guard.dart';
import 'package:brandhoop/services/order_service.dart';
import 'package:brandhoop/services/payment_gateway.dart';
import 'package:brandhoop/services/payment_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

const PayInstrument okUpi = PayInstrument.upiId('ravi@okaxis');
const PayInstrument okCard = PayInstrument.card(
  cardNumber: '4111 1111 1111 1111',
  cardExpiry: '12/30',
  cardCvv: '123',
  cardName: 'Test',
);

const String phoneImei = '490154203237518';

void main() {
  late Harness h;
  late AppUser cust;

  setUp(() async {
    h = await Harness.create();
    cust = await h.newCustomer();
  });

  Future<int> stockOf(String pid, String vid) async =>
      (await h.repos.catalog.get(pid))!.variant(vid)!.stock;

  CartLine samsung() => const CartLine(productId: 'ph_samsung', variantId: 'ph_samsung-v1');
  CartLine glass() => const CartLine(productId: 'ac_glass', variantId: 'ac_glass-v1');

  group('checkout', () {
    test('UPI: order is placed, paid, stock held', () async {
      final int before = await stockOf('ph_samsung', 'ph_samsung-v1');
      final CheckoutResult r = await h.services.checkout.placeOrder(CheckoutRequest(
        customer: cust,
        cart: <CartLine>[samsung(), glass()],
        fulfilment: Fulfilment.pickup,
        choice: PayChoice.upi,
        instrument: okUpi,
      ));
      expect(r.paymentFailed, isFalse);
      expect(r.order.status, OrderStatus.placed);
      expect(r.order.total, 13999 + 149);
      expect(r.order.paidAmount, r.order.total);
      expect(r.order.balanceDue, 0);
      expect(r.order.number, matches(RegExp(r'^BH-2610-\d{4}$')));
      expect(await stockOf('ph_samsung', 'ph_samsung-v1'), before - 1);
      expect(r.order.payments.single.note, 'ravi@okaxis');
    });

    test('a declined UPI leaves the order waiting, and a retry succeeds', () async {
      final CheckoutResult r = await h.services.checkout.placeOrder(CheckoutRequest(
        customer: cust,
        cart: <CartLine>[glass()],
        fulfilment: Fulfilment.pickup,
        choice: PayChoice.upi,
        instrument: const PayInstrument.upiId('fail@upi'),
      ));
      expect(r.paymentFailed, isTrue);
      expect(r.failure, GatewayFailure.declined);
      expect(r.order.status, OrderStatus.pendingPayment);
      expect(r.order.paidAmount, 0);

      final retry = await h.services.orders.retryPayment(r.order, okUpi);
      expect(retry.failure, isNull);
      expect(retry.order.status, OrderStatus.placed);
      expect(retry.order.balanceDue, 0);
    });

    test('an unpaid order is released after the timeout', () async {
      final int before = await stockOf('ac_glass', 'ac_glass-v1');
      final CheckoutResult r = await h.services.checkout.placeOrder(CheckoutRequest(
        customer: cust,
        cart: <CartLine>[glass()],
        fulfilment: Fulfilment.pickup,
        choice: PayChoice.upi,
        instrument: const PayInstrument.upiId('fail@upi'),
      ));
      expect(await stockOf('ac_glass', 'ac_glass-v1'), before - 1);
      h.advance(const Duration(minutes: 31));
      expect(await h.services.orders.expireStale(), 1);
      final Order o = (await h.repos.orders.get(r.order.id))!;
      expect(o.status, OrderStatus.cancelled);
      expect(await stockOf('ac_glass', 'ac_glass-v1'), before);
    });

    test('cash on delivery in town needs no online payment', () async {
      final CheckoutResult r = await h.services.checkout.placeOrder(CheckoutRequest(
        customer: cust,
        cart: <CartLine>[samsung()],
        fulfilment: Fulfilment.delivery,
        address: cust.defaultAddress,
        choice: PayChoice.cashOnDelivery,
      ));
      expect(r.order.status, OrderStatus.placed);
      expect(r.order.balanceDue, 13999);
      expect(r.order.paymentMode, PaymentMode.cashOnDelivery);
    });

    test('cash on delivery is refused outside town', () async {
      final address = cust.defaultAddress!.copyWith(pincode: '302001');
      expect(
        () => h.services.checkout.placeOrder(CheckoutRequest(
          customer: cust,
          cart: <CartLine>[samsung()],
          fulfilment: Fulfilment.delivery,
          address: address,
          choice: PayChoice.cashOnDelivery,
        )),
        throwsA(isA<ShopException>().having((e) => e.code, 'code', 'payNotAllowed')),
      );
    });

    test('reserve takes a token online and leaves the rest for the shop', () async {
      final CheckoutResult r = await h.services.checkout.placeOrder(CheckoutRequest(
        customer: cust,
        cart: <CartLine>[samsung()],
        fulfilment: Fulfilment.pickup,
        choice: PayChoice.reserve,
        instrument: okUpi,
      ));
      expect(r.order.status, OrderStatus.placed);
      expect(r.order.paidAmount, 1000);
      expect(r.order.balanceDue, 12999);
      expect(r.order.reservedUntil, h.now.add(const Duration(hours: 72)));
      final List<Lead> leads = await h.repos.leads.all();
      expect(leads.where((Lead l) => l.type == LeadType.reserve && l.phone == cust.phone), hasLength(1));
    });

    test('an expired reservation is released and the token is owed back', () async {
      final int before = await stockOf('ph_samsung', 'ph_samsung-v1');
      final CheckoutResult r = await h.services.checkout.placeOrder(CheckoutRequest(
        customer: cust,
        cart: <CartLine>[samsung()],
        fulfilment: Fulfilment.pickup,
        choice: PayChoice.reserve,
        instrument: okUpi,
      ));
      h.advance(const Duration(hours: 73));
      expect(await h.services.orders.expireStale(), 1);
      final Order o = (await h.repos.orders.get(r.order.id))!;
      expect(o.status, OrderStatus.cancelled);
      expect(await stockOf('ph_samsung', 'ph_samsung-v1'), before);
      final PaymentRecord refund = o.payments.singleWhere((PaymentRecord p) => p.kind == PaymentKind.refund);
      expect(refund.amount, 1000);
      expect(refund.status, PaymentStatus.pending);
    });

    test('Bajaj EMI creates an application, a lender record and a lead', () async {
      final CheckoutResult r = await h.services.checkout.placeOrder(CheckoutRequest(
        customer: cust,
        cart: <CartLine>[samsung()],
        fulfilment: Fulfilment.pickup,
        choice: PayChoice.bajajEmi,
        emi: const EmiSelection(schemeId: 'bajaj_nocost', months: 6, downPayment: 2000),
        instrument: okUpi,
      ));
      expect(r.order.paymentMode, PaymentMode.bajajEmi);
      expect(r.plan, isNotNull);
      expect(r.plan!.status, EmiPlanStatus.applied);
      expect(r.plan!.principal, 11999);
      expect(r.plan!.emi, 2000); // 11999 / 6 rounded up
      expect(r.plan!.noCost, isTrue);
      expect(r.order.lenderAmount, 11999);
      expect(r.order.paidAmount, 2000);
      expect(r.order.balanceDue, 0);
      expect(r.order.status, OrderStatus.placed);
      expect(
        (await h.repos.leads.all()).where((Lead l) => l.type == LeadType.emiApplication && l.phone == cust.phone),
        hasLength(1),
      );
    });

    test('Bajaj down payment is raised to the scheme minimum', () async {
      final CheckoutResult r = await h.services.checkout.placeOrder(CheckoutRequest(
        customer: cust,
        cart: <CartLine>[samsung()],
        fulfilment: Fulfilment.pickup,
        choice: PayChoice.bajajEmi,
        emi: const EmiSelection(schemeId: 'bajaj_nocost', months: 6, downPayment: 0),
      ));
      expect(r.plan!.downPayment, 1400); // 10% of 13,999, rounded up
      expect(r.order.balanceDue, 1400); // left to pay at the counter
    });

    test('card EMI converts the whole bill and starts the schedule', () async {
      final CheckoutResult r = await h.services.checkout.placeOrder(CheckoutRequest(
        customer: cust,
        cart: <CartLine>[samsung()],
        fulfilment: Fulfilment.pickup,
        choice: PayChoice.cardEmi,
        emi: const EmiSelection(schemeId: 'card_standard', months: 12),
        instrument: okCard,
      ));
      expect(r.paymentFailed, isFalse);
      expect(r.order.status, OrderStatus.placed);
      expect(r.plan!.status, EmiPlanStatus.active);
      expect(r.plan!.instalments, hasLength(12));
      expect(r.plan!.instalments.first.dueDate, DateTime(2026, 11, 15));
      expect(r.order.payments.single.method, PaymentMethod.cardEmi);
    });

    test('a no-cost scheme is refused for a phone that is not eligible', () async {
      await expectLater(
        h.services.checkout.placeOrder(CheckoutRequest(
          customer: cust,
          cart: const <CartLine>[CartLine(productId: 'ph_oppo', variantId: 'ph_oppo-v1')],
          fulfilment: Fulfilment.pickup,
          choice: PayChoice.bajajEmi,
          emi: const EmiSelection(schemeId: 'bajaj_nocost', months: 6, downPayment: 2000),
        )),
        throwsA(isA<ShopException>().having((e) => e.code, 'code', 'badEmiScheme')),
      );
      // The same phone is fine on the standard scheme.
      final CheckoutResult r = await h.services.checkout.placeOrder(CheckoutRequest(
        customer: cust,
        cart: const <CartLine>[CartLine(productId: 'ph_oppo', variantId: 'ph_oppo-v1')],
        fulfilment: Fulfilment.pickup,
        choice: PayChoice.bajajEmi,
        emi: const EmiSelection(schemeId: 'bajaj_standard', months: 12, downPayment: 2000),
      ));
      expect(r.plan!.annualRatePct, 16);
      expect(r.plan!.noCost, isFalse);
    });

    test('a bad coupon stops the order instead of silently ignoring it', () async {
      expect(
        () => h.services.checkout.placeOrder(CheckoutRequest(
          customer: cust,
          cart: <CartLine>[glass()],
          fulfilment: Fulfilment.pickup,
          choice: PayChoice.cashAtStore,
          couponCode: 'NOSUCH',
        )),
        throwsA(isA<ShopException>().having((e) => e.code, 'code', 'badCoupon')),
      );
    });

    test('coupon and coins reduce the total and coins are spent', () async {
      final AppUser rich = h.customer; // demo customer has 240 coins
      final CheckoutResult r = await h.services.checkout.placeOrder(CheckoutRequest(
        customer: rich,
        cart: const <CartLine>[CartLine(productId: 'ac_tws', variantId: 'ac_tws-v1')],
        fulfilment: Fulfilment.pickup,
        choice: PayChoice.cashAtStore,
        couponCode: 'welcome100',
        coinsToUse: 500,
      ));
      expect(r.order.couponDiscount, 100);
      expect(r.order.coinsUsed, 129); // 10% of the 1,299 accessory bill
      expect(r.order.total, 1299 - 100 - 129);
      final AppUser after = (await h.repos.users.get(rich.id))!;
      expect(after.coins, 240 - 129);
    });

    test('cannot buy what is not in stock', () async {
      expect(
        () => h.services.checkout.placeOrder(CheckoutRequest(
          customer: cust,
          cart: const <CartLine>[CartLine(productId: 'ph_oneplus', variantId: 'ph_oneplus-v1', qty: 9)],
          fulfilment: Fulfilment.pickup,
          choice: PayChoice.cashAtStore,
        )),
        throwsA(isA<ShopException>().having((e) => e.code, 'code', 'stockChanged')),
      );
    });
  });

  group('order life', () {
    Future<Order> paidPickup(List<CartLine> cart) async => (await h.services.checkout.placeOrder(
          CheckoutRequest(
            customer: cust,
            cart: cart,
            fulfilment: Fulfilment.pickup,
            choice: PayChoice.upi,
            instrument: okUpi,
          ),
        ))
            .order;

    test('a pickup order moves through the shop and books profit on delivery', () async {
      Order o = await paidPickup(<CartLine>[samsung(), glass()]);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.confirmed);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.packed);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.readyForPickup);
      // A phone cannot leave without its IMEI.
      await expectLater(
        h.services.orders.updateStatus(h.staff, o, OrderStatus.delivered),
        throwsA(isA<ShopException>().having((e) => e.code, 'code', 'imeiRequired')),
      );
      o = await h.services.orders.setImeis(h.staff, o, <int, List<String>>{0: <String>[phoneImei]});
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.delivered);
      expect(o.status, OrderStatus.delivered);
      expect(o.deliveredAt, h.now);
      final FinanceEntry e = (await h.repos.finance.entry(o.id))!;
      expect(e.revenue, 13999 + 149);
      expect(e.profit, greaterThan(0));
      expect(e.profitByGroup.keys, containsAll(<String>['phones', 'accessories']));
    });

    test('invalid and duplicate IMEIs are refused', () async {
      Order o = await paidPickup(<CartLine>[samsung()]);
      await expectLater(
        h.services.orders.setImeis(h.staff, o, <int, List<String>>{0: <String>['123']}),
        throwsA(isA<ShopException>().having((e) => e.code, 'code', 'badImei')),
      );
    });

    test('statuses cannot skip steps', () async {
      final Order o = await paidPickup(<CartLine>[glass()]);
      await expectLater(
        h.services.orders.updateStatus(h.staff, o, OrderStatus.delivered),
        throwsA(isA<ShopException>().having((e) => e.code, 'code', 'badTransition')),
      );
    });

    test('a customer is not allowed to run the back office', () async {
      final Order o = await paidPickup(<CartLine>[glass()]);
      await expectLater(
        h.services.orders.updateStatus(cust, o, OrderStatus.confirmed),
        throwsA(isA<PermissionDenied>()),
      );
    });

    test('cancelling after payment restores stock and queues a refund', () async {
      final int before = await stockOf('ac_glass', 'ac_glass-v1');
      Order o = await paidPickup(<CartLine>[glass()]);
      o = await h.services.orders.cancelByCustomer(o, reason: 'changed mind');
      expect(o.status, OrderStatus.cancelled);
      expect(await stockOf('ac_glass', 'ac_glass-v1'), before);
      final PaymentRecord refund = o.payments.singleWhere((PaymentRecord p) => p.kind == PaymentKind.refund);
      expect(refund.amount, 149);
      // Only someone who may issue refunds can send it.
      await expectLater(
        h.services.orders.issueRefund(h.staff, o, refund.id),
        throwsA(isA<PermissionDenied>()),
      );
      o = await h.services.orders.issueRefund(h.owner, o, refund.id);
      expect(o.payments.last.status, PaymentStatus.paid);
      expect(o.paidAmount, 0);
    });

    test('a customer cannot cancel once the shop has packed it', () async {
      Order o = await paidPickup(<CartLine>[glass()]);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.confirmed);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.packed);
      await expectLater(
        h.services.orders.cancelByCustomer(o),
        throwsA(isA<ShopException>().having((e) => e.code, 'code', 'cannotCancel')),
      );
    });

    test('cash on delivery cannot be delivered until the cash is taken', () async {
      Order o = (await h.services.checkout.placeOrder(CheckoutRequest(
        customer: cust,
        cart: <CartLine>[glass()],
        fulfilment: Fulfilment.delivery,
        address: cust.defaultAddress,
        choice: PayChoice.cashOnDelivery,
      )))
          .order;
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.confirmed);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.packed);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.outForDelivery);
      await expectLater(
        h.services.orders.updateStatus(h.staff, o, OrderStatus.delivered),
        throwsA(isA<ShopException>().having((e) => e.code, 'code', 'balanceDue')),
      );
      o = await h.services.orders.recordCounterPayment(h.staff, o, amount: 149, method: PaymentMethod.cash);
      expect(o.balanceDue, 0);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.delivered);
      expect(o.status, OrderStatus.delivered);
    });

    test('accessory coins are earned on delivery', () async {
      final AppUser c = (await h.repos.users.get(cust.id))!;
      Order o = await paidPickup(<CartLine>[const CartLine(productId: 'ac_tws', variantId: 'ac_tws-v1')]);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.confirmed);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.packed);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.readyForPickup);
      await h.services.orders.updateStatus(h.staff, o, OrderStatus.delivered);
      final AppUser after = (await h.repos.users.get(cust.id))!;
      expect(after.coins - c.coins, 25); // 2% of 1,299, rounded down
    });

    test('returns take the profit back out', () async {
      Order o = await paidPickup(<CartLine>[glass()]);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.confirmed);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.packed);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.readyForPickup);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.delivered);
      final FinanceEntry sale = (await h.repos.finance.entry(o.id))!;
      o = await h.services.orders.requestReturn(o, reason: 'wrong size');
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.returned);
      final FinanceEntry back = (await h.repos.finance.entry('${o.id}#return'))!;
      expect(back.profit, -sale.profit);
    });

    test('returns are refused after the window closes', () async {
      Order o = await paidPickup(<CartLine>[glass()]);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.confirmed);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.packed);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.readyForPickup);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.delivered);
      h.advance(const Duration(days: 8));
      await expectLater(
        h.services.orders.requestReturn(o),
        throwsA(isA<ShopException>().having((e) => e.code, 'code', 'returnWindowClosed')),
      );
    });
  });

  group('Bajaj EMI at the counter', () {
    test('the phone cannot be handed over before the lender approves', () async {
      Order o = (await h.services.checkout.placeOrder(CheckoutRequest(
        customer: cust,
        cart: <CartLine>[samsung()],
        fulfilment: Fulfilment.pickup,
        choice: PayChoice.bajajEmi,
        emi: const EmiSelection(schemeId: 'bajaj_standard', months: 9, downPayment: 3000),
        instrument: okUpi,
      )))
          .order;
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.confirmed);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.packed);
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.readyForPickup);
      o = await h.services.orders.setImeis(h.staff, o, <int, List<String>>{0: <String>[phoneImei]});
      await expectLater(
        h.services.orders.updateStatus(h.staff, o, OrderStatus.delivered),
        throwsA(isA<ShopException>().having((e) => e.code, 'code', 'emiNotApproved')),
      );
      // Staff cannot approve a loan: only a manager or the owner.
      EmiPlan plan = (await h.repos.plans.get(o.emiPlanId!))!;
      await expectLater(h.services.emi.approve(h.staff, plan), throwsA(isA<PermissionDenied>()));
      plan = await h.services.emi.approve(h.manager, plan, lenderRef: 'BFL123');
      expect(plan.status, EmiPlanStatus.active);
      expect(plan.instalments, hasLength(9));
      expect(plan.instalments.first.dueDate, DateTime(2026, 11, 15));
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.delivered);
      expect(o.status, OrderStatus.delivered);
      // Bajaj's fee on a no-cost plan is not on this scheme; the standard plan
      // charges the customer, so the shop bears no subvention.
      expect((await h.repos.finance.entry(o.id))!.fees, 0);
      o = await h.services.orders.markLenderPaid(h.manager, o, reference: 'UTR1');
      expect(o.isSettled, isTrue);
    });

    test('a no-cost plan costs the shop the interest the lender would charge', () async {
      Order o = (await h.services.checkout.placeOrder(CheckoutRequest(
        customer: cust,
        cart: <CartLine>[samsung()],
        fulfilment: Fulfilment.pickup,
        choice: PayChoice.bajajEmi,
        emi: const EmiSelection(schemeId: 'bajaj_nocost', months: 6, downPayment: 2000),
      )))
          .order;
      EmiPlan plan = (await h.repos.plans.get(o.emiPlanId!))!;
      plan = await h.services.emi.approve(h.owner, plan);
      o = await h.services.orders.recordCounterPayment(h.staff, o, amount: 2000, method: PaymentMethod.cash);
      for (final OrderStatus s in <OrderStatus>[
        OrderStatus.confirmed,
        OrderStatus.packed,
        OrderStatus.readyForPickup,
      ]) {
        o = await h.services.orders.updateStatus(h.staff, o, s);
      }
      o = await h.services.orders.setImeis(h.staff, o, <int, List<String>>{0: <String>[phoneImei]});
      o = await h.services.orders.updateStatus(h.staff, o, OrderStatus.delivered);
      final FinanceEntry e = (await h.repos.finance.entry(o.id))!;
      expect(e.fees, greaterThan(300)); // ~15% p.a. on 11,999 over 6 months
    });

    test('a declined application hands the balance back to the customer', () async {
      Order o = (await h.services.checkout.placeOrder(CheckoutRequest(
        customer: cust,
        cart: <CartLine>[samsung()],
        fulfilment: Fulfilment.pickup,
        choice: PayChoice.bajajEmi,
        emi: const EmiSelection(schemeId: 'bajaj_nocost', months: 6, downPayment: 2000),
        instrument: okUpi,
      )))
          .order;
      EmiPlan plan = (await h.repos.plans.get(o.emiPlanId!))!;
      plan = await h.services.emi.reject(h.manager, plan, reason: 'KYC');
      o = await h.services.orders.markLenderDeclined(h.manager, o);
      expect(plan.status, EmiPlanStatus.rejected);
      expect(o.balanceDue, 11999);
    });
  });

  group('EMI plans and Autopay', () {
    Future<EmiPlan> activePlan() async {
      final CheckoutResult r = await h.services.checkout.placeOrder(CheckoutRequest(
        customer: cust,
        cart: <CartLine>[samsung()],
        fulfilment: Fulfilment.pickup,
        choice: PayChoice.cardEmi,
        emi: const EmiSelection(schemeId: 'card_nocost', months: 3),
        instrument: okCard,
      ));
      return r.plan!;
    }

    test('sets up a mandate and collects what falls due, never twice', () async {
      EmiPlan plan = await activePlan();
      plan = await h.services.emi.setupAutopay(
        plan,
        method: AutopayMethod.upiAutopay,
        instrument: okUpi,
      );
      expect(plan.mandate!.isActive, isTrue);
      expect(plan.mandate!.maskedInstrument, 'ravi@okaxis');
      expect(await h.services.emi.runAutopay(), 0); // nothing due yet
      h.advance(const Duration(days: 32));
      // The seeded demo plan has an instalment due in this window too.
      expect(await h.services.emi.runAutopay(), 2);
      expect(await h.services.emi.runAutopay(), 0);
      plan = (await h.repos.plans.get(plan.id))!;
      expect(plan.paidCount, 1);
    });

    test('a paused mandate collects nothing', () async {
      EmiPlan plan = await activePlan();
      plan = await h.services.emi.setupAutopay(plan, method: AutopayMethod.upiAutopay, instrument: okUpi);
      plan = await h.services.emi.setAutopayStatus(plan, AutopayStatus.paused);
      h.advance(const Duration(days: 40));
      await h.services.emi.runAutopay();
      expect((await h.repos.plans.get(plan.id))!.paidCount, 0);
    });

    test('a declined mandate raises an error and sets nothing', () async {
      final EmiPlan plan = await activePlan();
      await expectLater(
        h.services.emi.setupAutopay(
          plan,
          method: AutopayMethod.upiAutopay,
          instrument: const PayInstrument.upiId('fail@upi'),
        ),
        throwsA(isA<ShopException>().having((e) => e.code, 'code', 'mandateFailed')),
      );
      expect((await h.repos.plans.get(plan.id))!.mandate, isNull);
    });

    test('paying every instalment closes the plan', () async {
      EmiPlan plan = await activePlan();
      for (int i = 1; i <= plan.months; i++) {
        plan = await h.services.emi.markInstalmentPaid(h.manager, plan, i);
      }
      expect(plan.status, EmiPlanStatus.closed);
      expect(plan.remainingAmount, 0);
    });

    test('reminder days are kept within a week', () async {
      EmiPlan plan = await activePlan();
      plan = await h.services.emi.setupAutopay(plan, method: AutopayMethod.upiAutopay, instrument: okUpi);
      plan = await h.services.emi.setReminderDays(plan, 30);
      expect(plan.mandate!.remindDaysBefore, 7);
    });
  });

  group('counter sales', () {
    test('a cash sale is delivered at once, books profit and creates the customer', () async {
      final Order o = await h.services.orders.createWalkInSale(
        h.staff,
        const WalkInRequest(
          phone: '9222222222',
          name: 'Walk In',
          lines: <WalkInLine>[
            WalkInLine(productId: 'ph_poco', variantId: 'ph_poco-v1', imeis: <String>[phoneImei]),
            WalkInLine(productId: 'ac_glass', variantId: 'ac_glass-v1'),
          ],
          payments: <WalkInPayment>[WalkInPayment(method: PaymentMethod.cash, amount: 8499 + 149)],
        ),
      );
      expect(o.status, OrderStatus.delivered);
      expect(o.source, OrderSource.pos);
      expect(o.balanceDue, 0);
      final AppUser? c = await h.repos.users.byPhone('9222222222');
      expect(c, isNotNull);
      expect(c!.invited, isTrue);
      expect(c.role, AppRole.customer);
      expect(await h.repos.finance.entry(o.id), isNotNull);
    });

    test('payments must add up to the bill', () async {
      await expectLater(
        h.services.orders.createWalkInSale(
          h.staff,
          const WalkInRequest(
            phone: '9222222222',
            lines: <WalkInLine>[WalkInLine(productId: 'ac_glass', variantId: 'ac_glass-v1')],
            payments: <WalkInPayment>[WalkInPayment(method: PaymentMethod.cash, amount: 100)],
          ),
        ),
        throwsA(isA<ShopException>().having((e) => e.code, 'code', 'badAmount')),
      );
    });

    test('counter staff cannot discount more than 5%, a manager can', () async {
      const WalkInRequest big = WalkInRequest(
        phone: '9222222222',
        lines: <WalkInLine>[WalkInLine(productId: 'ac_tws', variantId: 'ac_tws-v1')],
        discount: 300,
        payments: <WalkInPayment>[WalkInPayment(method: PaymentMethod.cash, amount: 999)],
      );
      await expectLater(
        h.services.orders.createWalkInSale(h.staff, big),
        throwsA(isA<ShopException>().having((e) => e.code, 'code', 'discountTooHigh')),
      );
      final Order o = await h.services.orders.createWalkInSale(h.manager, big);
      expect(o.total, 999);
    });

    test('a counter Bajaj sale waits for approval', () async {
      final Order o = await h.services.orders.createWalkInSale(
        h.staff,
        const WalkInRequest(
          phone: '9222222222',
          name: 'Walk In',
          lines: <WalkInLine>[WalkInLine(productId: 'ph_samsung', variantId: 'ph_samsung-v1')],
          payments: <WalkInPayment>[WalkInPayment(method: PaymentMethod.upi, amount: 2000)],
          emi: EmiSelection(schemeId: 'bajaj_nocost', months: 6),
        ),
      );
      expect(o.status, OrderStatus.confirmed);
      expect(o.paymentMode, PaymentMode.bajajEmi);
      expect(o.lenderAmount, 11999);
      expect(o.balanceDue, 0);
      expect(await h.repos.finance.entry(o.id), isNull);
    });

    test('an invalid IMEI stops a phone sale', () async {
      await expectLater(
        h.services.orders.createWalkInSale(
          h.staff,
          const WalkInRequest(
            phone: '9222222222',
            lines: <WalkInLine>[
              WalkInLine(productId: 'ph_poco', variantId: 'ph_poco-v1', imeis: <String>['111111111111111']),
            ],
            payments: <WalkInPayment>[WalkInPayment(method: PaymentMethod.cash, amount: 8499)],
          ),
        ),
        throwsA(isA<ShopException>().having((e) => e.code, 'code', 'badImei')),
      );
    });
  });

  group('roster', () {
    test('only an owner can hand out roles, and the last owner cannot be removed', () async {
      await expectLater(
        h.services.profile.setRole(h.manager, '9333333333', AppRole.staff),
        throwsA(isA<PermissionDenied>()),
      );
      final AppUser u = await h.services.profile.setRole(h.owner, '9333333333', AppRole.manager, name: 'New');
      expect(u.role, AppRole.manager);
      await expectLater(
        h.services.profile.setRole(h.owner, h.owner.phone, AppRole.staff),
        throwsA(isA<ShopException>().having((e) => e.code, 'code', 'lastOwner')),
      );
      await expectLater(
        h.services.profile.setActive(h.owner, h.owner, false),
        throwsA(isA<ShopException>().having((e) => e.code, 'code', 'lastOwner')),
      );
    });

    test('a manager can set prices but a staff member cannot; costs follow permission', () async {
      final Product p = (await h.repos.catalog.get('ac_case'))!;
      final Product cheaper = p.copyWith(
        variants: <ProductVariant>[p.variants.first.copyWith(price: 179)],
      );
      await expectLater(h.services.catalog.saveProduct(h.staff, cheaper), throwsA(isA<PermissionDenied>()));
      await h.services.catalog.saveProduct(h.manager, cheaper, costs: <String, int>{'ac_case-v1': 60});
      expect((await h.repos.catalog.get('ac_case'))!.variants.first.price, 179);
      await expectLater(
        h.services.catalog.saveProduct(h.manager, p.copyWith(variants: <ProductVariant>[
          p.variants.first.copyWith(price: 500, mrp: 400),
        ])),
        throwsA(isA<ShopException>().having((e) => e.code, 'code', 'badPrice')),
      );
    });
  });
}

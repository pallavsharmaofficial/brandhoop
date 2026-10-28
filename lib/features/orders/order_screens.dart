import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/emi.dart';
import '../../core/money.dart';
import '../../domain/order.dart';
import '../../domain/payment.dart';
import '../../domain/product.dart';
import '../../domain/store_settings.dart';
import '../../l10n/l10n.dart';
import '../../services/app_services.dart';
import '../../services/payment_gateway.dart';
import '../../state/cart_cubit.dart';
import '../../state/data_cubits.dart';
import '../../state/session_cubit.dart';
import '../../util/launch.dart';
import '../../widgets/common.dart';
import '../../widgets/store_widgets.dart';
import '../checkout/payment_forms.dart';
import 'invoice.dart';
import 'order_widgets.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionState session = context.watch<SessionCubit>().state;
    final List<Order> orders = context.watch<MyOrdersCubit>().state.toList()
      ..sort((Order a, Order b) => b.createdAt.compareTo(a.createdAt));
    final List<Order> active = orders.where((Order o) => o.status.isOpen || o.status == OrderStatus.returnRequested).toList();
    final List<Order> past = orders.where((Order o) => !active.contains(o)).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr.navOrders),
          actions: const <Widget>[LanguageButton(), SizedBox(width: 12)],
          bottom: session.signedIn
              ? TabBar(tabs: <Tab>[Tab(text: '${context.tr.activeOrders} (${active.length})'), Tab(text: context.tr.pastOrders)])
              : null,
        ),
        body: !session.signedIn
            ? EmptyState(
                icon: Icons.receipt_long_outlined,
                title: context.tr.signInToSeeOrders,
                message: context.tr.signInToSeeOrdersHint,
                actionLabel: context.tr.signIn,
                onAction: () => context.push(Routes.login),
              )
            : orders.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: context.tr.noOrdersYet,
                    message: context.tr.noOrdersYetHint,
                    actionLabel: context.tr.startShopping,
                    onAction: () => context.go(Routes.shop),
                  )
                : TabBarView(
                    children: <Widget>[
                      _list(context, active),
                      _list(context, past),
                    ],
                  ),
      ),
    );
  }

  Widget _list(BuildContext context, List<Order> list) => list.isEmpty
      ? EmptyState(icon: Icons.inbox_outlined, title: context.tr.noResults)
      : MaxWidth(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: list.length,
            separatorBuilder: (BuildContext _, int i) => const SizedBox(height: 10),
            itemBuilder: (BuildContext _, int i) => OrderCard(order: list[i], onTap: () => context.push(Routes.order(list[i].id))),
          ),
        );
}

class OrderDoneScreen extends StatelessWidget {
  const OrderDoneScreen({super.key, required this.orderId, this.failure});

  final String orderId;
  final String? failure;

  @override
  Widget build(BuildContext context) {
    final Order? o = context.watch<MyOrdersCubit>().state.where((Order x) => x.id == orderId).firstOrNull;
    final StoreSettings store = context.watch<StoreCubit>().state;
    if (o == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final bool failed = o.status == OrderStatus.pendingPayment;
    final Color c = failed ? const Color(0xFFEF6C00) : BrandColors.green;
    final bool pickup = o.fulfilment != Fulfilment.delivery;
    String next;
    switch (o.paymentMode) {
      case PaymentMode.cashOnDelivery:
        next = context.tr.nextCod(formatRupees(o.total));
      case PaymentMode.cashAtStore:
        next = context.tr.nextCashStore(formatRupees(o.total));
      case PaymentMode.token:
        next = context.tr.nextReserve(formatRupees(o.balanceDue), Dates.dateTime(o.reservedUntil ?? o.createdAt, context.lang));
      case PaymentMode.bajajEmi:
        next = context.tr.nextBajaj;
      case PaymentMode.cardEmi:
      case PaymentMode.full:
      case PaymentMode.mixed:
        next = pickup ? context.tr.nextPickup : context.tr.nextDelivery;
    }
    GatewayFailure? f;
    for (final GatewayFailure x in GatewayFailure.values) {
      if (x.name == failure) f = x;
    }

    return Scaffold(
      body: SafeArea(
        child: MaxWidth(
          width: 560,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              const SizedBox(height: 16),
              Center(
                child: CircleAvatar(radius: 44, backgroundColor: c.withValues(alpha: 0.14), child: Icon(failed ? Icons.error_outline : Icons.check_circle, size: 54, color: c)),
              ),
              const SizedBox(height: 16),
              Text(
                failed ? context.tr.paymentNotDone : context.tr.orderPlacedTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                failed ? (f == null ? context.tr.paymentNotDoneHint : context.tr.gatewayFailure(f)) : context.tr.orderNumberIs(o.number),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (failed)
                Card(child: Padding(padding: const EdgeInsets.all(14), child: _RetryPay(order: o)))
              else ...<Widget>[
                if (pickup)
                  Card(
                    color: BrandColors.saffronSoft.withValues(alpha: 0.35),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: <Widget>[
                          Text(context.tr.showThisCode, style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text(o.pickupCode, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 6)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(context.tr.whatHappensNext, style: const TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text(next, style: const TextStyle(height: 1.45)),
                        if (pickup) ...<Widget>[
                          const SizedBox(height: 12),
                          AddressLines(store),
                          const SizedBox(height: 6),
                          StoreStatusBadge(store),
                          const SizedBox(height: 10),
                          ContactButtons(settings: store),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(onPressed: () => context.go(Routes.order(o.id)), child: Text(context.tr.viewOrder)),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: () => context.go(Routes.home), child: Text(context.tr.continueShopping)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Try again with the same or another way of paying.
class _RetryPay extends StatefulWidget {
  const _RetryPay({required this.order});
  final Order order;

  @override
  State<_RetryPay> createState() => _RetryPayState();
}

class _RetryPayState extends State<_RetryPay> {
  PayInstrument? _instrument;

  @override
  Widget build(BuildContext context) {
    final int due = widget.order.payments
        .where((PaymentRecord p) => p.kind == PaymentKind.payment && p.status == PaymentStatus.pending && p.method != PaymentMethod.cash)
        .fold(0, (int s, PaymentRecord p) => s + p.amount);
    final bool cardOnly = widget.order.payments.any((PaymentRecord p) => p.method == PaymentMethod.cardEmi);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(context.tr.tryAnotherWay, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        InstrumentPicker(
          methods: cardOnly ? const <PaymentMethod>[PaymentMethod.card] : const <PaymentMethod>[PaymentMethod.upi, PaymentMethod.card, PaymentMethod.netbanking],
          onChanged: (PayInstrument? i) => setState(() => _instrument = i),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _instrument == null
              ? null
              : () async {
                  final AppServices s = context.read<AppServices>();
                  final r = await runBusy(context, () => s.orders.retryPayment(widget.order, _instrument!));
                  if (r == null || !context.mounted) return;
                  if (r.failure != null) {
                    toast(context, context.tr.gatewayFailure(r.failure!));
                  } else {
                    context.go(Routes.orderDone(widget.order.id));
                  }
                },
          child: Text(context.tr.payAmount(formatRupees(due))),
        ),
      ],
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final Order? o = context.watch<MyOrdersCubit>().state.where((Order x) => x.id == orderId).firstOrNull;
    final StoreSettings store = context.watch<StoreCubit>().state;
    final String lang = context.lang;
    if (o == null) return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.receipt_long_outlined, title: context.tr.orderNotFound));
    final bool pickup = o.fulfilment != Fulfilment.delivery;
    final bool open = o.status.isOpen;
    final AppServices services = context.read<AppServices>();

    return Scaffold(
      appBar: AppBar(
        title: Text(o.number),
        actions: <Widget>[
          IconButton(
            tooltip: context.tr.shareInvoice,
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Launch.shareText(Invoice.text(o, store, context.tr, lang)),
          ),
        ],
      ),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: <Widget>[
            Row(
              children: <Widget>[
                StatusPill(context.tr.orderStatus(o.status), color: statusColor(o.status)),
                const Spacer(),
                Text(Dates.dateTime(o.createdAt, lang), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (o.status == OrderStatus.pendingPayment)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Card(child: Padding(padding: const EdgeInsets.all(14), child: _RetryPay(order: o))),
              ),
            if (pickup && open && o.pickupCode.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Card(
                  color: BrandColors.saffronSoft.withValues(alpha: 0.35),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.qr_code_2, size: 28),
                        const SizedBox(width: 12),
                        Expanded(child: Text(context.tr.pickupCode, style: const TextStyle(fontWeight: FontWeight.w700))),
                        Text(o.pickupCode, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4)),
                      ],
                    ),
                  ),
                ),
              ),
            if (o.reservedUntil != null && open)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InfoBanner(text: context.tr.reservedUntil(Dates.dateTime(o.reservedUntil!, lang)), icon: Icons.bookmark_added_outlined, color: BrandColors.saffron),
              ),
            Section(title: context.tr.trackOrder, child: OrderTimeline(order: o)),
            Section(
              title: context.tr.itemsHeader,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: <Widget>[
                      for (final OrderLine l in o.lines)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(l.nameFor(lang), style: const TextStyle(fontWeight: FontWeight.w800)),
                                        Text('${l.variantLabel} × ${l.qty}', style: Theme.of(context).textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                  Text(formatRupees(l.total), style: const TextStyle(fontWeight: FontWeight.w800)),
                                ],
                              ),
                              for (final String imei in l.imeis)
                                Text('IMEI $imei', style: Theme.of(context).textTheme.bodySmall),
                              if (l.imeis.isNotEmpty && o.deliveredAt != null)
                                Text(
                                  context.tr.warrantyUntil(Dates.date(Emi.addMonths(o.deliveredAt!, l.warrantyMonths), lang)),
                                  style: const TextStyle(color: BrandColors.green, fontWeight: FontWeight.w700, fontSize: 12.5),
                                ),
                            ],
                          ),
                        ),
                      const Divider(height: 20),
                      KeyValue(context.tr.subtotal, formatRupees(o.subtotal)),
                      if (o.couponDiscount > 0) KeyValue('${context.tr.coupon} ${o.couponCode ?? ''}', '-${formatRupees(o.couponDiscount)}', color: BrandColors.green),
                      if (o.coinsUsed > 0) KeyValue(context.tr.coinsUsed, '-${formatRupees(o.coinsUsed)}', color: BrandColors.green),
                      KeyValue(context.tr.deliveryFee, o.deliveryFee == 0 ? context.tr.freeLabel : formatRupees(o.deliveryFee)),
                      const Divider(height: 20),
                      KeyValue(context.tr.orderTotal, formatRupees(o.total), bold: true),
                    ],
                  ),
                ),
              ),
            ),
            Section(
              title: context.tr.paymentHeader,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: <Widget>[
                      KeyValue(context.tr.paymentMode, context.tr.payMode(o.paymentMode)),
                      const SizedBox(height: 4),
                      PaymentList(order: o),
                      if (o.balanceDue > 0 && o.status != OrderStatus.cancelled) ...<Widget>[
                        const Divider(height: 20),
                        KeyValue(context.tr.balanceDue, formatRupees(o.balanceDue), bold: true, color: const Color(0xFFEF6C00)),
                      ],
                      if (o.emiPlanId != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: OutlinedButton.icon(
                            onPressed: () => context.push(Routes.plan(o.emiPlanId!)),
                            icon: const Icon(Icons.credit_score_outlined),
                            label: Text(context.tr.viewEmiPlan),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Section(
              title: pickup ? context.tr.pickupHeader : context.tr.deliveryHeader,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: pickup
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            AddressLines(store),
                            const SizedBox(height: 6),
                            StoreStatusBadge(store),
                            const SizedBox(height: 10),
                            ContactButtons(settings: store),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(o.address?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                            Text(o.address?.oneLine ?? ''),
                            Text(o.address?.phone ?? ''),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                if (OrderFlow.customerMayCancel(o))
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: BrandColors.red),
                    onPressed: () async {
                      final String? reason = await promptDialog(context, title: context.tr.cancelOrderQ, hint: context.tr.reasonOptional);
                      if (reason == null || !context.mounted) return;
                      final Order? r = await runBusy(context, () => services.orders.cancelByCustomer(o, reason: reason));
                      if (r != null && context.mounted) toast(context, context.tr.orderCancelled);
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: Text(context.tr.cancelOrder),
                  ),
                if (OrderFlow.customerMayReturn(o, DateTime.now()))
                  OutlinedButton.icon(
                    onPressed: () async {
                      final String? reason = await promptDialog(context, title: context.tr.returnOrderQ, hint: context.tr.reasonOptional);
                      if (reason == null || !context.mounted) return;
                      final Order? r = await runBusy(context, () => services.orders.requestReturn(o, reason: reason));
                      if (r != null && context.mounted) toast(context, context.tr.returnRequestedMsg);
                    },
                    icon: const Icon(Icons.assignment_return_outlined),
                    label: Text(context.tr.returnItems),
                  ),
                if (!open)
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final CartCubit cart = context.read<CartCubit>();
                      final ProductsCubit products = context.read<ProductsCubit>();
                      for (final OrderLine l in o.lines) {
                        final Product? p = products.state.where((Product x) => x.id == l.productId).firstOrNull;
                        if (p != null && p.variant(l.variantId)?.inStock == true) await cart.add(l.productId, l.variantId, qty: l.qty);
                      }
                      if (context.mounted) unawaited(context.push(Routes.cart));
                    },
                    icon: const Icon(Icons.replay),
                    label: Text(context.tr.orderAgain),
                  ),
                if (store.hasPhone)
                  OutlinedButton.icon(
                    onPressed: () => Launch.call(store.phone),
                    icon: const Icon(Icons.support_agent_outlined),
                    label: Text(context.tr.needHelp),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

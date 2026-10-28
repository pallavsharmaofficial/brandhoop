import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../domain/emi_plan.dart';
import '../../domain/order.dart';
import '../../domain/payment.dart';
import '../../l10n/l10n.dart';
import '../../services/app_services.dart';
import '../../state/data_cubits.dart';
import '../../state/session_cubit.dart';
import '../../util/launch.dart';
import '../../widgets/common.dart';
import '../orders/order_widgets.dart';

enum _Filter { toHandle, ready, done, cancelled, all }

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  _Filter _filter = _Filter.toHandle;
  String _q = '';

  bool _match(Order o) {
    switch (_filter) {
      case _Filter.toHandle:
        return o.status == OrderStatus.pendingPayment || o.status == OrderStatus.placed || o.status == OrderStatus.confirmed || o.status == OrderStatus.packed;
      case _Filter.ready:
        return o.status == OrderStatus.outForDelivery || o.status == OrderStatus.readyForPickup;
      case _Filter.done:
        return o.status == OrderStatus.delivered || o.status == OrderStatus.returnRequested;
      case _Filter.cancelled:
        return o.status == OrderStatus.cancelled || o.status == OrderStatus.returned;
      case _Filter.all:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Order> all = context.watch<AllOrdersCubit>().state;
    final String q = _q.trim().toLowerCase();
    final List<Order> list = all
        .where(_match)
        .where((Order o) => q.isEmpty || o.number.toLowerCase().contains(q) || o.customerName.toLowerCase().contains(q) || o.customerPhone.contains(q))
        .toList()
      ..sort((Order a, Order b) => b.createdAt.compareTo(a.createdAt));
    String label(_Filter f) {
      switch (f) {
        case _Filter.toHandle:
          return context.tr.fltToHandle;
        case _Filter.ready:
          return context.tr.fltReady;
        case _Filter.done:
          return context.tr.fltDone;
        case _Filter.cancelled:
          return context.tr.fltCancelled;
        case _Filter.all:
          return context.tr.groupAll;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.tr.navOrders), actions: const <Widget>[LanguageButton(), SizedBox(width: 12)]),
      body: MaxWidth(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                onChanged: (String v) => setState(() => _q = v),
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: context.tr.searchOrdersHint),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: <Widget>[
                  for (final _Filter f in _Filter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(label: Text(label(f)), selected: _filter == f, onSelected: (_) => setState(() => _filter = f)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? EmptyState(icon: Icons.inbox_outlined, title: context.tr.noResults)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: list.length,
                      separatorBuilder: (BuildContext c, int i) => const SizedBox(height: 10),
                      itemBuilder: (BuildContext c, int i) {
                        final Order o = list[i];
                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => context.push(Routes.adminOrder(o.id)),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(child: Text(o.number, style: const TextStyle(fontWeight: FontWeight.w900))),
                                      if (o.source == OrderSource.pos) ...<Widget>[StatusPill(context.tr.sourceCounter, color: Colors.blueGrey), const SizedBox(width: 6)],
                                      StatusPill(context.tr.orderStatus(o.status), color: statusColor(o.status)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('${o.customerName} · ${o.customerPhone}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(o.lines.map((OrderLine l) => l.name).join(', '), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: <Widget>[
                                      Text(Dates.dateTime(o.createdAt, context.lang), style: Theme.of(context).textTheme.bodySmall),
                                      const Spacer(),
                                      StatusPill(context.tr.payMode(o.paymentMode), color: BrandColors.indigo),
                                      const SizedBox(width: 8),
                                      Text(formatRupees(o.total), style: const TextStyle(fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                  if (o.balanceDue > 0 && o.status.isOpen)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(context.tr.balanceToPay(formatRupees(o.balanceDue)), style: const TextStyle(color: Color(0xFFEF6C00), fontWeight: FontWeight.w700, fontSize: 12.5)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminOrderDetailScreen extends StatelessWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final Order? o = context.watch<AllOrdersCubit>().state.where((Order x) => x.id == orderId).firstOrNull;
    final SessionState session = context.watch<SessionCubit>().state;
    final EmiPlan? plan = o?.emiPlanId == null ? null : context.watch<AllPlansCubit>().state.where((EmiPlan p) => p.id == o!.emiPlanId).firstOrNull;
    if (o == null) return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.receipt_long_outlined, title: context.tr.orderNotFound));
    final AppServices services = context.read<AppServices>();
    final String lang = context.lang;
    final bool canOrders = session.can(Permission.manageOrders);
    final bool canEmi = session.can(Permission.manageEmi);
    final bool canRefund = session.can(Permission.issueRefunds);
    final List<OrderStatus> next = OrderFlow.next(o);

    Future<void> change(OrderStatus to) async {
      if (to == OrderStatus.cancelled || to == OrderStatus.returned) {
        final bool ok = await confirmDialog(context, title: to == OrderStatus.cancelled ? context.tr.cancelOrderQ : context.tr.confirmReturnQ, destructive: true);
        if (!ok || !context.mounted) return;
      }
      Order cur = o;
      if (to == OrderStatus.delivered && cur.lines.any((OrderLine l) => l.category.needsImei && l.imeis.length != l.qty)) {
        final Order? r = await _imeiDialog(context, services, session, cur);
        if (r == null || !context.mounted) return;
        cur = r;
      }
      if (to == OrderStatus.delivered && cur.balanceDue > 0) {
        final Order? r = await _collectDialog(context, services, session, cur);
        if (r == null || !context.mounted) return;
        cur = r;
      }
      await runBusy(context, () => services.orders.updateStatus(session.user, cur, to));
    }

    return Scaffold(
      appBar: AppBar(title: Text(o.number)),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: <Widget>[
            Row(
              children: <Widget>[
                StatusPill(context.tr.orderStatus(o.status), color: statusColor(o.status)),
                const SizedBox(width: 8),
                StatusPill(o.source == OrderSource.pos ? context.tr.sourceCounter : context.tr.sourceApp, color: Colors.blueGrey),
                const Spacer(),
                Text(Dates.dateTime(o.createdAt, lang), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (canOrders && next.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final OrderStatus s in next)
                      s == OrderStatus.cancelled || s == OrderStatus.returned
                          ? OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: BrandColors.red), onPressed: () => change(s), child: Text(_action(context, s, o)))
                          : FilledButton(onPressed: () => change(s), child: Text(_action(context, s, o))),
                  ],
                ),
              ),
            Section(
              title: context.tr.customer,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(o.customerName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      Text('+91 ${o.customerPhone}'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: <Widget>[
                          OutlinedButton.icon(onPressed: () => Launch.call(o.customerPhone), icon: const Icon(Icons.call_outlined, size: 18), label: Text(context.tr.call)),
                          OutlinedButton.icon(onPressed: () => Launch.whatsapp(o.customerPhone, text: context.tr.orderUpdateText(o.number, context.tr.orderStatus(o.status))), icon: const Icon(Icons.chat_outlined, size: 18), label: Text(context.tr.whatsapp)),
                        ],
                      ),
                      const Divider(height: 22),
                      Text(context.tr.fulfilment(o.fulfilment), style: const TextStyle(fontWeight: FontWeight.w800)),
                      if (o.address != null) Text('${o.address!.name}, ${o.address!.oneLine}\n${o.address!.phone}'),
                      if (o.fulfilment != Fulfilment.delivery && o.pickupCode.isNotEmpty) Text('${context.tr.pickupCode}: ${o.pickupCode}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      if (o.reservedUntil != null) Text(context.tr.reservedUntil(Dates.dateTime(o.reservedUntil!, lang)), style: const TextStyle(color: Color(0xFFEF6C00), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
            Section(
              title: context.tr.itemsHeader,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: <Widget>[
                      for (final OrderLine l in o.lines)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(child: Text('${l.nameFor(lang)} (${l.variantLabel}) × ${l.qty}', style: const TextStyle(fontWeight: FontWeight.w700))),
                                  Text(formatRupees(l.total), style: const TextStyle(fontWeight: FontWeight.w800)),
                                ],
                              ),
                              if (l.category.needsImei)
                                Text(
                                  l.imeis.isEmpty ? context.tr.imeiMissing : l.imeis.map((String i) => 'IMEI $i').join('\n'),
                                  style: TextStyle(fontSize: 12.5, color: l.imeis.length == l.qty ? null : BrandColors.red, fontWeight: l.imeis.length == l.qty ? null : FontWeight.w700),
                                ),
                            ],
                          ),
                        ),
                      if (canOrders && o.hasPhone && o.status.isOpen)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(onPressed: () => _imeiDialog(context, services, session, o), icon: const Icon(Icons.pin_outlined), label: Text(context.tr.enterImei)),
                        ),
                      const Divider(height: 20),
                      KeyValue(context.tr.subtotal, formatRupees(o.subtotal)),
                      if (o.couponDiscount > 0) KeyValue(o.source == OrderSource.pos ? context.tr.discount : '${context.tr.coupon} ${o.couponCode ?? ''}', '-${formatRupees(o.couponDiscount)}'),
                      if (o.coinsUsed > 0) KeyValue(context.tr.coinsUsed, '-${formatRupees(o.coinsUsed)}'),
                      if (o.deliveryFee > 0) KeyValue(context.tr.deliveryFee, formatRupees(o.deliveryFee)),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      KeyValue(context.tr.paymentMode, context.tr.payMode(o.paymentMode)),
                      PaymentList(order: o),
                      if (o.balanceDue > 0 && o.status != OrderStatus.cancelled) ...<Widget>[
                        const Divider(height: 20),
                        KeyValue(context.tr.balanceDue, formatRupees(o.balanceDue), bold: true, color: const Color(0xFFEF6C00)),
                        if (canOrders)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: FilledButton.icon(onPressed: () => _collectDialog(context, services, session, o), icon: const Icon(Icons.payments_outlined), label: Text(context.tr.collectPayment)),
                          ),
                      ],
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          if (canEmi && o.payments.any((PaymentRecord p) => p.kind == PaymentKind.lenderDisbursement && p.status == PaymentStatus.pending) && (plan?.isLive ?? false))
                            OutlinedButton.icon(
                              onPressed: () async {
                                final String? ref = await promptDialog(context, title: context.tr.lenderReference, hint: 'UTR / loan no.');
                                if (ref == null || !context.mounted) return;
                                await runBusy(context, () => services.orders.markLenderPaid(session.user, o, reference: ref));
                              },
                              icon: const Icon(Icons.account_balance_outlined),
                              label: Text(context.tr.markLenderPaid),
                            ),
                          if (canRefund)
                            for (final PaymentRecord p in o.payments.where((PaymentRecord x) => x.kind == PaymentKind.refund && x.status == PaymentStatus.pending))
                              FilledButton.tonalIcon(
                                onPressed: () => runBusy(context, () => services.orders.issueRefund(session.user, o, p.id)),
                                icon: const Icon(Icons.undo),
                                label: Text(context.tr.sendRefund(formatRupees(p.amount))),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (plan != null)
              Section(
                title: context.tr.emiPlan,
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.credit_score_outlined),
                    title: Text('${formatRupees(plan.emi)}${context.tr.perMonth} × ${plan.months}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text('${context.tr.provider(plan.provider)} · ${context.tr.planStatus(plan.status)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(Routes.adminPlan(plan.id)),
                  ),
                ),
              ),
            Section(title: context.tr.trackOrder, child: OrderTimeline(order: o)),
            if (o.notes.isNotEmpty) Section(title: context.tr.notes, child: Text(o.notes)),
          ],
        ),
      ),
    );
  }

  String _action(BuildContext c, OrderStatus s, Order o) {
    switch (s) {
      case OrderStatus.placed:
        return c.tr.actMarkPaid;
      case OrderStatus.confirmed:
        return c.tr.actConfirm;
      case OrderStatus.packed:
        return c.tr.actPack;
      case OrderStatus.outForDelivery:
        return c.tr.actOut;
      case OrderStatus.readyForPickup:
        return c.tr.actReady;
      case OrderStatus.delivered:
        return o.status == OrderStatus.returnRequested ? c.tr.actRejectReturn : c.tr.actDeliver;
      case OrderStatus.cancelled:
        return c.tr.actCancel;
      case OrderStatus.returned:
        return c.tr.actAcceptReturn;
      case OrderStatus.returnRequested:
      case OrderStatus.pendingPayment:
        return c.tr.orderStatus(s);
    }
  }

  Future<Order?> _imeiDialog(BuildContext context, AppServices services, SessionState session, Order o) async {
    final Map<int, List<TextEditingController>> ctrls = <int, List<TextEditingController>>{};
    for (int i = 0; i < o.lines.length; i++) {
      final OrderLine l = o.lines[i];
      if (!l.category.needsImei) continue;
      ctrls[i] = <TextEditingController>[
        for (int k = 0; k < l.qty; k++) TextEditingController(text: k < l.imeis.length ? l.imeis[k] : ''),
      ];
    }
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(ctx.tr.enterImei),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(ctx.tr.imeiHelp, style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 10),
              for (final MapEntry<int, List<TextEditingController>> e in ctrls.entries)
                for (int k = 0; k < e.value.length; k++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: e.value[k],
                      keyboardType: TextInputType.number,
                      maxLength: 15,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(labelText: '${o.lines[e.key].name} #${k + 1}', counterText: ''),
                    ),
                  ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.tr.save)),
        ],
      ),
    );
    final Map<int, List<String>> values = <int, List<String>>{
      for (final MapEntry<int, List<TextEditingController>> e in ctrls.entries) e.key: e.value.map((TextEditingController c) => c.text.trim()).toList(),
    };
    for (final List<TextEditingController> l in ctrls.values) {
      for (final TextEditingController c in l) {
        c.dispose();
      }
    }
    if (ok != true || !context.mounted) return null;
    return runBusy(context, () => services.orders.setImeis(session.user, o, values));
  }

  Future<Order?> _collectDialog(BuildContext context, AppServices services, SessionState session, Order o) async {
    PaymentMethod method = PaymentMethod.cash;
    final TextEditingController amount = TextEditingController(text: '${o.balanceDue}');
    final TextEditingController ref = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter set) => AlertDialog(
          title: Text(ctx.tr.collectPayment),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SegmentedButton<PaymentMethod>(
                showSelectedIcon: false,
                segments: <ButtonSegment<PaymentMethod>>[
                  ButtonSegment<PaymentMethod>(value: PaymentMethod.cash, label: Text(ctx.tr.payMethodCash)),
                  ButtonSegment<PaymentMethod>(value: PaymentMethod.upi, label: Text(ctx.tr.payMethodUpi)),
                  ButtonSegment<PaymentMethod>(value: PaymentMethod.card, label: Text(ctx.tr.payMethodCard)),
                ],
                selected: <PaymentMethod>{method},
                onSelectionChanged: (Set<PaymentMethod> s) => set(() => method = s.first),
              ),
              const SizedBox(height: 12),
              TextField(controller: amount, keyboardType: TextInputType.number, inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: ctx.tr.amount, prefixText: '₹ ')),
              if (method != PaymentMethod.cash) ...<Widget>[
                const SizedBox(height: 12),
                TextField(controller: ref, decoration: InputDecoration(labelText: ctx.tr.referenceOptional)),
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.tr.confirm)),
          ],
        ),
      ),
    );
    final int amt = int.tryParse(amount.text) ?? 0;
    final String reference = ref.text.trim();
    amount.dispose();
    ref.dispose();
    if (ok != true || !context.mounted) return null;
    return runBusy(context, () => services.orders.recordCounterPayment(session.user, o, amount: amt, method: method, reference: reference));
  }
}

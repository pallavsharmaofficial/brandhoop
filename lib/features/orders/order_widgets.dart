import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../domain/order.dart';
import '../../domain/payment.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';

Color statusColor(OrderStatus s) {
  switch (s) {
    case OrderStatus.pendingPayment:
      return const Color(0xFFEF6C00);
    case OrderStatus.placed:
    case OrderStatus.confirmed:
    case OrderStatus.packed:
      return BrandColors.indigo;
    case OrderStatus.outForDelivery:
    case OrderStatus.readyForPickup:
      return const Color(0xFF00897B);
    case OrderStatus.delivered:
      return BrandColors.green;
    case OrderStatus.cancelled:
    case OrderStatus.returned:
      return BrandColors.red;
    case OrderStatus.returnRequested:
      return const Color(0xFFEF6C00);
  }
}

/// Placed, confirmed, packed, on its way or ready, delivered: with the time
/// each was reached and what is still ahead.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final List<OrderStatus> steps = OrderFlow.timeline(order);
    final Map<OrderStatus, DateTime> reached = <OrderStatus, DateTime>{
      for (final OrderEvent e in order.events) e.status: e.at,
    };
    final bool cancelled = order.status == OrderStatus.cancelled;
    final int current = steps.lastIndexWhere((OrderStatus s) => reached.containsKey(s));
    return Column(
      children: <Widget>[
        for (int i = 0; i < steps.length; i++)
          _row(context, steps[i], i, current, reached[steps[i]], i == steps.length - 1, cancelled),
        if (cancelled)
          _row(context, OrderStatus.cancelled, steps.length, steps.length, reached[OrderStatus.cancelled], true, true, red: true),
      ],
    );
  }

  Widget _row(BuildContext context, OrderStatus s, int i, int current, DateTime? at, bool last, bool cancelled, {bool red = false}) {
    final bool done = at != null;
    final Color c = red ? BrandColors.red : (done ? BrandColors.green : Theme.of(context).colorScheme.outline);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 28,
            child: Column(
              children: <Widget>[
                Icon(red ? Icons.cancel : (done ? Icons.check_circle : Icons.radio_button_unchecked), color: c, size: 22),
                if (!last) Expanded(child: Container(width: 2, color: done && i < current ? BrandColors.green : Theme.of(context).colorScheme.outlineVariant)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(context.tr.orderStatus(s), style: TextStyle(fontWeight: done ? FontWeight.w800 : FontWeight.w500, color: done || red ? null : Theme.of(context).colorScheme.onSurfaceVariant)),
                  if (at != null) Text(Dates.dateTime(at, context.lang), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentList extends StatelessWidget {
  const PaymentList({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          for (final PaymentRecord p in order.payments)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: <Widget>[
                  Icon(_icon(p), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          p.kind == PaymentKind.refund
                              ? context.tr.payKindRefund
                              : p.kind == PaymentKind.lenderDisbursement
                                  ? context.tr.payKindLender
                                  : context.tr.payMethod(p.method),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (p.note.isNotEmpty && !p.note.startsWith('failed:') && p.note != 'token' && p.note != 'cancelled' && p.note != 'declined')
                          Text(p.note, style: Theme.of(context).textTheme.bodySmall),
                        if (p.note == 'token') Text(context.tr.reserveTokenLabel, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(formatRupees(p.amount), style: const TextStyle(fontWeight: FontWeight.w800)),
                      StatusPill(
                        context.tr.payStatus(p.status),
                        color: p.status == PaymentStatus.paid ? BrandColors.green : (p.status == PaymentStatus.failed ? BrandColors.red : const Color(0xFFEF6C00)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      );

  IconData _icon(PaymentRecord p) {
    if (p.kind == PaymentKind.refund) return Icons.undo;
    switch (p.method) {
      case PaymentMethod.upi:
        return Icons.qr_code_2;
      case PaymentMethod.card:
      case PaymentMethod.cardEmi:
        return Icons.credit_card;
      case PaymentMethod.netbanking:
        return Icons.account_balance_outlined;
      case PaymentMethod.cash:
        return Icons.payments_outlined;
      case PaymentMethod.bajajEmi:
        return Icons.account_balance_wallet_outlined;
    }
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String lang = context.lang;
    final String names = order.lines.map((OrderLine l) => l.nameFor(lang)).join(', ');
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: Text(order.number, style: const TextStyle(fontWeight: FontWeight.w900))),
                  StatusPill(context.tr.orderStatus(order.status), color: statusColor(order.status)),
                ],
              ),
              const SizedBox(height: 6),
              Text(names, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Text(Dates.date(order.createdAt, lang), style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  Text(formatRupees(order.total), style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
              if (order.balanceDue > 0 && order.status.isOpen)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(context.tr.balanceToPay(formatRupees(order.balanceDue)), style: const TextStyle(color: Color(0xFFEF6C00), fontWeight: FontWeight.w700, fontSize: 12.5)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

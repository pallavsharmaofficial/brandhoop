import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../domain/finance.dart';
import '../../domain/order.dart';
import '../../domain/payment.dart';
import '../../domain/product.dart';
import '../../l10n/l10n.dart';
import '../../services/analytics.dart';
import '../../state/data_cubits.dart';
import '../../state/session_cubit.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';

enum _Period { week, month, thisMonth }

/// Orders as CSV text, one line per item, for a spreadsheet or the accountant.
class OrdersCsv {
  const OrdersCsv._();

  static String _q(String s) => '"${s.replaceAll('"', '""')}"';

  static String build(Iterable<Order> orders) {
    final StringBuffer b = StringBuffer('order,date,customer,phone,item,variant,qty,unit_price,line_total,order_total,payment_mode,status\n');
    for (final Order o in orders) {
      for (final OrderLine l in o.lines) {
        b.writeln(<String>[
          o.number,
          (o.deliveredAt ?? o.createdAt).toLocal().toIso8601String().substring(0, 10),
          _q(o.customerName),
          o.customerPhone,
          _q(l.name),
          _q(l.variantLabel),
          '${l.qty}',
          '${l.unitPrice}',
          '${l.total}',
          '${o.total}',
          o.paymentMode.name,
          o.status.name,
        ].join(','));
      }
    }
    return b.toString();
  }
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _Period _p = _Period.month;

  @override
  Widget build(BuildContext context) {
    final List<Order> orders = context.watch<AllOrdersCubit>().state;
    final List<FinanceEntry> entries = context.watch<FinanceEntriesCubit>().state;
    final SessionState session = context.watch<SessionCubit>().state;
    final DateTime now = DateTime.now();
    final DateTime to = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final DateTime from = _p == _Period.week
        ? to.subtract(const Duration(days: 7))
        : _p == _Period.month
            ? to.subtract(const Duration(days: 30))
            : DateTime(now.year, now.month, 1);
    final List<Order> sales = Analytics.soldBetween(orders, from, to).toList();
    final int revenue = sales.fold(0, (int s, Order o) => s + o.total - o.deliveryFee);
    final int phones = Analytics.phoneUnits(sales);
    final bool money = session.can(Permission.viewFinancials);
    final int profit = entries.where((FinanceEntry e) => !e.at.isBefore(from) && e.at.isBefore(to)).fold(0, (int s, FinanceEntry e) => s + e.profit);

    final Map<ProductGroup, int> byGroup = <ProductGroup, int>{};
    final Map<PaymentMethod, int> byMethod = <PaymentMethod, int>{};
    for (final Order o in sales) {
      for (final OrderLine l in o.lines) {
        byGroup[l.category.group] = (byGroup[l.category.group] ?? 0) + l.total;
      }
      for (final PaymentRecord p in o.payments) {
        if (p.status == PaymentStatus.paid && p.kind != PaymentKind.refund) byMethod[p.method] = (byMethod[p.method] ?? 0) + p.amount;
      }
    }
    final int maxG = byGroup.values.fold(1, (int m, int v) => v > m ? v : m);
    final int maxM = byMethod.values.fold(1, (int m, int v) => v > m ? v : m);
    final top = Analytics.topProducts(orders, from, to);
    final days = Analytics.daily(entries: entries, orders: orders, now: now, days: _p == _Period.week ? 7 : 14);

    String label(_Period p) => p == _Period.week ? context.tr.last7Days : (p == _Period.month ? context.tr.last30Days : context.tr.thisMonth);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.reportsTitle),
        actions: <Widget>[
          IconButton(
            tooltip: context.tr.exportCsv,
            icon: const Icon(Icons.download_outlined),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: OrdersCsv.build(sales)));
              if (context.mounted) toast(context, context.tr.csvCopied);
            },
          ),
        ],
      ),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: <Widget>[
            Wrap(
              spacing: 8,
              children: <Widget>[for (final _Period p in _Period.values) ChoiceChip(label: Text(label(p)), selected: p == _p, onSelected: (_) => setState(() => _p = p))],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: <Widget>[
                _tile(context, context.tr.revenue, formatRupees(revenue), BrandColors.indigo),
                _tile(context, context.tr.ordersLabel, '${sales.length}', BrandColors.saffron),
                _tile(context, context.tr.avgOrder, formatRupees(sales.isEmpty ? 0 : (revenue / sales.length).round()), const Color(0xFF00897B)),
                _tile(context, context.tr.phonesSold, '$phones', const Color(0xFF8E24AA)),
                if (money) _tile(context, context.tr.profit, formatRupees(profit), BrandColors.green),
                if (money) _tile(context, context.tr.margin, revenue == 0 ? '-' : '${(profit * 100 / revenue).toStringAsFixed(1)}%', BrandColors.green),
              ],
            ),
            Section(
              title: context.tr.dailyProfitRevenue,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: BarChartMini(points: <BarPoint>[for (final DayStats d in days) BarPoint('${d.day.day}', money ? d.profit : d.revenue)], color: money ? BrandColors.green : BrandColors.indigo),
                ),
              ),
            ),
            Section(
              title: context.tr.salesByGroup,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(children: <Widget>[for (final MapEntry<ProductGroup, int> e in byGroup.entries) HBar(label: context.tr.group(e.key), value: e.value, max: maxG, valueText: formatRupees(e.value))]),
                ),
              ),
            ),
            Section(
              title: context.tr.paymentMix,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(children: <Widget>[for (final MapEntry<PaymentMethod, int> e in byMethod.entries) HBar(label: context.tr.payMethod(e.key), value: e.value, max: maxM, valueText: formatRupees(e.value), color: BrandColors.saffron)]),
                ),
              ),
            ),
            Section(
              title: context.tr.topProducts,
              child: Card(
                child: Column(
                  children: <Widget>[
                    for (final p in top)
                      ListTile(dense: true, title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(context.tr.unitsSold(p.units)), trailing: Text(formatRupees(p.revenue), style: const TextStyle(fontWeight: FontWeight.w900))),
                    if (top.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(context.tr.noResults)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, String label, String value, Color c) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: c))),
          ],
        ),
      );
}

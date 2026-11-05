import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/env.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../domain/emi_plan.dart';
import '../../domain/finance.dart';
import '../../domain/lead.dart';
import '../../domain/order.dart';
import '../../domain/product.dart';
import '../../domain/repair.dart';
import '../../domain/store_settings.dart';
import '../../l10n/l10n.dart';
import '../../services/analytics.dart';
import '../../services/app_services.dart';
import '../../services/finance_calc.dart';
import '../../state/data_cubits.dart';
import '../../state/session_cubit.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionState session = context.watch<SessionCubit>().state;
    final StoreSettings store = context.watch<StoreCubit>().state;
    final List<Order> orders = context.watch<AllOrdersCubit>().state;
    final List<Lead> leads = context.watch<LeadsCubit>().state;
    final List<EmiPlan> plans = context.watch<AllPlansCubit>().state;
    final List<RepairTicket> repairs = context.watch<AllRepairsCubit>().state;
    final List<Product> products = context.watch<ProductsCubit>().state;
    final List<FinanceEntry> entries = context.watch<FinanceEntriesCubit>().state;
    final DateTime now = DateTime.now();
    final bool money = session.can(Permission.viewFinancials);
    final bool owner = session.can(Permission.manageSettings);

    final Iterable<Order> today = orders.where((Order o) => o.createdAt.toLocal().year == now.year && o.createdAt.toLocal().month == now.month && o.createdAt.toLocal().day == now.day && o.status != OrderStatus.cancelled);
    final int todaySales = Analytics.revenueOn(orders, now);
    final List<Order> toHandle = orders.where((Order o) => o.status == OrderStatus.placed || o.status == OrderStatus.confirmed || o.status == OrderStatus.packed).toList();
    final List<EmiPlan> applied = plans.where((EmiPlan p) => p.status == EmiPlanStatus.applied).toList();
    final overdue = Analytics.overdueEmi(plans, now);
    final lowStock = Analytics.lowStock(products);
    final List<Lead> freshLeads = leads.where((Lead l) => l.status == LeadStatus.fresh).toList();
    final List<Lead> dueFollowUps = leads.where((Lead l) => l.isOpen && l.followUpAt != null && !l.followUpAt!.isAfter(now)).toList();
    final List<RepairTicket> repairsWaiting = repairs.where((RepairTicket r) => r.status == RepairStatus.booked || r.status == RepairStatus.received || r.status == RepairStatus.awaitingApproval).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.navDashboard),
        actions: <Widget>[
          const LanguageButton(),
          IconButton(
            tooltip: context.tr.viewAsCustomer,
            icon: const Icon(Icons.storefront_outlined),
            onPressed: () async {
              await context.read<SessionCubit>().setMode(AppMode.customer);
              if (context.mounted) context.go(Routes.home);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: MaxWidth(
        width: 880,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: <Widget>[
            if (AppEnv.demo) Padding(padding: const EdgeInsets.only(bottom: 10), child: InfoBanner(text: context.tr.demoBanner, icon: Icons.science_outlined, color: BrandColors.saffron)),
            if (money) _RoadHero(entries: entries, store: store, now: now),
            if (owner && store.missingSetup.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: _SetupCard(store: store)),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(child: _Stat(context.tr.todaySales, formatRupees(todaySales), Icons.currency_rupee, BrandColors.green)),
                const SizedBox(width: 10),
                Expanded(child: _Stat(context.tr.ordersToday, '${today.length}', Icons.receipt_long_outlined, BrandColors.indigo)),
              ],
            ),
            Section(
              title: context.tr.needsAttention,
              padding: const EdgeInsets.only(top: 18),
              child: Card(
                child: Column(
                  children: <Widget>[
                    _attn(context, Icons.shopping_bag_outlined, context.tr.attnOrders(toHandle.length), toHandle.length, () => context.go(Routes.adminOrders)),
                    _attn(context, Icons.account_balance_wallet_outlined, context.tr.attnEmiApprovals(applied.length), applied.length, () => context.push(Routes.adminEmi), perm: session.can(Permission.manageEmi)),
                    _attn(context, Icons.event_busy_outlined, context.tr.attnOverdue(overdue.count, formatRupees(overdue.amount)), overdue.count, () => context.push(Routes.adminEmi), perm: session.can(Permission.manageEmi)),
                    _attn(context, Icons.person_add_alt_outlined, context.tr.attnLeads(freshLeads.length), freshLeads.length, () => context.go(Routes.adminLeads)),
                    _attn(context, Icons.alarm_outlined, context.tr.attnFollowUps(dueFollowUps.length), dueFollowUps.length, () => context.go(Routes.adminLeads)),
                    _attn(context, Icons.build_outlined, context.tr.attnRepairs(repairsWaiting.length), repairsWaiting.length, () => context.push(Routes.adminRepairs)),
                    _attn(context, Icons.inventory_2_outlined, context.tr.attnLowStock(lowStock.length), lowStock.length, () => context.go(Routes.adminStock)),
                  ],
                ),
              ),
            ),
            if (money) ...<Widget>[
              _Last14(entries: entries, orders: orders, now: now),
              _Levers(entries: entries, now: now, store: store),
            ],
            if (session.can(Permission.viewReports) || money) _Scorecard(orders: orders, leads: leads, entries: entries, now: now),
            Section(
              title: context.tr.quickActions,
              padding: const EdgeInsets.only(top: 18),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  if (session.can(Permission.createWalkInSale)) FilledButton.icon(onPressed: () => context.push(Routes.adminPos), icon: const Icon(Icons.point_of_sale), label: Text(context.tr.newSale)),
                  if (session.can(Permission.manageCatalog)) OutlinedButton.icon(onPressed: () => context.push(Routes.adminProduct('new')), icon: const Icon(Icons.add_box_outlined), label: Text(context.tr.addProduct)),
                  if (AppEnv.demo)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final AppServices s = context.read<AppServices>();
                        final int n = await runBusy<int>(context, s.emi.runAutopay) ?? 0;
                        if (context.mounted) toast(context, context.tr.autopayRan(n));
                      },
                      icon: const Icon(Icons.autorenew),
                      label: Text(context.tr.runAutopayNow),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attn(BuildContext context, IconData i, String text, int n, VoidCallback onTap, {bool perm = true}) {
    if (!perm) return const SizedBox.shrink();
    return ListTile(
      dense: true,
      leading: Icon(i, color: n > 0 ? BrandColors.saffron : Theme.of(context).colorScheme.outline),
      title: Text(text, style: TextStyle(fontWeight: n > 0 ? FontWeight.w800 : FontWeight.w500)),
      trailing: Icon(n > 0 ? Icons.chevron_right : Icons.check, size: 18, color: n > 0 ? null : BrandColors.green),
      onTap: n > 0 ? onTap : null,
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                    Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

/// The month against the target: the number the app exists to move.
class _RoadHero extends StatelessWidget {
  const _RoadHero({required this.entries, required this.store, required this.now});

  final List<FinanceEntry> entries;
  final StoreSettings store;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final TargetProgress p = TargetTracker.compute(entries: entries, now: now, target: store.monthlyProfitTarget);
    final bool hi = context.isHindi;
    final bool on = p.onTrack;
    final double multiple = store.baselineMonthlyProfit <= 0 ? 0 : store.monthlyProfitTarget / store.baselineMonthlyProfit;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[BrandColors.indigoDeep, BrandColors.indigo]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(context.tr.roadToTarget(formatCompactRupees(store.monthlyProfitTarget, hindi: hi)), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
              StatusPill(on ? context.tr.onTrack : context.tr.behindTarget, color: on ? const Color(0xFF69F0AE) : BrandColors.saffron, icon: on ? Icons.trending_up : Icons.trending_flat),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              ProgressRing(
                value: p.percent,
                size: 112,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('${(p.percent * 100).toStringAsFixed(p.percent < 0.1 ? 1 : 0)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
                    Text(context.tr.ofTarget, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(context.tr.profitThisMonth, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(formatRupees(p.monthToDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28)),
                    const SizedBox(height: 6),
                    Text(context.tr.projectedMonthEnd(formatCompactRupees(p.projected, hindi: hi)), style: const TextStyle(color: Colors.white)),
                    Text(context.tr.needPerDay(formatRupees(p.requiredPerDay), p.daysLeft), style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (store.baselineMonthlyProfit > 0)
            Text(
              context.tr.baselineLine(formatCompactRupees(store.baselineMonthlyProfit, hindi: hi), multiple.toStringAsFixed(multiple >= 10 ? 0 : 1)),
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          const SizedBox(height: 2),
          Text(context.tr.profitBasisNote, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}

class _Last14 extends StatelessWidget {
  const _Last14({required this.entries, required this.orders, required this.now});

  final List<FinanceEntry> entries;
  final List<Order> orders;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final List<DayStats> d = Analytics.daily(entries: entries, orders: orders, now: now);
    final int total = d.fold(0, (int s, DayStats x) => s + x.profit);
    return Section(
      title: context.tr.last14Days,
      padding: const EdgeInsets.only(top: 18),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('${context.tr.profit}: ${formatRupees(total)}', style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              BarChartMini(points: <BarPoint>[for (final DayStats x in d) BarPoint('${x.day.day}', x.profit)]),
            ],
          ),
        ),
      ),
    );
  }
}

class _Levers extends StatelessWidget {
  const _Levers({required this.entries, required this.now, required this.store});

  final List<FinanceEntry> entries;
  final DateTime now;
  final StoreSettings store;

  @override
  Widget build(BuildContext context) {
    final TargetProgress p = TargetTracker.compute(entries: entries, now: now, target: store.monthlyProfitTarget);
    final List<(String, String, Color)> groups = <(String, String, Color)>[
      (ProfitCalculator.phones, context.tr.groupPhones, BrandColors.indigo),
      (ProfitCalculator.accessories, context.tr.groupAccessories, BrandColors.saffron),
      (ProfitCalculator.protection, context.tr.groupProtection, const Color(0xFF00897B)),
      (ProfitCalculator.repairs, context.tr.leverRepairs, const Color(0xFF8E24AA)),
    ];
    final int maxV = groups.fold(1, (int m, (String, String, Color) g) => (p.byGroup[g.$1] ?? 0) > m ? (p.byGroup[g.$1] ?? 0) : m);
    return Section(
      title: context.tr.whereProfitComes,
      padding: const EdgeInsets.only(top: 18),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: <Widget>[
              for (final (String, String, Color) g in groups)
                HBar(label: g.$2, value: p.byGroup[g.$1] ?? 0, max: maxV, valueText: formatRupees(p.byGroup[g.$1] ?? 0), color: g.$3),
              const SizedBox(height: 6),
              Text(context.tr.leversHint, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Scorecard extends StatelessWidget {
  const _Scorecard({required this.orders, required this.leads, required this.entries, required this.now});

  final List<Order> orders;
  final List<Lead> leads;
  final List<FinanceEntry> entries;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final DateTime from = now.subtract(const Duration(days: 30));
    final DateTime to = now.add(const Duration(days: 1));
    final List<Order> sales = Analytics.soldBetween(orders, from, to).toList();
    final int phones = Analytics.phoneUnits(sales);
    final double attach = Analytics.attachRate(sales);
    final double prot = Analytics.protectionRate(sales);
    final double repeat = Analytics.repeatRate(orders, from, to);
    final funnel = Analytics.leadFunnel(leads, from, to);
    final double conv = funnel.total == 0 ? 0 : funnel.converted / funnel.total;
    final int repairs = entries.where((FinanceEntry e) => e.kind == 'repair' && !e.at.isBefore(from)).length;

    Widget row(String label, String actual, String target, double ratio) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                  Text(actual, style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text('  /  $target', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(minHeight: 7, value: ratio.clamp(0, 1).toDouble(), color: ratio >= 1 ? BrandColors.green : BrandColors.saffron),
              ),
            ],
          ),
        );

    String pct(double v) => '${(v * 100).round()}%';
    return Section(
      title: context.tr.growthScorecard,
      padding: const EdgeInsets.only(top: 18),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(context.tr.scorecardHint, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              row(context.tr.scPhones, '$phones', '${GrowthTargets.phonesPerMonth}', phones / GrowthTargets.phonesPerMonth),
              row(context.tr.scAttach, pct(attach), pct(GrowthTargets.attachRate), attach / GrowthTargets.attachRate),
              row(context.tr.scProtection, pct(prot), pct(GrowthTargets.protectionRate), prot / GrowthTargets.protectionRate),
              row(context.tr.scRepairs, '$repairs', '${GrowthTargets.repairsPerMonth}', repairs / GrowthTargets.repairsPerMonth),
              row(context.tr.scLeadConv, pct(conv), pct(GrowthTargets.leadConversion), conv / GrowthTargets.leadConversion),
              row(context.tr.scRepeat, pct(repeat), pct(GrowthTargets.repeatRate), repeat / GrowthTargets.repeatRate),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.store});
  final StoreSettings store;

  @override
  Widget build(BuildContext context) {
    final Map<String, String> labels = <String, String>{
      'phone': context.tr.setupPhone,
      'whatsapp': context.tr.setupWhatsapp,
      'upi': context.tr.setupUpi,
      'gstin': context.tr.setupGstin,
      'location': context.tr.setupLocation,
      'emiRates': context.tr.setupEmiRates,
    };
    return Card(
      color: BrandColors.saffronSoft.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.checklist_outlined, color: BrandColors.saffron),
                const SizedBox(width: 8),
                Expanded(child: Text(context.tr.finishSetup, style: const TextStyle(fontWeight: FontWeight.w900))),
              ],
            ),
            const SizedBox(height: 6),
            Text(context.tr.finishSetupBody, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: <Widget>[for (final String k in store.missingSetup) Chip(label: Text(labels[k] ?? k), visualDensity: VisualDensity.compact)]),
            const SizedBox(height: 6),
            FilledButton.tonal(onPressed: () => context.push(Routes.adminSettings), child: Text(context.tr.openSettings)),
          ],
        ),
      ),
    );
  }
}

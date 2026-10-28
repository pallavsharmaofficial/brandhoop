import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../domain/emi_plan.dart';
import '../../domain/order.dart';
import '../../l10n/l10n.dart';
import '../../services/analytics.dart';
import '../../services/app_services.dart';
import '../../state/data_cubits.dart';
import '../../state/session_cubit.dart';
import '../../util/launch.dart';
import '../../widgets/common.dart';
import '../emi/emi_screen.dart';

class EmiDeskScreen extends StatelessWidget {
  const EmiDeskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<EmiPlan> plans = context.watch<AllPlansCubit>().state.toList()..sort((EmiPlan a, EmiPlan b) => b.createdAt.compareTo(a.createdAt));
    final DateTime now = DateTime.now();
    final List<EmiPlan> applied = plans.where((EmiPlan p) => p.status == EmiPlanStatus.applied).toList();
    final List<EmiPlan> active = plans.where((EmiPlan p) => p.status == EmiPlanStatus.active).toList();
    final List<EmiPlan> other = plans.where((EmiPlan p) => !applied.contains(p) && !active.contains(p)).toList();
    final overdue = Analytics.overdueEmi(plans, now);
    final int monthDue = active.fold(0, (int s, EmiPlan p) => s + p.instalments.where((Instalment i) => i.status != InstalmentStatus.paid && i.dueDate.year == now.year && i.dueDate.month == now.month).fold(0, (int a, Instalment i) => a + i.amount));

    Widget list(List<EmiPlan> l) => l.isEmpty
        ? EmptyState(icon: Icons.credit_score_outlined, title: context.tr.noResults)
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: l.length,
            separatorBuilder: (BuildContext c, int i) => const SizedBox(height: 10),
            itemBuilder: (BuildContext c, int i) => _DeskCard(plan: l[i], now: now),
          );

    return DefaultTabController(
      length: 3,
      initialIndex: applied.isEmpty && active.isNotEmpty ? 1 : 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr.emiDesk),
          bottom: TabBar(tabs: <Tab>[
            Tab(text: '${context.tr.tabApplications} (${applied.length})'),
            Tab(text: '${context.tr.tabActive} (${active.length})'),
            Tab(text: context.tr.tabOther),
          ]),
        ),
        body: MaxWidth(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: <Widget>[
                    Expanded(child: _Mini(context.tr.dueThisMonth, formatRupees(monthDue), BrandColors.indigo)),
                    const SizedBox(width: 10),
                    Expanded(child: _Mini(context.tr.overdueLabel, '${formatRupees(overdue.amount)} (${overdue.count})', overdue.count > 0 ? BrandColors.red : BrandColors.green)),
                  ],
                ),
              ),
              Expanded(child: TabBarView(children: <Widget>[list(applied), list(active), list(other)])),
            ],
          ),
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 15)),
          ],
        ),
      );
}

class _DeskCard extends StatelessWidget {
  const _DeskCard({required this.plan, required this.now});

  final EmiPlan plan;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final int od = plan.overdueCount(now);
    return Stack(
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            PlanCard(plan: plan, now: now, onTap: () => context.push(Routes.adminPlan(plan.id))),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text('${plan.customerName} · +91 ${plan.customerPhone}', style: Theme.of(context).textTheme.bodySmall)),
                  if (od > 0) StatusPill(context.tr.overdueCount(od), color: BrandColors.red),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One plan, with everything the desk can do to it.
class AdminPlanScreen extends StatelessWidget {
  const AdminPlanScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context) {
    final EmiPlan? p = context.watch<AllPlansCubit>().state.where((EmiPlan x) => x.id == planId).firstOrNull;
    final SessionState session = context.watch<SessionCubit>().state;
    if (p == null) return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.credit_score_outlined, title: context.tr.planNotFound));
    final AppServices services = context.read<AppServices>();
    final DateTime now = DateTime.now();
    final String lang = context.lang;
    final Order? order = context.watch<AllOrdersCubit>().state.where((Order o) => o.id == p.orderId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(p.orderNumber)),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: <Widget>[
            PlanCard(plan: p, now: now, onTap: () {}),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('${p.customerName} · +91 ${p.customerPhone}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        OutlinedButton.icon(onPressed: () => Launch.call(p.customerPhone), icon: const Icon(Icons.call_outlined, size: 18), label: Text(context.tr.call)),
                        OutlinedButton.icon(onPressed: () => Launch.whatsapp(p.customerPhone), icon: const Icon(Icons.chat_outlined, size: 18), label: Text(context.tr.whatsapp)),
                        if (order != null) OutlinedButton.icon(onPressed: () => context.push(Routes.adminOrder(order.id)), icon: const Icon(Icons.receipt_long_outlined, size: 18), label: Text(context.tr.viewOrder)),
                      ],
                    ),
                    const Divider(height: 22),
                    KeyValue(context.tr.itemPrice, formatRupees(p.price)),
                    KeyValue(context.tr.downPayment, formatRupees(p.downPayment)),
                    KeyValue(context.tr.amountFinanced, formatRupees(p.principal)),
                    KeyValue(context.tr.interestRate, p.annualRatePct <= 0 ? '0%' : '${p.annualRatePct}%'),
                    if (p.lenderRef.isNotEmpty) KeyValue(context.tr.lenderRef, p.lenderRef),
                    if (p.note.isNotEmpty) KeyValue(context.tr.notes, p.note),
                  ],
                ),
              ),
            ),
            if (p.status == EmiPlanStatus.applied) ...<Widget>[
              const SizedBox(height: 12),
              InfoBanner(text: context.tr.approveHint, icon: Icons.fact_check_outlined, color: const Color(0xFFEF6C00)),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final String? ref = await promptDialog(context, title: context.tr.lenderReference, hint: context.tr.lenderRefHint);
                        if (ref == null || !context.mounted) return;
                        await runBusy(context, () => services.emi.approve(session.user, p, lenderRef: ref));
                      },
                      icon: const Icon(Icons.check),
                      label: Text(context.tr.approvePlan),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: BrandColors.red),
                      onPressed: () async {
                        final String? reason = await promptDialog(context, title: context.tr.rejectPlan, hint: context.tr.reasonOptional);
                        if (reason == null || !context.mounted) return;
                        await runBusy<bool>(context, () async {
                          await services.emi.reject(session.user, p, reason: reason);
                          if (order != null) await services.orders.markLenderDeclined(session.user, order);
                          return true;
                        });
                      },
                      icon: const Icon(Icons.close),
                      label: Text(context.tr.rejectPlan),
                    ),
                  ),
                ],
              ),
            ],
            if (p.mandate != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Card(
                  child: ListTile(
                    leading: Icon(Icons.autorenew, color: autopayColor(p.mandate!.status)),
                    title: Text(context.tr.autopayStatus(p.mandate!.status), style: TextStyle(fontWeight: FontWeight.w800, color: autopayColor(p.mandate!.status))),
                    subtitle: Text('${context.tr.autopayMethod(p.mandate!.method)} · ${p.mandate!.maskedInstrument}'),
                  ),
                ),
              ),
            if (p.instalments.isNotEmpty)
              Section(
                title: context.tr.instalmentSchedule,
                child: Card(
                  child: Column(
                    children: <Widget>[
                      for (final Instalment i in p.instalments)
                        ListTile(
                          dense: true,
                          leading: CircleAvatar(radius: 14, child: Text('${i.index}', style: const TextStyle(fontSize: 12))),
                          title: Text('${Dates.date(i.dueDate, lang)} · ${formatRupees(i.amount)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(context.tr.instalmentStatus(i.statusAt(now)), style: TextStyle(color: i.statusAt(now) == InstalmentStatus.overdue ? BrandColors.red : (i.status == InstalmentStatus.paid ? BrandColors.green : null), fontWeight: FontWeight.w700)),
                          trailing: i.status == InstalmentStatus.paid || p.status != EmiPlanStatus.active
                              ? null
                              : TextButton(onPressed: () => runBusy(context, () => services.emi.markInstalmentPaid(session.user, p, i.index)), child: Text(context.tr.markPaid)),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

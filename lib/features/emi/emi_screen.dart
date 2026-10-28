import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../domain/emi_plan.dart';
import '../../l10n/l10n.dart';
import '../../state/data_cubits.dart';
import '../../state/session_cubit.dart';
import '../../widgets/common.dart';

Color planColor(EmiPlanStatus s) {
  switch (s) {
    case EmiPlanStatus.applied:
      return const Color(0xFFEF6C00);
    case EmiPlanStatus.approved:
    case EmiPlanStatus.active:
      return BrandColors.green;
    case EmiPlanStatus.closed:
      return BrandColors.indigo;
    case EmiPlanStatus.rejected:
    case EmiPlanStatus.cancelled:
      return BrandColors.red;
  }
}

Color autopayColor(AutopayStatus s) {
  switch (s) {
    case AutopayStatus.active:
      return BrandColors.green;
    case AutopayStatus.pending:
    case AutopayStatus.paused:
      return const Color(0xFFEF6C00);
    case AutopayStatus.failed:
    case AutopayStatus.cancelled:
      return BrandColors.red;
    case AutopayStatus.notSet:
      return Colors.blueGrey;
  }
}

class EmiScreen extends StatelessWidget {
  const EmiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionState session = context.watch<SessionCubit>().state;
    final List<EmiPlan> plans = context.watch<MyPlansCubit>().state.toList()
      ..sort((EmiPlan a, EmiPlan b) => b.createdAt.compareTo(a.createdAt));
    final DateTime now = DateTime.now();
    final List<EmiPlan> live = plans.where((EmiPlan p) => p.status == EmiPlanStatus.active).toList();

    // The single next payment across all live plans.
    ({EmiPlan plan, Instalment inst})? next;
    for (final EmiPlan p in live) {
      final Instalment? i = p.nextDue(now);
      if (i != null && (next == null || i.dueDate.isBefore(next.inst.dueDate))) next = (plan: p, inst: i);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.emiAndAutopay),
        actions: const <Widget>[LanguageButton(), SizedBox(width: 12)],
      ),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: <Widget>[
            if (next != null) _NextDue(plan: next.plan, inst: next.inst, now: now),
            if (!session.signedIn)
              EmptyState(
                icon: Icons.credit_score_outlined,
                title: context.tr.emiSignInTitle,
                message: context.tr.emiSignInBody,
                actionLabel: context.tr.signIn,
                onAction: () => context.push(Routes.login),
              )
            else if (plans.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: EmptyState(
                  icon: Icons.credit_score_outlined,
                  title: context.tr.noEmiPlans,
                  message: context.tr.noEmiPlansBody,
                  actionLabel: context.tr.browseEmiPhones,
                  onAction: () => context.go(Routes.shopWith(category: 'smartphone', emi: true)),
                ),
              )
            else ...<Widget>[
              Section(
                title: context.tr.yourEmiPlans,
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  children: <Widget>[
                    for (final EmiPlan p in plans)
                      Padding(padding: const EdgeInsets.only(bottom: 10), child: PlanCard(plan: p, now: now)),
                  ],
                ),
              ),
            ],
            Section(
              title: context.tr.emiHowItWorks,
              padding: const EdgeInsets.only(top: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _point(Icons.account_balance_wallet_outlined, context.tr.emiPointBajaj),
                      _point(Icons.credit_card, context.tr.emiPointCard),
                      _point(Icons.autorenew, context.tr.emiPointAutopay),
                      _point(Icons.description_outlined, context.tr.emiPointDocs),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => context.push(Routes.calculator),
                        icon: const Icon(Icons.calculate_outlined),
                        label: Text(context.tr.serviceEmiCalc),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _point(IconData i, String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(i, size: 20, color: BrandColors.indigo),
            const SizedBox(width: 10),
            Expanded(child: Text(t, style: const TextStyle(height: 1.4))),
          ],
        ),
      );
}

class _NextDue extends StatelessWidget {
  const _NextDue({required this.plan, required this.inst, required this.now});

  final EmiPlan plan;
  final Instalment inst;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final bool overdue = inst.statusAt(now) == InstalmentStatus.overdue;
    final int days = DateTime(inst.dueDate.year, inst.dueDate.month, inst.dueDate.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    final Color c = overdue ? BrandColors.red : BrandColors.indigo;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(Routes.plan(plan.id)),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(colors: <Color>[c, c.withValues(alpha: 0.8)]),
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.event_available_outlined, color: Colors.white, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(overdue ? context.tr.emiOverdue : context.tr.nextEmiDue, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(formatRupees(inst.amount), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    Text(
                      '${Dates.date(inst.dueDate, context.lang)}${overdue ? '' : ' · ${context.tr.inDays(days)}'}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              if (plan.mandate?.isActive == true)
                const Icon(Icons.autorenew, color: Colors.white)
              else
                const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.plan, required this.now, this.onTap});

  final EmiPlan plan;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final int total = plan.instalments.isEmpty ? plan.months : plan.instalments.length;
    final Instalment? next = plan.nextDue(now);
    final AutopayStatus ap = plan.mandate?.status ?? AutopayStatus.notSet;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap ?? () => context.push(Routes.plan(plan.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: Text(plan.productSummary, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900))),
                  StatusPill(context.tr.planStatus(plan.status), color: planColor(plan.status)),
                ],
              ),
              const SizedBox(height: 4),
              Text('${context.tr.provider(plan.provider)} · ${plan.orderNumber}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 10),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: <Widget>[
                  Text(formatRupees(plan.emi), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                  Text('${context.tr.perMonth} × ${plan.months}', style: Theme.of(context).textTheme.bodyMedium),
                  if (plan.noCost) StatusPill(context.tr.zeroInterest, color: BrandColors.green),
                ],
              ),
              if (plan.status == EmiPlanStatus.active || plan.status == EmiPlanStatus.closed) ...<Widget>[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: total == 0 ? 0 : plan.paidCount / total, minHeight: 8),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Text(context.tr.paidOf(plan.paidCount, total), style: Theme.of(context).textTheme.bodySmall),
                    const Spacer(),
                    if (next != null) Text(context.tr.nextOn(Dates.dateShort(next.dueDate, context.lang)), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
              if (plan.status == EmiPlanStatus.active) ...<Widget>[
                const SizedBox(height: 8),
                StatusPill(context.tr.autopayStatus(ap), color: autopayColor(ap), icon: Icons.autorenew),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

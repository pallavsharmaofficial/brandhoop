import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../domain/emi_plan.dart';
import '../../domain/payment.dart';
import '../../domain/store_settings.dart';
import '../../l10n/l10n.dart';
import '../../services/app_services.dart';
import '../../services/payment_gateway.dart';
import '../../state/data_cubits.dart';
import '../../util/launch.dart';
import '../../widgets/common.dart';
import '../checkout/payment_forms.dart';
import 'emi_screen.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context) {
    final EmiPlan? p = context.watch<MyPlansCubit>().state.where((EmiPlan x) => x.id == planId).firstOrNull;
    final StoreSettings store = context.watch<StoreCubit>().state;
    if (p == null) return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.credit_score_outlined, title: context.tr.planNotFound));
    final DateTime now = DateTime.now();
    final String lang = context.lang;
    final int total = p.instalments.fold(0, (int s, Instalment i) => s + i.amount);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr.emiPlan)),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(child: Text(p.productSummary, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                        StatusPill(context.tr.planStatus(p.status), color: planColor(p.status)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${context.tr.provider(p.provider)} · ${p.orderNumber}', style: Theme.of(context).textTheme.bodySmall),
                    const Divider(height: 22),
                    KeyValue(context.tr.itemPrice, formatRupees(p.price)),
                    KeyValue(context.tr.downPayment, formatRupees(p.downPayment)),
                    KeyValue(context.tr.amountFinanced, formatRupees(p.principal)),
                    KeyValue(context.tr.tenure, context.tr.monthsCount(p.months)),
                    KeyValue(context.tr.interestRate, p.annualRatePct <= 0 ? '0%' : '${p.annualRatePct.toStringAsFixed(p.annualRatePct % 1 == 0 ? 0 : 1)}% ${context.tr.perYear}'),
                    KeyValue(context.tr.monthlyEmi, formatRupees(p.emi), bold: true),
                    if (p.lenderRef.isNotEmpty) KeyValue(context.tr.lenderRef, p.lenderRef),
                  ],
                ),
              ),
            ),
            if (p.status == EmiPlanStatus.applied)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InfoBanner(text: context.tr.planAppliedHint, icon: Icons.hourglass_top, color: const Color(0xFFEF6C00)),
              ),
            if (p.status == EmiPlanStatus.rejected)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InfoBanner(text: context.tr.planRejectedHint, icon: Icons.info_outline, color: BrandColors.red),
              ),
            if (p.status == EmiPlanStatus.active || p.status == EmiPlanStatus.approved) _AutopayCard(plan: p, now: now, store: store),
            if (p.instalments.isNotEmpty)
              Section(
                title: context.tr.instalmentSchedule,
                child: Card(
                  child: Column(
                    children: <Widget>[
                      for (final Instalment i in p.instalments)
                        ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: _instColor(i.statusAt(now)).withValues(alpha: 0.14),
                            child: Text('${i.index}', style: TextStyle(color: _instColor(i.statusAt(now)), fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                          title: Text(Dates.date(i.dueDate, lang), style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: i.paidOn == null ? null : Text(context.tr.paidOn(Dates.date(i.paidOn!, lang))),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Text(formatRupees(i.amount), style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text(context.tr.instalmentStatus(i.statusAt(now)), style: TextStyle(color: _instColor(i.statusAt(now)), fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: KeyValue(context.tr.totalYouPay, formatRupees(total + p.downPayment), bold: true),
                      ),
                    ],
                  ),
                ),
              ),
            if (p.status == EmiPlanStatus.active) ...<Widget>[
              const SizedBox(height: 16),
              if (p.provider == EmiProvider.bajaj)
                OutlinedButton.icon(
                  onPressed: () => Launch.url('https://www.bajajfinserv.in/'),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(context.tr.openBajajApp),
                ),
              if (p.provider == EmiProvider.bank) InfoBanner(text: context.tr.bankAutoDebit, icon: Icons.credit_card),
              const SizedBox(height: 10),
              if (store.hasPhone)
                OutlinedButton.icon(onPressed: () => Launch.call(store.phone), icon: const Icon(Icons.support_agent_outlined), label: Text(context.tr.needHelp)),
            ],
          ],
        ),
      ),
    );
  }

  Color _instColor(InstalmentStatus s) {
    switch (s) {
      case InstalmentStatus.paid:
        return BrandColors.green;
      case InstalmentStatus.overdue:
        return BrandColors.red;
      case InstalmentStatus.upcoming:
        return BrandColors.indigo;
    }
  }
}

class _AutopayCard extends StatelessWidget {
  const _AutopayCard({required this.plan, required this.now, required this.store});

  final EmiPlan plan;
  final DateTime now;
  final StoreSettings store;

  @override
  Widget build(BuildContext context) {
    final AutopayMandate? m = plan.mandate;
    final AutopayStatus st = m?.status ?? AutopayStatus.notSet;
    final Instalment? next = plan.nextDue(now);
    final AppServices services = context.read<AppServices>();
    final bool on = st == AutopayStatus.active;
    final bool canSetUp = store.autopayEnabled && plan.status == EmiPlanStatus.active;

    return Section(
      title: context.tr.autopaySettings,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.autorenew, color: autopayColor(st)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(context.tr.autopayStatus(st), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: autopayColor(st)))),
                ],
              ),
              const SizedBox(height: 6),
              Text(on ? context.tr.autopayOnBody : context.tr.autopayOffBody, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4)),
              if (m != null && st != AutopayStatus.notSet && st != AutopayStatus.cancelled) ...<Widget>[
                const Divider(height: 24),
                KeyValue(context.tr.autopayMethodLabel, context.tr.autopayMethod(m.method)),
                if (m.maskedInstrument.isNotEmpty) KeyValue(context.tr.autopayAccount, m.maskedInstrument),
                KeyValue(context.tr.autopayLimit, formatRupees(m.maxAmount)),
                if (next != null && on) KeyValue(context.tr.nextDebit, '${Dates.date(next.dueDate, context.lang)} · ${formatRupees(next.amount)}'),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(child: Text(context.tr.remindMe, style: const TextStyle(fontWeight: FontWeight.w700))),
                    IconButton(
                      onPressed: m.remindDaysBefore <= 0 ? null : () => services.emi.setReminderDays(plan, m.remindDaysBefore - 1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(context.tr.daysBefore(m.remindDaysBefore), style: const TextStyle(fontWeight: FontWeight.w800)),
                    IconButton(
                      onPressed: m.remindDaysBefore >= 7 ? null : () => services.emi.setReminderDays(plan, m.remindDaysBefore + 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              if (st == AutopayStatus.active)
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: () => services.emi.setAutopayStatus(plan, AutopayStatus.paused),
                      icon: const Icon(Icons.pause_circle_outline),
                      label: Text(context.tr.pauseAutopay),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: BrandColors.red),
                      onPressed: () async {
                        final bool ok = await confirmDialog(context, title: context.tr.cancelAutopayQ, message: context.tr.cancelAutopayBody, destructive: true);
                        if (ok) await services.emi.setAutopayStatus(plan, AutopayStatus.cancelled);
                      },
                      icon: const Icon(Icons.cancel_outlined),
                      label: Text(context.tr.cancelAutopay),
                    ),
                  ],
                )
              else if (st == AutopayStatus.paused)
                FilledButton.icon(
                  onPressed: () => services.emi.setAutopayStatus(plan, AutopayStatus.active),
                  icon: const Icon(Icons.play_circle_outline),
                  label: Text(context.tr.resumeAutopay),
                )
              else if (canSetUp)
                FilledButton.icon(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext _) => AutopaySetupSheet(plan: plan, services: services),
                  ),
                  icon: const Icon(Icons.autorenew),
                  label: Text(st == AutopayStatus.failed ? context.tr.setupAutopayAgain : context.tr.turnOnAutopay),
                ),
              if (plan.provider == EmiProvider.bajaj && st != AutopayStatus.notSet)
                Padding(padding: const EdgeInsets.only(top: 10), child: Text(context.tr.autopayLenderNote, style: Theme.of(context).textTheme.bodySmall)),
            ],
          ),
        ),
      ),
    );
  }
}

class AutopaySetupSheet extends StatefulWidget {
  const AutopaySetupSheet({super.key, required this.plan, required this.services});

  final EmiPlan plan;
  final AppServices services;

  @override
  State<AutopaySetupSheet> createState() => _AutopaySetupSheetState();
}

class _AutopaySetupSheetState extends State<AutopaySetupSheet> {
  PayInstrument? _instrument;
  bool _agreed = false;

  AutopayMethod? get _method {
    final PayInstrument? i = _instrument;
    if (i == null) return null;
    switch (i.method) {
      case PaymentMethod.upi:
        return AutopayMethod.upiAutopay;
      case PaymentMethod.card:
      case PaymentMethod.cardEmi:
        return AutopayMethod.cardMandate;
      case PaymentMethod.netbanking:
      case PaymentMethod.cash:
      case PaymentMethod.bajajEmi:
        return AutopayMethod.bankMandate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int limit = widget.plan.instalments.isEmpty
        ? widget.plan.emi
        : widget.plan.instalments.map((Instalment i) => i.amount).reduce((int a, int b) => a > b ? a : b);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(context.tr.turnOnAutopay, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(context.tr.autopaySheetBody(formatRupees(widget.plan.emi)), style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              InstrumentPicker(
                methods: const <PaymentMethod>[PaymentMethod.upi, PaymentMethod.card, PaymentMethod.netbanking],
                onChanged: (PayInstrument? i) => setState(() => _instrument = i),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _agreed,
                onChanged: (bool? v) => setState(() => _agreed = v ?? false),
                title: Text(context.tr.autopayConsent(formatRupees(limit)), style: const TextStyle(fontSize: 13, height: 1.35)),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _instrument != null && _agreed
                    ? () async {
                        final NavigatorState nav = Navigator.of(context);
                        final EmiPlan? r = await runBusy(context, () => widget.services.emi.setupAutopay(widget.plan, method: _method!, instrument: _instrument!));
                        if (r != null) nav.pop();
                      }
                    : null,
                child: Text(context.tr.authoriseAutopay),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

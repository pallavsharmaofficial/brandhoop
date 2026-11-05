import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/env.dart';
import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../domain/repair.dart';
import '../../domain/store_settings.dart';
import '../../l10n/l10n.dart';
import '../../util/shop_message.dart';
import '../../services/app_services.dart';
import '../../state/data_cubits.dart';
import '../../util/launch.dart';
import '../../widgets/common.dart';
import '../auth/auth_gate.dart';

Color repairColor(RepairStatus s) {
  switch (s) {
    case RepairStatus.booked:
    case RepairStatus.received:
    case RepairStatus.diagnosing:
      return BrandColors.indigo;
    case RepairStatus.awaitingApproval:
      return const Color(0xFFEF6C00);
    case RepairStatus.inRepair:
      return const Color(0xFF00897B);
    case RepairStatus.ready:
    case RepairStatus.delivered:
      return BrandColors.green;
    case RepairStatus.cancelled:
      return BrandColors.red;
  }
}

class RepairScreen extends StatefulWidget {
  const RepairScreen({super.key});

  @override
  State<RepairScreen> createState() => _RepairScreenState();
}

class _RepairScreenState extends State<RepairScreen> {
  final TextEditingController _brand = TextEditingController();
  final TextEditingController _model = TextEditingController();
  final TextEditingController _note = TextEditingController();
  RepairIssue _issue = RepairIssue.screen;

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StoreSettings store = context.watch<StoreCubit>().state;
    final List<RepairTicket> mine = context.watch<MyRepairsCubit>().state.toList()
      ..sort((RepairTicket a, RepairTicket b) => b.createdAt.compareTo(a.createdAt));
    return Scaffold(
      appBar: AppBar(title: Text(context.tr.serviceRepair)),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: <Widget>[
            Text(context.tr.repairIntro, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4)),
            const SizedBox(height: 16),
            Text(context.tr.whatIsWrong, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final RepairIssue i in RepairIssue.values)
                  ChoiceChip(
                    label: Text('${context.tr.repairIssue(i)} · ${context.tr.fromPrice(formatRupees(store.repairPrice(i)))}'),
                    selected: i == _issue,
                    onSelected: (_) => setState(() => _issue = i),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(child: TextField(controller: _brand, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: context.tr.brand))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _model, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: context.tr.model))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: _note, maxLines: 3, decoration: InputDecoration(labelText: context.tr.describeProblem)),
            const SizedBox(height: 12),
            InfoBanner(text: context.tr.repairHowItWorks, icon: Icons.info_outline),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _book(context),
              icon: const Icon(Icons.build_circle_outlined),
              label: Text(context.tr.bookRepair),
            ),
            if (mine.isNotEmpty)
              Section(
                title: context.tr.myRepairs,
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  children: <Widget>[
                    for (final RepairTicket t in mine)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            onTap: () => context.push(Routes.repairTicket(t.id)),
                            title: Text('${t.brand} ${t.model}'.trim().isEmpty ? t.number : '${t.brand} ${t.model}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text('${t.number} · ${context.tr.repairIssue(t.issue)}'),
                            trailing: StatusPill(context.tr.repairStatus(t.status), color: repairColor(t.status)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _book(BuildContext context) async {
    if (_brand.text.trim().isEmpty || _model.text.trim().isEmpty) {
      toast(context, context.tr.enterBrandModel);
      return;
    }
    if (AppEnv.live) {
      final String shop = context.read<StoreCubit>().state.name.of(context.lang);
      final String device = '${_brand.text.trim()} ${_model.text.trim()}';
      final String issue = '${context.tr.repairIssue(_issue)} ${_note.text.trim()}'.trim();
      return sendToShop(context, context.tr.liveRepairMsg(shop, device, issue));
    }
    final user = await ensureSignedIn(context);
    if (user == null || !context.mounted) return;
    final AppServices services = context.read<AppServices>();
    final RepairTicket? t = await runBusy(
      context,
      () => services.repairs.book(user, brand: _brand.text, model: _model.text, issue: _issue, description: _note.text),
    );
    if (t == null || !context.mounted) return;
    toast(context, context.tr.repairBookedMsg(t.number));
    _brand.clear();
    _model.clear();
    _note.clear();
    unawaited(context.push(Routes.repairTicket(t.id)));
  }
}

class RepairTicketScreen extends StatelessWidget {
  const RepairTicketScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  Widget build(BuildContext context) {
    final RepairTicket? t = context.watch<MyRepairsCubit>().state.where((RepairTicket x) => x.id == ticketId).firstOrNull;
    final StoreSettings store = context.watch<StoreCubit>().state;
    if (t == null) return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.build_outlined, title: context.tr.noResults));
    final String lang = context.lang;
    final AppServices services = context.read<AppServices>();
    const List<RepairStatus> path = <RepairStatus>[
      RepairStatus.booked,
      RepairStatus.received,
      RepairStatus.diagnosing,
      RepairStatus.awaitingApproval,
      RepairStatus.inRepair,
      RepairStatus.ready,
      RepairStatus.delivered,
    ];
    final Map<RepairStatus, DateTime> reached = <RepairStatus, DateTime>{for (final RepairEvent e in t.events) e.status: e.at};
    return Scaffold(
      appBar: AppBar(title: Text(t.number)),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text('${t.brand} ${t.model}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
                StatusPill(context.tr.repairStatus(t.status), color: repairColor(t.status)),
              ],
            ),
            Text(context.tr.repairIssue(t.issue), style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: <Widget>[
                    KeyValue(context.tr.estimatedPrice, formatRupees(t.estimate)),
                    if (t.finalPrice != null) KeyValue(context.tr.quotedPrice, formatRupees(t.finalPrice!), bold: true),
                  ],
                ),
              ),
            ),
            if (t.status == RepairStatus.awaitingApproval) ...<Widget>[
              const SizedBox(height: 12),
              InfoBanner(text: context.tr.repairApprovePrompt(formatRupees(t.finalPrice ?? t.estimate)), icon: Icons.fact_check_outlined, color: const Color(0xFFEF6C00)),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () async {
                  final RepairTicket? r = await runBusy(context, () => services.repairs.approveQuote(t));
                  if (r != null && context.mounted) toast(context, context.tr.saved);
                },
                child: Text(context.tr.approveAndRepair),
              ),
            ],
            Section(
              title: context.tr.progress,
              child: Column(
                children: <Widget>[
                  for (final RepairStatus s in path)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(reached.containsKey(s) ? Icons.check_circle : Icons.radio_button_unchecked, color: reached.containsKey(s) ? BrandColors.green : Theme.of(context).colorScheme.outline),
                      title: Text(context.tr.repairStatus(s), style: TextStyle(fontWeight: reached.containsKey(s) ? FontWeight.w800 : FontWeight.w500)),
                      subtitle: reached[s] == null ? null : Text(Dates.dateTime(reached[s]!, lang)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: <Widget>[
                if (t.status == RepairStatus.booked || t.status == RepairStatus.received)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: BrandColors.red),
                    onPressed: () async {
                      final bool ok = await confirmDialog(context, title: context.tr.cancelRepairQ, destructive: true);
                      if (ok && context.mounted) await runBusy(context, () => services.repairs.cancelByCustomer(t));
                    },
                    child: Text(context.tr.cancel),
                  ),
                if (store.hasPhone) OutlinedButton.icon(onPressed: () => Launch.call(store.phone), icon: const Icon(Icons.call_outlined), label: Text(context.tr.call)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

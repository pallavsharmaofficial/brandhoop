import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/validators.dart';
import '../../domain/repair.dart';
import '../../l10n/l10n.dart';
import '../../services/app_services.dart';
import '../../state/data_cubits.dart';
import '../../state/session_cubit.dart';
import '../../util/launch.dart';
import '../../widgets/common.dart';
import '../services/repair_screens.dart';

class RepairsDeskScreen extends StatefulWidget {
  const RepairsDeskScreen({super.key});

  @override
  State<RepairsDeskScreen> createState() => _RepairsDeskScreenState();
}

class _RepairsDeskScreenState extends State<RepairsDeskScreen> {
  bool _openOnly = true;

  @override
  Widget build(BuildContext context) {
    final List<RepairTicket> all = context.watch<AllRepairsCubit>().state.toList()..sort((RepairTicket a, RepairTicket b) => b.updatedAt.compareTo(a.updatedAt));
    final List<RepairTicket> list = all.where((RepairTicket t) => !_openOnly || t.isOpen).toList();
    return Scaffold(
      appBar: AppBar(title: Text(context.tr.repairsDesk), actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilterChip(label: Text(context.tr.fltOpen), selected: _openOnly, onSelected: (bool v) => setState(() => _openOnly = v)),
        ),
      ]),
      body: MaxWidth(
        child: list.isEmpty
            ? EmptyState(icon: Icons.build_outlined, title: context.tr.noResults)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: list.length,
                separatorBuilder: (BuildContext c, int i) => const SizedBox(height: 10),
                itemBuilder: (BuildContext c, int i) {
                  final RepairTicket t = list[i];
                  return Card(
                    child: ListTile(
                      onTap: () => context.push(Routes.adminRepair(t.id)),
                      title: Text('${t.number} · ${t.brand} ${t.model}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${t.name} · ${context.tr.repairIssue(t.issue)}'),
                      trailing: StatusPill(context.tr.repairStatus(t.status), color: repairColor(t.status)),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class AdminRepairScreen extends StatelessWidget {
  const AdminRepairScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  Widget build(BuildContext context) {
    final RepairTicket? t = context.watch<AllRepairsCubit>().state.where((RepairTicket x) => x.id == ticketId).firstOrNull;
    final SessionState session = context.watch<SessionCubit>().state;
    if (t == null) return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.build_outlined, title: context.tr.noResults));
    final AppServices services = context.read<AppServices>();
    final String lang = context.lang;

    Future<void> go(RepairStatus to) async {
      int? price;
      int? parts;
      String? imei;
      if (to == RepairStatus.awaitingApproval) {
        final String? v = await promptDialog(context, title: context.tr.quotePrice, keyboard: TextInputType.number, initial: '${t.finalPrice ?? t.estimate}');
        price = int.tryParse(v ?? '');
        if (price == null || !context.mounted) return;
      }
      if (to == RepairStatus.delivered) {
        final String? v = await promptDialog(context, title: context.tr.partsCostPrompt, keyboard: TextInputType.number, initial: '0');
        parts = int.tryParse(v ?? '');
        if (parts == null || !context.mounted) return;
      }
      if (to == RepairStatus.received && t.imei.isEmpty) {
        final String? v = await promptDialog(context, title: '${context.tr.enterImei} (${context.tr.optional})', keyboard: TextInputType.number);
        if (v == null || !context.mounted) return;
        imei = v.isEmpty ? null : v;
        if (imei != null && !Validators.imei(imei)) {
          toast(context, context.tr.errBadImei);
          return;
        }
      }
      await runBusy(context, () => services.repairs.advance(session.user, t, to, finalPrice: price, partsCost: parts, imei: imei));
    }

    const List<RepairStatus> forward = <RepairStatus>[
      RepairStatus.booked,
      RepairStatus.received,
      RepairStatus.diagnosing,
      RepairStatus.awaitingApproval,
      RepairStatus.inRepair,
      RepairStatus.ready,
      RepairStatus.delivered,
    ];
    final int idx = forward.indexOf(t.status);
    final RepairStatus? next = t.isOpen && idx >= 0 && idx < forward.length - 1 ? forward[idx + 1] : null;

    return Scaffold(
      appBar: AppBar(title: Text(t.number)),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text('${t.brand} ${t.model}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
                StatusPill(context.tr.repairStatus(t.status), color: repairColor(t.status)),
              ],
            ),
            Text('${t.name} · +91 ${t.phone}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <Widget>[
                OutlinedButton.icon(onPressed: () => Launch.call(t.phone), icon: const Icon(Icons.call_outlined, size: 18), label: Text(context.tr.call)),
                OutlinedButton.icon(onPressed: () => Launch.whatsapp(t.phone), icon: const Icon(Icons.chat_outlined, size: 18), label: Text(context.tr.whatsapp)),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: <Widget>[
                    KeyValue(context.tr.issueLabel, context.tr.repairIssue(t.issue)),
                    if (t.description.isNotEmpty) KeyValue(context.tr.description, t.description),
                    KeyValue(context.tr.estimatedPrice, formatRupees(t.estimate)),
                    if (t.finalPrice != null) KeyValue(context.tr.quotedPrice, formatRupees(t.finalPrice!), bold: true),
                    if (t.imei.isNotEmpty) KeyValue('IMEI', t.imei),
                  ],
                ),
              ),
            ),
            if (t.isOpen) ...<Widget>[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: <Widget>[
                  if (next != null && !(t.status == RepairStatus.awaitingApproval))
                    FilledButton(onPressed: () => go(next), child: Text(context.tr.moveTo(context.tr.repairStatus(next)))),
                  if (t.status == RepairStatus.awaitingApproval) Text(context.tr.waitingForCustomer, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (t.status == RepairStatus.awaitingApproval)
                    OutlinedButton(onPressed: () => runBusy(context, () => services.repairs.approveQuote(t)), child: Text(context.tr.customerApproved)),
                  OutlinedButton(onPressed: () => go(RepairStatus.cancelled), child: Text(context.tr.cancel)),
                ],
              ),
            ],
            Section(
              title: context.tr.progress,
              child: Column(
                children: <Widget>[
                  for (final RepairEvent e in t.events.reversed)
                    ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.check_circle_outline), title: Text(context.tr.repairStatus(e.status)), subtitle: Text(Dates.dateTime(e.at, lang))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


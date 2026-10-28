import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../domain/lead.dart';
import '../../domain/store_settings.dart';
import '../../l10n/l10n.dart';
import '../../services/app_services.dart';
import '../../state/data_cubits.dart';
import '../../state/session_cubit.dart';
import '../../util/launch.dart';
import '../../widgets/common.dart';

enum _LeadFilter { open, fresh, due, converted, lost, all }

IconData leadIcon(LeadType t) {
  switch (t) {
    case LeadType.enquiry:
      return Icons.chat_bubble_outline;
    case LeadType.callback:
      return Icons.phone_callback_outlined;
    case LeadType.emiApplication:
      return Icons.account_balance_wallet_outlined;
    case LeadType.exchange:
      return Icons.swap_horiz;
    case LeadType.repair:
      return Icons.build_outlined;
    case LeadType.reserve:
      return Icons.bookmark_added_outlined;
    case LeadType.visit:
      return Icons.event_available_outlined;
  }
}

Color leadStatusColor(LeadStatus s) {
  switch (s) {
    case LeadStatus.fresh:
      return BrandColors.saffron;
    case LeadStatus.contacted:
      return BrandColors.indigo;
    case LeadStatus.visited:
      return const Color(0xFF00897B);
    case LeadStatus.converted:
      return BrandColors.green;
    case LeadStatus.lost:
      return BrandColors.red;
  }
}

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  _LeadFilter _f = _LeadFilter.open;

  @override
  Widget build(BuildContext context) {
    final List<Lead> all = context.watch<LeadsCubit>().state;
    final DateTime now = DateTime.now();
    bool match(Lead l) {
      switch (_f) {
        case _LeadFilter.open:
          return l.isOpen;
        case _LeadFilter.fresh:
          return l.status == LeadStatus.fresh;
        case _LeadFilter.due:
          return l.isOpen && l.followUpAt != null && !l.followUpAt!.isAfter(now);
        case _LeadFilter.converted:
          return l.status == LeadStatus.converted;
        case _LeadFilter.lost:
          return l.status == LeadStatus.lost;
        case _LeadFilter.all:
          return true;
      }
    }

    final List<Lead> list = all.where(match).toList()..sort((Lead a, Lead b) => b.updatedAt.compareTo(a.updatedAt));
    String label(_LeadFilter f) {
      switch (f) {
        case _LeadFilter.open:
          return context.tr.fltOpen;
        case _LeadFilter.fresh:
          return context.tr.leadFresh;
        case _LeadFilter.due:
          return context.tr.fltFollowUpDue;
        case _LeadFilter.converted:
          return context.tr.leadConverted;
        case _LeadFilter.lost:
          return context.tr.leadLost;
        case _LeadFilter.all:
          return context.tr.groupAll;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.tr.navLeads), actions: const <Widget>[LanguageButton(), SizedBox(width: 12)]),
      body: MaxWidth(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: <Widget>[
                  for (final _LeadFilter f in _LeadFilter.values)
                    Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(label(f)), selected: _f == f, onSelected: (_) => setState(() => _f = f))),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? EmptyState(icon: Icons.people_outline, title: context.tr.noLeads, message: context.tr.noLeadsHint)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: list.length,
                      separatorBuilder: (BuildContext c, int i) => const SizedBox(height: 10),
                      itemBuilder: (BuildContext c, int i) => _LeadCard(lead: list[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final AppServices services = context.read<AppServices>();
    final SessionState session = context.watch<SessionCubit>().state;
    final StoreSettings store = context.watch<StoreCubit>().state;
    final String lang = context.lang;
    final bool due = lead.isOpen && lead.followUpAt != null && !lead.followUpAt!.isAfter(DateTime.now());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(leadIcon(lead.type), size: 20, color: BrandColors.indigo),
                const SizedBox(width: 8),
                Expanded(child: Text(context.tr.leadType(lead.type), style: const TextStyle(fontWeight: FontWeight.w800))),
                StatusPill(context.tr.leadStatus(lead.status), color: leadStatusColor(lead.status)),
              ],
            ),
            const SizedBox(height: 8),
            Text('${lead.name} · +91 ${lead.phone}', style: const TextStyle(fontWeight: FontWeight.w900)),
            if (lead.productName.isNotEmpty) Text(lead.productName),
            if (lead.message.isNotEmpty) Text(lead.message, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(Dates.dateTime(lead.createdAt, lang), style: Theme.of(context).textTheme.bodySmall),
            if (lead.followUpAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.alarm, size: 16, color: due ? BrandColors.red : BrandColors.saffron),
                    const SizedBox(width: 4),
                    Text(context.tr.followUpOn(Dates.dateTime(lead.followUpAt!, lang)), style: TextStyle(color: due ? BrandColors.red : null, fontWeight: FontWeight.w700, fontSize: 12.5)),
                  ],
                ),
              ),
            for (final LeadNote n in lead.notes.take(3))
              Padding(padding: const EdgeInsets.only(top: 4), child: Text('• ${n.text}', style: Theme.of(context).textTheme.bodySmall)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
                  onPressed: () async {
                    await Launch.call(lead.phone);
                    if (lead.status == LeadStatus.fresh && context.mounted) await services.leads.setStatus(session.user, lead, LeadStatus.contacted);
                  },
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: Text(context.tr.call),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
                  onPressed: () => Launch.whatsapp(lead.phone, text: context.tr.leadWhatsappText(lead.name, lead.productName.isEmpty ? context.tr.yourEnquiry : lead.productName, store.name.of(lang))),
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: Text(context.tr.whatsapp),
                ),
                PopupMenuButton<LeadStatus>(
                  tooltip: context.tr.changeStatus,
                  onSelected: (LeadStatus s) => services.leads.setStatus(session.user, lead, s),
                  itemBuilder: (BuildContext c) => <PopupMenuEntry<LeadStatus>>[
                    for (final LeadStatus s in LeadStatus.values) PopupMenuItem<LeadStatus>(value: s, child: Text(c.tr.leadStatus(s))),
                  ],
                  child: Chip(avatar: const Icon(Icons.swap_vert, size: 18), label: Text(context.tr.changeStatus)),
                ),
                ActionChip(
                  avatar: const Icon(Icons.note_add_outlined, size: 18),
                  label: Text(context.tr.addNote),
                  onPressed: () async {
                    final String? t = await promptDialog(context, title: context.tr.addNote, maxLines: 3);
                    if (t != null && t.isNotEmpty && context.mounted) await services.leads.addNote(session.user, lead, t);
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.alarm_add_outlined, size: 18),
                  label: Text(context.tr.followUp),
                  onPressed: () async {
                    final DateTime now = DateTime.now();
                    final DateTime? d = await showDatePicker(context: context, initialDate: now.add(const Duration(days: 1)), firstDate: now, lastDate: now.add(const Duration(days: 365)));
                    if (d == null || !context.mounted) return;
                    final TimeOfDay? t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 11, minute: 0));
                    if (t == null || !context.mounted) return;
                    await services.leads.setFollowUp(session.user, lead, DateTime(d.year, d.month, d.day, t.hour, t.minute));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
import '../../widgets/store_widgets.dart';
import '../auth/auth_gate.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StoreSettings store = context.watch<StoreCubit>().state;
    final String lang = context.lang;
    final int today = DateTime.now().weekday;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr.visitStore)),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: <Widget>[
            // The shop's poster sits here once the owner adds assets/branding/poster.jpg.
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 1.6,
                child: Image.asset(
                  'assets/branding/poster.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (BuildContext c, Object e, StackTrace? s) => Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: <Color>[BrandColors.indigoDeep, BrandColors.indigo]),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(Icons.storefront, color: Colors.white, size: 52),
                        const SizedBox(height: 10),
                        Text(store.name.of(lang), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(store.tagline.of(lang), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.place_outlined, color: BrandColors.indigo),
                        const SizedBox(width: 8),
                        Expanded(child: Text(store.name.of(lang), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AddressLines(store),
                    const SizedBox(height: 8),
                    StoreStatusBadge(store),
                    const SizedBox(height: 12),
                    ContactButtons(settings: store),
                  ],
                ),
              ),
            ),
            Section(
              title: context.tr.openingHours,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: <Widget>[
                      for (int d = 1; d <= 7; d++)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          decoration: BoxDecoration(
                            color: d == today ? BrandColors.indigo.withValues(alpha: 0.08) : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(child: Text(context.tr.weekday(d), style: TextStyle(fontWeight: d == today ? FontWeight.w900 : FontWeight.w500))),
                              Text(
                                store.hours.of(d).closed
                                    ? context.tr.closed
                                    : '${Dates.minutes(store.hours.of(d).openMinute, lang)} - ${Dates.minutes(store.hours.of(d).closeMinute, lang)}',
                                style: TextStyle(fontWeight: d == today ? FontWeight.w900 : FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Section(title: context.tr.planYourVisit, child: _VisitPlanner(store: store)),
            Section(
              title: context.tr.inTheShop,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _line(Icons.phone_android, context.tr.shopLine1),
                      _line(Icons.account_balance_wallet_outlined, context.tr.shopLine2),
                      _line(Icons.swap_horiz, context.tr.shopLine3),
                      _line(Icons.build_outlined, context.tr.shopLine4),
                      _line(Icons.sim_card_outlined, context.tr.shopLine5),
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

  Widget _line(IconData i, String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: <Widget>[Icon(i, size: 20, color: BrandColors.saffron), const SizedBox(width: 10), Expanded(child: Text(t))]),
      );
}

class _VisitPlanner extends StatefulWidget {
  const _VisitPlanner({required this.store});
  final StoreSettings store;

  @override
  State<_VisitPlanner> createState() => _VisitPlannerState();
}

class _VisitPlannerState extends State<_VisitPlanner> {
  int _dayOffset = 0;
  int? _slot;

  /// Morning, afternoon and evening, trimmed to the shop's hours that day.
  List<({int from, int to})> _slots(DateTime day) {
    final DayHours h = widget.store.hours.of(day.weekday);
    if (h.closed) return const <({int from, int to})>[];
    const List<(int, int)> bands = <(int, int)>[(0, 13 * 60), (13 * 60, 17 * 60), (17 * 60, 24 * 60)];
    final List<({int from, int to})> out = <({int from, int to})>[];
    for (final (int, int) b in bands) {
      final int from = h.openMinute > b.$1 ? h.openMinute : b.$1;
      final int to = h.closeMinute < b.$2 ? h.closeMinute : b.$2;
      if (to - from >= 60) out.add((from: from, to: to));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime day = DateTime(now.year, now.month, now.day + _dayOffset);
    final List<({int from, int to})> slots = _slots(day);
    final String lang = context.lang;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(context.tr.planYourVisitBody, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4)),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                separatorBuilder: (BuildContext c, int i) => const SizedBox(width: 8),
                itemBuilder: (BuildContext c, int i) {
                  final DateTime d = DateTime(now.year, now.month, now.day + i);
                  return ChoiceChip(
                    label: Text(i == 0 ? context.tr.today : (i == 1 ? context.tr.tomorrow : Dates.dateShort(d, lang))),
                    selected: i == _dayOffset,
                    onSelected: (_) => setState(() {
                      _dayOffset = i;
                      _slot = null;
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            if (slots.isEmpty)
              Text(context.tr.closedThatDay)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (int i = 0; i < slots.length; i++)
                    ChoiceChip(
                      label: Text('${Dates.minutes(slots[i].from, lang)} - ${Dates.minutes(slots[i].to, lang)}'),
                      selected: _slot == i,
                      onSelected: (_) => setState(() => _slot = i),
                    ),
                ],
              ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _slot == null || slots.isEmpty ? null : () => _book(context, day, slots[_slot!]),
              icon: const Icon(Icons.event_available_outlined),
              label: Text(context.tr.tellShopIAmComing),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _book(BuildContext context, DateTime day, ({int from, int to}) slot) async {
    final AppServices services = context.read<AppServices>();
    final SessionState session = context.read<SessionCubit>().state;
    final String lang = context.lang;
    final String ok = context.tr.visitNoted;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    String name = session.user?.displayName ?? '';
    String phone = session.user?.phone ?? '';
    if (session.user == null) {
      final ({String name, String phone})? c = await askContact(context, title: context.tr.planYourVisit);
      if (c == null) return;
      name = c.name;
      phone = c.phone;
    }
    await services.leads.capture(
      type: LeadType.visit,
      name: name,
      phone: phone,
      userId: session.user?.id,
      message: '${Dates.date(day, lang)} ${Dates.minutes(slot.from, lang)} - ${Dates.minutes(slot.to, lang)}',
    );
    messenger.showSnackBar(SnackBar(content: Text(ok)));
    if (widget.store.hasWhatsapp) {
      // Offer to confirm on WhatsApp too; ignore failures.
      await Launch.whatsapp(
        widget.store.whatsapp,
        text: '${widget.store.name.of(lang)}: ${Dates.date(day, lang)} ${Dates.minutes(slot.from, lang)}',
      );
    }
  }
}

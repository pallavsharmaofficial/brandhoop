import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../domain/app_user.dart';
import '../../domain/order.dart';
import '../../l10n/l10n.dart';
import '../../services/analytics.dart';
import '../../state/data_cubits.dart';
import '../../util/launch.dart';
import '../../widgets/common.dart';
import '../orders/order_widgets.dart';

enum _Seg { all, upgrade, top, repeat, newlyJoined }

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  _Seg _seg = _Seg.all;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final List<AppUser> users = context.watch<UsersCubit>().state.where((AppUser u) => u.role == AppRole.customer).toList();
    final List<Order> orders = context.watch<AllOrdersCubit>().state;
    final store = context.watch<StoreCubit>().state;
    final DateTime now = DateTime.now();
    final Map<String, int> spend = Analytics.lifetimeSpend(orders);
    final Map<String, int> counts = <String, int>{};
    for (final Order o in Analytics.sold(orders)) {
      counts[o.customerId] = (counts[o.customerId] ?? 0) + 1;
    }
    final Set<String> due = Analytics.upgradeDue(orders, users, now).map((r) => r.user.id).toSet();
    final String q = _q.trim().toLowerCase();
    List<AppUser> list = users.where((AppUser u) => q.isEmpty || u.name.toLowerCase().contains(q) || u.phone.contains(q)).toList();
    switch (_seg) {
      case _Seg.all:
        list.sort((AppUser a, AppUser b) => (spend[b.id] ?? 0).compareTo(spend[a.id] ?? 0));
      case _Seg.upgrade:
        list = list.where((AppUser u) => due.contains(u.id)).toList();
      case _Seg.top:
        list = list.where((AppUser u) => (spend[u.id] ?? 0) > 0).toList()..sort((AppUser a, AppUser b) => (spend[b.id] ?? 0).compareTo(spend[a.id] ?? 0));
      case _Seg.repeat:
        list = list.where((AppUser u) => (counts[u.id] ?? 0) >= 2).toList();
      case _Seg.newlyJoined:
        list = list.where((AppUser u) => now.difference(u.createdAt).inDays <= 30).toList();
    }
    String label(_Seg s) {
      switch (s) {
        case _Seg.all:
          return context.tr.groupAll;
        case _Seg.upgrade:
          return '${context.tr.segUpgrade} (${due.length})';
        case _Seg.top:
          return context.tr.segTop;
        case _Seg.repeat:
          return context.tr.segRepeat;
        case _Seg.newlyJoined:
          return context.tr.segNew;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.tr.customersTitle)),
      body: MaxWidth(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(onChanged: (String v) => setState(() => _q = v), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: context.tr.searchCustomersHint)),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: <Widget>[
                  for (final _Seg s in _Seg.values) Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(label(s)), selected: _seg == s, onSelected: (_) => setState(() => _seg = s))),
                ],
              ),
            ),
            if (_seg == _Seg.upgrade) Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: InfoBanner(text: context.tr.upgradeHint, icon: Icons.upgrade)),
            Expanded(
              child: list.isEmpty
                  ? EmptyState(icon: Icons.groups_outlined, title: context.tr.noResults)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: list.length,
                      separatorBuilder: (BuildContext c, int i) => const SizedBox(height: 8),
                      itemBuilder: (BuildContext c, int i) {
                        final AppUser u = list[i];
                        return Card(
                          child: ListTile(
                            onTap: () => context.push(Routes.adminCustomer(u.id)),
                            leading: CircleAvatar(backgroundColor: BrandColors.indigo.withValues(alpha: 0.12), child: Text(u.displayName.characters.first.toUpperCase(), style: const TextStyle(color: BrandColors.indigo, fontWeight: FontWeight.w800))),
                            title: Text(u.displayName, style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text('+91 ${u.phone} · ${context.tr.ordersCount(counts[u.id] ?? 0)}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(formatRupees(spend[u.id] ?? 0), style: const TextStyle(fontWeight: FontWeight.w900)),
                                if (due.contains(u.id)) StatusPill(context.tr.segUpgrade, color: BrandColors.saffron),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (_seg == _Seg.upgrade && list.isNotEmpty && store.name.en.isNotEmpty)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(context.tr.tapCustomerToMessage, style: Theme.of(context).textTheme.bodySmall),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final AppUser? u = context.watch<UsersCubit>().state.where((AppUser x) => x.id == userId).firstOrNull;
    final List<Order> orders = context.watch<AllOrdersCubit>().state.where((Order o) => o.customerId == userId).toList()..sort((Order a, Order b) => b.createdAt.compareTo(a.createdAt));
    final store = context.watch<StoreCubit>().state;
    if (u == null) return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.person_off_outlined, title: context.tr.noResults));
    final String lang = context.lang;
    final int spend = Analytics.lifetimeSpend(orders)[u.id] ?? 0;
    final lastPhone = Analytics.upgradeDue(orders, <AppUser>[u], DateTime.now(), months: 0);
    return Scaffold(
      appBar: AppBar(title: Text(u.displayName)),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('+91 ${u.phone}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('${context.tr.customerSince(Dates.date(u.createdAt, lang))}${u.invited ? ' · ${context.tr.addedAtCounter}' : ''}', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 10),
                    KeyValue(context.tr.lifetimeSpend, formatRupees(spend), bold: true),
                    KeyValue(context.tr.coinsLabel, '${u.coins}'),
                    if (lastPhone.isNotEmpty) KeyValue(context.tr.lastPhoneBought, Dates.date(lastPhone.first.lastPhone, lang)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        OutlinedButton.icon(onPressed: () => Launch.call(u.phone), icon: const Icon(Icons.call_outlined, size: 18), label: Text(context.tr.call)),
                        FilledButton.icon(
                          onPressed: () => Launch.whatsapp(u.phone, text: context.tr.customerOfferText(u.displayName, store.name.of(lang))),
                          icon: const Icon(Icons.campaign_outlined, size: 18),
                          label: Text(context.tr.sendOffer),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Launch.whatsapp(u.phone, text: context.tr.upgradeText(u.displayName, store.name.of(lang))),
                          icon: const Icon(Icons.upgrade, size: 18),
                          label: Text(context.tr.sendUpgrade),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Section(
              title: context.tr.navOrders,
              child: orders.isEmpty
                  ? Text(context.tr.noOrdersYet)
                  : Column(children: <Widget>[for (final Order o in orders) Padding(padding: const EdgeInsets.only(bottom: 8), child: OrderCard(order: o, onTap: () => context.push(Routes.adminOrder(o.id))))]),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/env.dart';
import '../../domain/order.dart';
import '../../l10n/l10n.dart';
import '../../state/data_cubits.dart';

/// The customer's five tabs. Each keeps its own scroll position and place.
class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final int open = AppEnv.live ? 0 : context.watch<MyOrdersCubit>().state.where((Order o) => o.status.isOpen).length;
    // Branch order: home, shop, EMI, orders, account. The storefront has no orders.
    final List<int> branches = AppEnv.live ? <int>[0, 1, 2, 4] : <int>[0, 1, 2, 3, 4];
    final List<NavigationDestination> all = <NavigationDestination>[
      NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: context.tr.navHome),
      NavigationDestination(icon: const Icon(Icons.storefront_outlined), selectedIcon: const Icon(Icons.storefront), label: context.tr.navShop),
      NavigationDestination(icon: const Icon(Icons.credit_score_outlined), selectedIcon: const Icon(Icons.credit_score), label: context.tr.navEmi),
      NavigationDestination(
        icon: Badge(isLabelVisible: open > 0, label: Text('$open'), child: const Icon(Icons.receipt_long_outlined)),
        selectedIcon: Badge(isLabelVisible: open > 0, label: Text('$open'), child: const Icon(Icons.receipt_long)),
        label: context.tr.navOrders,
      ),
      NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: context.tr.navAccount),
    ];
    final int selected = branches.indexOf(shell.currentIndex).clamp(0, branches.length - 1);
    void go(int i) => shell.goBranch(branches[i], initialLocation: branches[i] == shell.currentIndex);
    final List<NavigationDestination> dests = <NavigationDestination>[for (final int b in branches) all[b]];

    // Laptop and tablet screens get a side rail, phones the bottom bar.
    if (MediaQuery.sizeOf(context).width >= 900) {
      final bool extended = MediaQuery.sizeOf(context).width >= 1180;
      return Scaffold(
        body: Row(
          children: <Widget>[
            NavigationRail(
              extended: extended,
              minExtendedWidth: 190,
              selectedIndex: selected,
              onDestinationSelected: go,
              labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(context.tr.appName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              ),
              destinations: <NavigationRailDestination>[
                for (final NavigationDestination d in dests)
                  NavigationRailDestination(icon: d.icon, selectedIcon: d.selectedIcon, label: Text(d.label)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(selectedIndex: selected, onDestinationSelected: go, destinations: dests),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/order.dart';
import '../../l10n/l10n.dart';
import '../../state/data_cubits.dart';

/// The customer's five tabs. Each keeps its own scroll position and place.
class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final int open = context.watch<MyOrdersCubit>().state.where((Order o) => o.status.isOpen).length;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: <NavigationDestination>[
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: context.tr.navHome),
          NavigationDestination(icon: const Icon(Icons.storefront_outlined), selectedIcon: const Icon(Icons.storefront), label: context.tr.navShop),
          NavigationDestination(icon: const Icon(Icons.credit_score_outlined), selectedIcon: const Icon(Icons.credit_score), label: context.tr.navEmi),
          NavigationDestination(
            icon: Badge(isLabelVisible: open > 0, label: Text('$open'), child: const Icon(Icons.receipt_long_outlined)),
            selectedIcon: Badge(isLabelVisible: open > 0, label: Text('$open'), child: const Icon(Icons.receipt_long)),
            label: context.tr.navOrders,
          ),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: context.tr.navAccount),
        ],
      ),
    );
  }
}

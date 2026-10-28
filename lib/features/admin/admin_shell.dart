import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../domain/lead.dart';
import '../../domain/order.dart';
import '../../l10n/l10n.dart';
import '../../state/data_cubits.dart';

/// The back-office frame: five tabs, kept alive while you move between them.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final int newOrders = context.watch<AllOrdersCubit>().state.where((Order o) => o.status == OrderStatus.placed).length;
    final int newLeads = context.watch<LeadsCubit>().state.where((Lead l) => l.status == LeadStatus.fresh).length;
    Widget badge(int n, Widget icon) => Badge(isLabelVisible: n > 0, label: Text('$n'), child: icon);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: <NavigationDestination>[
          NavigationDestination(icon: const Icon(Icons.dashboard_outlined), selectedIcon: const Icon(Icons.dashboard), label: context.tr.navDashboard),
          NavigationDestination(icon: badge(newOrders, const Icon(Icons.receipt_long_outlined)), selectedIcon: badge(newOrders, const Icon(Icons.receipt_long)), label: context.tr.navOrders),
          NavigationDestination(icon: const Icon(Icons.inventory_2_outlined), selectedIcon: const Icon(Icons.inventory_2), label: context.tr.navStock),
          NavigationDestination(icon: badge(newLeads, const Icon(Icons.people_alt_outlined)), selectedIcon: badge(newLeads, const Icon(Icons.people_alt)), label: context.tr.navLeads),
          NavigationDestination(icon: const Icon(Icons.apps_outlined), selectedIcon: const Icon(Icons.apps), label: context.tr.navMore),
        ],
      ),
    );
  }
}

/// Where the admin's "view as customer" button goes.
void exitAdmin(BuildContext context) => context.go(Routes.home);

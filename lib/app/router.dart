import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../core/permissions.dart';
import 'env.dart';
import '../features/account/account_screen.dart';
import '../features/account/profile_screens.dart';
import '../features/admin/admin_orders_screen.dart';
import '../features/admin/admin_shell.dart';
import '../features/admin/customers_screen.dart';
import '../features/admin/emi_desk_screen.dart';
import '../features/admin/leads_screen.dart';
import '../features/admin/more_screen.dart';
import '../features/admin/offers_screen.dart';
import '../features/admin/pos_screen.dart';
import '../features/admin/product_edit_screen.dart';
import '../features/admin/repairs_desk_screen.dart';
import '../features/admin/reports_screen.dart';
import '../features/admin/dashboard_screen.dart';
import '../features/admin/staff_screen.dart';
import '../features/admin/stock_screen.dart';
import '../features/admin/store_settings_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/catalog/catalog_query.dart';
import '../features/catalog/catalog_screen.dart';
import '../features/catalog/product_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/emi/emi_screen.dart';
import '../features/emi/live_emi.dart';
import '../features/emi/plan_screen.dart';
import '../features/home/home_screen.dart';
import '../features/orders/order_screens.dart';
import '../features/services/exchange_screen.dart';
import '../features/services/repair_screens.dart';
import '../features/shell/customer_shell.dart';
import '../features/shell/language_screen.dart';
import '../features/store/store_screen.dart';
import '../state/session_cubit.dart';
import '../state/settings_cubit.dart';
import 'routes.dart';

/// Tells the router to re-run its redirects when sign-in or language state changes.
class _Refresh extends ChangeNotifier {
  _Refresh(SessionCubit session, SettingsCubit settings) {
    _subs = <StreamSubscription<Object?>>[
      session.stream.listen((_) => notifyListeners()),
      settings.stream.listen((_) => notifyListeners()),
    ];
  }

  late final List<StreamSubscription<Object?>> _subs;

  @override
  void dispose() {
    for (final StreamSubscription<Object?> s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}

/// Paths that need a signed-in customer.
const List<String> _needsLogin = <String>[
  Routes.checkout,
  Routes.profile,
  Routes.addresses,
  Routes.wishlist,
];

/// Back-office paths and the permission each one needs. A role that lacks it is
/// sent back to the dashboard, which is every staff member's home.
const Map<String, Permission> _adminGate = <String, Permission>{
  Routes.adminPos: Permission.createWalkInSale,
  Routes.adminEmi: Permission.manageEmi,
  '/admin/plan': Permission.manageEmi,
  Routes.adminRepairs: Permission.manageRepairs,
  '/admin/repair': Permission.manageRepairs,
  Routes.adminOffers: Permission.manageOffers,
  '/admin/offer': Permission.manageOffers,
  Routes.adminCustomers: Permission.viewCustomers,
  '/admin/customer': Permission.viewCustomers,
  Routes.adminStaff: Permission.manageStaff,
  Routes.adminReports: Permission.viewReports,
  Routes.adminSettings: Permission.manageSettings,
  '/admin/product': Permission.adjustStock,
};

/// Paths that exist only where there are accounts and orders on a server of
/// their own. The live storefront has neither, so they lead back to the shop.
const List<String> _notInStorefront = <String>[
  Routes.login,
  Routes.orders,
  '/order/',
  '/plan/',
  Routes.profile,
  Routes.addresses,
  Routes.wishlist,
  '/admin',
];

String? redirectFor({
  required String location,
  required SessionState session,
  required AppPrefs prefs,
  bool storefront = false,
}) {
  if (!prefs.onboarded) return location == Routes.language ? null : Routes.language;
  if (storefront) {
    if (location == Routes.language) return Routes.home;
    // Checkout is a cart that is sent on WhatsApp.
    if (location == Routes.checkout) return Routes.cart;
    if (_notInStorefront.any(location.startsWith)) return Routes.home;
    return null;
  }
  if (location == Routes.language || location == '/') return session.inAdmin ? Routes.adminDashboard : Routes.home;

  final bool adminPath = location.startsWith('/admin');
  if (session.inAdmin) {
    if (!adminPath && location != Routes.login) return Routes.adminDashboard;
    for (final MapEntry<String, Permission> g in _adminGate.entries) {
      if ((location == g.key || location.startsWith('${g.key}/')) && !session.can(g.value)) {
        return Routes.adminDashboard;
      }
    }
    // Editing a product needs the catalogue permission, stock-only staff may only view.
    if (location.startsWith('/admin/product') && !session.can(Permission.manageCatalog)) {
      return Routes.adminStock;
    }
    return null;
  }
  if (adminPath) return Routes.home;
  if (!session.signedIn && _needsLogin.any(location.startsWith)) {
    return '${Routes.login}?next=${Uri.encodeComponent(location)}';
  }
  return null;
}

GoRouter buildRouter({required SessionCubit session, required SettingsCubit settings}) {
  final _Refresh refresh = _Refresh(session, settings);
  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: refresh,
    redirect: (_, GoRouterState state) => redirectFor(
      location: state.uri.path,
      session: session.state,
      prefs: settings.state,
      storefront: AppEnv.live,
    ),
    routes: <RouteBase>[
      GoRoute(path: '/', redirect: (_, _) => Routes.home),
      GoRoute(path: Routes.language, builder: (_, _) => const LanguageScreen()),
      GoRoute(
        path: Routes.login,
        builder: (_, GoRouterState s) => LoginScreen(next: s.uri.queryParameters['next']),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, StatefulNavigationShell shell) => CustomerShell(shell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(routes: <RouteBase>[GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(
              path: Routes.shop,
              builder: (_, GoRouterState s) => CatalogScreen(
                key: ValueKey<String>(s.uri.toString()),
                initial: CatalogQuery.fromParams(s.uri.queryParameters),
              ),
            ),
          ]),
          StatefulShellBranch(routes: <RouteBase>[GoRoute(path: Routes.emi, builder: (_, _) => AppEnv.live ? const LiveEmiScreen() : const EmiScreen())]),
          StatefulShellBranch(routes: <RouteBase>[GoRoute(path: Routes.orders, builder: (_, _) => const OrdersScreen())]),
          StatefulShellBranch(routes: <RouteBase>[GoRoute(path: Routes.account, builder: (_, _) => const AccountScreen())]),
        ],
      ),
      GoRoute(path: '/product/:id', builder: (_, GoRouterState s) => ProductScreen(productId: s.pathParameters['id']!)),
      GoRoute(path: Routes.cart, builder: (_, _) => const CartScreen()),
      GoRoute(
        path: Routes.checkout,
        builder: (_, GoRouterState s) => CheckoutScreen(reserve: s.uri.queryParameters['mode'] == 'reserve'),
      ),
      GoRoute(path: '/order/:id', builder: (_, GoRouterState s) => OrderDetailScreen(orderId: s.pathParameters['id']!)),
      GoRoute(
        path: '/order/:id/done',
        builder: (_, GoRouterState s) => OrderDoneScreen(orderId: s.pathParameters['id']!, failure: s.uri.queryParameters['fail']),
      ),
      GoRoute(path: '/plan/:id', builder: (_, GoRouterState s) => PlanScreen(planId: s.pathParameters['id']!)),
      GoRoute(
        path: Routes.calculator,
        builder: (_, GoRouterState s) => LiveEmiScreen(price: int.tryParse(s.uri.queryParameters['price'] ?? '')),
      ),
      GoRoute(path: Routes.store, builder: (_, _) => const StoreScreen()),
      GoRoute(path: Routes.exchange, builder: (_, _) => const ExchangeScreen()),
      GoRoute(path: Routes.repair, builder: (_, _) => const RepairScreen()),
      GoRoute(path: '/repair/:id', builder: (_, GoRouterState s) => RepairTicketScreen(ticketId: s.pathParameters['id']!)),
      GoRoute(path: Routes.wishlist, builder: (_, _) => const WishlistScreen()),
      GoRoute(path: Routes.addresses, builder: (_, _) => const AddressesScreen()),
      GoRoute(path: '/addresses/:id', builder: (_, GoRouterState s) => AddressEditScreen(addressId: s.pathParameters['id']!)),
      GoRoute(path: Routes.help, builder: (_, _) => const HelpScreen()),
      GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen()),

      // ---- Back office -----------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (_, _, StatefulNavigationShell shell) => AdminShell(shell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(routes: <RouteBase>[GoRoute(path: Routes.adminDashboard, builder: (_, _) => const DashboardScreen())]),
          StatefulShellBranch(routes: <RouteBase>[GoRoute(path: Routes.adminOrders, builder: (_, _) => const AdminOrdersScreen())]),
          StatefulShellBranch(routes: <RouteBase>[GoRoute(path: Routes.adminStock, builder: (_, _) => const StockScreen())]),
          StatefulShellBranch(routes: <RouteBase>[GoRoute(path: Routes.adminLeads, builder: (_, _) => const LeadsScreen())]),
          StatefulShellBranch(routes: <RouteBase>[GoRoute(path: Routes.adminMore, builder: (_, _) => const MoreScreen())]),
        ],
      ),
      GoRoute(path: Routes.adminPos, builder: (_, _) => const PosScreen()),
      GoRoute(path: Routes.adminEmi, builder: (_, _) => const EmiDeskScreen()),
      GoRoute(path: Routes.adminRepairs, builder: (_, _) => const RepairsDeskScreen()),
      GoRoute(path: Routes.adminOffers, builder: (_, _) => const OffersScreen()),
      GoRoute(path: Routes.adminCustomers, builder: (_, _) => const CustomersScreen()),
      GoRoute(path: Routes.adminStaff, builder: (_, _) => const StaffScreen()),
      GoRoute(path: Routes.adminReports, builder: (_, _) => const ReportsScreen()),
      GoRoute(path: Routes.adminSettings, builder: (_, _) => const StoreSettingsScreen()),
      GoRoute(path: '/admin/order/:id', builder: (_, GoRouterState s) => AdminOrderDetailScreen(orderId: s.pathParameters['id']!)),
      GoRoute(path: '/admin/product/:id', builder: (_, GoRouterState s) => ProductEditScreen(productId: s.pathParameters['id']!)),
      GoRoute(path: '/admin/plan/:id', builder: (_, GoRouterState s) => AdminPlanScreen(planId: s.pathParameters['id']!)),
      GoRoute(path: '/admin/customer/:id', builder: (_, GoRouterState s) => CustomerDetailScreen(userId: s.pathParameters['id']!)),
      GoRoute(path: '/admin/repair/:id', builder: (_, GoRouterState s) => AdminRepairScreen(ticketId: s.pathParameters['id']!)),
      GoRoute(path: '/admin/offer/:id', builder: (_, GoRouterState s) => OfferEditScreen(offerId: s.pathParameters['id']!)),
    ],
  );
}

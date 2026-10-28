import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/permissions.dart';
import '../l10n/l10n.dart';
import '../services/app_services.dart';
import '../state/cart_cubit.dart';
import '../state/data_cubits.dart';
import '../state/session_cubit.dart';
import '../state/settings_cubit.dart';
import 'router.dart';
import 'theme.dart';

/// The whole app: one tree for customers and for the shop's own people. What a
/// signed-in person sees is decided by their role (see core/permissions.dart)
/// and, for staff, by which side they have chosen to look at.
class BrandhoopApp extends StatefulWidget {
  const BrandhoopApp({
    super.key,
    required this.services,
    required this.prefs,
    this.deviceLanguage = 'hi',
  });

  final AppServices services;
  final SharedPreferences prefs;
  final String deviceLanguage;

  @override
  State<BrandhoopApp> createState() => _BrandhoopAppState();
}

class _BrandhoopAppState extends State<BrandhoopApp> {
  late final SettingsCubit _settings = SettingsCubit(widget.prefs, deviceLanguage: widget.deviceLanguage);
  late final SessionCubit _session = SessionCubit(widget.services.auth, widget.services.repos.users, widget.prefs);
  late final CartCubit _cart = CartCubit(widget.prefs);
  late final ProductsCubit _products = ProductsCubit(widget.services.repos.catalog);
  late final OffersCubit _offers = OffersCubit(widget.services.repos.offers);
  late final StoreCubit _store = StoreCubit(widget.services.repos.settings);
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRouter(session: _session, settings: _settings);
    _session.restore();
  }

  @override
  void dispose() {
    _router.dispose();
    _settings.close();
    _session.close();
    _cart.close();
    _products.close();
    _offers.close();
    _store.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepositoryProvider<AppServices>.value(
        value: widget.services,
        child: MultiBlocProvider(
          providers: <BlocProvider<dynamic>>[
            BlocProvider<SettingsCubit>.value(value: _settings),
            BlocProvider<SessionCubit>.value(value: _session),
            BlocProvider<CartCubit>.value(value: _cart),
            BlocProvider<ProductsCubit>.value(value: _products),
            BlocProvider<OffersCubit>.value(value: _offers),
            BlocProvider<StoreCubit>.value(value: _store),
          ],
          child: _Scoped(
            child: BlocBuilder<SettingsCubit, AppPrefs>(
              builder: (BuildContext context, AppPrefs prefs) => MaterialApp.router(
                debugShowCheckedModeBanner: false,
                onGenerateTitle: (BuildContext c) => c.tr.appName,
                routerConfig: _router,
                locale: prefs.locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: buildTheme(Brightness.light),
                darkTheme: buildTheme(Brightness.dark),
                themeMode: prefs.themeMode,
              ),
            ),
          ),
        ),
      );
}

/// Per-person data. Rebuilt whenever someone signs in, out or changes role, so
/// nobody ever sees another person's orders, and a customer's tree never even
/// opens the back-office collections.
class _Scoped extends StatelessWidget {
  const _Scoped({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppServices s = context.read<AppServices>();
    return BlocBuilder<SessionCubit, SessionState>(
      buildWhen: (SessionState a, SessionState b) => a.user?.id != b.user?.id || a.user?.role != b.user?.role,
      builder: (BuildContext context, SessionState session) {
        final String uid = session.user?.id ?? '__guest__';
        final bool staff = session.isStaff;
        final bool money = session.can(Permission.viewFinancials);
        final bool costs = session.can(Permission.viewCosts);
        return MultiBlocProvider(
          key: ValueKey<String>('$uid-${session.role.name}'),
          providers: <BlocProvider<dynamic>>[
            BlocProvider<MyOrdersCubit>(create: (_) => MyOrdersCubit(s.repos.orders, uid)),
            BlocProvider<MyPlansCubit>(create: (_) => MyPlansCubit(s.repos.plans, uid)),
            BlocProvider<MyRepairsCubit>(create: (_) => MyRepairsCubit(s.repos.repairs, uid)),
            BlocProvider<AllOrdersCubit>(create: (_) => AllOrdersCubit(s.repos.orders, enabled: staff)),
            BlocProvider<AllPlansCubit>(create: (_) => AllPlansCubit(s.repos.plans, enabled: staff)),
            BlocProvider<LeadsCubit>(create: (_) => LeadsCubit(s.repos.leads, enabled: staff)),
            BlocProvider<AllRepairsCubit>(create: (_) => AllRepairsCubit(s.repos.repairs, enabled: staff)),
            BlocProvider<UsersCubit>(create: (_) => UsersCubit(s.repos.users, enabled: staff)),
            BlocProvider<FinanceEntriesCubit>(create: (_) => FinanceEntriesCubit(s.repos.finance, enabled: money)),
            BlocProvider<CostsCubit>(create: (_) => CostsCubit(s.repos.finance, enabled: costs)),
          ],
          child: child,
        );
      },
    );
  }
}

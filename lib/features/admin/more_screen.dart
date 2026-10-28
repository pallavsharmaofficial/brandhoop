import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/env.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/permissions.dart';
import '../../data/demo_seed.dart';
import '../../domain/app_user.dart';
import '../../l10n/l10n.dart';
import '../../services/app_services.dart';
import '../../state/session_cubit.dart';
import '../../widgets/common.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionState session = context.watch<SessionCubit>().state;
    final AppUser? u = session.user;
    Widget tile(IconData i, String t, String route, {bool show = true, String? sub}) => show
        ? Column(
            children: <Widget>[
              ListTile(
                leading: Icon(i, color: BrandColors.indigo),
                title: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: sub == null ? null : Text(sub),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(route),
              ),
              const Divider(height: 1),
            ],
          )
        : const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr.navMore), actions: const <Widget>[LanguageButton(), SizedBox(width: 12)]),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: <Widget>[
            if (u != null)
              Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: BrandColors.indigo, child: Text(u.displayName.characters.first.toUpperCase(), style: const TextStyle(color: Colors.white))),
                  title: Text(u.displayName, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${context.tr.role(u.role)} · +91 ${u.phone}'),
                ),
              ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: <Widget>[
                  tile(Icons.point_of_sale, context.tr.newSale, Routes.adminPos, show: session.can(Permission.createWalkInSale), sub: context.tr.newSaleHint),
                  tile(Icons.account_balance_wallet_outlined, context.tr.emiDesk, Routes.adminEmi, show: session.can(Permission.manageEmi), sub: context.tr.emiDeskHint),
                  tile(Icons.build_outlined, context.tr.repairsDesk, Routes.adminRepairs, show: session.can(Permission.manageRepairs)),
                  tile(Icons.local_offer_outlined, context.tr.offersAndCoupons, Routes.adminOffers, show: session.can(Permission.manageOffers)),
                  tile(Icons.groups_outlined, context.tr.customersTitle, Routes.adminCustomers, show: session.can(Permission.viewCustomers), sub: context.tr.customersHint),
                  tile(Icons.insights_outlined, context.tr.reportsTitle, Routes.adminReports, show: session.can(Permission.viewReports)),
                  tile(Icons.badge_outlined, context.tr.staffTitle, Routes.adminStaff, show: session.can(Permission.manageStaff), sub: context.tr.staffHint),
                  tile(Icons.settings_outlined, context.tr.shopSettings, Routes.adminSettings, show: session.can(Permission.manageSettings)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () async {
                await context.read<SessionCubit>().setMode(AppMode.customer);
                if (context.mounted) context.go(Routes.home);
              },
              icon: const Icon(Icons.storefront_outlined),
              label: Text(context.tr.viewAsCustomer),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final bool ok = await confirmDialog(context, title: context.tr.signOutQ);
                if (ok && context.mounted) {
                  await context.read<SessionCubit>().signOut();
                  if (context.mounted) context.go(Routes.home);
                }
              },
              icon: const Icon(Icons.logout),
              label: Text(context.tr.signOut),
            ),
            if (AppEnv.demo && session.can(Permission.manageSettings)) ...<Widget>[
              const SizedBox(height: 24),
              InfoBanner(text: context.tr.resetDemoHint, icon: Icons.science_outlined, color: BrandColors.saffron),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: BrandColors.red),
                onPressed: () async {
                  final bool ok = await confirmDialog(context, title: context.tr.resetDemoQ, message: context.tr.resetDemoBody, destructive: true);
                  if (!ok || !context.mounted) return;
                  final AppServices s = context.read<AppServices>();
                  await runBusy<bool>(context, () async {
                    await DemoSeed.reset(s.repos, DateTime.now());
                    return true;
                  });
                  if (context.mounted) {
                    await context.read<SessionCubit>().signOut();
                    if (context.mounted) context.go(Routes.home);
                  }
                },
                icon: const Icon(Icons.restart_alt),
                label: Text(context.tr.resetDemo),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

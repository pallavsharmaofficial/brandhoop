import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/env.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../domain/app_user.dart';
import '../../domain/store_settings.dart';
import '../../l10n/l10n.dart';
import '../../state/data_cubits.dart';
import '../../state/session_cubit.dart';
import '../../state/settings_cubit.dart';
import '../../util/launch.dart';
import '../../widgets/common.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionState session = context.watch<SessionCubit>().state;
    final AppPrefs prefs = context.watch<SettingsCubit>().state;
    final StoreSettings store = context.watch<StoreCubit>().state;
    final AppUser? u = session.user;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr.navAccount), actions: const <Widget>[LanguageButton(), SizedBox(width: 12)]),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: <Widget>[
            if (u == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: <Widget>[
                      const CircleAvatar(radius: 32, child: Icon(Icons.person_outline, size: 34)),
                      const SizedBox(height: 12),
                      Text(context.tr.welcomeGuest, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(context.tr.signInBody, textAlign: TextAlign.center),
                      const SizedBox(height: 14),
                      FilledButton(onPressed: () => context.push(Routes.login), child: Text(context.tr.signIn)),
                    ],
                  ),
                ),
              )
            else ...<Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: BrandColors.indigo,
                        child: Text(
                          (u.name.isEmpty ? u.phone.substring(8) : u.name.trim().characters.first).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(u.displayName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                            Text('+91 ${u.phone}', style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: <Widget>[
                                if (u.isStaff) StatusPill(context.tr.role(u.role), color: BrandColors.indigo, icon: Icons.badge_outlined),
                                StatusPill(context.tr.coinsBalance(u.coins), color: BrandColors.saffron, icon: Icons.stars_outlined),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (u.isStaff)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Card(
                    color: BrandColors.indigo,
                    child: ListTile(
                      leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white),
                      title: Text(context.tr.openAdmin, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      subtitle: Text(context.tr.openAdminHint, style: const TextStyle(color: Colors.white70)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white),
                      onTap: () async {
                        await context.read<SessionCubit>().setMode(AppMode.admin);
                        if (context.mounted) context.go(Routes.adminDashboard);
                      },
                    ),
                  ),
                ),
              Section(
                title: context.tr.myAccount,
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  child: Column(
                    children: <Widget>[
                      _tile(context, Icons.person_outline, context.tr.myProfile, () => context.push(Routes.profile)),
                      const Divider(height: 1),
                      _tile(context, Icons.location_on_outlined, context.tr.myAddresses, () => context.push(Routes.addresses)),
                      const Divider(height: 1),
                      _tile(context, Icons.favorite_border, context.tr.wishlist, () => context.push(Routes.wishlist)),
                      const Divider(height: 1),
                      _tile(context, Icons.build_outlined, context.tr.myRepairs, () => context.push(Routes.repair)),
                      const Divider(height: 1),
                      _tile(context, Icons.card_giftcard_outlined, context.tr.referAndEarn, () => _refer(context, u, store)),
                    ],
                  ),
                ),
              ),
            ],
            Section(
              title: context.tr.settingsHeader,
              padding: const EdgeInsets.only(top: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(context.tr.languageLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: <ButtonSegment<String>>[
                          ButtonSegment<String>(value: 'hi', label: Text(context.tr.languageHindi)),
                          ButtonSegment<String>(value: 'en', label: Text(context.tr.languageEnglish)),
                        ],
                        selected: <String>{prefs.languageCode},
                        onSelectionChanged: (Set<String> s) => context.read<SettingsCubit>().setLanguage(s.first),
                      ),
                      const SizedBox(height: 16),
                      Text(context.tr.themeLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: <ButtonSegment<ThemeMode>>[
                          ButtonSegment<ThemeMode>(value: ThemeMode.system, label: Text(context.tr.themeSystem)),
                          ButtonSegment<ThemeMode>(value: ThemeMode.light, label: Text(context.tr.themeLight)),
                          ButtonSegment<ThemeMode>(value: ThemeMode.dark, label: Text(context.tr.themeDark)),
                        ],
                        selected: <ThemeMode>{prefs.themeMode},
                        onSelectionChanged: (Set<ThemeMode> s) => context.read<SettingsCubit>().setThemeMode(s.first),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Section(
              title: context.tr.helpHeader,
              padding: const EdgeInsets.only(top: 16),
              child: Card(
                child: Column(
                  children: <Widget>[
                    _tile(context, Icons.storefront_outlined, context.tr.visitStore, () => context.push(Routes.store)),
                    const Divider(height: 1),
                    _tile(context, Icons.help_outline, context.tr.helpAndFaq, () => context.push(Routes.help)),
                    if (u != null) ...<Widget>[
                      const Divider(height: 1),
                      _tile(context, Icons.logout, context.tr.signOut, () async {
                        final bool ok = await confirmDialog(context, title: context.tr.signOutQ);
                        if (ok && context.mounted) {
                          await context.read<SessionCubit>().signOut();
                          if (context.mounted) context.go(Routes.home);
                        }
                      }),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${context.tr.appName} 0.1.0${AppEnv.demo ? ' · ${context.tr.demoMode}' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData i, String t, VoidCallback onTap) => ListTile(
        leading: Icon(i),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );

  void _refer(BuildContext context, AppUser u, StoreSettings store) {
    Launch.shareText(context.tr.referShareText(u.referralCode, formatRupees(store.referralBonusCoins), store.name.of(context.lang)));
  }
}

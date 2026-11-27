import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/env.dart';
import '../../app/palette.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../state/data_cubits.dart';
import '../../util/launch.dart';
import '../../util/shop_message.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import 'emi_calculator_screen.dart';

/// The EMI screen of the live storefront. Until the shop has confirmed its real
/// Bajaj Finserv schemes and rates, a calculator would show made-up figures, so
/// customers get a plain note and the shop's contact buttons instead.
class LiveEmiScreen extends StatelessWidget {
  const LiveEmiScreen({super.key, this.price});

  final int? price;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreCubit>().state;
    if (!AppEnv.live || store.emiRatesConfirmed) return EmiCalculatorScreen(initialPrice: price);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr.navEmi), actions: const <Widget>[LanguageButton(), SizedBox(width: 12)]),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            PageHero(
              icon: Icons.credit_score_outlined,
              title: context.tr.emiHeroTitle,
              subtitle: context.tr.emiHeroSub,
              children: <Widget>[
                Wrap(spacing: 10, runSpacing: 10, children: <Widget>[
                  _heroButton(context, Icons.chat_outlined, context.tr.whatsapp, () => sendToShop(context, context.tr.liveGenericAsk(store.name.of(context.lang)))),
                  if (store.phone.trim().isNotEmpty) _heroButton(context, Icons.call_outlined, context.tr.call, () => Launch.call(store.phone)),
                ]),
              ],
            ),
            Section(
              title: context.tr.emiHowTitle,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Column(children: <Widget>[
                    StepTile(n: 1, title: context.tr.emiStep1, text: context.tr.emiStep1Sub),
                    StepTile(n: 2, title: context.tr.emiStep2, text: context.tr.emiStep2Sub),
                    StepTile(n: 3, title: context.tr.emiStep3, text: context.tr.emiStep3Sub),
                    StepTile(n: 4, title: context.tr.emiStep4, text: context.tr.emiStep4Sub),
                  ]),
                ),
              ),
            ),
            Section(
              title: context.tr.emiLendersTitle,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Row(children: <Widget>[
                      Icon(Icons.account_balance_outlined, color: dark ? Palette.saffron300 : Palette.saffron700),
                      const SizedBox(width: 10),
                      Expanded(child: Text(context.tr.emiLendersList, style: const TextStyle(fontWeight: FontWeight.w800, height: 1.3))),
                    ]),
                    const SizedBox(height: 8),
                    Text(context.tr.emiCardNote, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4)),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Pressable(
              child: OutlinedButton.icon(
                onPressed: () => context.push(Routes.store),
                icon: const Icon(Icons.storefront_outlined),
                label: Text(context.tr.visitStore),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroButton(BuildContext context, IconData icon, String label, VoidCallback onTap) => Pressable(
        child: FilledButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(label)),
      );
}

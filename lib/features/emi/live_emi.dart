import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/env.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../state/data_cubits.dart';
import '../../widgets/common.dart';
import '../../widgets/store_widgets.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(context.tr.navEmi), actions: const <Widget>[LanguageButton(), SizedBox(width: 12)]),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.credit_score_outlined, size: 36),
                    const SizedBox(height: 12),
                    Text(context.tr.liveEmiTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(context.tr.liveEmiBody, style: const TextStyle(height: 1.4)),
                    const SizedBox(height: 16),
                    ContactButtons(settings: store),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => context.push(Routes.store),
                      icon: const Icon(Icons.storefront_outlined),
                      label: Text(context.tr.visitStore),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

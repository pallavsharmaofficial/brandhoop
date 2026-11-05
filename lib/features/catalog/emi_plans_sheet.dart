import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../app/env.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/emi.dart';
import '../../core/money.dart';
import '../../domain/product.dart';
import '../../domain/store_settings.dart';
import '../../l10n/l10n.dart';
import '../../services/emi_hint.dart';
import '../../widgets/common.dart';

/// Every EMI option for a price, scheme by scheme, tenure by tenure.
class EmiPlansSheet extends StatelessWidget {
  const EmiPlansSheet({super.key, required this.settings, required this.product, required this.price});

  final StoreSettings settings;
  final Product product;
  final int price;

  @override
  Widget build(BuildContext context) {
    final List<EmiScheme> schemes = EmiHint.schemesFor(settings, product, price);
    final String lang = context.lang;
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (BuildContext _, ScrollController c) => ListView(
          controller: c,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: <Widget>[
            Text(context.tr.emiOptions, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${product.name.of(lang)} · ${formatRupees(price)}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            InfoBanner(text: context.tr.emiIndicative, icon: Icons.info_outline),
            if (AppEnv.live) ...<Widget>[
              const SizedBox(height: 8),
              InfoBanner(text: context.tr.liveEmiShopOnly, icon: Icons.face_retouching_natural_outlined, color: BrandColors.saffron),
            ],
            if (!settings.emiRatesConfirmed) ...<Widget>[
              const SizedBox(height: 8),
              InfoBanner(text: context.tr.emiRatesUnconfirmed, icon: Icons.warning_amber_outlined, color: const Color(0xFFEF6C00)),
            ],
            const SizedBox(height: 12),
            if (schemes.isEmpty) EmptyState(icon: Icons.credit_card_off_outlined, title: context.tr.noEmiForThis),
            for (final EmiScheme s in schemes) ...<Widget>[
              _SchemeCard(scheme: s, price: price, lang: lang),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('${Routes.calculator}?price=$price');
              },
              icon: const Icon(Icons.calculate_outlined),
              label: Text(context.tr.openCalculator),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchemeCard extends StatelessWidget {
  const _SchemeCard({required this.scheme, required this.price, required this.lang});

  final EmiScheme scheme;
  final int price;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final int down = (price * scheme.minDownPaymentPct / 100).ceil();
    final int principal = price - down;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(scheme.name.of(lang), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                if (scheme.noCost) StatusPill(context.tr.zeroInterest, color: const Color(0xFF2E7D32)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              <String>[
                context.tr.provider(scheme.provider),
                if (down > 0) context.tr.downPaymentFrom(formatRupees(down)),
                if (scheme.processingFee > 0) context.tr.processingFee(formatRupees(scheme.processingFee)),
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 20),
            for (final int m in scheme.tenures)
              Builder(builder: (BuildContext context) {
                final EmiQuote q = Emi.quote(principal: principal, months: m, annualRatePct: scheme.annualRatePct);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: <Widget>[
                      SizedBox(width: 92, child: Text(context.tr.monthsCount(m), style: const TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                        child: Text('${formatRupees(q.emi)}${context.tr.perMonth}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      ),
                      Text(
                        q.totalInterest <= 0 ? context.tr.noExtraCost : context.tr.totalPayable(formatRupees(q.totalPayable + down)),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

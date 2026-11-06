import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme.dart';
import '../../core/money.dart';
import '../../domain/product.dart';
import '../../domain/store_settings.dart';
import '../../l10n/l10n.dart';
import '../../state/data_cubits.dart';
import '../../util/launch.dart';
import '../../util/shop_message.dart';
import '../../widgets/common.dart';

/// The price line of a product the shop quotes on a call: what the reference
/// is (for example "Launch price, Dec 2025") and its figure, never a sale price.
class LiveReferencePrice extends StatelessWidget {
  const LiveReferencePrice({super.key, required this.product, required this.variant});

  final Product product;
  final ProductVariant variant;

  @override
  Widget build(BuildContext context) {
    final String lang = context.lang;
    final String label = product.refPriceLabel.isEmpty ? context.tr.liveRefPrice : product.refPriceLabel.of(lang);
    final ThemeData t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(
          variant.price > 0 ? formatRupees(variant.price) : context.tr.livePriceOnCall,
          style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        StatusPill(context.tr.liveCallForBest, color: BrandColors.saffron, icon: Icons.local_offer_outlined),
      ],
    );
  }
}

/// What the customer gains: the saving against the printed price, the gift, and
/// the two added together. For a quoted-on-a-call product it explains that the
/// shop's price is the one to ask for.
class LiveBenefitCard extends StatelessWidget {
  const LiveBenefitCard({super.key, required this.product, required this.variant});

  final Product product;
  final ProductVariant variant;

  @override
  Widget build(BuildContext context) {
    final String lang = context.lang;
    final int saving = !product.callForBest && variant.mrp > variant.price ? variant.mrp - variant.price : 0;
    final bool hasGift = !product.gift.isEmpty;
    if (!product.callForBest && saving == 0 && !hasGift) return const SizedBox.shrink();
    final int total = saving + (hasGift ? product.giftValue : 0);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Card(
        color: const Color(0xFFE8F5E9),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(children: <Widget>[
                const Icon(Icons.savings_outlined, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Text(context.tr.liveGiftTitle, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1B5E20))),
              ]),
              if (saving > 0) ...<Widget>[
                const SizedBox(height: 8),
                Text(context.tr.liveYouSave(formatRupees(saving)), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1B5E20))),
              ],
              if (hasGift) ...<Widget>[
                const SizedBox(height: 8),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  const Icon(Icons.card_giftcard, size: 20, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      product.giftValue > 0
                          ? '${product.gift.of(lang)} · ${context.tr.liveGiftWorth(formatRupees(product.giftValue))}'
                          : product.gift.of(lang),
                      style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3),
                    ),
                  ),
                ]),
              ],
              if (saving > 0 && hasGift && product.giftValue > 0) ...<Widget>[
                const SizedBox(height: 8),
                Text(context.tr.liveTotalBenefit(formatRupees(total)), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1B5E20))),
              ],
              if (product.callForBest) ...<Widget>[
                const SizedBox(height: 8),
                Text(context.tr.liveRefNote, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The bottom bar of a product the shop quotes on a call: call to bargain, or
/// ask for the offer on WhatsApp with the model already written in.
class LiveBargainBar extends StatelessWidget {
  const LiveBargainBar({super.key, required this.product, required this.variant});

  final Product product;
  final ProductVariant variant;

  @override
  Widget build(BuildContext context) {
    final StoreSettings store = context.watch<StoreCubit>().state;
    final String lang = context.lang;
    final String shop = store.name.of(lang);
    final String name = '${product.name.of(lang)}${variant.label.isEmpty ? '' : ' (${variant.label})'}';
    final String msg = variant.price > 0
        ? context.tr.liveBargainMsg(shop, name, formatRupees(variant.price))
        : context.tr.liveBargainMsgNoPrice(shop, name);
    final bool hasPhone = store.phone.trim().isNotEmpty;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        ),
        child: MaxWidth(
          child: Row(
            children: <Widget>[
              if (hasPhone) ...<Widget>[
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: BrandColors.saffron, foregroundColor: Colors.black87),
                    onPressed: () => Launch.call(store.phone),
                    icon: const Icon(Icons.call),
                    label: FittedBox(fit: BoxFit.scaleDown, child: Text(context.tr.liveBargainBtn)),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => sendToShop(context, msg),
                  icon: const Icon(Icons.chat_outlined),
                  label: FittedBox(fit: BoxFit.scaleDown, child: Text(context.tr.liveWhatsappAsk)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

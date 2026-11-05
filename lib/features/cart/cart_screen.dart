import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/env.dart';
import '../../app/routes.dart';
import '../../core/money.dart';
import '../../domain/cart.dart';
import '../../domain/order.dart';
import '../../domain/product.dart';
import '../../l10n/l10n.dart';
import '../../services/pricing.dart';
import '../../state/cart_cubit.dart';
import '../../state/data_cubits.dart';
import '../../util/shop_message.dart';
import '../../widgets/common.dart';
import '../../widgets/product_art.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<CartLine> cart = context.watch<CartCubit>().state;
    final Map<String, Product> catalogue = <String, Product>{
      for (final Product p in context.watch<ProductsCubit>().state) p.id: p,
    };
    final Quote q = Pricing.quote(
      cart: cart,
      catalogue: catalogue,
      settings: context.watch<StoreCubit>().state,
      fulfilment: Fulfilment.pickup,
      now: DateTime.now(),
    );
    final String lang = context.lang;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr.cartTitle)),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                ),
                child: MaxWidth(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(context.tr.subtotal, style: Theme.of(context).textTheme.bodySmall),
                            Text(formatRupees(q.subtotal), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: !q.isValid
                            ? null
                            : AppEnv.live
                                ? () => sendToShop(context, _orderMessage(context, cart, catalogue, q))
                                : () => context.push(Routes.checkout),
                        child: Text(AppEnv.live ? context.tr.liveOrderCta : context.tr.proceedToCheckout),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      body: cart.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: context.tr.cartEmpty,
              message: context.tr.cartEmptyHint,
              actionLabel: context.tr.startShopping,
              onAction: () => context.go(Routes.shop),
            )
          : MaxWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: <Widget>[
                  for (final CartLine line in cart)
                    Builder(builder: (BuildContext context) {
                      final Product? p = catalogue[line.productId];
                      final ProductVariant? v = p?.variant(line.variantId);
                      if (p == null || v == null) {
                        return _Gone(line: line);
                      }
                      final bool short = v.stock < line.qty;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              InkWell(
                                onTap: () => context.push(Routes.product(p.id)),
                                child: SizedBox(width: 76, height: 76, child: ProductArt(product: p, radius: 12)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(p.name.of(lang), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                                    Text(v.label, style: Theme.of(context).textTheme.bodySmall),
                                    const SizedBox(height: 4),
                                    PriceBlock(price: v.price, mrp: v.mrp),
                                    if (short)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          v.stock == 0 ? context.tr.outOfStock : context.tr.onlyFewLeft(v.stock),
                                          style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w700, fontSize: 12),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: <Widget>[
                                        QtyStepper(
                                          qty: line.qty,
                                          max: v.stock.clamp(1, CartCubit.maxPerLine),
                                          onChanged: (int n) => context.read<CartCubit>().setQty(line.productId, line.variantId, n),
                                        ),
                                        const Spacer(),
                                        TextButton.icon(
                                          onPressed: () => context.read<CartCubit>().remove(line.productId, line.variantId),
                                          icon: const Icon(Icons.delete_outline, size: 18),
                                          label: Text(context.tr.remove),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: <Widget>[
                          KeyValue(context.tr.itemsCount(q.lines.fold(0, (int s, PricedLine l) => s + l.qty)), formatRupees(q.mrpTotal)),
                          if (q.mrpTotal > q.subtotal) KeyValue(context.tr.youSave, '-${formatRupees(q.mrpTotal - q.subtotal)}', color: const Color(0xFF2E7D32)),
                          const Divider(height: 18),
                          KeyValue(context.tr.subtotal, formatRupees(q.subtotal), bold: true),
                          const SizedBox(height: 4),
                          Text(
                            AppEnv.live ? context.tr.liveCartHint : context.tr.deliveryCalculatedAtCheckout,
                            style: Theme.of(context).textTheme.bodySmall,
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

/// The WhatsApp text for an order: what, how many, the total, and a request
/// for the shop to confirm stock and the day's offers.
String _orderMessage(BuildContext context, List<CartLine> cart, Map<String, Product> catalogue, Quote q) {
  final String lang = context.lang;
  final String shop = context.read<StoreCubit>().state.name.of(lang);
  final StringBuffer b = StringBuffer(context.tr.liveOrderIntro(shop))..writeln();
  for (final CartLine line in cart) {
    final Product? p = catalogue[line.productId];
    final ProductVariant? v = p?.variant(line.variantId);
    if (p == null || v == null) continue;
    b.writeln('\u2022 ${p.name.of(lang)} (${v.label}) \u00d7 ${line.qty} \u2014 ${formatRupees(v.price * line.qty)}');
  }
  b
    ..writeln(context.tr.liveOrderTotal(formatRupees(q.subtotal)))
    ..write(context.tr.liveOrderOutro);
  return b.toString();
}

class _Gone extends StatelessWidget {
  const _Gone({required this.line});
  final CartLine line;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: const Icon(Icons.error_outline, color: Color(0xFFC62828)),
          title: Text(context.tr.itemNoLongerAvailable),
          trailing: TextButton(
            onPressed: () => context.read<CartCubit>().remove(line.productId, line.variantId),
            child: Text(context.tr.remove),
          ),
        ),
      );
}

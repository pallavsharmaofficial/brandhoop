import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/routes.dart';
import '../core/money.dart';
import '../domain/product.dart';
import '../domain/store_settings.dart';
import '../l10n/l10n.dart';
import '../services/emi_hint.dart';
import 'common.dart';
import 'product_art.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.settings, this.width});

  final Product product;
  final StoreSettings settings;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final ThemeData t = Theme.of(context);
    final String lang = context.lang;
    final EmiHint? emi = EmiHint.forProduct(settings, product, product.minPrice);
    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(Routes.product(product.id)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ProductArt(product: product, radius: 0),
                    if (product.discountPct > 0)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: _Tag('${product.discountPct}% ${context.tr.off}', const Color(0xFF2E7D32)),
                      ),
                    if (!product.inStock)
                      Positioned.fill(
                        child: ColoredBox(
                          color: Colors.black38,
                          child: Center(
                            child: Text(context.tr.outOfStock, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(product.brand.toUpperCase(), style: t.textTheme.labelSmall?.copyWith(color: t.colorScheme.onSurfaceVariant, letterSpacing: 0.8)),
                    const SizedBox(height: 2),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 36),
                      child: Text(
                        product.name.of(lang),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
                      ),
                    ),
                    const SizedBox(height: 6),
                    PriceBlock(price: product.minPrice, mrp: product.minMrp),
                    if (emi != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        emi.zeroInterest
                            ? context.tr.emiFromZero(formatRupees(emi.emi))
                            : context.tr.emiFrom(formatRupees(emi.emi)),
                        style: TextStyle(color: t.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
      );
}

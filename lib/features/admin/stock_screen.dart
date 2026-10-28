import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../domain/finance.dart';
import '../../domain/product.dart';
import '../../l10n/l10n.dart';
import '../../services/app_services.dart';
import '../../state/data_cubits.dart';
import '../../state/session_cubit.dart';
import '../../widgets/common.dart';
import '../../widgets/product_art.dart';

enum _Stock { all, low, out, phones, accessories }

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  _Stock _f = _Stock.all;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final List<Product> all = context.watch<ProductsCubit>().state;
    final SessionState session = context.watch<SessionCubit>().state;
    final List<CostEntry> costs = context.watch<CostsCubit>().state;
    final String lang = context.lang;
    final String q = _q.trim().toLowerCase();
    final List<Product> list = all.where((Product p) {
      if (q.isNotEmpty && !('${p.name.en} ${p.name.hi} ${p.brand}'.toLowerCase().contains(q))) return false;
      switch (_f) {
        case _Stock.all:
          return true;
        case _Stock.low:
          return p.variants.any((ProductVariant v) => v.stock > 0 && v.stock <= 3);
        case _Stock.out:
          return p.variants.any((ProductVariant v) => v.stock == 0);
        case _Stock.phones:
          return p.category.group == ProductGroup.phones;
        case _Stock.accessories:
          return p.category.group != ProductGroup.phones;
      }
    }).toList()
      ..sort((Product a, Product b) => a.name.en.compareTo(b.name.en));

    final bool canCatalog = session.can(Permission.manageCatalog);
    final bool canStock = session.can(Permission.adjustStock);
    final bool canCosts = session.can(Permission.viewCosts);
    final int missingCost = canCosts ? all.where((Product p) => p.active && p.variants.any((ProductVariant v) => (costs.where((CostEntry c) => c.productId == p.id).firstOrNull?.costOf(v.id) ?? 0) == 0)).length : 0;

    String label(_Stock f) {
      switch (f) {
        case _Stock.all:
          return context.tr.groupAll;
        case _Stock.low:
          return context.tr.stockLow;
        case _Stock.out:
          return context.tr.outOfStock;
        case _Stock.phones:
          return context.tr.groupPhones;
        case _Stock.accessories:
          return context.tr.groupAccessories;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.tr.navStock), actions: const <Widget>[LanguageButton(), SizedBox(width: 12)]),
      floatingActionButton: canCatalog
          ? FloatingActionButton.extended(onPressed: () => context.push(Routes.adminProduct('new')), icon: const Icon(Icons.add), label: Text(context.tr.addProduct))
          : null,
      body: MaxWidth(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(onChanged: (String v) => setState(() => _q = v), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: context.tr.searchHint)),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: <Widget>[
                  for (final _Stock f in _Stock.values)
                    Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(label(f)), selected: _f == f, onSelected: (_) => setState(() => _f = f))),
                ],
              ),
            ),
            if (missingCost > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: InfoBanner(text: context.tr.missingCosts(missingCost), icon: Icons.warning_amber_outlined, color: const Color(0xFFEF6C00)),
              ),
            Expanded(
              child: list.isEmpty
                  ? EmptyState(icon: Icons.inventory_2_outlined, title: context.tr.noResults)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: list.length,
                      separatorBuilder: (BuildContext c, int i) => const SizedBox(height: 10),
                      itemBuilder: (BuildContext c, int i) {
                        final Product p = list[i];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                InkWell(
                                  onTap: canCatalog ? () => context.push(Routes.adminProduct(p.id)) : null,
                                  child: Row(
                                    children: <Widget>[
                                      SizedBox(width: 52, height: 52, child: ProductArt(product: p, radius: 10, iconSize: 26)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(p.name.of(lang), style: const TextStyle(fontWeight: FontWeight.w800)),
                                            Text('${p.brand} · ${context.tr.category(p.category)}', style: Theme.of(context).textTheme.bodySmall),
                                          ],
                                        ),
                                      ),
                                      if (!p.active) StatusPill(context.tr.hidden, color: Colors.blueGrey),
                                      if (p.tags.contains('sample')) ...<Widget>[const SizedBox(width: 6), StatusPill(context.tr.sample, color: BrandColors.saffron)],
                                      if (canCatalog) const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                                const Divider(height: 18),
                                for (final ProductVariant v in p.variants)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(child: Text('${v.label}${v.color.isEmpty ? '' : ' · ${v.color}'}  ·  ${formatRupees(v.price)}', style: const TextStyle(fontSize: 13))),
                                        if (canStock)
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            icon: const Icon(Icons.remove_circle_outline),
                                            onPressed: v.stock == 0 ? null : () => context.read<AppServices>().catalog.adjustStock(session.user, p.id, v.id, -1),
                                          ),
                                        Container(
                                          constraints: const BoxConstraints(minWidth: 34),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: (v.stock == 0 ? BrandColors.red : (v.stock <= 3 ? const Color(0xFFEF6C00) : BrandColors.green)).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text('${v.stock}', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: v.stock == 0 ? BrandColors.red : (v.stock <= 3 ? const Color(0xFFEF6C00) : BrandColors.green))),
                                        ),
                                        if (canStock)
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            icon: const Icon(Icons.add_circle_outline),
                                            onPressed: () => context.read<AppServices>().catalog.adjustStock(session.user, p.id, v.id, 1),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

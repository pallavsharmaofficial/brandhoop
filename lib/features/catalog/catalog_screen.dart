import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/env.dart';
import '../../app/routes.dart';
import '../../core/money.dart';
import '../../domain/product.dart';
import '../../domain/store_settings.dart';
import '../../l10n/l10n.dart';
import '../../state/cart_cubit.dart';
import '../../state/data_cubits.dart';
import '../../widgets/common.dart';
import '../../widgets/product_card.dart';
import 'catalog_query.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, this.initial = const CatalogQuery()});

  final CatalogQuery initial;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late CatalogQuery q = widget.initial;
  late final TextEditingController _search = TextEditingController(text: widget.initial.text);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Product> all = context.watch<ProductsCubit>().state;
    final StoreSettings store = context.watch<StoreCubit>().state;
    final List<Product> shown = applyQuery(all, q);
    final int cartCount = context.watch<CartCubit>().count;
    if (AppEnv.live && !all.any((Product p) => p.active)) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr.navShop), actions: const <Widget>[LanguageButton(), SizedBox(width: 12)]),
        body: EmptyState(
          icon: Icons.storefront_outlined,
          title: context.tr.liveCatalogTitle,
          message: context.tr.liveCatalogBody,
          actionLabel: context.tr.visitStore,
          onAction: () => context.push(Routes.store),
        ),
      );
    }

    final List<ProductCategory> cats = ProductCategory.values
        .where((ProductCategory c) => q.group == null || c.group == q.group)
        .where((ProductCategory c) => all.any((Product p) => p.active && p.category == c))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.navShop),
        actions: <Widget>[
          const LanguageButton(),
          IconButton(
            onPressed: () => context.push(Routes.cart),
            icon: Badge(isLabelVisible: cartCount > 0, label: Text('$cartCount'), child: const Icon(Icons.shopping_cart_outlined)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: MaxWidth(
        wideWidth: 1180,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: (String v) => setState(() => q = q.copyWith(text: v)),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: context.tr.searchHint,
                  suffixIcon: q.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            setState(() => q = q.copyWith(text: ''));
                          },
                        ),
                ),
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  _chip(context.tr.groupAll, q.group == null && q.category == null,
                      () => setState(() => q = q.copyWith(clearGroup: true, clearCategory: true))),
                  for (final ProductGroup g in ProductGroup.values)
                    _chip(context.tr.group(g), q.group == g && q.category == null,
                        () => setState(() => q = q.copyWith(group: g, clearCategory: true))),
                ],
              ),
            ),
            if (cats.length > 1)
              SizedBox(
                height: 42,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: <Widget>[
                    for (final ProductCategory c in cats)
                      _chip(context.tr.category(c), q.category == c,
                          () => setState(() => q = q.category == c ? q.copyWith(clearCategory: true) : q.copyWith(category: c, group: c.group)),
                          small: true),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      context.tr.resultsCount(shown.length),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openFilters(context, all),
                    icon: Badge(
                      isLabelVisible: q.activeFilters > 0,
                      label: Text('${q.activeFilters}'),
                      child: const Icon(Icons.tune, size: 20),
                    ),
                    label: Text(context.tr.filters),
                  ),
                  PopupMenuButton<CatalogSort>(
                    tooltip: context.tr.sortBy,
                    icon: const Icon(Icons.sort),
                    initialValue: q.sort,
                    onSelected: (CatalogSort s) => setState(() => q = q.copyWith(sort: s)),
                    itemBuilder: (BuildContext _) => <PopupMenuEntry<CatalogSort>>[
                      PopupMenuItem<CatalogSort>(value: CatalogSort.popular, child: Text(context.tr.sortPopular)),
                      PopupMenuItem<CatalogSort>(value: CatalogSort.priceLow, child: Text(context.tr.sortPriceLow)),
                      PopupMenuItem<CatalogSort>(value: CatalogSort.priceHigh, child: Text(context.tr.sortPriceHigh)),
                      PopupMenuItem<CatalogSort>(value: CatalogSort.discount, child: Text(context.tr.sortDiscount)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: shown.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off,
                      title: context.tr.noResults,
                      message: context.tr.noResultsHint,
                      actionLabel: context.tr.clearFilters,
                      onAction: () {
                        _search.clear();
                        setState(() => q = const CatalogQuery());
                      },
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 240,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 296,
                      ),
                      itemCount: shown.length,
                      itemBuilder: (BuildContext _, int i) => ProductCard(product: shown[i], settings: store),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, {bool small = false}) => Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 4, top: 4),
        child: ChoiceChip(
          label: Text(label, style: TextStyle(fontSize: small ? 12 : 13)),
          selected: selected,
          onSelected: (_) => onTap(),
          visualDensity: small ? VisualDensity.compact : VisualDensity.standard,
        ),
      );

  Future<void> _openFilters(BuildContext context, List<Product> all) async {
    final List<String> brands = all
        .where((Product p) => p.active && (q.group == null || p.category.group == q.group))
        .map((Product p) => p.brand)
        .toSet()
        .toList()
      ..sort();
    final CatalogQuery? next = await showModalBottomSheet<CatalogQuery>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => _FilterSheet(query: q, brands: brands),
    );
    if (next != null) setState(() => q = next);
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.query, required this.brands});

  final CatalogQuery query;
  final List<String> brands;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late CatalogQuery q = widget.query;

  static const List<(int?, int?)> _bands = <(int?, int?)>[
    (null, 5000),
    (5000, 10000),
    (10000, 15000),
    (15000, 20000),
    (20000, null),
  ];

  String _bandLabel(BuildContext context, (int?, int?) b) {
    if (b.$1 == null) return context.tr.priceBelow(formatRupees(b.$2!));
    if (b.$2 == null) return context.tr.priceAbove(formatRupees(b.$1!));
    return '${formatRupees(b.$1!)} - ${formatRupees(b.$2!)}';
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(context.tr.filters, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Text(context.tr.priceRange, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final (int?, int?) b in _bands)
                      ChoiceChip(
                        label: Text(_bandLabel(context, b)),
                        selected: q.min == b.$1 && q.max == b.$2,
                        onSelected: (bool on) => setState(() => q = on ? q.copyWith(clearPrice: true).copyWith(min: b.$1, max: b.$2) : q.copyWith(clearPrice: true)),
                      ),
                  ],
                ),
                if (widget.brands.length > 1) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(context.tr.brand, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final String b in widget.brands)
                        FilterChip(
                          label: Text(b),
                          selected: q.brands.contains(b),
                          onSelected: (bool on) {
                            final Set<String> s = Set<String>.of(q.brands);
                            on ? s.add(b) : s.remove(b);
                            setState(() => q = q.copyWith(brands: s));
                          },
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr.zeroEmiOnly),
                  value: q.zeroEmiOnly,
                  onChanged: (bool v) => setState(() => q = q.copyWith(zeroEmiOnly: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr.inStockOnly),
                  value: q.inStockOnly,
                  onChanged: (bool v) => setState(() => q = q.copyWith(inStockOnly: v)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(
                          context,
                          q.copyWith(clearPrice: true, brands: const <String>{}, zeroEmiOnly: false, inStockOnly: false),
                        ),
                        child: Text(context.tr.clearFilters),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(onPressed: () => Navigator.pop(context, q), child: Text(context.tr.apply)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

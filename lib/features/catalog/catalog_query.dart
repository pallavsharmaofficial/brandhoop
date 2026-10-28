import 'package:equatable/equatable.dart';

import '../../domain/product.dart';

enum CatalogSort { popular, priceLow, priceHigh, discount }

class CatalogQuery extends Equatable {
  const CatalogQuery({
    this.text = '',
    this.group,
    this.category,
    this.brands = const <String>{},
    this.min,
    this.max,
    this.zeroEmiOnly = false,
    this.inStockOnly = false,
    this.sort = CatalogSort.popular,
  });

  final String text;
  final ProductGroup? group;
  final ProductCategory? category;
  final Set<String> brands;
  final int? min;
  final int? max;
  final bool zeroEmiOnly;
  final bool inStockOnly;
  final CatalogSort sort;

  factory CatalogQuery.fromParams(Map<String, String> p) => CatalogQuery(
        text: p['q'] ?? '',
        group: ProductGroup.values.where((ProductGroup g) => g.name == p['group']).firstOrNull,
        category: ProductCategory.values.where((ProductCategory c) => c.name == p['cat']).firstOrNull,
        brands: p['brand'] == null ? const <String>{} : <String>{p['brand']!},
        min: int.tryParse(p['min'] ?? ''),
        max: int.tryParse(p['max'] ?? ''),
        zeroEmiOnly: p['emi'] == '1',
      );

  CatalogQuery copyWith({
    String? text,
    ProductGroup? group,
    bool clearGroup = false,
    ProductCategory? category,
    bool clearCategory = false,
    Set<String>? brands,
    int? min,
    int? max,
    bool clearPrice = false,
    bool? zeroEmiOnly,
    bool? inStockOnly,
    CatalogSort? sort,
  }) =>
      CatalogQuery(
        text: text ?? this.text,
        group: clearGroup ? null : (group ?? this.group),
        category: clearCategory ? null : (category ?? this.category),
        brands: brands ?? this.brands,
        min: clearPrice ? null : (min ?? this.min),
        max: clearPrice ? null : (max ?? this.max),
        zeroEmiOnly: zeroEmiOnly ?? this.zeroEmiOnly,
        inStockOnly: inStockOnly ?? this.inStockOnly,
        sort: sort ?? this.sort,
      );

  /// How many filters beyond the category chips are on.
  int get activeFilters =>
      (brands.isEmpty ? 0 : 1) +
      ((min != null || max != null) ? 1 : 0) +
      (zeroEmiOnly ? 1 : 0) +
      (inStockOnly ? 1 : 0);

  @override
  List<Object?> get props =>
      <Object?>[text, group, category, brands, min, max, zeroEmiOnly, inStockOnly, sort];
}

/// Filters and sorts the catalogue. Pure, so it is tested without a screen.
List<Product> applyQuery(List<Product> all, CatalogQuery q) {
  final String needle = q.text.trim().toLowerCase();
  final List<Product> out = all.where((Product p) {
    if (!p.active) return false;
    if (q.group != null && p.category.group != q.group) return false;
    if (q.category != null && p.category != q.category) return false;
    if (q.brands.isNotEmpty && !q.brands.contains(p.brand)) return false;
    if (q.min != null && p.minPrice < q.min!) return false;
    if (q.max != null && p.minPrice >= q.max!) return false;
    if (q.zeroEmiOnly && !p.noCostEmi) return false;
    if (q.inStockOnly && !p.inStock) return false;
    if (needle.isNotEmpty) {
      final String hay = '${p.name.en} ${p.name.hi} ${p.brand} ${p.tags.join(' ')}'.toLowerCase();
      if (!needle.split(RegExp(r'\s+')).every(hay.contains)) return false;
    }
    return true;
  }).toList();

  // Phones lead, then what the shop features, then what is in stock, then the
  // biggest discount.
  int byPopular(Product a, Product b) {
    final int g = a.category.group.index.compareTo(b.category.group.index);
    if (g != 0) return g;
    final int f = (b.featured ? 1 : 0).compareTo(a.featured ? 1 : 0);
    if (f != 0) return f;
    final int s = (b.inStock ? 1 : 0).compareTo(a.inStock ? 1 : 0);
    if (s != 0) return s;
    return b.discountPct.compareTo(a.discountPct);
  }

  switch (q.sort) {
    case CatalogSort.popular:
      out.sort(byPopular);
    case CatalogSort.priceLow:
      out.sort((Product a, Product b) => a.minPrice.compareTo(b.minPrice));
    case CatalogSort.priceHigh:
      out.sort((Product a, Product b) => b.minPrice.compareTo(a.minPrice));
    case CatalogSort.discount:
      out.sort((Product a, Product b) => b.discountPct.compareTo(a.discountPct));
  }
  return out;
}

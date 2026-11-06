import 'package:equatable/equatable.dart';

import '../core/json.dart';
import '../core/money.dart';
import 'localized_text.dart';

enum ProductGroup { phones, accessories, protection }

enum ProductCategory {
  smartphone(ProductGroup.phones),
  featurePhone(ProductGroup.phones),
  tablet(ProductGroup.phones),
  earphones(ProductGroup.accessories),
  charger(ProductGroup.accessories),
  cable(ProductGroup.accessories),
  caseCover(ProductGroup.accessories),
  screenGuard(ProductGroup.accessories),
  powerBank(ProductGroup.accessories),
  smartwatch(ProductGroup.accessories),
  speaker(ProductGroup.accessories),
  memory(ProductGroup.accessories),
  holder(ProductGroup.accessories),
  protection(ProductGroup.protection);

  const ProductCategory(this.group);
  final ProductGroup group;

  /// Phones carry an IMEI and a brand warranty; the shop records both at sale.
  bool get needsImei =>
      this == ProductCategory.smartphone ||
      this == ProductCategory.featurePhone ||
      this == ProductCategory.tablet;
}

class ProductVariant extends Equatable {
  const ProductVariant({
    required this.id,
    required this.label,
    this.color = '',
    required this.price,
    required this.mrp,
    required this.stock,
  });

  final String id;

  /// "8 GB + 128 GB", "65W", "Black".
  final String label;
  final String color;

  /// Selling price, GST included, whole rupees.
  final int price;
  final int mrp;
  final int stock;

  bool get inStock => stock > 0;
  int get discountPct => discountPercent(mrp, price);

  ProductVariant copyWith({
    String? label,
    String? color,
    int? price,
    int? mrp,
    int? stock,
  }) =>
      ProductVariant(
        id: id,
        label: label ?? this.label,
        color: color ?? this.color,
        price: price ?? this.price,
        mrp: mrp ?? this.mrp,
        stock: stock ?? this.stock,
      );

  Json toJson() => <String, dynamic>{
        'id': id,
        'label': label,
        'color': color,
        'price': price,
        'mrp': mrp,
        'stock': stock,
      };

  factory ProductVariant.fromJson(Json j) => ProductVariant(
        id: j.str('id'),
        label: j.str('label'),
        color: j.str('color'),
        price: j.integer('price'),
        mrp: j.integer('mrp'),
        stock: j.integer('stock'),
      );

  @override
  List<Object?> get props => <Object?>[id, label, color, price, mrp, stock];
}

class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    this.description = LocalizedText.empty,
    this.highlights = const <LocalizedText>[],
    this.specs = const <String, String>{},
    this.imageUrls = const <String>[],
    required this.variants,
    this.warrantyMonths = 12,
    this.gstRatePct = 18,
    this.emiEligible = false,
    this.noCostEmi = false,
    this.featured = false,
    this.active = true,
    this.tags = const <String>[],
    this.callForBest = false,
    this.refPriceLabel = LocalizedText.empty,
    this.gift = LocalizedText.empty,
    this.giftValue = 0,
    required this.createdAt,
  });

  final String id;
  final LocalizedText name;
  final String brand;
  final ProductCategory category;
  final LocalizedText description;
  final List<LocalizedText> highlights;

  /// Canonical keys (ram, storage, display, battery, camera, chip, os, ...)
  /// to values; the screens translate the keys.
  final Map<String, String> specs;
  final List<String> imageUrls;
  final List<ProductVariant> variants;
  final int warrantyMonths;
  final double gstRatePct;
  final bool emiEligible;

  /// Eligible for a zero-interest ("no-cost") scheme.
  final bool noCostEmi;
  final bool featured;
  final bool active;
  final List<String> tags;

  /// The shop quotes the price on a call: the app shows a reference price (for
  /// example the launch price) and invites the customer to bargain and ask for
  /// the day's offer. Such a product is never added to a cart or shown "in stock".
  final bool callForBest;

  /// What the reference price is, e.g. "Launch price, Dec 2025".
  final LocalizedText refPriceLabel;

  /// The gift that goes with this product, and what the shop says it is worth.
  final LocalizedText gift;
  final int giftValue;
  final DateTime createdAt;

  ProductVariant? variant(String id) {
    for (final ProductVariant v in variants) {
      if (v.id == id) return v;
    }
    return null;
  }

  /// Cheapest variant that is in stock, else the cheapest overall.
  ProductVariant get lead {
    final List<ProductVariant> sorted = List<ProductVariant>.of(variants)
      ..sort((ProductVariant a, ProductVariant b) => a.price.compareTo(b.price));
    return sorted.firstWhere(
      (ProductVariant v) => v.inStock,
      orElse: () => sorted.first,
    );
  }

  int get minPrice => lead.price;
  int get minMrp => lead.mrp;
  int get discountPct => lead.discountPct;
  bool get inStock => variants.any((ProductVariant v) => v.inStock);
  int get totalStock =>
      variants.fold(0, (int s, ProductVariant v) => s + v.stock);
  bool get isPhone => category.needsImei;

  Product copyWith({
    LocalizedText? name,
    String? brand,
    ProductCategory? category,
    LocalizedText? description,
    List<LocalizedText>? highlights,
    Map<String, String>? specs,
    List<String>? imageUrls,
    List<ProductVariant>? variants,
    int? warrantyMonths,
    double? gstRatePct,
    bool? emiEligible,
    bool? noCostEmi,
    bool? featured,
    bool? active,
    List<String>? tags,
    bool? callForBest,
    LocalizedText? refPriceLabel,
    LocalizedText? gift,
    int? giftValue,
  }) =>
      Product(
        id: id,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        category: category ?? this.category,
        description: description ?? this.description,
        highlights: highlights ?? this.highlights,
        specs: specs ?? this.specs,
        imageUrls: imageUrls ?? this.imageUrls,
        variants: variants ?? this.variants,
        warrantyMonths: warrantyMonths ?? this.warrantyMonths,
        gstRatePct: gstRatePct ?? this.gstRatePct,
        emiEligible: emiEligible ?? this.emiEligible,
        noCostEmi: noCostEmi ?? this.noCostEmi,
        featured: featured ?? this.featured,
        active: active ?? this.active,
        tags: tags ?? this.tags,
        callForBest: callForBest ?? this.callForBest,
        refPriceLabel: refPriceLabel ?? this.refPriceLabel,
        gift: gift ?? this.gift,
        giftValue: giftValue ?? this.giftValue,
        createdAt: createdAt,
      );

  Json toJson() => <String, dynamic>{
        'id': id,
        'name': name.toJson(),
        'brand': brand,
        'category': category.name,
        'description': description.toJson(),
        'highlights': highlights.map((LocalizedText t) => t.toJson()).toList(),
        'specs': specs,
        'imageUrls': imageUrls,
        'variants': variants.map((ProductVariant v) => v.toJson()).toList(),
        'warrantyMonths': warrantyMonths,
        'gstRatePct': gstRatePct,
        'emiEligible': emiEligible,
        'noCostEmi': noCostEmi,
        'featured': featured,
        'active': active,
        'tags': tags,
        'callForBest': callForBest,
        'refPriceLabel': refPriceLabel.toJson(),
        'gift': gift.toJson(),
        'giftValue': giftValue,
        'createdAt': isoOrNull(createdAt),
      };

  factory Product.fromJson(Json j) {
    final Json specs = j.obj('specs');
    final Object? rawHighlights = j['highlights'];
    return Product(
      id: j.str('id'),
      name: LocalizedText.fromJson(j['name']),
      brand: j.str('brand'),
      category:
          j.pick('category', ProductCategory.values, ProductCategory.smartphone),
      description: LocalizedText.fromJson(j['description']),
      highlights: rawHighlights is List
          ? rawHighlights.map(LocalizedText.fromJson).toList()
          : const <LocalizedText>[],
      specs: specs.map((String k, dynamic v) => MapEntry<String, String>(k, '$v')),
      imageUrls: j.strings('imageUrls'),
      variants: j.list('variants').map(ProductVariant.fromJson).toList(),
      warrantyMonths: j.integer('warrantyMonths', 12),
      gstRatePct: j.decimal('gstRatePct', 18),
      emiEligible: j.flag('emiEligible'),
      noCostEmi: j.flag('noCostEmi'),
      featured: j.flag('featured'),
      active: j.flag('active', true),
      tags: j.strings('tags'),
      callForBest: j.flag('callForBest'),
      refPriceLabel: LocalizedText.fromJson(j['refPriceLabel']),
      gift: LocalizedText.fromJson(j['gift']),
      giftValue: j.integer('giftValue'),
      createdAt: j.time('createdAt') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id, name, brand, category, description, highlights, specs, imageUrls,
        variants, warrantyMonths, gstRatePct, emiEligible, noCostEmi, featured,
        active, tags, callForBest, refPriceLabel, gift, giftValue, createdAt,
      ];
}

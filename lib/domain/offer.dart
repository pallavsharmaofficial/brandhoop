import 'package:equatable/equatable.dart';

import '../core/json.dart';
import 'localized_text.dart';
import 'product.dart';

enum OfferKind { banner, coupon }

enum DiscountKind { percent, flat }

class Offer extends Equatable {
  const Offer({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle = LocalizedText.empty,
    this.code = '',
    this.discountKind = DiscountKind.percent,
    this.value = 0,
    this.minOrder = 0,
    this.maxDiscount = 0,
    this.groups = const <ProductGroup>[],
    required this.startsAt,
    required this.endsAt,
    this.active = true,
    this.colorSeed = 0,
  });

  final String id;
  final OfferKind kind;
  final LocalizedText title;
  final LocalizedText subtitle;

  /// Upper-case code a customer types. Empty for a plain banner.
  final String code;
  final DiscountKind discountKind;

  /// Percent (1-100) or flat rupees, by [discountKind].
  final int value;
  final int minOrder;

  /// Cap for a percent discount; 0 means no cap.
  final int maxDiscount;

  /// Product groups the discount applies to; empty means everything.
  final List<ProductGroup> groups;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool active;
  final int colorSeed;

  bool isLive(DateTime now) =>
      active && !now.isBefore(startsAt) && now.isBefore(endsAt);

  bool get isCoupon => kind == OfferKind.coupon && code.isNotEmpty;

  Offer copyWith({
    LocalizedText? title,
    LocalizedText? subtitle,
    String? code,
    DiscountKind? discountKind,
    int? value,
    int? minOrder,
    int? maxDiscount,
    List<ProductGroup>? groups,
    DateTime? startsAt,
    DateTime? endsAt,
    bool? active,
  }) =>
      Offer(
        id: id,
        kind: kind,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        code: code ?? this.code,
        discountKind: discountKind ?? this.discountKind,
        value: value ?? this.value,
        minOrder: minOrder ?? this.minOrder,
        maxDiscount: maxDiscount ?? this.maxDiscount,
        groups: groups ?? this.groups,
        startsAt: startsAt ?? this.startsAt,
        endsAt: endsAt ?? this.endsAt,
        active: active ?? this.active,
        colorSeed: colorSeed,
      );

  Json toJson() => <String, dynamic>{
        'id': id,
        'kind': kind.name,
        'title': title.toJson(),
        'subtitle': subtitle.toJson(),
        'code': code,
        'discountKind': discountKind.name,
        'value': value,
        'minOrder': minOrder,
        'maxDiscount': maxDiscount,
        'groups': groups.map((ProductGroup g) => g.name).toList(),
        'startsAt': isoOrNull(startsAt),
        'endsAt': isoOrNull(endsAt),
        'active': active,
        'colorSeed': colorSeed,
      };

  factory Offer.fromJson(Json j) => Offer(
        id: j.str('id'),
        kind: j.pick('kind', OfferKind.values, OfferKind.banner),
        title: LocalizedText.fromJson(j['title']),
        subtitle: LocalizedText.fromJson(j['subtitle']),
        code: j.str('code'),
        discountKind:
            j.pick('discountKind', DiscountKind.values, DiscountKind.percent),
        value: j.integer('value'),
        minOrder: j.integer('minOrder'),
        maxDiscount: j.integer('maxDiscount'),
        groups: j
            .strings('groups')
            .map((String n) => ProductGroup.values.firstWhere(
                  (ProductGroup g) => g.name == n,
                  orElse: () => ProductGroup.accessories,
                ))
            .toList(),
        startsAt: j.time('startsAt') ?? DateTime(2000),
        endsAt: j.time('endsAt') ?? DateTime(2100),
        active: j.flag('active', true),
        colorSeed: j.integer('colorSeed'),
      );

  @override
  List<Object?> get props => <Object?>[
        id, kind, title, subtitle, code, discountKind, value, minOrder,
        maxDiscount, groups, startsAt, endsAt, active, colorSeed,
      ];
}

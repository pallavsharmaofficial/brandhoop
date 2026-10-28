import 'package:equatable/equatable.dart';

import '../core/json.dart';
import 'emi_plan.dart';
import 'localized_text.dart';
import 'repair.dart';

class DayHours extends Equatable {
  const DayHours({this.openMinute = 600, this.closeMinute = 1260, this.closed = false});

  /// Minutes after midnight.
  final int openMinute;
  final int closeMinute;
  final bool closed;

  DayHours copyWith({int? openMinute, int? closeMinute, bool? closed}) =>
      DayHours(
        openMinute: openMinute ?? this.openMinute,
        closeMinute: closeMinute ?? this.closeMinute,
        closed: closed ?? this.closed,
      );

  Json toJson() => <String, dynamic>{
        'open': openMinute,
        'close': closeMinute,
        'closed': closed,
      };

  factory DayHours.fromJson(Json j) => DayHours(
        openMinute: j.integer('open', 600),
        closeMinute: j.integer('close', 1260),
        closed: j.flag('closed'),
      );

  @override
  List<Object?> get props => <Object?>[openMinute, closeMinute, closed];
}

/// Opening hours by weekday, 1 = Monday ... 7 = Sunday (as in [DateTime]).
class StoreHours extends Equatable {
  const StoreHours(this.days);

  /// Same hours every day.
  factory StoreHours.everyDay(int open, int close) => StoreHours(
        <int, DayHours>{
          for (int d = 1; d <= 7; d++)
            d: DayHours(openMinute: open, closeMinute: close),
        },
      );

  final Map<int, DayHours> days;

  DayHours of(int weekday) => days[weekday] ?? const DayHours(closed: true);

  bool isOpenAt(DateTime t) {
    final DayHours h = of(t.weekday);
    if (h.closed) return false;
    final int m = t.hour * 60 + t.minute;
    return m >= h.openMinute && m < h.closeMinute;
  }

  /// The next moment the shop opens or closes after [t], or null if closed all week.
  ({DateTime at, bool opening})? nextChange(DateTime t) {
    if (isOpenAt(t)) {
      final DayHours h = of(t.weekday);
      return (
        at: DateTime(t.year, t.month, t.day).add(Duration(minutes: h.closeMinute)),
        opening: false,
      );
    }
    for (int i = 0; i < 8; i++) {
      final DateTime day = DateTime(t.year, t.month, t.day + i);
      final DayHours h = of(day.weekday);
      if (h.closed) continue;
      final DateTime opens = day.add(Duration(minutes: h.openMinute));
      if (opens.isAfter(t)) return (at: opens, opening: true);
    }
    return null;
  }

  StoreHours withDay(int weekday, DayHours h) =>
      StoreHours(<int, DayHours>{...days, weekday: h});

  Json toJson() => <String, dynamic>{
        for (final MapEntry<int, DayHours> e in days.entries)
          '${e.key}': e.value.toJson(),
      };

  factory StoreHours.fromJson(Json j) {
    if (j.isEmpty) return StoreHours.everyDay(600, 1260);
    return StoreHours(<int, DayHours>{
      for (int d = 1; d <= 7; d++)
        d: j.objOrNull('$d') == null
            ? const DayHours(closed: true)
            : DayHours.fromJson(j.obj('$d')),
    });
  }

  @override
  List<Object?> get props => <Object?>[days];
}

/// One financing option the shop offers, with the rate its lender gave it.
/// The rates are the shop's to confirm: the defaults are placeholders.
class EmiScheme extends Equatable {
  const EmiScheme({
    required this.id,
    required this.provider,
    required this.name,
    required this.tenures,
    required this.annualRatePct,
    this.noCost = false,
    this.lenderRatePct = 0,
    this.minPrice = 0,
    this.maxPrice = 0,
    this.processingFee = 0,
    this.minDownPaymentPct = 0,
    this.enabled = true,
  });

  final String id;
  final EmiProvider provider;
  final LocalizedText name;
  final List<int> tenures;

  /// What the customer pays per year. Zero for a no-cost scheme.
  final double annualRatePct;
  final bool noCost;

  /// For a no-cost scheme, the rate the lender really charges; the shop (or the
  /// brand) bears that interest, and it is counted against the shop's profit.
  final double lenderRatePct;
  final int minPrice;

  /// 0 means no ceiling.
  final int maxPrice;
  final int processingFee;
  final int minDownPaymentPct;
  final bool enabled;

  bool allows(int price) =>
      enabled && price >= minPrice && (maxPrice == 0 || price <= maxPrice);

  EmiScheme copyWith({
    double? annualRatePct,
    double? lenderRatePct,
    int? processingFee,
    int? minPrice,
    int? maxPrice,
    int? minDownPaymentPct,
    List<int>? tenures,
    bool? enabled,
  }) =>
      EmiScheme(
        id: id,
        provider: provider,
        name: name,
        tenures: tenures ?? this.tenures,
        annualRatePct: annualRatePct ?? this.annualRatePct,
        noCost: noCost,
        lenderRatePct: lenderRatePct ?? this.lenderRatePct,
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
        processingFee: processingFee ?? this.processingFee,
        minDownPaymentPct: minDownPaymentPct ?? this.minDownPaymentPct,
        enabled: enabled ?? this.enabled,
      );

  Json toJson() => <String, dynamic>{
        'id': id,
        'provider': provider.name,
        'name': name.toJson(),
        'tenures': tenures,
        'annualRatePct': annualRatePct,
        'noCost': noCost,
        'lenderRatePct': lenderRatePct,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'processingFee': processingFee,
        'minDownPaymentPct': minDownPaymentPct,
        'enabled': enabled,
      };

  factory EmiScheme.fromJson(Json j) => EmiScheme(
        id: j.str('id'),
        provider: j.pick('provider', EmiProvider.values, EmiProvider.bank),
        name: LocalizedText.fromJson(j['name']),
        tenures: j.ints('tenures'),
        annualRatePct: j.decimal('annualRatePct'),
        noCost: j.flag('noCost'),
        lenderRatePct: j.decimal('lenderRatePct'),
        minPrice: j.integer('minPrice'),
        maxPrice: j.integer('maxPrice'),
        processingFee: j.integer('processingFee'),
        minDownPaymentPct: j.integer('minDownPaymentPct'),
        enabled: j.flag('enabled', true),
      );

  @override
  List<Object?> get props => <Object?>[
        id, provider, name, tenures, annualRatePct, noCost, lenderRatePct,
        minPrice, maxPrice, processingFee, minDownPaymentPct, enabled,
      ];
}

class StoreSettings extends Equatable {
  const StoreSettings({
    required this.name,
    required this.tagline,
    this.phone = '',
    this.whatsapp = '',
    required this.addressLine,
    required this.landmark,
    required this.city,
    this.district = 'Neem Ka Thana',
    this.state = 'Rajasthan',
    required this.pincode,
    this.mapsUrl = '',
    this.latitude,
    this.longitude,
    required this.hours,
    this.upiId = '',
    this.gstin = '',
    this.localPincodes = const <String>[],
    this.localDeliveryFee = 0,
    this.courierFee = 99,
    this.freeDeliveryAbove = 5000,
    this.reserveToken = 1000,
    this.reserveHours = 72,
    this.codLimit = 15000,
    this.emiSchemes = const <EmiScheme>[],
    this.emiRatesConfirmed = false,
    this.monthlyProfitTarget = 500000,
    this.baselineMonthlyProfit = 35000,
    this.cardFeePct = 2,
    this.upiFeePct = 0,
    this.profitExcludesGst = true,
    this.repairPrices = const <String, int>{},
    this.bajajEnabled = true,
    this.cardEmiEnabled = true,
    this.codEnabled = true,
    this.reserveEnabled = true,
    this.autopayEnabled = true,
    this.shopInstalmentsEnabled = false,
    this.referralBonusCoins = 100,
    this.coinsEarnPct = 2,
    this.maxCoinsPctOfOrder = 10,
  });

  final LocalizedText name;
  final LocalizedText tagline;
  final String phone;
  final String whatsapp;
  final LocalizedText addressLine;
  final LocalizedText landmark;
  final String city;
  final String district;
  final String state;
  final String pincode;
  final String mapsUrl;
  final double? latitude;
  final double? longitude;
  final StoreHours hours;
  final String upiId;
  final String gstin;

  /// Pincodes the shop delivers to itself, the same day.
  final List<String> localPincodes;
  final int localDeliveryFee;
  final int courierFee;
  final int freeDeliveryAbove;
  final int reserveToken;
  final int reserveHours;
  final int codLimit;
  final List<EmiScheme> emiSchemes;

  /// False until the owner has typed in the rates their lenders really gave.
  final bool emiRatesConfirmed;
  final int monthlyProfitTarget;
  final int baselineMonthlyProfit;
  final double cardFeePct;
  final double upiFeePct;

  /// Profit is measured after the GST on the margin, which goes to the government.
  final bool profitExcludesGst;

  /// Indicative starting price per [RepairIssue] name.
  final Map<String, int> repairPrices;
  final bool bajajEnabled;
  final bool cardEmiEnabled;
  final bool codEnabled;
  final bool reserveEnabled;
  final bool autopayEnabled;

  /// Instalments collected by the shop itself. Off until the owner has taken
  /// advice on the rules for it (see docs/PAYMENTS.md).
  final bool shopInstalmentsEnabled;
  final int referralBonusCoins;
  final int coinsEarnPct;
  final int maxCoinsPctOfOrder;

  bool get hasPhone => phone.trim().isNotEmpty;
  bool get hasWhatsapp => whatsapp.trim().isNotEmpty;

  /// Things the owner still has to fill in before the shop is really open.
  List<String> get missingSetup => <String>[
        if (!hasPhone) 'phone',
        if (!hasWhatsapp) 'whatsapp',
        if (upiId.trim().isEmpty) 'upi',
        if (gstin.trim().isEmpty) 'gstin',
        if (latitude == null || longitude == null) 'location',
        if (!emiRatesConfirmed) 'emiRates',
      ];

  EmiScheme? scheme(String id) {
    for (final EmiScheme s in emiSchemes) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<EmiScheme> schemesFor(int price, {EmiProvider? provider}) => emiSchemes
      .where((EmiScheme s) =>
          s.allows(price) && (provider == null || s.provider == provider))
      .toList();

  bool isLocalPincode(String pincode) =>
      localPincodes.contains(pincode.trim());

  String get mapsLink => mapsUrl.isNotEmpty
      ? mapsUrl
      : 'https://www.google.com/maps/search/?api=1&query='
          '${Uri.encodeComponent('${name.en} ${addressLine.en} $city $state $pincode')}';

  StoreSettings copyWith({
    LocalizedText? name,
    LocalizedText? tagline,
    String? phone,
    String? whatsapp,
    LocalizedText? addressLine,
    LocalizedText? landmark,
    String? city,
    String? pincode,
    String? mapsUrl,
    double? latitude,
    double? longitude,
    StoreHours? hours,
    String? upiId,
    String? gstin,
    List<String>? localPincodes,
    int? localDeliveryFee,
    int? courierFee,
    int? freeDeliveryAbove,
    int? reserveToken,
    int? reserveHours,
    int? codLimit,
    List<EmiScheme>? emiSchemes,
    bool? emiRatesConfirmed,
    int? monthlyProfitTarget,
    int? baselineMonthlyProfit,
    double? cardFeePct,
    double? upiFeePct,
    bool? profitExcludesGst,
    Map<String, int>? repairPrices,
    bool? bajajEnabled,
    bool? cardEmiEnabled,
    bool? codEnabled,
    bool? reserveEnabled,
    bool? autopayEnabled,
    bool? shopInstalmentsEnabled,
    int? referralBonusCoins,
    int? coinsEarnPct,
    int? maxCoinsPctOfOrder,
  }) =>
      StoreSettings(
        name: name ?? this.name,
        tagline: tagline ?? this.tagline,
        phone: phone ?? this.phone,
        whatsapp: whatsapp ?? this.whatsapp,
        addressLine: addressLine ?? this.addressLine,
        landmark: landmark ?? this.landmark,
        city: city ?? this.city,
        district: district,
        state: state,
        pincode: pincode ?? this.pincode,
        mapsUrl: mapsUrl ?? this.mapsUrl,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        hours: hours ?? this.hours,
        upiId: upiId ?? this.upiId,
        gstin: gstin ?? this.gstin,
        localPincodes: localPincodes ?? this.localPincodes,
        localDeliveryFee: localDeliveryFee ?? this.localDeliveryFee,
        courierFee: courierFee ?? this.courierFee,
        freeDeliveryAbove: freeDeliveryAbove ?? this.freeDeliveryAbove,
        reserveToken: reserveToken ?? this.reserveToken,
        reserveHours: reserveHours ?? this.reserveHours,
        codLimit: codLimit ?? this.codLimit,
        emiSchemes: emiSchemes ?? this.emiSchemes,
        emiRatesConfirmed: emiRatesConfirmed ?? this.emiRatesConfirmed,
        monthlyProfitTarget: monthlyProfitTarget ?? this.monthlyProfitTarget,
        baselineMonthlyProfit:
            baselineMonthlyProfit ?? this.baselineMonthlyProfit,
        cardFeePct: cardFeePct ?? this.cardFeePct,
        upiFeePct: upiFeePct ?? this.upiFeePct,
        profitExcludesGst: profitExcludesGst ?? this.profitExcludesGst,
        repairPrices: repairPrices ?? this.repairPrices,
        bajajEnabled: bajajEnabled ?? this.bajajEnabled,
        cardEmiEnabled: cardEmiEnabled ?? this.cardEmiEnabled,
        codEnabled: codEnabled ?? this.codEnabled,
        reserveEnabled: reserveEnabled ?? this.reserveEnabled,
        autopayEnabled: autopayEnabled ?? this.autopayEnabled,
        shopInstalmentsEnabled:
            shopInstalmentsEnabled ?? this.shopInstalmentsEnabled,
        referralBonusCoins: referralBonusCoins ?? this.referralBonusCoins,
        coinsEarnPct: coinsEarnPct ?? this.coinsEarnPct,
        maxCoinsPctOfOrder: maxCoinsPctOfOrder ?? this.maxCoinsPctOfOrder,
      );

  Json toJson() => <String, dynamic>{
        'name': name.toJson(),
        'tagline': tagline.toJson(),
        'phone': phone,
        'whatsapp': whatsapp,
        'addressLine': addressLine.toJson(),
        'landmark': landmark.toJson(),
        'city': city,
        'district': district,
        'state': state,
        'pincode': pincode,
        'mapsUrl': mapsUrl,
        'latitude': latitude,
        'longitude': longitude,
        'hours': hours.toJson(),
        'upiId': upiId,
        'gstin': gstin,
        'localPincodes': localPincodes,
        'localDeliveryFee': localDeliveryFee,
        'courierFee': courierFee,
        'freeDeliveryAbove': freeDeliveryAbove,
        'reserveToken': reserveToken,
        'reserveHours': reserveHours,
        'codLimit': codLimit,
        'emiSchemes': emiSchemes.map((EmiScheme s) => s.toJson()).toList(),
        'emiRatesConfirmed': emiRatesConfirmed,
        'monthlyProfitTarget': monthlyProfitTarget,
        'baselineMonthlyProfit': baselineMonthlyProfit,
        'cardFeePct': cardFeePct,
        'upiFeePct': upiFeePct,
        'profitExcludesGst': profitExcludesGst,
        'repairPrices': repairPrices,
        'bajajEnabled': bajajEnabled,
        'cardEmiEnabled': cardEmiEnabled,
        'codEnabled': codEnabled,
        'reserveEnabled': reserveEnabled,
        'autopayEnabled': autopayEnabled,
        'shopInstalmentsEnabled': shopInstalmentsEnabled,
        'referralBonusCoins': referralBonusCoins,
        'coinsEarnPct': coinsEarnPct,
        'maxCoinsPctOfOrder': maxCoinsPctOfOrder,
      };

  factory StoreSettings.fromJson(Json j, StoreSettings fallback) {
    if (j.isEmpty) return fallback;
    return StoreSettings(
      name: LocalizedText.fromJson(j['name']),
      tagline: LocalizedText.fromJson(j['tagline']),
      phone: j.str('phone'),
      whatsapp: j.str('whatsapp'),
      addressLine: LocalizedText.fromJson(j['addressLine']),
      landmark: LocalizedText.fromJson(j['landmark']),
      city: j.str('city', fallback.city),
      district: j.str('district', fallback.district),
      state: j.str('state', fallback.state),
      pincode: j.str('pincode', fallback.pincode),
      mapsUrl: j.str('mapsUrl'),
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      hours: StoreHours.fromJson(j.obj('hours')),
      upiId: j.str('upiId'),
      gstin: j.str('gstin'),
      localPincodes: j.strings('localPincodes'),
      localDeliveryFee: j.integer('localDeliveryFee'),
      courierFee: j.integer('courierFee', 99),
      freeDeliveryAbove: j.integer('freeDeliveryAbove', 5000),
      reserveToken: j.integer('reserveToken', 1000),
      reserveHours: j.integer('reserveHours', 72),
      codLimit: j.integer('codLimit', 15000),
      emiSchemes: j.list('emiSchemes').map(EmiScheme.fromJson).toList(),
      emiRatesConfirmed: j.flag('emiRatesConfirmed'),
      monthlyProfitTarget: j.integer('monthlyProfitTarget', 500000),
      baselineMonthlyProfit: j.integer('baselineMonthlyProfit', 35000),
      cardFeePct: j.decimal('cardFeePct', 2),
      upiFeePct: j.decimal('upiFeePct'),
      profitExcludesGst: j.flag('profitExcludesGst', true),
      repairPrices: j.obj('repairPrices').map(
            (String k, dynamic v) => MapEntry<String, int>(k, (v as num).toInt()),
          ),
      bajajEnabled: j.flag('bajajEnabled', true),
      cardEmiEnabled: j.flag('cardEmiEnabled', true),
      codEnabled: j.flag('codEnabled', true),
      reserveEnabled: j.flag('reserveEnabled', true),
      autopayEnabled: j.flag('autopayEnabled', true),
      shopInstalmentsEnabled: j.flag('shopInstalmentsEnabled'),
      referralBonusCoins: j.integer('referralBonusCoins', 100),
      coinsEarnPct: j.integer('coinsEarnPct', 2),
      maxCoinsPctOfOrder: j.integer('maxCoinsPctOfOrder', 10),
    );
  }

  int repairPrice(RepairIssue issue) => repairPrices[issue.name] ?? 0;

  @override
  List<Object?> get props => <Object?>[
        name, tagline, phone, whatsapp, addressLine, landmark, city, district,
        state, pincode, mapsUrl, latitude, longitude, hours, upiId, gstin,
        localPincodes, localDeliveryFee, courierFee, freeDeliveryAbove,
        reserveToken, reserveHours, codLimit, emiSchemes, emiRatesConfirmed,
        monthlyProfitTarget, baselineMonthlyProfit, cardFeePct, upiFeePct,
        profitExcludesGst, repairPrices, bajajEnabled, cardEmiEnabled,
        codEnabled, reserveEnabled, autopayEnabled, shopInstalmentsEnabled,
        referralBonusCoins, coinsEarnPct, maxCoinsPctOfOrder,
      ];
}

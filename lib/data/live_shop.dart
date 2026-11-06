import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/shop_config.dart';
import '../domain/offer.dart';
import '../domain/localized_text.dart';
import '../domain/product.dart';
import '../domain/store_settings.dart';
import 'repositories.dart';

/// One photo in the shop's gallery strip (festival gifts, offers).
class GalleryItem {
  const GalleryItem(this.url, this.caption);

  final String url;
  final LocalizedText caption;
}

/// What the live storefront shows, read from one JSON file the shop owns.
///
/// The file is `assets/live/shop.json`. It is bundled into every build as the
/// fallback and also published on the site, and the app fetches the published
/// copy each time it opens, so the owner can change a price or an offer without
/// anybody reinstalling the app. If the network is down the last copy it got is
/// used, and if there never was one the bundled copy.
///
/// Shape (every part is optional):
///
///     { "settings": { "whatsapp": "98xxxxxxxx", "phone": "98xxxxxxxx" },
///       "offers":   [ { "id": "d1", "title": {"en": "...", "hi": "..."}, ... } ],
///       "products": [ <Product JSON, see docs/LIVE.md> ] }
class LiveShop {
  const LiveShop._();

  /// What the shop has said it offers. Everything starts off: the storefront
  /// promises only what the shop's own file turns on, never a default written
  /// before the shop was asked. Set by [apply] from the file's `features`
  /// (`repair`, `exchange`, `delivery`, `reserve`) and from `settings.hours`.
  static bool repair = false;
  static bool exchange = false;
  static bool delivery = false;
  static bool reserve = false;

  /// True only when the file gives opening hours, so "Open now" is never a guess.
  static bool hoursKnown = false;

  /// The gallery strip on the home screen, from the file's `gallery` list.
  static List<GalleryItem> gallery = const <GalleryItem>[];

  static const String bundledAsset = 'assets/live/shop.json';
  /// The file as committed to the repository. The admin panel writes here, and
  /// GitHub serves it within a few minutes, with no site rebuild in between.
  static const String repoUrl = 'https://raw.githubusercontent.com/pallavsharmaofficial/brandhoop/main/assets/live/shop.json';

  /// The copy published with the site, used if the first address cannot be reached.
  static const String publishedUrl = 'https://pallavsharmaofficial.github.io/brandhoop/live/shop.json';
  static const String _cacheKey = 'bh.live.shop';

  /// Where to look, in order. On the web the published copy sits next to the
  /// app, so its address is worked out from where the page itself was loaded.
  static List<Uri> get _remotes => <Uri>[
        Uri.parse(repoUrl),
        kIsWeb ? Uri.base.resolve('../live/shop.json') : Uri.parse(publishedUrl),
      ];

  /// The freshest usable copy of the file: published, else cached, else bundled.
  static Future<Map<String, dynamic>> load(
    SharedPreferences prefs, {
    http.Client? client,
    Future<String> Function()? bundled,
    Uri? remote,
  }) async {
    final http.Client c = client ?? http.Client();
    try {
      for (final Uri base in remote == null ? _remotes : <Uri>[remote]) {
        try {
          final Uri url = base.replace(queryParameters: <String, String>{
            ...base.queryParameters,
            't': '${DateTime.now().millisecondsSinceEpoch ~/ 60000}',
          });
          final http.Response r = await c.get(url).timeout(const Duration(seconds: 5));
          if (r.statusCode == 200) {
            final Map<String, dynamic>? parsed = _parse(utf8.decode(r.bodyBytes));
            if (parsed != null) {
              await prefs.setString(_cacheKey, jsonEncode(parsed));
              return parsed;
            }
          }
        } catch (e) {
          debugPrint('Live shop file not fetched from $base: $e');
        }
      }
    } finally {
      if (client == null) c.close();
    }
    final String? cached = prefs.getString(_cacheKey);
    if (cached != null) {
      final Map<String, dynamic>? parsed = _parse(cached);
      if (parsed != null) return parsed;
    }
    try {
      final String text = await (bundled ?? () => rootBundle.loadString(bundledAsset))();
      return _parse(text) ?? <String, dynamic>{};
    } catch (e) {
      debugPrint('Bundled shop file unreadable: $e');
      return <String, dynamic>{};
    }
  }

  static Map<String, dynamic>? _parse(String text) {
    try {
      final Object? v = jsonDecode(text);
      return v is Map ? Map<String, dynamic>.from(v) : null;
    } catch (_) {
      return null;
    }
  }

  /// Makes the repositories hold exactly what [shop] describes. An entry that
  /// does not parse is skipped, so one typo in the file costs one product and
  /// never the whole shop. Returns how many entries were skipped.
  static Future<int> apply(Repositories repos, Map<String, dynamic> shop, {DateTime? now}) async {
    int skipped = 0;
    final DateTime at = now ?? DateTime.now();

    final Object? feats = shop['features'];
    bool on(String k) => feats is Map && feats[k] == true;
    repair = on('repair');
    exchange = on('exchange');
    delivery = on('delivery');
    reserve = on('reserve');

    final Object? rawGallery = shop['gallery'];
    gallery = <GalleryItem>[
      if (rawGallery is List)
        for (final Object? g in rawGallery)
          if (g is Map && '${g['url']}'.startsWith('http'))
            GalleryItem('${g['url']}', LocalizedText.fromJson(g['caption'])),
    ];

    final StoreSettings defaults = ShopConfig.defaults();
    final Object? raw = shop['settings'];
    hoursKnown = raw is Map && raw['hours'] is Map;
    final Map<String, dynamic> merged = <String, dynamic>{
      ...defaults.toJson(),
      if (raw is Map) ...Map<String, dynamic>.from(raw),
    };
    StoreSettings settings;
    try {
      settings = StoreSettings.fromJson(merged, defaults);
    } catch (_) {
      skipped++;
      settings = defaults;
    }
    await repos.settings.save(settings);

    final List<Product> products = <Product>[];
    final Object? rawProducts = shop['products'];
    if (rawProducts is List) {
      for (final Object? e in rawProducts) {
        try {
          final Map<String, dynamic> m = Map<String, dynamic>.from(e! as Map);
          m.putIfAbsent('createdAt', () => at.toIso8601String());
          // A warranty is shown only when the shop's file states one.
          m.putIfAbsent('warrantyMonths', () => 0);
          final Product p = Product.fromJson(m);
          if (p.id.isEmpty || p.variants.isEmpty) throw const FormatException('needs an id and a variant');
          products.add(p);
        } catch (_) {
          skipped++;
        }
      }
    }
    await _replace<Product>(repos.catalog, products, (Product p) => p.id);

    final List<Offer> offers = <Offer>[];
    final Object? rawOffers = shop['offers'];
    if (rawOffers is List) {
      for (final Object? e in rawOffers) {
        try {
          final Offer o = Offer.fromJson(Map<String, dynamic>.from(e! as Map));
          // The storefront has no checkout, so only banners mean anything.
          if (o.id.isEmpty || o.kind != OfferKind.banner) throw const FormatException('banner with an id');
          offers.add(o);
        } catch (_) {
          skipped++;
        }
      }
    }
    await _replace<Offer>(repos.offers, offers, (Offer o) => o.id);
    return skipped;
  }

  static Future<void> _replace<T>(Repo<T> repo, List<T> items, String Function(T) idOf) async {
    final Set<String> keep = items.map(idOf).toSet();
    for (final T old in await repo.all()) {
      if (!keep.contains(idOf(old))) await repo.delete(idOf(old));
    }
    await repo.saveAll(items);
  }
}

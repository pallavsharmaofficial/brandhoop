import 'dart:convert';

import 'package:brandhoop/app/router.dart';
import 'package:brandhoop/app/routes.dart';
import 'package:brandhoop/data/live_shop.dart';
import 'package:brandhoop/data/repositories.dart';
import 'package:brandhoop/domain/offer.dart';
import 'package:brandhoop/domain/product.dart';
import 'package:brandhoop/domain/store_settings.dart';
import 'package:brandhoop/state/session_cubit.dart';
import 'package:brandhoop/state/settings_cubit.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _good = '''
{
  "settings": {"whatsapp": "9876543210", "phone": "9876543211"},
  "offers": [
    {"id": "d1", "title": {"en": "Diwali", "hi": "दिवाली"}},
    {"id": "c1", "kind": "coupon", "code": "X", "title": {"en": "Coupon"}}
  ],
  "products": [
    {"id": "p1", "name": {"en": "Phone"}, "brand": "B", "category": "smartphone",
     "variants": [{"id": "v1", "label": "8+128", "price": 15000, "mrp": 17000, "stock": 3}]},
    {"id": "broken", "name": {"en": "No variants"}, "brand": "B", "variants": []},
    "not an object"
  ]
}
''';

Future<Repositories> _repos() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  return Repositories.local(await SharedPreferences.getInstance());
}

void main() {
  test('apply loads products, banners and contact, and skips what does not parse', () async {
    final Repositories r = await _repos();
    final int skipped = await LiveShop.apply(r, jsonDecode(_good) as Map<String, dynamic>);
    expect(skipped, 3); // the empty product, the string, the coupon
    final List<Product> products = await r.catalog.all();
    expect(products.map((Product p) => p.id), <String>['p1']);
    expect(products.single.lead.price, 15000);
    expect((await r.offers.all()).map((Offer o) => o.id), <String>['d1']);
    final StoreSettings s = await r.settings.get();
    expect(s.whatsapp, '9876543210');
    expect(s.hasWhatsapp, isTrue);
    // Everything the file did not mention keeps the shop's defaults.
    expect(s.name.en, 'Brandhoop Mobile Point');
    expect(s.pincode, '332713');
  });

  test('apply replaces what was there, so a removed product disappears', () async {
    final Repositories r = await _repos();
    await LiveShop.apply(r, jsonDecode(_good) as Map<String, dynamic>);
    await LiveShop.apply(r, <String, dynamic>{'products': <Object>[]});
    expect(await r.catalog.all(), isEmpty);
    expect(await r.offers.all(), isEmpty);
    expect((await r.settings.get()).hasWhatsapp, isFalse);
  });

  test('the empty file the app ships with is valid and shows no products', () async {
    final Repositories r = await _repos();
    await LiveShop.apply(r, <String, dynamic>{});
    expect(await r.catalog.all(), isEmpty);
  });

  test('the storefront promises nothing the file does not turn on', () async {
    final Repositories r = await _repos();
    await LiveShop.apply(r, <String, dynamic>{});
    expect(
      <bool>[LiveShop.repair, LiveShop.exchange, LiveShop.delivery, LiveShop.reserve, LiveShop.hoursKnown],
      everyElement(isFalse),
    );
    await LiveShop.apply(r, <String, dynamic>{
      'features': <String, dynamic>{'repair': true, 'delivery': true},
      'settings': <String, dynamic>{
        'hours': StoreHours.everyDay(600, 1260).toJson(),
      },
    });
    expect(LiveShop.repair, isTrue);
    expect(LiveShop.delivery, isTrue);
    expect(LiveShop.exchange, isFalse);
    expect(LiveShop.hoursKnown, isTrue);
    expect((await r.settings.get()).hours.isOpenAt(DateTime(2026, 11, 8, 12)), isTrue);
  });

  group('load', () {
    final Uri remote = Uri.parse('https://example.test/live/shop.json');

    test('takes the published copy and remembers it', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final http.Client ok = MockClient((_) async => http.Response.bytes(utf8.encode(_good), 200));
      final Map<String, dynamic> m = await LiveShop.load(prefs, client: ok, remote: remote, bundled: () async => '{}');
      expect((m['products'] as List).length, 3);

      final http.Client down = MockClient((_) async => throw http.ClientException('offline'));
      final Map<String, dynamic> again = await LiveShop.load(prefs, client: down, remote: remote, bundled: () async => '{}');
      expect((again['products'] as List).length, 3, reason: 'falls back to the copy it kept');
    });

    test('a half-edited published file does not replace a good copy', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await LiveShop.load(prefs, client: MockClient((_) async => http.Response.bytes(utf8.encode(_good), 200)), remote: remote, bundled: () async => '{}');
      final Map<String, dynamic> m = await LiveShop.load(
        prefs,
        client: MockClient((_) async => http.Response('{ "products": [ ', 200)),
        remote: remote,
        bundled: () async => '{}',
      );
      expect((m['products'] as List).length, 3);
    });

    test('with no network and no copy, the bundled file is used', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> m = await LiveShop.load(
        prefs,
        client: MockClient((_) async => http.Response('nope', 404)),
        remote: remote,
        bundled: () async => '{"offers": []}',
      );
      expect(m.containsKey('offers'), isTrue);
    });
  });

  group('storefront routing', () {
    const AppPrefs prefs = AppPrefs(onboarded: true, languageCode: 'en', themeMode: ThemeMode.system);
    const SessionState guest = SessionState(ready: true);
    String? go(String l) => redirectFor(location: l, session: guest, prefs: prefs, storefront: true);

    test('checkout is the cart; accounts, orders and the back office lead home', () {
      expect(go(Routes.checkout), Routes.cart);
      expect(go(Routes.login), Routes.home);
      expect(go(Routes.orders), Routes.home);
      expect(go('/order/abc'), Routes.home);
      expect(go(Routes.adminDashboard), Routes.home);
      expect(go('/admin/pos'), Routes.home);
      expect(go(Routes.shop), isNull);
      expect(go('/product/p1'), isNull);
      expect(go(Routes.cart), isNull);
      expect(go(Routes.calculator), isNull);
      expect(go(Routes.store), isNull);
    });
  });
}

import 'package:brandhoop/app/app.dart';
import 'package:brandhoop/data/demo_seed.dart';
import 'package:brandhoop/data/repositories.dart';
import 'package:brandhoop/services/app_services.dart';
import 'package:brandhoop/services/auth_service.dart';
import 'package:brandhoop/services/payment_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The whole app on a phone-sized surface, with demo data and a gateway that
/// answers at once.
class AppUnderTest {
  AppUnderTest(this.services, this.prefs);

  final AppServices services;
  final SharedPreferences prefs;

  Repositories get repos => services.repos;

  static Future<AppUnderTest> pump(
    WidgetTester tester, {
    String language = 'en',
    bool onboarded = true,
    Map<String, Object> extra = const <String, Object>{},
    Size size = const Size(412, 915),
  }) async {
    await initializeDateFormatting('hi');
    await initializeDateFormatting('en_IN');
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues(<String, Object>{
      if (onboarded) 'bh.onboarded': true,
      if (onboarded) 'bh.lang': language,
      ...extra,
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Repositories repos = Repositories.local(prefs);
    await DemoSeed.populate(repos, DateTime.now());
    final AppServices services = AppServices.create(
      repos: repos,
      auth: LocalAuthService(repos.users, prefs),
      gateway: MockPaymentGateway(delay: Duration.zero),
    );
    await tester.pumpWidget(BrandhoopApp(services: services, prefs: prefs, deviceLanguage: language));
    await settle(tester);
    return AppUnderTest(services, prefs);
  }

  /// pumpAndSettle can spin forever on looping progress indicators; this
  /// pumps a bounded number of frames instead.
  static Future<void> settle(WidgetTester tester, [int frames = 12]) async {
    for (int i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

extension Taps on WidgetTester {
  Future<void> tapText(String text, {bool settleAfter = true}) async {
    final Finder f = find.text(text);
    expect(f, findsWidgets, reason: 'looking for "$text"');
    await ensureVisible(f.first);
    await pump();
    await tapAt(getRect(f.first).center);
    if (settleAfter) await AppUnderTest.settle(this);
  }

  /// Scrolls the first scrollable until [text] is built, for lazy lists.
  Future<void> reveal(String text) async {
    final Finder f = find.text(text);
    if (f.evaluate().isNotEmpty) return;
    await scrollUntilVisible(f, 400, scrollable: find.byType(Scrollable).first, maxScrolls: 40);
    await AppUnderTest.settle(this, 3);
  }
}

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/env.dart';
import 'data/demo_seed.dart';
import 'data/live_shop.dart';
import 'data/repositories.dart';
import 'services/app_services.dart';
import 'services/auth_service.dart';
import 'services/payment_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('hi');
  await initializeDateFormatting('en_IN');
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final Repositories repos = Repositories.local(prefs);
  if (AppEnv.demo) {
    await DemoSeed.populate(repos, DateTime.now());
  } else {
    // The public storefront: whatever the shop has published, never sample data.
    await LiveShop.apply(repos, await LiveShop.load(prefs));
  }

  final AppServices services = AppServices.create(
    repos: repos,
    auth: LocalAuthService(repos.users, prefs),
    gateway: MockPaymentGateway(),
  );
  // Let go of stock held by orders nobody paid for or came to collect.
  if (AppEnv.demo) unawaited(services.orders.expireStale());
  if (AppEnv.demo) unawaited(services.emi.runAutopay());

  runApp(BrandhoopApp(
    services: services,
    prefs: prefs,
    deviceLanguage: ui.PlatformDispatcher.instance.locale.languageCode,
  ));
}

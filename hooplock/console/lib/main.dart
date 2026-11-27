import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';

import 'api.dart';
import 'i18n.dart';
import 'screens/home.dart';
import 'screens/login.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Lang.I.load();
  await Api.I.restore();
  runApp(const HoopLockApp());
}

class HoopLockApp extends StatelessWidget {
  const HoopLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Lang.I,
      builder: (context, lang, _) => MaterialApp(
        title: 'HoopLock',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: Locale(lang),
        supportedLocales: const [Locale('en'), Locale('hi')],
        localizationsDelegates: [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
        home: ListenableBuilder(
          listenable: Api.I,
          builder: (context, _) => Api.I.signedIn ? const HomeScreen() : const LoginScreen(),
        ),
      ),
    );
  }
}

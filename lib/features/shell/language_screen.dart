import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/palette.dart';
import '../../l10n/l10n.dart';
import '../../state/settings_cubit.dart';
import '../../widgets/common.dart';
import '../../widgets/hero_phones.dart';
import '../../widgets/motion.dart';

/// The first thing a new customer sees: pick Hindi or English.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _code = context.read<SettingsCubit>().state.languageCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.navy800,
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Palette.navy600, Palette.navy800])),
        child: SafeArea(
          child: MaxWidth(
            width: 480,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Spacer(),
                  const Reveal(child: Center(child: HeroPhones(height: 170))),
                  const SizedBox(height: 18),
                  Reveal(
                    delay: const Duration(milliseconds: 120),
                    child: Column(children: <Widget>[
                      Text(context.tr.appName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 6),
                      Text(context.tr.appTagline, textAlign: TextAlign.center, style: const TextStyle(color: Palette.saffron200, fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const Spacer(),
                  Reveal(
                    delay: const Duration(milliseconds: 220),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                      const Text('भाषा चुनें / Choose language', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 14),
                      _choice('hi', 'हिन्दी', 'आगे बढ़ें'),
                      const SizedBox(height: 10),
                      _choice('en', 'English', 'Continue'),
                      const SizedBox(height: 20),
                      Pressable(
                        child: FilledButton(
                          onPressed: () => context.read<SettingsCubit>().finishOnboarding(_code),
                          child: Text(_code == 'hi' ? 'आगे बढ़ें' : 'Continue'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(context.tr.chooseLanguageHint, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _choice(String code, String name, String hint) {
    final bool on = _code == code;
    return Pressable(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() => _code = code);
          // Show the rest of this screen in the language just picked.
          context.read<SettingsCubit>().setLanguage(code);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: on ? Palette.saffron500 : Colors.white24, width: on ? 2.2 : 1),
            color: on ? Palette.saffron500.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.05),
          ),
          child: Row(
            children: <Widget>[
              Expanded(child: Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white))),
              Icon(on ? Icons.radio_button_checked : Icons.radio_button_off, color: on ? Palette.saffron400 : Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

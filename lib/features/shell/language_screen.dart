import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme.dart';
import '../../l10n/l10n.dart';
import '../../state/settings_cubit.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/common.dart';

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
      body: SafeArea(
        child: MaxWidth(
          width: 480,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Spacer(),
                const Center(child: BrandMark(size: 96)),
                const SizedBox(height: 20),
                Text(context.tr.appName, textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: BrandColors.indigo)),
                const SizedBox(height: 6),
                Text(context.tr.appTagline, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                const Spacer(),
                Text(
                  'भाषा चुनें / Choose language',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                _choice('hi', 'हिन्दी', 'आगे बढ़ें'),
                const SizedBox(height: 10),
                _choice('en', 'English', 'Continue'),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.read<SettingsCubit>().finishOnboarding(_code),
                  child: Text(_code == 'hi' ? 'आगे बढ़ें' : 'Continue'),
                ),
                const SizedBox(height: 8),
                Text(context.tr.chooseLanguageHint, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _choice(String code, String name, String hint) {
    final bool on = _code == code;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() => _code = code);
        // Show the rest of this screen in the language just picked.
        context.read<SettingsCubit>().setLanguage(code);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: on ? BrandColors.indigo : Theme.of(context).colorScheme.outlineVariant, width: on ? 2.2 : 1),
          color: on ? BrandColors.indigo.withValues(alpha: 0.07) : null,
        ),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
            Icon(on ? Icons.radio_button_checked : Icons.radio_button_off, color: on ? BrandColors.indigo : null),
          ],
        ),
      ),
    );
  }
}

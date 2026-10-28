import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs extends Equatable {
  const AppPrefs({
    required this.languageCode,
    this.themeMode = ThemeMode.system,
    this.onboarded = false,
  });

  final String languageCode;
  final ThemeMode themeMode;
  final bool onboarded;

  Locale get locale => Locale(languageCode);
  bool get isHindi => languageCode == 'hi';

  AppPrefs copyWith({String? languageCode, ThemeMode? themeMode, bool? onboarded}) =>
      AppPrefs(
        languageCode: languageCode ?? this.languageCode,
        themeMode: themeMode ?? this.themeMode,
        onboarded: onboarded ?? this.onboarded,
      );

  @override
  List<Object?> get props => <Object?>[languageCode, themeMode, onboarded];
}

/// Language, theme and whether the first-run language screen has been seen.
class SettingsCubit extends Cubit<AppPrefs> {
  SettingsCubit(this._prefs, {String deviceLanguage = 'hi'})
      : super(AppPrefs(
          languageCode: _prefs.getString(_langKey) ??
              (deviceLanguage == 'en' ? 'en' : 'hi'),
          themeMode: ThemeMode.values.firstWhere(
            (ThemeMode m) => m.name == _prefs.getString(_themeKey),
            orElse: () => ThemeMode.system,
          ),
          onboarded: _prefs.getBool(_onboardedKey) ?? false,
        ));

  static const String _langKey = 'bh.lang';
  static const String _themeKey = 'bh.theme';
  static const String _onboardedKey = 'bh.onboarded';

  final SharedPreferences _prefs;

  Future<void> setLanguage(String code) async {
    await _prefs.setString(_langKey, code);
    emit(state.copyWith(languageCode: code));
  }

  Future<void> toggleLanguage() => setLanguage(state.isHindi ? 'en' : 'hi');

  Future<void> setThemeMode(ThemeMode m) async {
    await _prefs.setString(_themeKey, m.name);
    emit(state.copyWith(themeMode: m));
  }

  Future<void> finishOnboarding(String code) async {
    await _prefs.setString(_langKey, code);
    await _prefs.setBool(_onboardedKey, true);
    emit(state.copyWith(languageCode: code, onboarded: true));
  }
}

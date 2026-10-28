import 'package:equatable/equatable.dart';

import '../core/json.dart';

/// Text the shop writes in two languages. English is always present; Hindi is
/// optional and falls back to English, so a half-translated catalogue still
/// reads fine.
class LocalizedText extends Equatable {
  const LocalizedText(this.en, [this.hi = '']);

  static const LocalizedText empty = LocalizedText('');

  final String en;
  final String hi;

  String of(String languageCode) =>
      languageCode == 'hi' && hi.trim().isNotEmpty ? hi : en;

  bool get isEmpty => en.trim().isEmpty && hi.trim().isEmpty;

  Json toJson() => <String, dynamic>{'en': en, 'hi': hi};

  factory LocalizedText.fromJson(Object? raw) {
    if (raw is String) return LocalizedText(raw);
    if (raw is Map) {
      final Json m = Json.from(raw);
      return LocalizedText(m.str('en'), m.str('hi'));
    }
    return empty;
  }

  @override
  List<Object?> get props => <Object?>[en, hi];
}

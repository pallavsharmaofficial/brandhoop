import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';
export 'labels.dart';

extension TrContext on BuildContext {
  /// The app's translated strings: `context.tr.cancel`.
  AppLocalizations get tr => AppLocalizations.of(this);

  /// `hi` or `en`.
  String get lang => Localizations.localeOf(this).languageCode;
  bool get isHindi => lang == 'hi';
}

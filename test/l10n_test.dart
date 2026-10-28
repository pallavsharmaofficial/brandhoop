import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> load(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;

Set<String> placeholders(String msg) {
  // Names that appear as {name} or {name, plural, ...} but not plural branch words.
  final Set<String> out = <String>{};
  int depth = 0;
  for (int i = 0; i < msg.length; i++) {
    if (msg[i] == '{') {
      final String before = msg.substring(0, i);
      // `=0{...}` and `other{...}` open a plural branch, not a placeholder.
      final bool branch = RegExp(r'(=\d+|other|one|few|many|zero|two)$').hasMatch(before);
      final RegExpMatch? m = RegExp(r'^\{\s*([A-Za-z_]\w*)\s*[,}]').firstMatch(msg.substring(i));
      if (!branch && m != null) out.add(m.group(1)!);
      depth++;
    } else if (msg[i] == '}') {
      depth--;
    }
  }
  expect(depth, 0, reason: 'unbalanced braces in: $msg');
  return out;
}

void main() {
  final Map<String, dynamic> en = load('en');
  final Map<String, dynamic> hi = load('hi');
  final List<String> enKeys = en.keys.where((String k) => !k.startsWith('@')).toList();
  final List<String> hiKeys = hi.keys.where((String k) => !k.startsWith('@')).toList();

  test('Hindi and English have exactly the same keys', () {
    expect(hiKeys.toSet().difference(enKeys.toSet()), isEmpty, reason: 'only in Hindi');
    expect(enKeys.toSet().difference(hiKeys.toSet()), isEmpty, reason: 'missing from Hindi');
  });

  test('every message has the same placeholders in both languages', () {
    for (final String k in enKeys) {
      if (k == '@@locale') continue;
      expect(placeholders(hi[k] as String), placeholders(en[k] as String), reason: k);
    }
  });

  test('nothing is empty and Hindi is really Hindi where it should be', () {
    final RegExp devanagari = RegExp(r'[ऀ-ॿ]');
    // Words that are legitimately the same in both languages.
    const Set<String> same = <String>{
      'languageEnglish', 'languageShortEn', 'languageShortHi', 'whatsapp', 'ok', 'budget10to15',
      'budget15to20', 'payMethodUpi', 'providerBajaj',
    };
    int untranslated = 0;
    for (final String k in enKeys) {
      if (k == '@@locale') continue;
      final String h = hi[k] as String;
      expect(h.trim(), isNotEmpty, reason: k);
      expect((en[k] as String).trim(), isNotEmpty, reason: k);
      if (!devanagari.hasMatch(h) && !same.contains(k)) untranslated++;
    }
    // A handful (units, "CVV", "IMEI") are fine; a wall of English is not.
    expect(untranslated, lessThan(12));
  });

  test('every metadata block belongs to a real key', () {
    for (final String k in en.keys.where((String k) => k.startsWith('@') && k != '@@locale')) {
      expect(en.containsKey(k.substring(1)), isTrue, reason: k);
    }
  });
}

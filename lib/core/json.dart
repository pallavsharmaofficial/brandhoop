import 'dart:convert';

/// Small helpers for reading the JSON the local store and, later, a server
/// give us. Every reader has a default so an old saved document never crashes
/// a newer app.
typedef Json = Map<String, dynamic>;

extension JsonRead on Json {
  String str(String key, [String fallback = '']) =>
      (this[key] as String?) ?? fallback;

  String? strOrNull(String key) => this[key] as String?;

  int integer(String key, [int fallback = 0]) =>
      (this[key] as num?)?.toInt() ?? fallback;

  int? integerOrNull(String key) => (this[key] as num?)?.toInt();

  double decimal(String key, [double fallback = 0]) =>
      (this[key] as num?)?.toDouble() ?? fallback;

  bool flag(String key, [bool fallback = false]) =>
      (this[key] as bool?) ?? fallback;

  DateTime? time(String key) {
    final String? raw = this[key] as String?;
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Json obj(String key) {
    final Object? raw = this[key];
    return raw is Map ? Json.from(raw) : <String, dynamic>{};
  }

  Json? objOrNull(String key) {
    final Object? raw = this[key];
    return raw is Map ? Json.from(raw) : null;
  }

  List<Json> list(String key) {
    final Object? raw = this[key];
    if (raw is! List) return <Json>[];
    return raw.whereType<Map<dynamic, dynamic>>().map(Json.from).toList();
  }

  List<String> strings(String key) {
    final Object? raw = this[key];
    if (raw is! List) return <String>[];
    return raw.whereType<String>().toList();
  }

  List<int> ints(String key) {
    final Object? raw = this[key];
    if (raw is! List) return <int>[];
    return raw.whereType<num>().map((num n) => n.toInt()).toList();
  }

  T pick<T extends Enum>(String key, List<T> values, T fallback) {
    final String? name = this[key] as String?;
    for (final T v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }
}

String? isoOrNull(DateTime? t) => t?.toUtc().toIso8601String();

Json jsonDecodeMap(String raw) {
  final Object? v = jsonDecode(raw);
  return v is Map ? Json.from(v) : <String, dynamic>{};
}

String jsonEncodeMap(Json map) => jsonEncode(map);

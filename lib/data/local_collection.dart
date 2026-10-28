import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/json.dart';

/// A small persisted collection: every document is JSON, the whole collection
/// is one string in shared preferences (localStorage on the web). It is the
/// offline "database" that lets the app run, and be demonstrated, with no
/// server. A server-backed repository replaces it without the screens knowing.
class LocalCollection<T> {
  LocalCollection({
    required SharedPreferences prefs,
    required this.name,
    required this.fromJson,
    required this.toJson,
    required this.idOf,
  }) : _prefs = prefs {
    _load();
  }

  final SharedPreferences _prefs;
  final String name;
  final T Function(Json) fromJson;
  final Json Function(T) toJson;
  final String Function(T) idOf;

  final Map<String, T> _items = <String, T>{};
  final StreamController<List<T>> _changes =
      StreamController<List<T>>.broadcast();

  String get _key => 'bh.col.$name';

  void _load() {
    final String? raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final Object? e in decoded) {
          if (e is Map) {
            final T item = fromJson(Json.from(e));
            _items[idOf(item)] = item;
          }
        }
      }
    } catch (_) {
      // A corrupt document must not stop the shop opening: start empty.
      _items.clear();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _key,
      jsonEncode(_items.values.map(toJson).toList()),
    );
    _changes.add(all);
  }

  List<T> get all => List<T>.unmodifiable(_items.values);
  T? get(String id) => _items[id];
  bool get isEmpty => _items.isEmpty;
  int get length => _items.length;

  Future<void> put(T item) {
    _items[idOf(item)] = item;
    return _persist();
  }

  Future<void> putAll(Iterable<T> items) {
    for (final T i in items) {
      _items[idOf(i)] = i;
    }
    return _persist();
  }

  Future<void> remove(String id) {
    _items.remove(id);
    return _persist();
  }

  Future<void> clear() {
    _items.clear();
    return _persist();
  }

  /// The current list first, then every change.
  Stream<List<T>> watch() {
    late StreamController<List<T>> out;
    StreamSubscription<List<T>>? sub;
    out = StreamController<List<T>>(
      onListen: () {
        out.add(all);
        sub = _changes.stream.listen(out.add);
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }
}

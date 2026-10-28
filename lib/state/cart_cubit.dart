import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/json.dart';
import '../domain/cart.dart';

/// The shopping cart: ids and quantities only. Prices are looked up fresh at
/// every screen and at checkout, so an old price can never be paid.
class CartCubit extends Cubit<List<CartLine>> {
  CartCubit(this._prefs) : super(_read(_prefs));

  static const String _key = 'bh.cart';
  static const int maxPerLine = 5;

  final SharedPreferences _prefs;

  static List<CartLine> _read(SharedPreferences p) {
    final String? raw = p.getString(_key);
    if (raw == null) return const <CartLine>[];
    try {
      final Object? v = jsonDecode(raw);
      if (v is List) {
        return v
            .whereType<Map<dynamic, dynamic>>()
            .map((Map<dynamic, dynamic> m) => CartLine.fromJson(Json.from(m)))
            .toList();
      }
    } catch (_) {}
    return const <CartLine>[];
  }

  Future<void> _write(List<CartLine> lines) async {
    emit(lines);
    await _prefs.setString(_key, jsonEncode(lines.map((CartLine l) => l.toJson()).toList()));
  }

  int get count => state.fold(0, (int s, CartLine l) => s + l.qty);

  int qtyOf(String productId, String variantId) {
    for (final CartLine l in state) {
      if (l.productId == productId && l.variantId == variantId) return l.qty;
    }
    return 0;
  }

  Future<void> add(String productId, String variantId, {int qty = 1}) {
    final List<CartLine> next = <CartLine>[];
    bool found = false;
    for (final CartLine l in state) {
      if (l.productId == productId && l.variantId == variantId) {
        next.add(l.withQty((l.qty + qty).clamp(1, maxPerLine)));
        found = true;
      } else {
        next.add(l);
      }
    }
    if (!found) next.add(CartLine(productId: productId, variantId: variantId, qty: qty.clamp(1, maxPerLine)));
    return _write(next);
  }

  Future<void> setQty(String productId, String variantId, int qty) {
    if (qty <= 0) return remove(productId, variantId);
    return _write(<CartLine>[
      for (final CartLine l in state)
        if (l.productId == productId && l.variantId == variantId)
          l.withQty(qty.clamp(1, maxPerLine))
        else
          l,
    ]);
  }

  Future<void> remove(String productId, String variantId) => _write(<CartLine>[
        for (final CartLine l in state)
          if (!(l.productId == productId && l.variantId == variantId)) l,
      ]);

  Future<void> clear() => _write(const <CartLine>[]);
}

import 'package:equatable/equatable.dart';

import '../core/json.dart';

class CartLine extends Equatable {
  const CartLine({
    required this.productId,
    required this.variantId,
    this.qty = 1,
  });

  final String productId;
  final String variantId;
  final int qty;

  CartLine withQty(int q) =>
      CartLine(productId: productId, variantId: variantId, qty: q);

  Json toJson() => <String, dynamic>{
        'productId': productId,
        'variantId': variantId,
        'qty': qty,
      };

  factory CartLine.fromJson(Json j) => CartLine(
        productId: j.str('productId'),
        variantId: j.str('variantId'),
        qty: j.integer('qty', 1),
      );

  @override
  List<Object?> get props => <Object?>[productId, variantId, qty];
}

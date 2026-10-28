import 'package:equatable/equatable.dart';

import '../core/json.dart';

/// The profit the shop actually made on one sale or one repair. It lives apart
/// from the order on purpose: a customer can read their own order, and must
/// never be able to read what the shop paid for the phone.
class FinanceEntry extends Equatable {
  const FinanceEntry({
    required this.id,
    required this.kind,
    required this.at,
    required this.revenue,
    required this.cost,
    required this.gst,
    required this.fees,
    required this.profit,
    this.profitByGroup = const <String, int>{},
  });

  /// `sale` or `repair`.
  final String kind;

  /// The order id or the repair ticket id.
  final String id;
  final DateTime at;
  final int revenue;
  final int cost;
  final int gst;

  /// Gateway charges and the lender's subvention the shop bore.
  final int fees;
  final int profit;

  /// Profit split into `phones`, `accessories`, `protection`, `repairs`.
  final Map<String, int> profitByGroup;

  Json toJson() => <String, dynamic>{
        'id': id,
        'kind': kind,
        'at': isoOrNull(at),
        'revenue': revenue,
        'cost': cost,
        'gst': gst,
        'fees': fees,
        'profit': profit,
        'profitByGroup': profitByGroup,
      };

  factory FinanceEntry.fromJson(Json j) => FinanceEntry(
        id: j.str('id'),
        kind: j.str('kind', 'sale'),
        at: j.time('at') ?? DateTime.now(),
        revenue: j.integer('revenue'),
        cost: j.integer('cost'),
        gst: j.integer('gst'),
        fees: j.integer('fees'),
        profit: j.integer('profit'),
        profitByGroup: j
            .obj('profitByGroup')
            .map((String k, dynamic v) =>
                MapEntry<String, int>(k, (v as num).toInt())),
      );

  @override
  List<Object?> get props =>
      <Object?>[id, kind, at, revenue, cost, gst, fees, profit, profitByGroup];
}

/// What the shop paid for each variant of a product (GST included). Admin only.
class CostEntry extends Equatable {
  const CostEntry({required this.productId, required this.costs});

  final String productId;
  final Map<String, int> costs;

  int costOf(String variantId) => costs[variantId] ?? 0;

  Json toJson() => <String, dynamic>{'productId': productId, 'costs': costs};

  factory CostEntry.fromJson(Json j) => CostEntry(
        productId: j.str('productId'),
        costs: j.obj('costs').map(
              (String k, dynamic v) => MapEntry<String, int>(k, (v as num).toInt()),
            ),
      );

  @override
  List<Object?> get props => <Object?>[productId, costs];
}

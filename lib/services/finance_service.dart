import '../data/repositories.dart';
import '../domain/emi_plan.dart';
import '../domain/finance.dart';
import '../domain/order.dart';
import '../domain/store_settings.dart';
import 'finance_calc.dart';

/// Writes the profit ledger. Only the back-office code paths call it, and the
/// ledger is readable by the owner alone.
class FinanceService {
  FinanceService(this.repos);

  final Repositories repos;

  Future<void> recordSale(Order order) async {
    final Map<String, CostEntry> costs = <String, CostEntry>{
      for (final CostEntry c in await repos.finance.costs()) c.productId: c,
    };
    final StoreSettings settings = await repos.settings.get();
    EmiPlan? plan;
    if (order.emiPlanId != null) plan = await repos.plans.get(order.emiPlanId!);
    await repos.finance.saveEntry(ProfitCalculator.forOrder(
      order: order,
      costs: costs,
      settings: settings,
      plan: plan,
    ));
  }

  /// A returned sale takes its profit back out, by a mirror entry dated now.
  Future<void> reverseSale(Order order, DateTime at) async {
    final FinanceEntry? e = await repos.finance.entry(order.id);
    if (e == null) return;
    await repos.finance.saveEntry(FinanceEntry(
      id: '${order.id}#return',
      kind: 'return',
      at: at,
      revenue: -e.revenue,
      cost: -e.cost,
      gst: -e.gst,
      fees: 0,
      profit: -e.profit,
      profitByGroup: e.profitByGroup.map(
        (String k, int v) => MapEntry<String, int>(k, -v),
      ),
    ));
  }

  Future<void> recordRepair({
    required String ticketId,
    required int price,
    required int partsCost,
    required DateTime at,
  }) async {
    final StoreSettings settings = await repos.settings.get();
    await repos.finance.saveEntry(ProfitCalculator.forRepair(
      ticketId: ticketId,
      price: price,
      partsCost: partsCost,
      at: at,
      settings: settings,
    ));
  }
}

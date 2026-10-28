import '../data/repositories.dart';
import '../domain/app_user.dart';
import '../domain/emi_plan.dart';
import '../domain/finance.dart';
import '../domain/lead.dart';
import '../domain/offer.dart';
import '../domain/order.dart';
import '../domain/product.dart';
import '../domain/repair.dart';
import '../domain/store_settings.dart';
import '../config/shop_config.dart';
import 'stream_cubit.dart';

class ProductsCubit extends StreamCubit<List<Product>> {
  ProductsCubit(CatalogRepository r) : super(r.watchAll(), const <Product>[]);
}

class OffersCubit extends StreamCubit<List<Offer>> {
  OffersCubit(OfferRepository r) : super(r.watchAll(), const <Offer>[]);
}

class StoreCubit extends StreamCubit<StoreSettings> {
  StoreCubit(SettingsRepository r) : super(r.watch(), ShopConfig.defaults());
}

// Customer-scoped

class MyOrdersCubit extends StreamCubit<List<Order>> {
  MyOrdersCubit(OrderRepository r, String userId)
      : super(r.watchForCustomer(userId), const <Order>[]);
}

class MyPlansCubit extends StreamCubit<List<EmiPlan>> {
  MyPlansCubit(PlanRepository r, String userId)
      : super(r.watchForCustomer(userId), const <EmiPlan>[]);
}

class MyRepairsCubit extends StreamCubit<List<RepairTicket>> {
  MyRepairsCubit(RepairRepository r, String userId)
      : super(r.watchForUser(userId), const <RepairTicket>[]);
}

// Back office

class AllOrdersCubit extends StreamCubit<List<Order>> {
  AllOrdersCubit(OrderRepository r, {bool enabled = true})
      : super(enabled ? r.watchAll() : const Stream<List<Order>>.empty(), const <Order>[]);
}

class AllPlansCubit extends StreamCubit<List<EmiPlan>> {
  AllPlansCubit(PlanRepository r, {bool enabled = true})
      : super(enabled ? r.watchAll() : const Stream<List<EmiPlan>>.empty(), const <EmiPlan>[]);
}

class LeadsCubit extends StreamCubit<List<Lead>> {
  LeadsCubit(LeadRepository r, {bool enabled = true})
      : super(enabled ? r.watchAll() : const Stream<List<Lead>>.empty(), const <Lead>[]);
}

class AllRepairsCubit extends StreamCubit<List<RepairTicket>> {
  AllRepairsCubit(RepairRepository r, {bool enabled = true})
      : super(enabled ? r.watchAll() : const Stream<List<RepairTicket>>.empty(), const <RepairTicket>[]);
}

class UsersCubit extends StreamCubit<List<AppUser>> {
  UsersCubit(UserRepository r, {bool enabled = true})
      : super(enabled ? r.watchAll() : const Stream<List<AppUser>>.empty(), const <AppUser>[]);
}

/// Profit and cost data is for owners and managers only: for anyone else the
/// cubit is created empty and never touches the repository.
class FinanceEntriesCubit extends StreamCubit<List<FinanceEntry>> {
  FinanceEntriesCubit(FinanceRepository r, {bool enabled = true})
      : super(enabled ? r.watchEntries() : const Stream<List<FinanceEntry>>.empty(),
            const <FinanceEntry>[]);
}

class CostsCubit extends StreamCubit<List<CostEntry>> {
  CostsCubit(FinanceRepository r, {bool enabled = true})
      : super(enabled ? r.watchCosts() : const Stream<List<CostEntry>>.empty(),
            const <CostEntry>[]);
}

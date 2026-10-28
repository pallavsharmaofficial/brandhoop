import '../data/repositories.dart';
import 'auth_service.dart';
import 'catalog_service.dart';
import 'checkout_service.dart';
import 'clock.dart';
import 'emi_service.dart';
import 'finance_service.dart';
import 'lead_service.dart';
import 'order_service.dart';
import 'payment_gateway.dart';
import 'profile_service.dart';
import 'repair_service.dart';

/// Every service, wired once, handed to the widget tree as one object.
class AppServices {
  AppServices._({
    required this.repos,
    required this.auth,
    required this.gateway,
    required this.leads,
    required this.emi,
    required this.finance,
    required this.checkout,
    required this.orders,
    required this.repairs,
    required this.profile,
    required this.catalog,
  });

  factory AppServices.create({
    required Repositories repos,
    required AuthService auth,
    required PaymentGateway gateway,
    Clock clock = systemClock,
  }) {
    final LeadService leads = LeadService(repos, clock: clock);
    final EmiService emi = EmiService(repos: repos, gateway: gateway, clock: clock);
    final FinanceService finance = FinanceService(repos);
    final CheckoutService checkout = CheckoutService(
      repos: repos,
      gateway: gateway,
      emi: emi,
      leads: leads,
      clock: clock,
    );
    return AppServices._(
      repos: repos,
      auth: auth,
      gateway: gateway,
      leads: leads,
      emi: emi,
      finance: finance,
      checkout: checkout,
      orders: OrderService(
        repos: repos,
        gateway: gateway,
        checkout: checkout,
        emi: emi,
        finance: finance,
        clock: clock,
      ),
      repairs: RepairService(
        repos: repos,
        leads: leads,
        finance: finance,
        clock: clock,
      ),
      profile: ProfileService(repos, clock: clock),
      catalog: CatalogService(repos),
    );
  }

  final Repositories repos;
  final AuthService auth;
  final PaymentGateway gateway;
  final LeadService leads;
  final EmiService emi;
  final FinanceService finance;
  final CheckoutService checkout;
  final OrderService orders;
  final RepairService repairs;
  final ProfileService profile;
  final CatalogService catalog;
}

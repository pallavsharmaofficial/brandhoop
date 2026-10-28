import 'package:brandhoop/core/permissions.dart';
import 'package:brandhoop/data/demo_seed.dart';
import 'package:brandhoop/data/repositories.dart';
import 'package:brandhoop/domain/address.dart';
import 'package:brandhoop/domain/app_user.dart';
import 'package:brandhoop/services/app_services.dart';
import 'package:brandhoop/services/auth_service.dart';
import 'package:brandhoop/services/payment_gateway.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A fully wired app over empty in-memory preferences, with a clock the test
/// can move and a gateway with no delay.
class Harness {
  Harness._(this.repos, this.services, this._now);

  final Repositories repos;
  final AppServices services;
  DateTime _now;

  DateTime get now => _now;
  void advance(Duration d) => _now = _now.add(d);

  late AppUser owner;
  late AppUser manager;
  late AppUser staff;
  late AppUser customer;

  static Future<Harness> create({bool seed = true, DateTime? at}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Repositories repos = Repositories.local(prefs);
    final DateTime start = at ?? DateTime(2026, 10, 15, 12);
    late Harness h;
    DateTime clock() => h._now;
    final AppServices services = AppServices.create(
      repos: repos,
      auth: LocalAuthService(repos.users, prefs, clock: clock),
      gateway: MockPaymentGateway(delay: Duration.zero),
      clock: clock,
    );
    h = Harness._(repos, services, start);
    if (seed) await DemoSeed.populate(repos, start);
    h.owner = (await repos.users.byPhone(DemoSeed.ownerPhone))!;
    h.manager = (await repos.users.byPhone(DemoSeed.managerPhone))!;
    h.staff = (await repos.users.byPhone(DemoSeed.staffPhone))!;
    h.customer = (await repos.users.byPhone(DemoSeed.customerPhone))!;
    return h;
  }

  /// A fresh customer with an address in town.
  Future<AppUser> newCustomer({String phone = '9111111111'}) async {
    final AppUser u = await services.profile.saveAddress(
      (await repos.users.byPhone(phone)) ??
          AppUser(
            id: 'u_$phone',
            phone: phone,
            name: 'Test Customer',
            createdAt: now,
            role: AppRole.customer,
          ),
      Address(
        id: 'a1',
        label: 'Home',
        name: 'Test Customer',
        phone: phone,
        line1: 'House 1',
        area: 'Abhay Colony',
        city: 'Neem Ka Thana',
        pincode: '332713',
      ),
    );
    return u;
  }
}

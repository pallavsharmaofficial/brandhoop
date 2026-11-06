import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/shop_config.dart';
import '../core/json.dart';
import '../domain/app_user.dart';
import '../domain/emi_plan.dart';
import '../domain/finance.dart';
import '../domain/lead.dart';
import '../domain/offer.dart';
import '../domain/order.dart';
import '../domain/product.dart';
import '../domain/repair.dart';
import '../domain/store_settings.dart';
import 'local_collection.dart';

/// What every collection can do. The screens and services depend on these
/// interfaces only; the offline implementations below are one way to satisfy
/// them, a Firestore one (docs/BACKEND.md) is the next.
abstract class Repo<T> {
  Future<T?> get(String id);
  Future<List<T>> all();
  Stream<List<T>> watchAll();
  Future<void> save(T item);

  /// Saves many at once. The default saves one by one; the offline
  /// implementation writes them in a single go.
  Future<void> saveAll(Iterable<T> items) async {
    for (final T item in items) {
      await save(item);
    }
  }

  Future<void> delete(String id);
}

abstract class CatalogRepository implements Repo<Product> {
  /// Adds [delta] (may be negative) to one variant's stock, never below zero.
  Future<void> adjustStock(String productId, String variantId, int delta);
}

abstract class OrderRepository implements Repo<Order> {
  Stream<List<Order>> watchForCustomer(String customerId);

  /// The next human-friendly number for the month of [now], e.g. BH-2610-0042.
  Future<String> nextNumber(DateTime now);
}

abstract class PlanRepository implements Repo<EmiPlan> {
  Stream<List<EmiPlan>> watchForCustomer(String customerId);
}

abstract class UserRepository implements Repo<AppUser> {
  Future<AppUser?> byPhone(String phone);
  Future<AppUser?> byReferralCode(String code);
  Stream<AppUser?> watchOne(String id);
}

abstract class LeadRepository implements Repo<Lead> {}

abstract class RepairRepository implements Repo<RepairTicket> {
  Stream<List<RepairTicket>> watchForUser(String userId);
  Future<String> nextNumber(DateTime now);
}

abstract class OfferRepository implements Repo<Offer> {}

abstract class SettingsRepository {
  Future<StoreSettings> get();
  Stream<StoreSettings> watch();
  Future<void> save(StoreSettings settings);
}

abstract class FinanceRepository {
  Future<List<CostEntry>> costs();
  Stream<List<CostEntry>> watchCosts();
  Future<void> saveCost(CostEntry cost);
  Future<List<FinanceEntry>> entries();
  Stream<List<FinanceEntry>> watchEntries();
  Future<FinanceEntry?> entry(String id);
  Future<void> saveEntry(FinanceEntry entry);
}

// ---------------------------------------------------------------------------
// Offline implementations
// ---------------------------------------------------------------------------

class _LocalRepo<T> implements Repo<T> {
  _LocalRepo(this.col);
  final LocalCollection<T> col;

  @override
  Future<T?> get(String id) async => col.get(id);
  @override
  Future<List<T>> all() async => col.all;
  @override
  Stream<List<T>> watchAll() => col.watch();
  @override
  Future<void> save(T item) => col.put(item);
  @override
  Future<void> saveAll(Iterable<T> items) => col.putAll(items);
  @override
  Future<void> delete(String id) => col.remove(id);
}

class LocalCatalogRepository extends _LocalRepo<Product>
    implements CatalogRepository {
  LocalCatalogRepository(super.col);

  @override
  Future<void> adjustStock(String productId, String variantId, int delta) async {
    final Product? p = col.get(productId);
    if (p == null) return;
    final List<ProductVariant> vs = <ProductVariant>[
      for (final ProductVariant v in p.variants)
        if (v.id == variantId)
          v.copyWith(stock: (v.stock + delta) < 0 ? 0 : v.stock + delta)
        else
          v,
    ];
    await col.put(p.copyWith(variants: vs));
  }
}

String _monthNumber(String prefix, DateTime now, Iterable<String> existing) {
  final String yy = (now.year % 100).toString().padLeft(2, '0');
  final String mm = now.month.toString().padLeft(2, '0');
  final String head = '$prefix-$yy$mm-';
  int max = 0;
  for (final String n in existing) {
    if (!n.startsWith(head)) continue;
    final int? seq = int.tryParse(n.substring(head.length));
    if (seq != null && seq > max) max = seq;
  }
  return '$head${(max + 1).toString().padLeft(4, '0')}';
}

class LocalOrderRepository extends _LocalRepo<Order> implements OrderRepository {
  LocalOrderRepository(super.col);

  @override
  Stream<List<Order>> watchForCustomer(String customerId) => col.watch().map(
        (List<Order> l) =>
            l.where((Order o) => o.customerId == customerId).toList(),
      );

  @override
  Future<String> nextNumber(DateTime now) async =>
      _monthNumber('BH', now, col.all.map((Order o) => o.number));
}

class LocalPlanRepository extends _LocalRepo<EmiPlan> implements PlanRepository {
  LocalPlanRepository(super.col);

  @override
  Stream<List<EmiPlan>> watchForCustomer(String customerId) => col.watch().map(
        (List<EmiPlan> l) =>
            l.where((EmiPlan p) => p.customerId == customerId).toList(),
      );
}

class LocalUserRepository extends _LocalRepo<AppUser> implements UserRepository {
  LocalUserRepository(super.col);

  @override
  Future<AppUser?> byPhone(String phone) async {
    for (final AppUser u in col.all) {
      if (u.phone == phone) return u;
    }
    return null;
  }

  @override
  Future<AppUser?> byReferralCode(String code) async {
    final String c = code.trim().toUpperCase();
    if (c.isEmpty) return null;
    for (final AppUser u in col.all) {
      if (u.referralCode == c) return u;
    }
    return null;
  }

  @override
  Stream<AppUser?> watchOne(String id) =>
      col.watch().map((List<AppUser> l) {
        for (final AppUser u in l) {
          if (u.id == id) return u;
        }
        return null;
      });
}

class LocalLeadRepository extends _LocalRepo<Lead> implements LeadRepository {
  LocalLeadRepository(super.col);
}

class LocalRepairRepository extends _LocalRepo<RepairTicket>
    implements RepairRepository {
  LocalRepairRepository(super.col);

  @override
  Stream<List<RepairTicket>> watchForUser(String userId) => col.watch().map(
        (List<RepairTicket> l) =>
            l.where((RepairTicket t) => t.userId == userId).toList(),
      );

  @override
  Future<String> nextNumber(DateTime now) async =>
      _monthNumber('RP', now, col.all.map((RepairTicket t) => t.number));
}

class LocalOfferRepository extends _LocalRepo<Offer> implements OfferRepository {
  LocalOfferRepository(super.col);
}

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._prefs) {
    final String? raw = _prefs.getString(_key);
    _current = raw == null
        ? ShopConfig.defaults()
        : StoreSettings.fromJson(
            _decode(raw),
            ShopConfig.defaults(),
          );
  }

  final SharedPreferences _prefs;
  static const String _key = 'bh.settings';
  late StoreSettings _current;
  final StreamController<StoreSettings> _changes =
      StreamController<StoreSettings>.broadcast();

  static Json _decode(String raw) {
    try {
      return jsonDecodeMap(raw);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  @override
  Future<StoreSettings> get() async => _current;

  @override
  Stream<StoreSettings> watch() {
    late StreamController<StoreSettings> out;
    StreamSubscription<StoreSettings>? sub;
    out = StreamController<StoreSettings>(
      onListen: () {
        out.add(_current);
        sub = _changes.stream.listen(out.add);
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }

  @override
  Future<void> save(StoreSettings settings) async {
    _current = settings;
    await _prefs.setString(_key, jsonEncodeMap(settings.toJson()));
    _changes.add(settings);
  }

  Future<void> reset() async {
    await _prefs.remove(_key);
    _current = ShopConfig.defaults();
    _changes.add(_current);
  }
}

class LocalFinanceRepository implements FinanceRepository {
  LocalFinanceRepository(this._costs, this._entries);
  final LocalCollection<CostEntry> _costs;
  final LocalCollection<FinanceEntry> _entries;

  @override
  Future<List<CostEntry>> costs() async => _costs.all;
  @override
  Stream<List<CostEntry>> watchCosts() => _costs.watch();
  @override
  Future<void> saveCost(CostEntry cost) => _costs.put(cost);
  @override
  Future<List<FinanceEntry>> entries() async => _entries.all;
  @override
  Stream<List<FinanceEntry>> watchEntries() => _entries.watch();
  @override
  Future<FinanceEntry?> entry(String id) async => _entries.get(id);
  @override
  Future<void> saveEntry(FinanceEntry entry) => _entries.put(entry);
}

/// Every repository the app uses, built over one [SharedPreferences].
class Repositories {
  Repositories._({
    required this.prefs,
    required this.catalog,
    required this.orders,
    required this.plans,
    required this.users,
    required this.leads,
    required this.repairs,
    required this.offers,
    required this.settings,
    required this.finance,
    required List<LocalCollection<dynamic>> collections,
  }) : _collections = collections;

  final SharedPreferences prefs;
  final CatalogRepository catalog;
  final OrderRepository orders;
  final PlanRepository plans;
  final UserRepository users;
  final LeadRepository leads;
  final RepairRepository repairs;
  final OfferRepository offers;
  final SettingsRepository settings;
  final FinanceRepository finance;
  final List<LocalCollection<dynamic>> _collections;

  /// The offline set: everything on this device.
  factory Repositories.local(SharedPreferences prefs) {
    final LocalCollection<Product> products = LocalCollection<Product>(
      prefs: prefs,
      name: 'products',
      fromJson: Product.fromJson,
      toJson: (Product p) => p.toJson(),
      idOf: (Product p) => p.id,
    );
    final LocalCollection<Order> orders = LocalCollection<Order>(
      prefs: prefs,
      name: 'orders',
      fromJson: Order.fromJson,
      toJson: (Order o) => o.toJson(),
      idOf: (Order o) => o.id,
    );
    final LocalCollection<EmiPlan> plans = LocalCollection<EmiPlan>(
      prefs: prefs,
      name: 'plans',
      fromJson: EmiPlan.fromJson,
      toJson: (EmiPlan p) => p.toJson(),
      idOf: (EmiPlan p) => p.id,
    );
    final LocalCollection<AppUser> users = LocalCollection<AppUser>(
      prefs: prefs,
      name: 'users',
      fromJson: AppUser.fromJson,
      toJson: (AppUser u) => u.toJson(),
      idOf: (AppUser u) => u.id,
    );
    final LocalCollection<Lead> leads = LocalCollection<Lead>(
      prefs: prefs,
      name: 'leads',
      fromJson: Lead.fromJson,
      toJson: (Lead l) => l.toJson(),
      idOf: (Lead l) => l.id,
    );
    final LocalCollection<RepairTicket> repairs = LocalCollection<RepairTicket>(
      prefs: prefs,
      name: 'repairs',
      fromJson: RepairTicket.fromJson,
      toJson: (RepairTicket t) => t.toJson(),
      idOf: (RepairTicket t) => t.id,
    );
    final LocalCollection<Offer> offers = LocalCollection<Offer>(
      prefs: prefs,
      name: 'offers',
      fromJson: Offer.fromJson,
      toJson: (Offer o) => o.toJson(),
      idOf: (Offer o) => o.id,
    );
    final LocalCollection<CostEntry> costs = LocalCollection<CostEntry>(
      prefs: prefs,
      name: 'costs',
      fromJson: CostEntry.fromJson,
      toJson: (CostEntry c) => c.toJson(),
      idOf: (CostEntry c) => c.productId,
    );
    final LocalCollection<FinanceEntry> entries = LocalCollection<FinanceEntry>(
      prefs: prefs,
      name: 'finance',
      fromJson: FinanceEntry.fromJson,
      toJson: (FinanceEntry e) => e.toJson(),
      idOf: (FinanceEntry e) => e.id,
    );
    return Repositories._(
      prefs: prefs,
      catalog: LocalCatalogRepository(products),
      orders: LocalOrderRepository(orders),
      plans: LocalPlanRepository(plans),
      users: LocalUserRepository(users),
      leads: LocalLeadRepository(leads),
      repairs: LocalRepairRepository(repairs),
      offers: LocalOfferRepository(offers),
      settings: LocalSettingsRepository(prefs),
      finance: LocalFinanceRepository(costs, entries),
      collections: <LocalCollection<dynamic>>[
        products, orders, plans, users, leads, repairs, offers, costs, entries,
      ],
    );
  }

  /// Wipes every offline collection (demo reset, or tests).
  Future<void> wipeLocal() async {
    for (final LocalCollection<dynamic> c in _collections) {
      await c.clear();
    }
    final SettingsRepository s = settings;
    if (s is LocalSettingsRepository) await s.reset();
  }
}

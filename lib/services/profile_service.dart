import '../core/ids.dart';
import '../core/permissions.dart';
import '../core/validators.dart';
import '../data/repositories.dart';
import '../domain/address.dart';
import '../domain/app_user.dart';
import 'clock.dart';
import 'guard.dart';

/// The customer's own account, and the owner's staff roster.
class ProfileService {
  ProfileService(this.repos, {this.clock = systemClock});

  final Repositories repos;
  final Clock clock;

  Future<AppUser> rename(AppUser user, String name) async {
    final AppUser next = user.copyWith(name: name.trim());
    await repos.users.save(next);
    return next;
  }

  Future<AppUser> saveAddress(AppUser user, Address address) async {
    final List<Address> list = <Address>[
      for (final Address a in user.addresses)
        if (a.id != address.id) a,
    ];
    // The newest edited address becomes the default (first).
    list.insert(0, address);
    final AppUser next = user.copyWith(addresses: list);
    await repos.users.save(next);
    return next;
  }

  Future<AppUser> removeAddress(AppUser user, String addressId) async {
    final AppUser next = user.copyWith(
      addresses: user.addresses.where((Address a) => a.id != addressId).toList(),
    );
    await repos.users.save(next);
    return next;
  }

  Future<AppUser> toggleWishlist(AppUser user, String productId) async {
    final List<String> list = List<String>.of(user.wishlist);
    if (!list.remove(productId)) list.insert(0, productId);
    final AppUser next = user.copyWith(wishlist: list);
    await repos.users.save(next);
    return next;
  }

  // ---- Staff roster (owner only) ----------------------------------------

  /// Gives a phone number a role. If the person has never opened the app, the
  /// account is created now and they take the role when they first sign in.
  Future<AppUser> setRole(
    AppUser? actor,
    String phone,
    AppRole role, {
    String name = '',
  }) async {
    requirePermission(actor, Permission.manageStaff);
    final String? p = Validators.mobile(phone);
    if (p == null) throw ShopException('badPhone');
    if (!RolePolicy.assignable.contains(role) && role != AppRole.customer) {
      throw ShopException('badRole');
    }
    AppUser? u = await repos.users.byPhone(p);
    if (u != null && u.id == actor!.id && role != AppRole.owner) {
      // An owner cannot demote themselves out of the shop.
      if (await _ownerCount() <= 1) throw ShopException('lastOwner');
    }
    if (u != null && u.role == AppRole.owner && role != AppRole.owner) {
      if (await _ownerCount() <= 1) throw ShopException('lastOwner');
    }
    u ??= AppUser(
      id: newId('u'),
      phone: p,
      name: name.trim(),
      createdAt: clock(),
      referralCode: newReferralCode(),
      invited: true,
    );
    final AppUser next = u.copyWith(
      role: role,
      name: u.name.isEmpty ? name.trim() : u.name,
      active: true,
    );
    await repos.users.save(next);
    return next;
  }

  Future<AppUser> setActive(AppUser? actor, AppUser target, bool active) async {
    requirePermission(actor, Permission.manageStaff);
    if (!active && target.role == AppRole.owner && await _ownerCount() <= 1) {
      throw ShopException('lastOwner');
    }
    if (target.id == actor!.id && !active) throw ShopException('lastOwner');
    final AppUser next = target.copyWith(active: active);
    await repos.users.save(next);
    return next;
  }

  Future<int> _ownerCount() async => (await repos.users.all())
      .where((AppUser u) => u.role == AppRole.owner && u.active)
      .length;
}

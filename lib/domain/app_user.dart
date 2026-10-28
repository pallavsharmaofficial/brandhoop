import 'package:equatable/equatable.dart';

import '../core/json.dart';
import '../core/permissions.dart';
import 'address.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.phone,
    this.name = '',
    this.role = AppRole.customer,
    this.active = true,
    required this.createdAt,
    this.addresses = const <Address>[],
    this.wishlist = const <String>[],
    this.referralCode = '',
    this.referredBy,
    this.coins = 0,
    this.invited = false,
  });

  final String id;

  /// Ten digits, no country code. The phone is the account.
  final String phone;
  final String name;
  final AppRole role;
  final bool active;
  final DateTime createdAt;
  final List<Address> addresses;
  final List<String> wishlist;
  final String referralCode;
  final String? referredBy;

  /// Brandhoop Coins: one coin is one rupee off accessories.
  final int coins;

  /// Created by the shop at the counter before the customer ever opened the app.
  final bool invited;

  bool get isStaff => RolePolicy.isStaff(role);
  bool can(Permission p) => active && RolePolicy.can(role, p);

  String get displayName => name.trim().isEmpty ? phone : name.trim();

  Address? get defaultAddress => addresses.isEmpty ? null : addresses.first;

  AppUser copyWith({
    String? name,
    AppRole? role,
    bool? active,
    List<Address>? addresses,
    List<String>? wishlist,
    String? referralCode,
    String? referredBy,
    int? coins,
    bool? invited,
  }) =>
      AppUser(
        id: id,
        phone: phone,
        name: name ?? this.name,
        role: role ?? this.role,
        active: active ?? this.active,
        createdAt: createdAt,
        addresses: addresses ?? this.addresses,
        wishlist: wishlist ?? this.wishlist,
        referralCode: referralCode ?? this.referralCode,
        referredBy: referredBy ?? this.referredBy,
        coins: coins ?? this.coins,
        invited: invited ?? this.invited,
      );

  Json toJson() => <String, dynamic>{
        'id': id,
        'phone': phone,
        'name': name,
        'role': role.name,
        'active': active,
        'createdAt': isoOrNull(createdAt),
        'addresses': addresses.map((Address a) => a.toJson()).toList(),
        'wishlist': wishlist,
        'referralCode': referralCode,
        'referredBy': referredBy,
        'coins': coins,
        'invited': invited,
      };

  factory AppUser.fromJson(Json j) => AppUser(
        id: j.str('id'),
        phone: j.str('phone'),
        name: j.str('name'),
        role: j.pick(
          'role',
          AppRole.values,
          AppRole.customer,
        ),
        active: j.flag('active', true),
        createdAt: j.time('createdAt') ?? DateTime.now(),
        addresses: j.list('addresses').map(Address.fromJson).toList(),
        wishlist: j.strings('wishlist'),
        referralCode: j.str('referralCode'),
        referredBy: j.strOrNull('referredBy'),
        coins: j.integer('coins'),
        invited: j.flag('invited'),
      );

  @override
  List<Object?> get props => <Object?>[
        id, phone, name, role, active, createdAt, addresses, wishlist,
        referralCode, referredBy, coins, invited,
      ];
}

import 'package:shared_preferences/shared_preferences.dart';

import '../core/ids.dart';
import '../core/permissions.dart';
import '../core/validators.dart';
import '../data/repositories.dart';
import '../domain/app_user.dart';
import 'clock.dart';
import 'guard.dart';

/// Sign-in by mobile number and a one-time code, which is how every customer
/// in India already signs in to everything.
abstract class AuthService {
  Future<void> sendOtp(String phone);
  Future<AppUser> verifyOtp(String phone, String code, {String? referralCode});
  Future<AppUser?> restore();
  Future<void> signOut();
}

/// The offline implementation. The code is always [demoCode]. It exists so the
/// app can be tried end to end; a build for real customers must use a server
/// that texts a real code (Firebase Phone Auth, docs/BACKEND.md).
class LocalAuthService implements AuthService {
  LocalAuthService(this._users, this._prefs, {Clock clock = systemClock})
      : _clock = clock;

  static const String demoCode = '123456';
  static const String _sessionKey = 'bh.session';

  final UserRepository _users;
  final SharedPreferences _prefs;
  final Clock _clock;

  @override
  Future<void> sendOtp(String phone) async {
    if (Validators.mobile(phone) == null) throw ShopException('badPhone');
  }

  @override
  Future<AppUser> verifyOtp(
    String phone,
    String code, {
    String? referralCode,
  }) async {
    final String? p = Validators.mobile(phone);
    if (p == null) throw ShopException('badPhone');
    if (code.trim() != demoCode) throw ShopException('badOtp');
    AppUser? user = await _users.byPhone(p);
    if (user != null && !user.active) throw ShopException('accountDisabled');
    if (user == null) {
      String? referrer;
      if (referralCode != null && referralCode.trim().isNotEmpty) {
        final AppUser? r = await _users.byReferralCode(referralCode);
        if (r != null && r.phone != p) referrer = r.id;
      }
      user = AppUser(
        id: newId('u'),
        phone: p,
        createdAt: _clock(),
        referralCode: newReferralCode(),
        referredBy: referrer,
      );
      await _users.save(user);
    } else if (user.referralCode.isEmpty) {
      user = user.copyWith(referralCode: newReferralCode());
      await _users.save(user);
    }
    await _prefs.setString(_sessionKey, user.id);
    return user;
  }

  @override
  Future<AppUser?> restore() async {
    final String? id = _prefs.getString(_sessionKey);
    if (id == null) return null;
    final AppUser? u = await _users.get(id);
    return (u != null && u.active) ? u : null;
  }

  @override
  Future<void> signOut() => _prefs.remove(_sessionKey);

  /// Demo only: sign straight in as an existing account (the quick-login chips).
  Future<AppUser?> signInAs(String userId) async {
    final AppUser? u = await _users.get(userId);
    if (u == null) return null;
    await _prefs.setString(_sessionKey, u.id);
    return u;
  }
}

extension AppUserRoleLabel on AppRole {
  bool get isCustomer => this == AppRole.customer;
}

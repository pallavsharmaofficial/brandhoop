import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/permissions.dart';
import '../data/repositories.dart';
import '../domain/app_user.dart';
import '../services/auth_service.dart';

/// Which half of the one app a signed-in person is looking at. Customers only
/// ever have [customer]; staff and the owner can switch between the two.
enum AppMode { customer, admin }

class SessionState extends Equatable {
  const SessionState({this.user, this.mode = AppMode.customer, this.ready = false});

  final AppUser? user;
  final AppMode mode;

  /// False until the saved sign-in has been looked up.
  final bool ready;

  bool get signedIn => user != null;
  bool get isStaff => user?.isStaff ?? false;
  bool get inAdmin => isStaff && mode == AppMode.admin;
  AppRole get role => user?.role ?? AppRole.customer;
  bool can(Permission p) => user?.can(p) ?? false;

  @override
  List<Object?> get props => <Object?>[user, mode, ready];
}

class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._auth, this._users, this._prefs) : super(const SessionState());

  static const String _modeKey = 'bh.mode';

  final AuthService _auth;
  final UserRepository _users;
  final SharedPreferences _prefs;
  StreamSubscription<AppUser?>? _watch;

  Future<void> restore() async {
    final AppUser? u = await _auth.restore();
    _attach(u, ready: true);
  }

  void _attach(AppUser? u, {bool ready = true}) {
    _watch?.cancel();
    _watch = null;
    if (u == null) {
      emit(SessionState(ready: ready));
      return;
    }
    final AppMode saved = _prefs.getString(_modeKey) == 'customer'
        ? AppMode.customer
        : AppMode.admin;
    emit(SessionState(
      user: u,
      mode: u.isStaff ? saved : AppMode.customer,
      ready: ready,
    ));
    // Keep coins, wishlist, addresses and role live, so a role the owner
    // changes (or a switched-off account) takes effect at once.
    _watch = _users.watchOne(u.id).listen((AppUser? fresh) {
      if (isClosed) return;
      if (fresh == null || !fresh.active) {
        unawaited(signOut());
        return;
      }
      emit(SessionState(
        user: fresh,
        mode: fresh.isStaff ? state.mode : AppMode.customer,
        ready: true,
      ));
    });
  }

  void signedInAs(AppUser u) => _attach(u);

  Future<void> signOut() async {
    await _auth.signOut();
    _attach(null);
  }

  Future<void> setMode(AppMode mode) async {
    if (!state.isStaff && mode == AppMode.admin) return;
    await _prefs.setString(_modeKey, mode.name);
    emit(SessionState(user: state.user, mode: mode, ready: true));
  }

  @override
  Future<void> close() async {
    await _watch?.cancel();
    return super.close();
  }
}

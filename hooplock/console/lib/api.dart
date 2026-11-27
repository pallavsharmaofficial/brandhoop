import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'demo/demo_backend.dart';

/// Practice build (--dart-define=HOOPLOCK_DEMO=true): runs with a built-in sample shop until the user
/// connects it to a real server from the sign-in screen.
const kDemoBuild = bool.fromEnvironment('HOOPLOCK_DEMO');

/// Server chosen on the sign-in screen (saved on the device), if any.
String? savedServer;

/// True while the app uses the built-in sample shop.
bool get kDemo => kDemoBuild && (savedServer == null || savedServer!.isEmpty);

/// Server address. On the website it is the same origin; for the phone app pass
/// --dart-define=API_BASE=https://your-server
const _apiBaseDefine = String.fromEnvironment('API_BASE');

String get apiBase {
  if (savedServer != null && savedServer!.isNotEmpty) return savedServer!;
  if (_apiBaseDefine.isNotEmpty) return _apiBaseDefine;
  if (kIsWeb) return Uri.base.origin;
  return 'http://10.0.2.2:8080';
}

class ApiError implements Exception {
  ApiError(this.status, this.message);
  final int status;
  final String message;
  @override
  String toString() => message;
}

class SessionUser {
  SessionUser(this.raw);
  final Map<String, dynamic> raw;
  String get id => raw['id'] as String;
  String get name => (raw['name'] ?? '') as String;
  String get phone => (raw['phone'] ?? '') as String;
  String get role => raw['role'] as String;
  String? get merchantId => raw['merchantId'] as String?;
  String get merchantName => (raw['merchantName'] ?? '') as String;
  bool get isSuperAdmin => role == 'super_admin';
  bool get isOwner => role == 'owner' || isSuperAdmin;
}

/// Holds the login and talks to the HoopLock API.
class Api extends ChangeNotifier {
  Api._();
  static final Api I = Api._();

  String? _token;
  SessionUser? user;

  /// Super admin can open any shop; this is the shop being viewed.
  String? actingMerchantId;
  String? actingMerchantName;

  bool get signedIn => _token != null && user != null;
  String? get merchantId => user?.isSuperAdmin == true ? actingMerchantId : user?.merchantId;
  String get shopName => user?.isSuperAdmin == true ? (actingMerchantName ?? 'HoopLock Admin') : (user?.merchantName ?? '');
  String? get token => _token;

  Future<void> restore() async {
    final p = await SharedPreferences.getInstance();
    savedServer = p.getString('server');
    _token = p.getString('token');
    final u = p.getString('user');
    if (_token != null && u != null) {
      user = SessionUser(jsonDecode(u) as Map<String, dynamic>);
      actingMerchantId = p.getString('acting_mid');
      actingMerchantName = p.getString('acting_name');
      try {
        final me = await get('/api/me');
        user = SessionUser({...user!.raw, ...me as Map<String, dynamic>});
      } on ApiError catch (e) {
        if (e.status == 401) await logout();
      } catch (_) {/* offline: keep session */}
    }
    notifyListeners();
  }

  Future<void> login(String phone, String password) async {
    final r = (kDemo
        ? await DemoBackend.I.handle('POST', '/api/auth/login', null, {'phone': phone, 'password': password}, null, null)
        : await _send(() => http.post(uri('/api/auth/login'), headers: headers(auth: false), body: jsonEncode({'phone': phone, 'password': password})))) as Map<String, dynamic>;
    _token = r['token'] as String;
    user = SessionUser(r['user'] as Map<String, dynamic>);
    final p = await SharedPreferences.getInstance();
    await p.setString('token', _token!);
    await p.setString('user', jsonEncode(user!.raw));
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    user = null;
    actingMerchantId = null;
    final p = await SharedPreferences.getInstance();
    for (final k in ['token', 'user', 'acting_mid', 'acting_name']) {
      await p.remove(k);
    }
    notifyListeners();
  }

  /// Connects the app to a HoopLock server (checks it answers first). null = back to practice mode.
  Future<void> setServer(String? url) async {
    final p = await SharedPreferences.getInstance();
    if (url == null || url.trim().isEmpty) {
      await logout();
      savedServer = null;
      await p.remove('server');
      notifyListeners();
      return;
    }
    var u = url.trim();
    if (!u.startsWith('http')) u = 'https://$u';
    u = u.replaceAll(RegExp(r'/+$'), '');
    try {
      final r = await http.get(Uri.parse('$u/healthz')).timeout(const Duration(seconds: 15));
      if (r.statusCode != 200 || !r.body.contains('ok')) throw Exception();
    } catch (_) {
      throw ApiError(0, 'No HoopLock server answered at $u');
    }
    await logout();
    savedServer = u;
    await p.setString('server', u);
    notifyListeners();
  }

  Future<void> actAs(String? merchantId, String? name) async {
    actingMerchantId = merchantId;
    actingMerchantName = name;
    final p = await SharedPreferences.getInstance();
    if (merchantId == null) {
      await p.remove('acting_mid');
      await p.remove('acting_name');
    } else {
      await p.setString('acting_mid', merchantId);
      await p.setString('acting_name', name ?? '');
    }
    notifyListeners();
  }

  Map<String, String> headers({bool auth = true}) => {
        'content-type': 'application/json',
        if (auth && _token != null) 'authorization': 'Bearer $_token',
        if (user?.isSuperAdmin == true && actingMerchantId != null) 'x-merchant-id': actingMerchantId!,
      };

  Uri uri(String path, [Map<String, dynamic>? query]) {
    final q = query?.map((k, v) => MapEntry(k, '$v'));
    return Uri.parse('$apiBase$path').replace(queryParameters: (q == null || q.isEmpty) ? null : q);
  }

  Future<dynamic> _demo(String method, String path, Map<String, dynamic>? query, Object? body) async {
    try {
      return await DemoBackend.I.handle(method, path, query, body, _token, actingMerchantId);
    } on ApiError catch (e) {
      if (e.status == 401) await logout();
      rethrow;
    }
  }

  Future<dynamic> get(String path, [Map<String, dynamic>? query]) => kDemo
      ? _demo('GET', path, query, null)
      : _send(() => http.get(uri(path, query), headers: headers()));

  Future<dynamic> post(String path, [Object? body]) => kDemo
      ? _demo('POST', path, null, body ?? {})
      : _send(() => http.post(uri(path), headers: headers(), body: jsonEncode(body ?? {})));

  Future<dynamic> patch(String path, Object body) =>
      kDemo ? _demo('PATCH', path, null, body) : _send(() => http.patch(uri(path), headers: headers(), body: jsonEncode(body)));

  Future<dynamic> put(String path, Object body) =>
      kDemo ? _demo('PUT', path, null, body) : _send(() => http.put(uri(path), headers: headers(), body: jsonEncode(body)));

  Future<dynamic> _send(Future<http.Response> Function() f) async {
    http.Response r;
    try {
      r = await f().timeout(const Duration(seconds: 25));
    } catch (_) {
      throw ApiError(0, 'No internet or server not reachable');
    }
    final body = r.body.isEmpty ? null : (r.headers['content-type']?.contains('json') == true ? jsonDecode(r.body) : r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    final msg = body is Map ? (body['message'] ?? 'Error ${r.statusCode}') : 'Error ${r.statusCode}';
    if (r.statusCode == 401 && _token != null && !r.request!.url.path.endsWith('/login')) {
      await logout();
    }
    throw ApiError(r.statusCode, '$msg');
  }
}

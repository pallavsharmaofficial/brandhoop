import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';

/// Practice mode: a complete HoopLock "server" inside the app, with a sample shop.
/// Same rules as the real server (lock only when overdue unless theft, auto-unlock on payment,
/// release only when paid). Nothing leaves the device; no real phone is controlled.
class DemoBackend {
  DemoBackend._();
  static final DemoBackend I = DemoBackend._();

  static const _key = 'hooplock_demo_v1';
  Map<String, dynamic> db = {};
  bool _loaded = false;
  final _rnd = Random();

  Future<void> _load() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key);
    db = s == null ? _seed() : jsonDecode(s) as Map<String, dynamic>;
    _loaded = true;
    await _save();
  }

  Future<void> _save() async => (await SharedPreferences.getInstance()).setString(_key, jsonEncode(db));

  Future<void> reset() async {
    db = _seed();
    await _save();
  }

  // ---------------- helpers ----------------
  String _id() => List.generate(4, (_) => _rnd.nextInt(0x10000).toRadixString(16).padLeft(4, '0')).join() +
      '-${_rnd.nextInt(0x10000).toRadixString(16).padLeft(4, '0')}-4${_rnd.nextInt(0x1000).toRadixString(16).padLeft(3, '0')}-a${_rnd.nextInt(0x1000).toRadixString(16).padLeft(3, '0')}-${List.generate(3, (_) => _rnd.nextInt(0x10000).toRadixString(16).padLeft(4, '0')).join()}';
  String _now() => DateTime.now().toUtc().toIso8601String();
  String _today() => DateTime.now().toIso8601String().substring(0, 10);
  String _addMonths(String iso, int m) {
    final d = DateTime.parse(iso);
    final first = DateTime(d.year, d.month + m, 1);
    final last = DateTime(first.year, first.month + 1, 0).day;
    return DateTime(first.year, first.month, min(d.day, last)).toIso8601String().substring(0, 10);
  }

  int _days(String from, String to) => DateTime.parse(to).difference(DateTime.parse(from)).inDays;

  List<Map<String, dynamic>> t(String name) => (db[name] as List).cast<Map<String, dynamic>>();
  Map<String, dynamic>? find(String table, bool Function(Map<String, dynamic>) f) {
    for (final r in t(table)) {
      if (f(r)) return r;
    }
    return null;
  }

  Never _err(int code, String msg) => throw ApiError(code, msg);

  void _audit(String? mid, String? uid, String action, [String target = '', Map<String, dynamic> data = const {}]) =>
      t('audit').insert(0, {'id': t('audit').length + 1, 'merchantId': mid, 'userId': uid, 'action': action, 'target': target, 'data': data, 'at': _now()});

  Map<String, dynamic>? _summary(String deviceId) {
    final loan = find('loans', (l) => l['deviceId'] == deviceId);
    if (loan == null) return null;
    final inst = t('instalments').where((i) => i['loanId'] == loan['id']).toList()..sort((a, b) => (a['seq'] as int).compareTo(b['seq'] as int));
    final today = _today();
    var paidCount = 0;
    num paidTotal = 0, balance = 0, overdue = 0;
    var overdueCount = 0;
    String? oldest;
    Map<String, dynamic>? next;
    for (final i in inst) {
      paidTotal += i['paidAmount'] as num;
      if (i['paidAt'] != null) { paidCount++; continue; }
      final rem = (i['amount'] as num) - (i['paidAmount'] as num);
      balance += rem;
      if ((i['dueDate'] as String).compareTo(today) < 0) { overdue += rem; overdueCount++; oldest ??= i['dueDate'] as String; }
      next ??= {'d': i['dueDate'], 'a': rem};
    }
    return {
      'loanId': loan['id'], 'status': loan['status'], 'paidCount': paidCount, 'emiCount': loan['emiCount'], 'paidTotal': paidTotal,
      'balance': balance, 'overdueAmount': overdue, 'overdueCount': overdueCount, 'overdueDays': oldest == null ? 0 : _days(oldest, today),
      'nextDueDate': next?['d'], 'nextDueAmount': next?['a'],
    };
  }

  // ---------------- request entry ----------------
  Future<dynamic> handle(String method, String path, Map<String, dynamic>? query, Object? body, String? token, String? actingMid) async {
    await _load();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final b = (body as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final q = query ?? <String, dynamic>{};
    if (method == 'POST' && path == '/api/auth/login') return _login(b);

    final user = token == null ? null : find('users', (u) => u['id'] == token.replaceFirst('demo:', ''));
    if (user == null || user['active'] != true) _err(401, 'Please sign in again');
    final isAdmin = user['role'] == 'super_admin';
    String mid() {
      final m = isAdmin ? (actingMid ?? q['merchantId'] as String?) : user['merchantId'] as String?;
      if (m == null) _err(400, 'Choose a shop first');
      return m;
    }
    void owner() { if (user['role'] == 'staff') _err(403, 'Only the owner can do this'); }

    final seg = path.split('/').where((s) => s.isNotEmpty).toList();
    final r = await _route(method, seg, q, b, user, isAdmin, mid, owner);
    await _save();
    return r;
  }

  Map<String, dynamic> _login(Map<String, dynamic> b) {
    final u = find('users', (u) => u['phone'] == b['phone'] && u['password'] == b['password']);
    if (u == null) _err(401, 'Wrong mobile number or password');
    final m = u['merchantId'] == null ? null : find('merchants', (m) => m['id'] == u['merchantId']);
    return {
      'token': 'demo:${u['id']}',
      'user': {'id': u['id'], 'role': u['role'], 'merchantId': u['merchantId'], 'name': u['name'], 'phone': u['phone'], 'merchantName': m?['name']},
    };
  }

  Future<dynamic> _route(String method, List<String> s, Map<String, dynamic> q, Map<String, dynamic> b, Map<String, dynamic> user, bool isAdmin,
      String Function() mid, void Function() owner) async {
    final uid = user['id'] as String;
    String p(int i) => s.length > i ? s[i] : '';

    // /api/me
    if (p(1) == 'me' && s.length == 2) {
      if (method == 'GET') {
        final m = find('merchants', (m) => m['id'] == user['merchantId']);
        return {'id': uid, 'name': user['name'], 'phone': user['phone'], 'role': user['role'], 'merchantId': user['merchantId'], 'merchantName': m?['name']};
      }
      if (b['phone'] != null && find('users', (u) => u['phone'] == b['phone'] && u['id'] != uid) != null) _err(400, 'This mobile number already has an account');
      if (b['name'] != null) user['name'] = b['name'];
      if (b['phone'] != null) user['phone'] = b['phone'];
      return {'ok': true};
    }
    if (p(1) == 'me' && p(2) == 'password') {
      if (user['password'] != b['current']) _err(400, 'Current password is wrong');
      if ((b['next'] as String).length < 8) _err(400, 'Use at least 8 characters');
      user['password'] = b['next'];
      return {'ok': true};
    }

    if (p(1) == 'dashboard') return _dashboard(mid());
    if (p(1) == 'customers' && s.length == 2) return _list(mid(), q);
    if (p(1) == 'customers' && s.length == 3 && method == 'PATCH') {
      final c = find('customers', (c) => c['id'] == p(2) && c['merchantId'] == mid()) ?? _err(404, 'Not found');
      for (final k in ['name', 'mobile', 'altMobile', 'address', 'notes']) { if (b[k] != null) c[k] = b[k]; }
      _audit(mid(), uid, 'customer.update', p(2));
      return {'ok': true};
    }
    if (p(1) == 'customers' && p(3) == 'photo') _err(400, 'Photos are not saved in practice mode');
    if (p(1) == 'sales' && s.length == 2) return _sale(mid(), uid, b);
    if (p(1) == 'devices' && s.length == 3) return _device(mid(), p(2));
    if (p(1) == 'devices') {
      final id = p(2);
      final d = find('devices', (d) => d['id'] == id && d['merchantId'] == mid()) ?? _err(404, 'Device not found');
      switch (p(3)) {
        case 'state':
          return _setState(d, b['state'] as String, b['reason'] as String? ?? 'overdue', b['message'] as String?, user);
        case 'enrollment':
          if (d['status'] != 'pending') _err(409, 'This phone is already enrolled');
          return _enrollment(id);
        case 'locate':
          if (d['status'] != 'active') _err(409, 'Phone is not active');
          if (d['platform'] == 'ios' && d['lockState'] != 'locked') _err(400, 'Apple allows locating an iPhone only while it is locked (Lost Mode)');
          _audit(mid(), uid, 'device.locate', id, {'reason': b['reason']});
          _addLocation(id, 'requested');
          return {'ok': true};
        case 'locations':
          return {'items': t('locations').where((l) => l['deviceId'] == id).toList()};
        case 'events':
          return {
            'events': t('events').where((e) => e['deviceId'] == id).toList(),
            'actions': t('audit').where((a) => a['target'] == id).map((a) => {...a, 'by': find('users', (u) => u['id'] == a['userId'])?['name']}).toList(),
          };
        case 'reminders':
          return {'items': t('reminders').where((r) => r['deviceId'] == id).toList()};
        case 'remind':
          final c = find('customers', (c) => c['id'] == d['customerId'])!;
          final sum = _summary(id);
          final text = (sum?['overdueAmount'] ?? 0) > 0
              ? 'Dear ${c['name']}, your EMI of Rs ${sum!['overdueAmount']} is overdue by ${sum['overdueDays']} days. Please pay at the shop.'
              : 'Dear ${c['name']}, your next EMI of Rs ${sum?['nextDueAmount']} is due on ${sum?['nextDueDate']}.';
          t('reminders').insert(0, {'id': t('reminders').length + 1, 'deviceId': id, 'kind': 'manual', 'channel': 'device', 'message': text, 'status': 'delivered', 'at': _now()});
          _audit(mid(), uid, 'device.remind', id);
          return {'ok': true, 'sms': 'logged', 'text': text};
        case 'payments':
          return _payment(d, (b['amount'] as num), b['method'] as String, b['ref'] as String? ?? '', user);
        case 'release':
          return _release(d, b['force'] == true, user);
        case 'mark-removed':
          owner();
          d['status'] = 'removed';
          _audit(mid(), uid, 'device.mark_removed', id);
          return {'ok': true};
        case 'offline-code':
          return {'state': d['lockState'], 'sms': _sms(d), 'smsTo': d['sim1Number']};
        case 'payment-link':
          _err(400, 'Online payment links need Razorpay on the live server');
        case 'simulate-scan':
          return _simulateScan(d);
      }
    }
    if (p(1) == 'merchant') {
      final m = find('merchants', (m) => m['id'] == mid()) ?? _err(404, 'Not found');
      if (method == 'GET') return {...m, 'settings': {..._defaultSettings, ...(m['settings'] as Map)}};
      owner();
      for (final k in ['name', 'ownerName', 'phone', 'city', 'address', 'callNumbers', 'upiId']) { if (b[k] != null) m[k] = b[k]; }
      if (b['settings'] != null) m['settings'] = {...(m['settings'] as Map), ...(b['settings'] as Map)};
      _audit(mid(), uid, 'merchant.update');
      return {'ok': true};
    }
    if (p(1) == 'staff') {
      owner();
      final m = mid();
      if (method == 'GET') return {'items': t('users').where((u) => u['merchantId'] == m).toList()};
      if (method == 'POST') {
        if (find('users', (u) => u['phone'] == b['phone']) != null) _err(409, 'This mobile number already has an account');
        if ((b['password'] as String? ?? '').length < 8) _err(400, 'Password: at least 8 characters');
        final id = _id();
        t('users').add({'id': id, 'merchantId': m, 'role': b['role'] ?? 'staff', 'name': b['name'], 'phone': b['phone'], 'password': b['password'], 'active': true, 'createdAt': _now()});
        return {'id': id};
      }
      final u = find('users', (u) => u['id'] == p(2) && u['merchantId'] == m) ?? _err(404, 'Not found');
      if (b['active'] != null) u['active'] = b['active'];
      return {'ok': true};
    }
    if (p(1) == 'keys') return {'items': t('keyLedger').where((k) => k['merchantId'] == mid()).toList()};
    if (p(1) == 'audit') {
      owner();
      return {'items': t('audit').where((a) => a['merchantId'] == mid()).map((a) => {...a, 'by': find('users', (u) => u['id'] == a['userId'])?['name']}).take(300).toList()};
    }
    if (p(1) == 'reports') return _report(mid(), q['from'] as String, q['to'] as String);
    if (p(1) == 'admin') {
      if (!isAdmin) _err(403, 'Only the admin can do this');
      return _admin(method, s, b, uid);
    }
    _err(404, 'Not available in practice mode');
  }

  static const _defaultSettings = {
    'remindDaysBefore': 3, 'autoWarnDays': 3, 'autoRestrictDays': 30, 'autoLockDays': null, 'lockRequiresOverdue': true,
    'autoUnlockOnPayment': true, 'noContactDays': 15, 'lockNeedsOwner': false, 'frpAccountIds': <String>[],
  };

  // ---------------- handlers ----------------
  Map<String, dynamic> _dashboard(String m) {
    final ds = t('devices').where((d) => d['merchantId'] == m).toList();
    bool recent(Map d) => d['lastSeenAt'] != null && DateTime.now().difference(DateTime.parse(d['lastSeenAt'] as String)).inDays < 3;
    final shop = find('merchants', (x) => x['id'] == m)!;
    num overdue = 0, week = 0;
    var overdueLoans = 0;
    final today = _today();
    final weekEnd = DateTime.now().add(const Duration(days: 7)).toIso8601String().substring(0, 10);
    for (final d in ds) {
      final loan = find('loans', (l) => l['deviceId'] == d['id']);
      if (loan == null || loan['status'] != 'open') continue;
      var od = false;
      for (final i in t('instalments').where((i) => i['loanId'] == loan['id'] && i['paidAt'] == null)) {
        final rem = (i['amount'] as num) - (i['paidAmount'] as num);
        final due = i['dueDate'] as String;
        if (due.compareTo(today) < 0) { overdue += rem; od = true; } else if (due.compareTo(weekEnd) <= 0) { week += rem; }
      }
      if (od) overdueLoans++;
    }
    final collected = t('audit').where((a) => a['merchantId'] == m && a['action'] == 'payment.record' && (a['at'] as String).startsWith(DateTime.now().toUtc().toIso8601String().substring(0, 10)))
        .fold<num>(0, (s, a) => s + ((a['data'] as Map)['applied'] as num? ?? 0));
    return {
      'shop': shop['name'],
      'keys': {'android': shop['androidKeys'], 'ios': shop['iosKeys']},
      'devices': {
        'total': ds.length,
        'active': ds.where((d) => d['status'] == 'active' && recent(d)).length,
        'inactive': ds.where((d) => d['status'] == 'active' && !recent(d)).length,
        'removed': ds.where((d) => d['status'] == 'removed').length,
        'pending': ds.where((d) => d['status'] == 'pending').length,
        'released': ds.where((d) => d['status'] == 'released').length,
        'locked': ds.where((d) => d['status'] == 'active' && d['lockState'] == 'locked').length,
        'restricted': ds.where((d) => d['status'] == 'active' && (d['lockState'] == 'warning' || d['lockState'] == 'restricted')).length,
      },
      'money': {'overdueAmount': overdue, 'overdueLoans': overdueLoans, 'dueThisWeek': week, 'collectedToday': collected},
    };
  }

  Map<String, dynamic> _row(Map<String, dynamic> d) {
    final c = find('customers', (c) => c['id'] == d['customerId'])!;
    final loan = find('loans', (l) => l['deviceId'] == d['id']);
    final s = _summary(d['id'] as String);
    final today = _today();
    String? oldest;
    if (loan != null) {
      final unpaid = t('instalments').where((i) => i['loanId'] == loan['id'] && i['paidAt'] == null && (i['dueDate'] as String).compareTo(today) < 0).toList();
      if (unpaid.isNotEmpty) oldest = unpaid.map((i) => i['dueDate'] as String).reduce((a, b) => a.compareTo(b) < 0 ? a : b);
    }
    return {
      'customerId': c['id'], 'name': c['name'], 'mobile': c['mobile'], 'hasPhoto': false, 'deviceId': d['id'], 'platform': d['platform'], 'status': d['status'],
      'lockState': d['lockState'], 'reportedState': d['reportedState'], 'brand': d['brand'], 'model': d['model'], 'imei1': d['imei1'], 'imei2': d['imei2'],
      'serial': d['serial'], 'sim1Number': d['sim1Number'], 'lastSeenAt': d['lastSeenAt'], 'createdAt': d['createdAt'], 'loanStatus': loan?['status'],
      'emiAmount': loan?['emiAmount'], 'nextDueDate': s?['nextDueDate'], 'nextDueAmount': s?['nextDueAmount'], 'overdueAmount': s?['overdueAmount'] ?? 0,
      'oldestOverdue': oldest, 'overdueDays': s?['overdueDays'] ?? 0,
    };
  }

  Map<String, dynamic> _list(String m, Map<String, dynamic> q) {
    final tab = q['tab'] ?? 'users';
    final search = (q['q'] as String? ?? '').toLowerCase();
    final status = q['status'] ?? 'all';
    final platform = q['platform'] ?? 'all';
    final limit = int.tryParse('${q['limit'] ?? 30}') ?? 30;
    final offset = int.tryParse('${q['offset'] ?? 0}') ?? 0;
    bool recent(Map d) => d['lastSeenAt'] != null && DateTime.now().difference(DateTime.parse(d['lastSeenAt'] as String)).inDays < 3;
    var rows = t('devices').where((d) => d['merchantId'] == m).map(_row).toList();
    if (search.isNotEmpty) {
      rows = rows.where((r) => [r['name'], r['mobile'], r['imei1'], r['imei2'], r['serial']].any((v) => '$v'.toLowerCase().contains(search))).toList();
    }
    if (platform != 'all') rows = rows.where((r) => r['platform'] == platform).toList();
    if (status != 'all') {
      rows = rows.where((r) => switch (status) {
            'active' => r['status'] == 'active' && recent(r),
            'inactive' => r['status'] == 'active' && !recent(r),
            'locked' => r['status'] == 'active' && r['lockState'] == 'locked',
            _ => r['status'] == status,
          }).toList();
    }
    final today = _today();
    final weekEnd = DateTime.now().add(const Duration(days: 7)).toIso8601String().substring(0, 10);
    if (tab == 'next_emi') {
      rows = rows.where((r) => r['loanStatus'] == 'open' && r['nextDueDate'] != null && (r['nextDueDate'] as String).compareTo(weekEnd) <= 0).toList()
        ..sort((a, b) => (a['nextDueDate'] as String).compareTo(b['nextDueDate'] as String));
    } else if (tab == 'high_risk') {
      rows = rows.where((r) => (r['status'] == 'active' || r['status'] == 'pending') && (r['oldestOverdue'] != null || r['lockState'] != 'unlocked' || (r['status'] == 'active' && !recent(r)))).toList()
        ..sort((a, b) => ((a['oldestOverdue'] ?? today) as String).compareTo((b['oldestOverdue'] ?? today) as String));
    } else {
      rows.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    }
    return {'items': rows.skip(offset).take(limit).toList()};
  }

  Map<String, dynamic> _sale(String m, String uid, Map<String, dynamic> b) {
    final c = (b['customer'] as Map).cast<String, dynamic>();
    final dv = ((b['device'] ?? {}) as Map).cast<String, dynamic>();
    final l = (b['loan'] as Map).cast<String, dynamic>();
    final platform = b['platform'] as String;
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch('${c['mobile']}')) _err(400, 'customer.mobile: Enter a 10-digit mobile number');
    if (((l['totalAmount'] as num) - (l['downPayment'] as num? ?? 0)) <= 0) _err(400, 'Down payment must be less than the total price');
    if (platform == 'ios' && '${dv['serial'] ?? ''}'.isEmpty) _err(400, 'Enter the iPhone serial number');
    final shop = find('merchants', (x) => x['id'] == m)!;
    if ((shop[platform == 'android' ? 'androidKeys' : 'iosKeys'] as int) <= 0) _err(400, 'No ${platform == 'android' ? 'Android' : 'iPhone'} keys left. Ask the admin to add keys.');
    final ids = _createSale(m, c, dv, l, platform);
    _audit(m, uid, 'sale.create', ids['deviceId']!, {'platform': platform, 'total': l['totalAmount']});
    return {...ids, 'enrollment': platform == 'android' ? _enrollment(ids['deviceId']!) : null};
  }

  Map<String, String> _createSale(String m, Map<String, dynamic> c, Map<String, dynamic> dv, Map<String, dynamic> l, String platform, {String? createdAt}) {
    final cid = _id(), did = _id(), lid = _id();
    final at = createdAt ?? _now();
    t('customers').add({'id': cid, 'merchantId': m, 'name': c['name'], 'mobile': c['mobile'], 'altMobile': c['altMobile'] ?? '', 'address': c['address'] ?? '',
      'idType': c['idType'] ?? '', 'idLast4': c['idLast4'] ?? '', 'notes': c['notes'] ?? '', 'createdAt': at});
    t('devices').add({'id': did, 'merchantId': m, 'customerId': cid, 'platform': platform, 'status': 'pending', 'lockState': 'unlocked', 'lockReason': '',
      'lockMessage': '', 'stateSeq': 1, 'reportedState': null, 'imei1': dv['imei1'] ?? '', 'imei2': dv['imei2'] ?? '', 'serial': dv['serial'] ?? '',
      'brand': platform == 'ios' ? 'Apple' : (dv['brand'] ?? ''), 'model': dv['model'] ?? '', 'osVersion': '', 'agentVersion': '', 'sim1Number': c['mobile'],
      'sim1Operator': '', 'sim2Number': '', 'sim2Operator': '', 'battery': null, 'lastSeenAt': null, 'enrolledAt': null, 'releasedAt': null, 'createdAt': at, 'changedAt': at});
    t('loans').add({'id': lid, 'deviceId': did, 'merchantId': m, 'totalAmount': l['totalAmount'], 'downPayment': l['downPayment'] ?? 0, 'emiAmount': l['emiAmount'],
      'emiCount': l['emiCount'], 'firstEmiDate': l['firstEmiDate'], 'loanRef': l['loanRef'] ?? '', 'notes': l['notes'] ?? '', 'status': 'open', 'consentAt': null, 'createdAt': at});
    for (var i = 0; i < (l['emiCount'] as int); i++) {
      t('instalments').add({'id': _id(), 'loanId': lid, 'seq': i + 1, 'dueDate': _addMonths(l['firstEmiDate'] as String, i), 'amount': l['emiAmount'], 'paidAmount': 0, 'paidAt': null, 'method': null, 'ref': null});
    }
    return {'customerId': cid, 'deviceId': did, 'loanId': lid};
  }

  Map<String, dynamic> _enrollment(String deviceId) => {
        'token': 'DEMO-${deviceId.substring(0, 8)}',
        'expiresAt': DateTime.now().toUtc().add(const Duration(minutes: 30)).toIso8601String(),
        'qr': jsonEncode({'practice': 'This is a practice QR. On the live system this QR installs HoopLock on the new phone.', 'device': deviceId}),
        'demo': true,
      };

  Map<String, dynamic> _simulateScan(Map<String, dynamic> d) {
    if (d['status'] != 'pending') return {'ok': true};
    final shop = find('merchants', (x) => x['id'] == d['merchantId'])!;
    final key = d['platform'] == 'android' ? 'androidKeys' : 'iosKeys';
    if ((shop[key] as int) <= 0) _err(402, 'The shop has no keys left');
    shop[key] = (shop[key] as int) - 1;
    t('keyLedger').insert(0, {'id': t('keyLedger').length + 1, 'merchantId': d['merchantId'], 'platform': d['platform'], 'delta': -1, 'reason': 'enroll', 'deviceId': d['id'],
      'customer': find('customers', (c) => c['id'] == d['customerId'])?['name'], 'at': _now()});
    _activate(d);
    _audit(d['merchantId'] as String, null, 'device.enrolled', d['id'] as String, {'model': d['model']});
    return {'ok': true};
  }

  void _activate(Map<String, dynamic> d, {String? at}) {
    final now = at ?? _now();
    d['status'] = 'active';
    d['enrolledAt'] = now;
    d['lastSeenAt'] = now;
    d['reportedState'] = 'unlocked';
    d['battery'] = 60 + _rnd.nextInt(40);
    d['agentVersion'] = '1.0.0';
    d['osVersion'] = d['platform'] == 'ios' ? '19.1' : '15';
    d['sim1Operator'] = ['airtel', 'Jio', 'Vi', 'BSNL'][_rnd.nextInt(4)];
    if ('${d['imei1']}'.isEmpty && d['platform'] == 'android') d['imei1'] = '86${List.generate(13, (_) => _rnd.nextInt(10)).join()}';
    final loan = find('loans', (l) => l['deviceId'] == d['id']);
    if (loan != null) loan['consentAt'] = now;
    t('events').insert(0, {'deviceId': d['id'], 'type': 'enrolled', 'data': {}, 'at': now});
    t('events').insert(0, {'deviceId': d['id'], 'type': 'consent', 'data': {}, 'at': now});
  }

  Map<String, dynamic> _device(String m, String id) {
    final d = find('devices', (d) => d['id'] == id && d['merchantId'] == m) ?? _err(404, 'Device not found');
    // The practice phone "applies" a change a few seconds later, like a real phone would.
    if (d['status'] == 'active') {
      if (DateTime.now().difference(DateTime.parse(d['changedAt'] as String)).inSeconds >= 4) d['reportedState'] = d['lockState'];
      if (DateTime.now().difference(DateTime.parse((d['lastSeenAt'] ?? d['createdAt']) as String)).inDays < 3) d['lastSeenAt'] = _now();
    }
    final c = find('customers', (c) => c['id'] == d['customerId'])!;
    final l = find('loans', (x) => x['deviceId'] == id)!;
    final locs = t('locations').where((x) => x['deviceId'] == id).toList();
    return {
      ...d,
      'push': true,
      'customer': {...c, 'hasPhoto': false},
      'loan': l,
      'instalments': t('instalments').where((i) => i['loanId'] == l['id']).toList()..sort((a, b) => (a['seq'] as int).compareTo(b['seq'] as int)),
      'summary': _summary(id),
      'lastLocation': locs.isEmpty ? null : locs.first,
    };
  }

  String _sms(Map<String, dynamic> d) {
    const codes = {'unlocked': 'U', 'warning': 'W', 'restricted': 'R', 'locked': 'L', 'released': 'X'};
    final st = d['status'] == 'released' ? 'released' : d['lockState'] as String;
    final sig = base64Url.encode(List.generate(16, (_) => _rnd.nextInt(256))).replaceAll('=', '');
    return 'HL1 ${d['stateSeq']} ${codes[st]} $sig';
  }

  Map<String, dynamic> _setState(Map<String, dynamic> d, String next, String reason, String? message, Map<String, dynamic> user) {
    if (d['status'] == 'released') _err(409, 'This phone is already released');
    if (d['status'] == 'removed') _err(409, 'The locker app is no longer on this phone');
    if (d['platform'] == 'ios') {
      if (next == 'warning' || next == 'restricted') _err(400, 'iPhones support Lock and Unlock only. Send a reminder instead.');
      if (d['status'] != 'active') _err(409, 'This iPhone has not enrolled yet');
    }
    const rank = {'unlocked': 0, 'warning': 1, 'restricted': 2, 'locked': 3};
    if (rank[next]! > rank[d['lockState']]!) {
      final shop = find('merchants', (x) => x['id'] == d['merchantId'])!;
      final s = {..._defaultSettings, ...(shop['settings'] as Map)};
      final sum = _summary(d['id'] as String);
      final emergency = reason == 'theft' || reason == 'tamper';
      if ((next == 'restricted' || next == 'locked') && s['lockRequiresOverdue'] == true && !emergency && (sum == null || (sum['overdueDays'] as int) <= 0)) {
        _err(400, 'No EMI is overdue. A lock is only allowed after a missed EMI (or for theft / tamper).');
      }
      if (next == 'locked' && s['lockNeedsOwner'] == true && user['role'] == 'staff') _err(403, 'Only the owner can fully lock a phone');
    }
    d['lockState'] = next;
    d['lockReason'] = next == 'unlocked' ? '' : reason;
    if (message != null) d['lockMessage'] = message;
    d['stateSeq'] = (d['stateSeq'] as int) + 1;
    d['changedAt'] = _now();
    _audit(d['merchantId'] as String, user['id'] as String?, 'device.$next', d['id'] as String, {'reason': reason, if (message != null) 'message': message});
    if (next == 'locked') _addLocation(d['id'] as String, 'locked');
    return {'seq': d['stateSeq'], 'sms': d['platform'] == 'ios' ? null : _sms(d), 'smsTo': d['sim1Number'], 'changed': true};
  }

  void _addLocation(String deviceId, String reason) {
    // Around Neem Ka Thana
    t('locations').insert(0, {'deviceId': deviceId, 'lat': 27.7337 + (_rnd.nextDouble() - .5) / 60, 'lng': 75.7846 + (_rnd.nextDouble() - .5) / 60,
      'accuracy': 10 + _rnd.nextInt(30), 'reason': reason, 'at': _now()});
  }

  Map<String, dynamic> _payment(Map<String, dynamic> d, num amount, String method, String ref, Map<String, dynamic> user) {
    final loan = find('loans', (l) => l['deviceId'] == d['id']) ?? _err(400, 'No loan for this phone');
    if (loan['status'] == 'closed') _err(409, 'This loan is already fully paid');
    var left = amount;
    for (final i in t('instalments').where((i) => i['loanId'] == loan['id'] && i['paidAt'] == null).toList()..sort((a, b) => (a['seq'] as int).compareTo(b['seq'] as int))) {
      if (left <= 0) break;
      final need = (i['amount'] as num) - (i['paidAmount'] as num);
      final pay = min(need, left);
      left -= pay;
      i['paidAmount'] = (i['paidAmount'] as num) + pay;
      i['method'] = method;
      i['ref'] = ref;
      if ((i['paidAmount'] as num) >= (i['amount'] as num)) i['paidAt'] = _now();
    }
    final applied = amount - left;
    final closed = t('instalments').where((i) => i['loanId'] == loan['id'] && i['paidAt'] == null).isEmpty;
    if (closed) loan['status'] = 'closed';
    _audit(d['merchantId'] as String, user['id'] as String?, 'payment.record', d['id'] as String, {'amount': amount, 'method': method, 'ref': ref, 'applied': applied});
    final sum = _summary(d['id'] as String)!;
    var unlocked = false;
    if (d['status'] == 'active' && d['lockState'] != 'unlocked' && d['lockReason'] != 'theft' && d['lockReason'] != 'tamper' && sum['overdueAmount'] == 0) {
      _setState(d, 'unlocked', 'paid', null, {'id': null, 'role': 'owner'});
      unlocked = true;
    }
    return {'applied': applied, 'closed': closed, 'unlocked': unlocked, 'summary': sum};
  }

  Map<String, dynamic> _release(Map<String, dynamic> d, bool force, Map<String, dynamic> user) {
    if (d['status'] == 'released') return {'sms': null};
    final sum = _summary(d['id'] as String);
    if (sum != null && sum['status'] != 'closed' && !force) _err(400, 'Loan still has ₹${sum['balance']} to pay. Close it first, or release anyway as owner.');
    if (force && user['role'] == 'staff') _err(403, 'Only the owner can release a phone with money still due');
    d['status'] = 'released';
    d['lockState'] = 'unlocked';
    d['releasedAt'] = _now();
    d['stateSeq'] = (d['stateSeq'] as int) + 1;
    t('events').insert(0, {'deviceId': d['id'], 'type': 'released', 'data': {}, 'at': _now()});
    _audit(d['merchantId'] as String, user['id'] as String?, 'device.release', d['id'] as String, {'force': force});
    return {
      'sms': d['platform'] == 'ios' ? null : _sms(d),
      if (d['platform'] == 'ios') 'appleBusinessManager': 'Also release this serial number from Apple Business Manager (Devices > Release).',
    };
  }

  Map<String, dynamic> _report(String m, String from, String to) {
    bool inRange(String? iso) => iso != null && iso.substring(0, 10).compareTo(from) >= 0 && iso.substring(0, 10).compareTo(to) <= 0;
    final a = t('audit').where((x) => x['merchantId'] == m && inRange(x['at'] as String));
    final loans = t('loans').where((l) => l['merchantId'] == m && inRange(l['createdAt'] as String));
    return {
      'enrolled': t('devices').where((d) => d['merchantId'] == m && inRange(d['enrolledAt'] as String?)).length,
      'sales': loans.length,
      'financed': loans.fold<num>(0, (s, l) => s + (l['totalAmount'] as num) - (l['downPayment'] as num)),
      'collected': a.where((x) => x['action'] == 'payment.record').fold<num>(0, (s, x) => s + ((x['data'] as Map)['applied'] as num? ?? 0)),
      'locks': a.where((x) => x['action'] == 'device.locked').length,
      'unlocks': a.where((x) => x['action'] == 'device.unlocked').length,
      'released': t('devices').where((d) => d['merchantId'] == m && inRange(d['releasedAt'] as String?)).length,
    };
  }

  Map<String, dynamic> _admin(String method, List<String> s, Map<String, dynamic> b, String uid) {
    if (s.length == 3 && method == 'GET') {
      return {
        'items': t('merchants').map((m) => {
              ...m,
              'devices': t('devices').where((d) => d['merchantId'] == m['id']).length,
              'activeDevices': t('devices').where((d) => d['merchantId'] == m['id'] && d['status'] == 'active').length,
            }).toList(),
      };
    }
    if (s.length == 3 && method == 'POST') {
      if (find('users', (u) => u['phone'] == b['phone']) != null) _err(409, 'This mobile number already has an account');
      final id = _id();
      t('merchants').add({'id': id, 'name': b['name'], 'ownerName': b['ownerName'] ?? '', 'phone': b['phone'], 'city': b['city'] ?? '', 'address': '', 'callNumbers': <String>[],
        'upiId': '', 'androidKeys': b['androidKeys'] ?? 0, 'iosKeys': b['iosKeys'] ?? 0, 'settings': {}, 'active': true, 'createdAt': _now()});
      t('users').add({'id': _id(), 'merchantId': id, 'role': 'owner', 'name': b['ownerName'] ?? b['name'], 'phone': b['phone'], 'password': b['ownerPassword'], 'active': true, 'createdAt': _now()});
      return {'id': id};
    }
    final m = find('merchants', (m) => m['id'] == s[3]) ?? _err(404, 'Shop not found');
    if (s.length == 5 && s[4] == 'keys') {
      final col = b['platform'] == 'android' ? 'androidKeys' : 'iosKeys';
      final n = (m[col] as int) + (b['count'] as int);
      if (n < 0) _err(400, 'Balance would go below zero');
      m[col] = n;
      t('keyLedger').insert(0, {'id': t('keyLedger').length + 1, 'merchantId': m['id'], 'platform': b['platform'], 'delta': b['count'], 'reason': b['reason'], 'deviceId': null, 'customer': null, 'at': _now()});
      return {'balance': n};
    }
    m['active'] = b['active'];
    return {'ok': true};
  }

  // ---------------- sample shop ----------------
  Map<String, dynamic> _seed() {
    db = {
      'merchants': <Map<String, dynamic>>[], 'users': <Map<String, dynamic>>[], 'customers': <Map<String, dynamic>>[], 'devices': <Map<String, dynamic>>[],
      'loans': <Map<String, dynamic>>[], 'instalments': <Map<String, dynamic>>[], 'locations': <Map<String, dynamic>>[], 'events': <Map<String, dynamic>>[],
      'reminders': <Map<String, dynamic>>[], 'audit': <Map<String, dynamic>>[], 'keyLedger': <Map<String, dynamic>>[],
    };
    final mid = _id();
    t('merchants').add({'id': mid, 'name': 'Brand Hoop Neem Ka Thana', 'ownerName': 'Shop Owner', 'phone': '9000000001', 'city': 'Neem Ka Thana',
      'address': 'Gate No. 5, Kamla Modi Market', 'callNumbers': <String>[], 'upiId': 'brandhoop@upi', 'androidKeys': 25, 'iosKeys': 3, 'settings': {}, 'active': true, 'createdAt': _now()});
    t('users').addAll([
      {'id': _id(), 'merchantId': null, 'role': 'super_admin', 'name': 'Admin', 'phone': '9999999999', 'password': 'demo1234', 'active': true, 'createdAt': _now()},
      {'id': _id(), 'merchantId': mid, 'role': 'owner', 'name': 'Shop Owner', 'phone': '9000000001', 'password': 'demo1234', 'active': true, 'createdAt': _now()},
      {'id': _id(), 'merchantId': mid, 'role': 'staff', 'name': 'Counter Staff', 'phone': '9000000003', 'password': 'demo1234', 'active': true, 'createdAt': _now()},
    ]);
    t('keyLedger').add({'id': 1, 'merchantId': mid, 'platform': 'android', 'delta': 30, 'reason': 'opening', 'deviceId': null, 'customer': null, 'at': _now()});
    final today = _today();
    final people = <List<dynamic>>[
      // name, mobile, brand, model, first EMI (months from now), paid EMIs, lock, days since enrolled
      ['Vikesh Kumar', '7023473415', 'Oppo', 'A6x 5G', -1, 0, 'warning', 30],
      ['Kana Malangar', '7378036240', 'Vivo', 'Y21 5G', -3, 0, 'locked', 95],
      ['Dinesh Saini', '9887778181', 'Realme', 'P4 5G', -2, 2, 'unlocked', 62],
      ['Sunita Devi', '9414000001', 'Samsung', 'Galaxy A26 5G', 1, 0, 'unlocked', 3],
      ['Ramesh Yadav', '9829100002', 'Redmi', 'Note 15 5G', -4, 4, 'unlocked', 120],
      ['Pooja Sharma', '9928300004', 'Vivo', 'T4 5G', 0, 0, 'unlocked', 25],
      ['Mahesh Gurjar', '9785400005', 'Oppo', 'K13x 5G', -2, 1, 'unlocked', 64],
    ];
    for (final p in people) {
      final created = DateTime.now().subtract(Duration(days: p[7] as int)).toUtc().toIso8601String();
      final ids = _createSale(mid, {'name': p[0], 'mobile': p[1], 'address': 'Neem Ka Thana'}, {'brand': p[2], 'model': p[3]},
          {'totalAmount': 21999, 'downPayment': 5999, 'emiAmount': 2700, 'emiCount': 6, 'firstEmiDate': _addMonths(today, p[4] as int)}, 'android', createdAt: created);
      final d = find('devices', (d) => d['id'] == ids['deviceId'])!;
      d['imei1'] = '86${List.generate(13, (_) => _rnd.nextInt(10)).join()}';
      d['imei2'] = '86${List.generate(13, (_) => _rnd.nextInt(10)).join()}';
      _activate(d, at: created);
      d['lastSeenAt'] = p[0] == 'Mahesh Gurjar' ? DateTime.now().subtract(const Duration(days: 6)).toUtc().toIso8601String() : _now();
      final inst = t('instalments').where((i) => i['loanId'] == ids['loanId']).toList();
      for (var i = 0; i < (p[5] as int); i++) {
        inst[i]['paidAmount'] = 2700;
        inst[i]['paidAt'] = _now();
        inst[i]['method'] = 'cash';
      }
      if (p[6] != 'unlocked') {
        d['lockState'] = p[6];
        d['reportedState'] = p[6];
        d['lockReason'] = 'overdue';
        d['lockMessage'] = 'Please pay your EMI at Brand Hoop';
        _addLocation(d['id'] as String, 'locked');
        _audit(mid, null, 'device.${p[6]}', d['id'] as String, {'reason': 'overdue'});
      }
    }
    // One sale waiting for the phone to be set up
    _createSale(mid, {'name': 'Anil Meena', 'mobile': '9636500006'}, {'brand': 'Samsung', 'model': 'Galaxy M36 5G'},
        {'totalAmount': 18999, 'downPayment': 4999, 'emiAmount': 2400, 'emiCount': 6, 'firstEmiDate': _addMonths(today, 1)}, 'android');
    return db;
  }
}

import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../i18n.dart';
import '../widgets.dart';

AppBar _bar(BuildContext context, String title, {List<Widget>? actions}) => AppBar(
      leading: IconButton(icon: const Icon(Icons.reply_rounded, color: brand, size: 32), onPressed: () => Navigator.pop(context)),
      title: Text(title),
      actions: actions,
    );

/// Generic "load JSON, show it" page.
class _Loader extends StatefulWidget {
  const _Loader({super.key, required this.load, required this.builder});
  final Future<dynamic> Function() load;
  final Widget Function(BuildContext, dynamic, VoidCallback reload) builder;
  @override
  State<_Loader> createState() => _LoaderState();
}

class _LoaderState extends State<_Loader> {
  dynamic _data;
  Object? _error;
  @override
  void initState() { super.initState(); _go(); }
  Future<void> _go() async {
    try {
      final d = await widget.load();
      if (mounted) setState(() { _data = d; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }
  @override
  Widget build(BuildContext context) =>
      _error != null ? ErrorRetry(_error!, _go) : _data == null ? const Loading() : RefreshIndicator(color: brand, onRefresh: _go, child: widget.builder(context, _data, _go));
}

// ---------------- Reports ----------------
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _range = 'month';
  (String, String) get _dates {
    final now = DateTime.now();
    String f(DateTime d) => d.toIso8601String().substring(0, 10);
    return switch (_range) {
      'today' => (f(now), f(now)),
      'week' => (f(now.subtract(const Duration(days: 6))), f(now)),
      'last_month' => (f(DateTime(now.year, now.month - 1, 1)), f(DateTime(now.year, now.month, 0))),
      _ => (f(DateTime(now.year, now.month, 1)), f(now)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (from, to) = _dates;
    return Scaffold(
      appBar: _bar(context, t('reports'), actions: [
        IconButton(tooltip: 'Export CSV', icon: const Icon(Icons.download), onPressed: () => launchUrl(Api.I.uri('/api/reports/devices.csv', {
              'access_token': Api.I.token, if (Api.I.actingMerchantId != null) 'merchantId': Api.I.actingMerchantId,
            }))),
      ]),
      body: PageBody(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(spacing: 8, children: [
              for (final r in const [('today', 'Today'), ('week', '7 days'), ('month', 'This month'), ('last_month', 'Last month')])
                ChoiceChip(label: Text(r.$2), selected: _range == r.$1, selectedColor: brand.withValues(alpha: .2), onSelected: (_) => setState(() => _range = r.$1)),
            ]),
          ),
          Expanded(
            child: _Loader(
              key: ValueKey(_range),
              load: () => Api.I.get('/api/reports/summary', {'from': from, 'to': to}),
              builder: (context, d, _) => ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
                Text('${dmy(from)} – ${dmy(to)}', style: const TextStyle(color: muted)),
                const SizedBox(height: 10),
                SoftCard(child: Column(children: [
                  PairRow('New EMI sales', '${d['sales']}', 'Phones enrolled', '${d['enrolled']}'),
                  PairRow('Amount financed', rupees(d['financed'] as num), 'EMI collected', rupees(d['collected'] as num)),
                  PairRow('Locks', '${d['locks']}', 'Unlocks', '${d['unlocks']}'),
                  PairRow('Phones released', '${d['released']}', '', ''),
                ])),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ---------------- Shop settings ----------------
class ShopSettingsScreen extends StatelessWidget {
  const ShopSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _bar(context, t('settings')),
        body: PageBody(child: _Loader(load: () => Api.I.get('/api/merchant'), builder: (context, d, reload) => _SettingsForm(d as Map<String, dynamic>))),
      );
}

class _SettingsForm extends StatefulWidget {
  const _SettingsForm(this.m);
  final Map<String, dynamic> m;
  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  late final name = TextEditingController(text: widget.m['name'] as String?);
  late final owner = TextEditingController(text: widget.m['ownerName'] as String?);
  late final phone = TextEditingController(text: widget.m['phone'] as String?);
  late final calls = TextEditingController(text: (widget.m['callNumbers'] as List).join(', '));
  late final upi = TextEditingController(text: widget.m['upiId'] as String?);
  late final address = TextEditingController(text: widget.m['address'] as String?);
  late final Map<String, dynamic> s = Map.of(widget.m['settings'] as Map<String, dynamic>);
  late final frp = TextEditingController(text: (s['frpAccountIds'] as List).join(', '));

  Widget _days(String key, String label, {bool nullable = true}) {
    final v = s[key];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(v == null ? 'Off' : '$v days'),
      trailing: SizedBox(
        width: 150,
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (nullable) Switch(value: v != null, activeTrackColor: brand, onChanged: (on) => setState(() => s[key] = on ? 30 : null)),
          if (v != null) IconButton(icon: const Icon(Icons.edit, color: brand), onPressed: () async {
            final c = TextEditingController(text: '$v');
            final r = await showDialog<int>(context: context, builder: (ctx) => AlertDialog(
              title: Text(label),
              content: TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(suffixText: 'days')),
              actions: [FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(100, 44)), onPressed: () => Navigator.pop(ctx, int.tryParse(c.text)), child: const Text('OK'))],
            ));
            if (r != null) setState(() => s[key] = r);
          }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final owner0 = Api.I.user!.isOwner;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Shop', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Shop name')),
      const SizedBox(height: 10),
      TextField(controller: owner, decoration: const InputDecoration(labelText: 'Owner name')),
      const SizedBox(height: 10),
      TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Shop owner mobile (shown on lock screen, always callable)')),
      const SizedBox(height: 10),
      TextField(controller: calls, decoration: const InputDecoration(labelText: 'Other numbers a locked phone may call (comma separated, max 3)')),
      const SizedBox(height: 10),
      TextField(controller: upi, decoration: const InputDecoration(labelText: 'UPI ID for the pay QR on the lock screen')),
      const SizedBox(height: 10),
      TextField(controller: address, maxLines: 2, decoration: const InputDecoration(labelText: 'Address')),
      const SizedBox(height: 24),
      const Text('Lock rules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const Text('Gradual steps follow the RBI device-loan rules: reminders first, then warning, then restriction. Calls to the shop and emergency calls always work.', style: TextStyle(color: muted)),
      _days('remindDaysBefore', 'Reminder before due date', nullable: false),
      _days('autoWarnDays', 'Auto warning after overdue'),
      _days('autoRestrictDays', 'Auto restrict apps after overdue'),
      _days('autoLockDays', 'Auto full lock after overdue'),
      _days('noContactDays', 'Restrict if phone is offline for', nullable: false),
      SwitchListTile(contentPadding: EdgeInsets.zero, activeTrackColor: brand, title: const Text('Lock only when an EMI is overdue'), subtitle: const Text('Theft / tamper locks are always allowed'),
          value: s['lockRequiresOverdue'] as bool, onChanged: (v) => setState(() => s['lockRequiresOverdue'] = v)),
      SwitchListTile(contentPadding: EdgeInsets.zero, activeTrackColor: brand, title: const Text('Unlock automatically when paid'),
          value: s['autoUnlockOnPayment'] as bool, onChanged: (v) => setState(() => s['autoUnlockOnPayment'] = v)),
      SwitchListTile(contentPadding: EdgeInsets.zero, activeTrackColor: brand, title: const Text('Only the owner can fully lock'),
          value: s['lockNeedsOwner'] as bool, onChanged: (v) => setState(() => s['lockNeedsOwner'] = v)),
      const SizedBox(height: 10),
      TextField(controller: frp, decoration: const InputDecoration(labelText: 'Factory-reset protection Google account IDs (advanced)', helperText: 'Numeric ID of the shop Google account. Phones flashed or reset will need this account to set up.')),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: !owner0 ? null : () async {
          final r = await busy(context, () => Api.I.patch('/api/merchant', {
                'name': name.text.trim(), 'ownerName': owner.text.trim(), 'phone': phone.text.trim(), 'address': address.text.trim(),
                'callNumbers': calls.text.split(RegExp(r'[,\s]+')).where((e) => e.isNotEmpty).toList(),
                'upiId': upi.text.trim(),
                'settings': {...s, 'frpAccountIds': frp.text.split(RegExp(r'[,\s]+')).where((e) => e.isNotEmpty).toList()},
              }), done: 'Saved');
          if (r != null && context.mounted) Navigator.pop(context);
        },
        child: Text(t('save')),
      ),
    ]);
  }
}

// ---------------- Staff ----------------
class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});
  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  int _v = 0;
  Future<void> _add() async {
    final name = TextEditingController(), phone = TextEditingController(), pass = TextEditingController();
    var role = 'staff';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, set) => AlertDialog(
      title: const Text('Add staff'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 10),
        TextField(controller: phone, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'Mobile', counterText: '')),
        const SizedBox(height: 10),
        TextField(controller: pass, decoration: const InputDecoration(labelText: 'Password (min 8)')),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(initialValue: role, decoration: const InputDecoration(labelText: 'Role'),
            items: const [DropdownMenuItem(value: 'staff', child: Text('Staff')), DropdownMenuItem(value: 'owner', child: Text('Owner / manager'))],
            onChanged: (v) => set(() => role = v!)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
        FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(100, 44)), onPressed: () => Navigator.pop(ctx, true), child: Text(t('save'))),
      ],
    )));
    if (ok != true || !mounted) return;
    final r = await busy(context, () => Api.I.post('/api/staff', {'name': name.text.trim(), 'phone': phone.text.trim(), 'password': pass.text, 'role': role}), done: 'Added');
    if (r != null) setState(() => _v++);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _bar(context, t('staff')),
        floatingActionButton: FloatingActionButton.extended(backgroundColor: brand, foregroundColor: Colors.white, onPressed: _add, icon: const Icon(Icons.person_add), label: const Text('Add')),
        body: PageBody(child: _Loader(key: ValueKey(_v), load: () => Api.I.get('/api/staff'), builder: (context, d, reload) => ListView(padding: const EdgeInsets.all(16), children: [
          for (final u in (d['items'] as List))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftCard(child: Row(children: [
                const CircleAvatar(backgroundColor: brand, child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u['name'] as String, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  Text('${u['phone']} · ${u['role']}', style: const TextStyle(color: muted)),
                ])),
                if (u['id'] != Api.I.user!.id)
                  Switch(value: u['active'] as bool, activeTrackColor: brand, onChanged: (v) async {
                    final r = await busy(context, () => Api.I.patch('/api/staff/${u['id']}', {'active': v}));
                    if (r != null) reload();
                  }),
              ])),
            ),
        ]))),
      );
}

// ---------------- Keys ----------------
class KeyLedgerScreen extends StatelessWidget {
  const KeyLedgerScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _bar(context, t('key_history')),
        body: PageBody(child: _Loader(
          load: () async => {'m': await Api.I.get('/api/merchant'), 'l': await Api.I.get('/api/keys/ledger')},
          builder: (context, d, _) => ListView(padding: const EdgeInsets.all(16), children: [
            SoftCard(child: PairRow('Android keys', '${d['m']['androidKeys']}', 'iPhone keys', '${d['m']['iosKeys']}')),
            const SizedBox(height: 8),
            const Text('One key is used when a phone finishes enrollment. Ask the admin to add more.', style: TextStyle(color: muted)),
            const SizedBox(height: 8),
            for (final k in (d['l']['items'] as List))
              ListTile(
                leading: Icon(k['platform'] == 'ios' ? Icons.phone_iphone : Icons.android, color: brand),
                title: Text('${(k['delta'] as int) > 0 ? '+' : ''}${k['delta']} · ${k['reason']}${k['customer'] != null ? ' · ${k['customer']}' : ''}'),
                subtitle: Text(dmyhm(k['at'] as String)),
              ),
          ]),
        )),
      );
}

// ---------------- Audit ----------------
class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _bar(context, t('audit')),
        body: PageBody(child: _Loader(
          load: () => Api.I.get('/api/audit'),
          builder: (context, d, _) => ListView(padding: const EdgeInsets.all(8), children: [
            for (final a in (d['items'] as List))
              ListTile(
                dense: true,
                leading: const Icon(Icons.history, color: brand),
                title: Text('${a['action']}'),
                subtitle: Text('${dmyhm(a['at'] as String)}${a['by'] != null ? ' · ${a['by']}' : ' · system'}${(a['data'] as Map)['reason'] != null ? ' · ${a['data']['reason']}' : ''}'),
              ),
          ]),
        )),
      );
}

// ---------------- Profile ----------------
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final u = Api.I.user!;
    return Scaffold(
      appBar: _bar(context, t('profile')),
      body: PageBody(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          SoftCard(child: Row(children: [
            const CircleAvatar(radius: 30, backgroundColor: brand, child: Icon(Icons.person, color: Colors.white, size: 34)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              Text('${u.phone} · ${u.role.replaceAll('_', ' ')}', style: const TextStyle(color: muted)),
              if (Api.I.shopName.isNotEmpty) Text(Api.I.shopName, style: const TextStyle(color: muted)),
            ])),
          ])),
          const SizedBox(height: 12),
          ListTile(leading: const Icon(Icons.translate, color: brand), title: Text(t('language')), onTap: () => Lang.I.set(Lang.I.value == 'hi' ? 'en' : 'hi')),
          ListTile(leading: const Icon(Icons.phone_android, color: brand), title: const Text('Change name / mobile'), onTap: () => _changeProfile(context)),
          ListTile(leading: const Icon(Icons.password, color: brand), title: const Text('Change password'), onTap: () => _changePassword(context)),
          ListTile(leading: const Icon(Icons.logout, color: danger), title: Text(t('logout')), onTap: () async {
            await Api.I.logout();
            if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
          }),
        ]),
      ),
    );
  }

  Future<void> _changeProfile(BuildContext context) async {
    final name = TextEditingController(text: Api.I.user!.name), phone = TextEditingController(text: Api.I.user!.phone);
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Change name / mobile'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 10),
        TextField(controller: phone, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'Mobile (used to sign in)', counterText: '')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
        FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(100, 44)), onPressed: () => Navigator.pop(ctx, true), child: Text(t('save'))),
      ],
    ));
    if (ok == true && context.mounted) {
      final r = await busy(context, () => Api.I.patch('/api/me', {'name': name.text.trim(), 'phone': phone.text.trim()}), done: 'Saved. Sign in again with the new number.');
      if (r != null) await Api.I.logout();
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final cur = TextEditingController(), next = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Change password'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: cur, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
        const SizedBox(height: 10),
        TextField(controller: next, obscureText: true, decoration: const InputDecoration(labelText: 'New password (min 8)')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
        FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(100, 44)), onPressed: () => Navigator.pop(ctx, true), child: Text(t('save'))),
      ],
    ));
    if (ok == true && context.mounted) {
      await busy(context, () => Api.I.post('/api/me/password', {'current': cur.text, 'next': next.text}), done: 'Password changed');
    }
  }
}

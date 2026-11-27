import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../i18n.dart';
import '../widgets.dart';
import 'new_sale.dart';

class DeviceDetailScreen extends StatefulWidget {
  const DeviceDetailScreen({super.key, required this.deviceId});
  final String deviceId;
  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  int _tab = 0;
  bool _offline = false;
  Map<String, dynamic>? _d;
  Object? _error;
  int _photoVersion = 0;

  String get _id => widget.deviceId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await Api.I.get('/api/devices/$_id') as Map<String, dynamic>;
      if (mounted) setState(() { _d = d; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.reply_rounded, color: brand, size: 32), onPressed: () => Navigator.pop(context)),
        title: Text(t('details')),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: PageBody(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width.clamp(0, 760) < 560 ? 620 : 728,
                child: OrangeTabs(
                  labels: [t('device'), t('reminder'), t('agreement'), t('location'), t('history')],
                  index: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
              ),
            ),
          ),
          Expanded(
            child: _error != null
                ? ErrorRetry(_error!, _load)
                : _d == null
                    ? const Loading()
                    : RefreshIndicator(color: brand, onRefresh: _load, child: _body()),
          ),
        ]),
      ),
    );
  }

  Widget _body() => switch (_tab) {
        0 => _deviceTab(),
        1 => _RemindersTab(deviceId: _id),
        2 => _agreementTab(),
        3 => _LocationTab(deviceId: _id, active: _d!['status'] == 'active'),
        _ => _HistoryTab(deviceId: _id, onChanged: _load),
      };

  // ---------------- DEVICE ----------------
  Widget _deviceTab() {
    final d = _d!;
    final c = d['customer'] as Map<String, dynamic>;
    final l = d['loan'] as Map<String, dynamic>;
    final s = d['summary'] as Map<String, dynamic>?;
    final ios = d['platform'] == 'ios';
    final (statusLabel, statusColor) = statusOf(d);
    final (lockLabel, lockColor) = lockOf(d['lockState'] as String?);
    final pending = d['status'] == 'pending';
    final active = d['status'] == 'active';
    final reported = d['reportedState'] as String?;
    final applied = reported == null || reported == d['lockState'];

    return ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 40), children: [
      Stack(clipBehavior: Clip.none, children: [
        SoftCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 18),
              child: Row(children: [
                CustomerAvatar(key: ValueKey(_photoVersion), customerId: c['id'] as String, hasPhoto: c['hasPhoto'] == true, size: 84),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c['name'] as String, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(timeAgo(d['lastSeenAt'] as String?), style: const TextStyle(color: muted, fontSize: 15)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: lockColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(applied ? lockLabel : '$lockLabel (sending…)', style: TextStyle(color: lockColor, fontWeight: FontWeight.w600)),
                  ]),
                ])),
                InkWell(
                  onTap: () => _editCustomer(c),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFFFE9DE), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.edit_note_rounded, color: brand, size: 34),
                  ),
                ),
              ]),
            ),
            const Divider(color: brand, height: 1.5, thickness: 1.5),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              child: Column(children: [
                PairRow('Model', '${d['model'] ?? ''}${(d['brand'] ?? '') != '' ? ' - ${d['brand']}' : ''}', '', '',
                    trailing2: Align(alignment: Alignment.centerRight, child: BrandMark(ios ? 'apple' : (d['brand'] as String? ?? ''), size: 24))),
                if (ios) PairRow('Serial', d['serial'] as String? ?? '', 'iOS', d['osVersion'] as String? ?? '')
                else PairRow('IMEI 1', d['imei1'] as String? ?? '', 'IMEI 2', d['imei2'] as String? ?? ''),
                PairRow('Mobile number 1', _sim(d['sim1Number'], d['sim1Operator']), 'Mobile number 2', _sim(d['sim2Number'], d['sim2Operator'])),
                if (active) PairRow('Battery', d['battery'] == null ? '' : '${d['battery']}%', 'App version', d['agentVersion'] as String? ?? ''),
              ]),
            ),
          ]),
        ),
        Positioned(top: -16, left: 0, right: 0, child: Center(child: Chip2(statusLabel, statusColor))),
      ]),
      const SizedBox(height: 16),
      SoftCard(
        child: Column(children: [
          PairRow('Total payment', num0(l['totalAmount'] as num?), 'Down payment', num0(l['downPayment'] as num?)),
          PairRow('EMI amount', num0(l['emiAmount'] as num?), 'Loan ID', l['loanRef'] as String? ?? ''),
          PairRow('EMI number', s == null ? '-' : '${s['paidCount']} / ${s['emiCount']}', 'EMI date', s?['nextDueDate'] as String? ?? 'Paid'),
          PairRow('Balance', rupees(s?['balance'] as num?), 'Overdue', (s?['overdueAmount'] ?? 0) == 0 ? '₹0' : '${rupees(s!['overdueAmount'] as num)} · ${s['overdueDays']}d'),
          PairRow('Notes', l['notes'] as String? ?? '', 'Lock reason', d['lockReason'] as String? ?? ''),
        ]),
      ),
      const SizedBox(height: 16),
      if (pending && !ios) ...[
        FilledButton.icon(
          icon: const Icon(Icons.qr_code_2),
          label: Text(t('show_qr')),
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => EnrollQrScreen(deviceId: _id, customerName: c['name'] as String)));
            _load();
          },
        ),
        const SizedBox(height: 8),
        const Text('Scan this QR on the new phone\'s first welcome screen (tap 6 times). The phone will lock/unlock from here after that.',
            style: TextStyle(color: muted)),
      ],
      if (pending && ios)
        const SoftCard(child: Text('iPhone locking needs the iOS MDM server (Apple Business Manager). Until it is set up, this iPhone is recorded for EMI tracking, reminders and payments only.')),
      if (active || d['status'] == 'removed') ...[
        OrangeTabs(labels: [t('online'), t('offline')], index: _offline ? 1 : 0, onChanged: (i) => setState(() => _offline = i == 1)),
        if (_offline)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Offline mode: for a phone without internet. Each action makes a signed SMS code — send it from your phone to the customer\'s SIM.', style: TextStyle(color: muted)),
          ),
        const SizedBox(height: 14),
        _actionsGrid(d, s),
      ],
      if (d['status'] == 'released')
        SoftCard(child: Text('Released on ${dmyhm(d['releasedAt'] as String?)}. HoopLock no longer controls this phone.', style: const TextStyle(fontSize: 16))),
    ]);
  }

  String _sim(dynamic n, dynamic op) => (n == null || n == '') ? '' : (op != null && op != '' ? '$n ($op)' : '$n');

  Widget _actionsGrid(Map<String, dynamic> d, Map<String, dynamic>? s) {
    final lock = d['lockState'] as String;
    final ios = d['platform'] == 'ios';
    final tiles = <Widget>[
      ActionTile(icon: Icons.lock_rounded, label: t('lock_device'), enabled: lock != 'locked' && !ios, onTap: () => _changeState('locked')),
      ActionTile(icon: Icons.lock_open_rounded, label: t('unlock_device'), enabled: lock != 'unlocked' && !ios, onTap: () => _changeState('unlocked')),
      ActionTile(icon: Icons.warning_amber_rounded, label: t('warning'), enabled: lock == 'unlocked' && !ios, onTap: () => _changeState('warning')),
      ActionTile(icon: Icons.apps_outage_rounded, label: t('restrict'), enabled: lock != 'restricted' && lock != 'locked' && !ios, onTap: () => _changeState('restricted')),
      ActionTile(icon: Icons.currency_rupee, label: t('collect'), enabled: (d['loan']['status']) == 'open', onTap: () => _collect(s)),
      if (!_offline) ActionTile(icon: Icons.notifications_active_outlined, label: t('remind'), onTap: _remind),
      if (!_offline) ActionTile(icon: Icons.message_outlined, label: t('message'), enabled: !ios, onTap: _message),
      if (!_offline) ActionTile(icon: Icons.my_location, label: t('locate'), enabled: !ios, onTap: _locate),
      if (!_offline) ActionTile(icon: Icons.link, label: 'Payment link', onTap: _payLink),
      ActionTile(icon: Icons.verified_outlined, label: t('release'), onTap: _release),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 600 ? 3 : 2;
      return GridView.count(
        crossAxisCount: cols, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.35,
        children: tiles,
      );
    });
  }

  // ---------------- actions ----------------
  Future<void> _changeState(String state) async {
    String reason = state == 'unlocked' ? 'other' : 'overdue';
    final msg = TextEditingController(text: (_d!['lockMessage'] as String?) ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) => AlertDialog(
        title: Text(switch (state) { 'locked' => t('lock_device'), 'unlocked' => t('unlock_device'), 'warning' => t('warning'), _ => t('restrict') }),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(switch (state) {
              'locked' => 'The phone shows only the lock screen. Calls to your shop number and emergency calls still work.',
              'restricted' => 'Apps pause; calls and SMS keep working.',
              'warning' => 'A full-screen notice the customer can close.',
              _ => 'All restrictions are removed.',
            }),
            if (state != 'unlocked') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: const [
                  DropdownMenuItem(value: 'overdue', child: Text('EMI overdue')),
                  DropdownMenuItem(value: 'theft', child: Text('Theft / phone missing')),
                  DropdownMenuItem(value: 'tamper', child: Text('Tampering / SIM removed')),
                  DropdownMenuItem(value: 'customer_request', child: Text('Customer request')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => set(() => reason = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: msg, maxLength: 300, maxLines: 3, decoration: const InputDecoration(labelText: 'Message on the phone (optional)')),
            ],
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
          FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(110, 44)), onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      )),
    );
    if (ok != true || !mounted) return;
    final r = await busy(context, () => Api.I.post('/api/devices/$_id/state', {
          'state': state, 'reason': reason, if (state != 'unlocked' && msg.text.trim().isNotEmpty) 'message': msg.text.trim(),
        }));
    if (r == null || !mounted) return;
    await _load();
    if (_offline) {
      _smsSheet(r['sms'] as String?, r['smsTo'] as String?);
    } else if (mounted) {
      toast(context, 'Sent. The phone applies it within seconds when online.');
    }
  }

  void _smsSheet(String? code, String? to) {
    if (code == null) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Send this SMS to the customer\'s phone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('To: ${to ?? '-'}', style: const TextStyle(color: muted)),
            const SizedBox(height: 12),
            SelectableText(code, style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.sms),
              label: const Text('Open SMS app'),
              onPressed: () => launchUrl(Uri(scheme: 'sms', path: to ?? '', queryParameters: {'body': code})),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(icon: const Icon(Icons.copy), label: const Text('Copy'), onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              toast(ctx, 'Copied');
            }),
          ]),
        ),
      ),
    );
  }

  Future<void> _collect(Map<String, dynamic>? s) async {
    final overdue = (s?['overdueAmount'] as num?) ?? 0;
    final suggested = overdue > 0 ? overdue : ((s?['nextDueAmount'] as num?) ?? '');
    final amount = TextEditingController(text: '$suggested');
    final ref = TextEditingController();
    var method = 'cash';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) => AlertDialog(
        title: Text(t('collect')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount ₹')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: method,
            decoration: const InputDecoration(labelText: 'Method'),
            items: const [
              DropdownMenuItem(value: 'cash', child: Text('Cash')),
              DropdownMenuItem(value: 'upi', child: Text('UPI')),
              DropdownMenuItem(value: 'card', child: Text('Card')),
              DropdownMenuItem(value: 'bank', child: Text('Bank transfer')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (v) => set(() => method = v!),
          ),
          const SizedBox(height: 12),
          TextField(controller: ref, decoration: const InputDecoration(labelText: 'Reference / UTR (optional)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
          FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(110, 44)), onPressed: () => Navigator.pop(ctx, true), child: Text(t('save'))),
        ],
      )),
    );
    final value = double.tryParse(amount.text.trim());
    if (ok != true || value == null || value <= 0 || !mounted) return;
    final r = await busy(context, () => Api.I.post('/api/devices/$_id/payments', {'amount': value, 'method': method, 'ref': ref.text.trim()}));
    if (r == null || !mounted) return;
    toast(context, [
      'Saved ${rupees(r['applied'] as num)}',
      if (r['unlocked'] == true) 'phone unlocked',
      if (r['closed'] == true) 'loan fully paid — you can release the phone',
    ].join(' · '));
    _load();
  }

  Future<void> _remind() async {
    final r = await busy(context, () => Api.I.post('/api/devices/$_id/remind', {}));
    if (r != null && mounted) toast(context, r['sms'] == 'sent' ? 'Reminder sent by SMS and on the phone' : 'Reminder sent on the phone (SMS provider not set up)');
  }

  Future<void> _message() async {
    final msg = TextEditingController(text: (_d!['lockMessage'] as String?) ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('message')),
        content: TextField(controller: msg, maxLength: 300, maxLines: 4, decoration: const InputDecoration(hintText: 'Shown on the warning and lock screens')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
          FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(110, 44)), onPressed: () => Navigator.pop(ctx, true), child: Text(t('save'))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final r = await busy(context, () => Api.I.post('/api/devices/$_id/state', {'state': _d!['lockState'], 'reason': (_d!['lockReason'] as String?)?.isNotEmpty == true ? _d!['lockReason'] : 'other', 'message': msg.text.trim()}), done: 'Message updated');
    if (r != null) _load();
  }

  Future<void> _locate() async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('locate')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Location requests are recorded. Use for theft, a missing customer or recovery.'),
          const SizedBox(height: 12),
          TextField(controller: reason, decoration: const InputDecoration(labelText: 'Reason')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
          FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(110, 44)), onPressed: () => Navigator.pop(ctx, true), child: const Text('Request')),
        ],
      ),
    );
    if (ok != true || reason.text.trim().length < 3 || !mounted) return;
    final r = await busy(context, () => Api.I.post('/api/devices/$_id/locate', {'reason': reason.text.trim()}), done: 'Requested. Open the LOCATION tab in a minute.');
    if (r != null) setState(() => _tab = 3);
  }

  Future<void> _payLink() async {
    final r = await busy(context, () => Api.I.post('/api/devices/$_id/payment-link', {}));
    if (r == null || !mounted) return;
    final url = r['url'] as String;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Payment link ${rupees(r['amount'] as num)}'),
      content: SelectableText(url),
      actions: [
        TextButton(onPressed: () { Clipboard.setData(ClipboardData(text: url)); toast(ctx, 'Copied'); }, child: const Text('Copy')),
        FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(110, 44)), onPressed: () => launchUrl(Uri.parse('https://wa.me/91${(_d!['customer'] as Map)['mobile']}?text=${Uri.encodeComponent('Please pay your EMI: $url')}')), child: const Text('WhatsApp')),
      ],
    ));
  }

  Future<void> _release() async {
    final s = _d!['summary'] as Map<String, dynamic>?;
    final open = s != null && s['status'] != 'closed';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('release')),
        content: Text(open
            ? '${rupees(s['balance'] as num)} is still due. Releasing removes all control from this phone for ever. Only the owner can do this.'
            : 'All EMIs are paid. Release the phone? HoopLock will remove itself.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
          FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(110, 44), backgroundColor: open ? danger : brand), onPressed: () => Navigator.pop(ctx, true), child: Text(open ? 'Release anyway' : 'Release')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final r = await busy(context, () => Api.I.post('/api/devices/$_id/release', {'force': open}), done: 'Release sent');
    if (r == null) return;
    await _load();
    if (_offline) _smsSheet(r['sms'] as String?, _d!['sim1Number'] as String?);
  }

  Future<void> _editCustomer(Map<String, dynamic> c) async {
    final name = TextEditingController(text: c['name'] as String?);
    final mobile = TextEditingController(text: c['mobile'] as String?);
    final alt = TextEditingController(text: c['altMobile'] as String?);
    final address = TextEditingController(text: c['address'] as String?);
    final notes = TextEditingController(text: c['notes'] as String?);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit customer'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            OutlinedButton.icon(icon: const Icon(Icons.photo_camera), label: const Text('Take / change photo'), onPressed: () async {
              Navigator.pop(ctx, false);
              await _pickPhoto(c['id'] as String);
            }),
            const SizedBox(height: 12),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 10),
            TextField(controller: mobile, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'Mobile', counterText: '')),
            const SizedBox(height: 10),
            TextField(controller: alt, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'Alternate mobile', counterText: '')),
            const SizedBox(height: 10),
            TextField(controller: address, maxLines: 2, decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 10),
            TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
          FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(110, 44)), onPressed: () => Navigator.pop(ctx, true), child: Text(t('save'))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final r = await busy(context, () => Api.I.patch('/api/customers/${c['id']}', {
          'name': name.text.trim(), 'mobile': mobile.text.trim(), 'altMobile': alt.text.trim(), 'address': address.text.trim(), 'notes': notes.text.trim(),
        }), done: 'Saved');
    if (r != null) _load();
  }

  Future<void> _pickPhoto(String customerId) async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 640, imageQuality: 75);
    if (x == null || !mounted) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    final r = await busy(context, () => Api.I.put('/api/customers/$customerId/photo', {'dataBase64': base64Encode(bytes), 'type': 'image/jpeg'}), done: 'Photo saved');
    if (r != null) { setState(() => _photoVersion++); _load(); }
  }

  // ---------------- AGREEMENT ----------------
  Widget _agreementTab() {
    final d = _d!;
    final c = d['customer'] as Map<String, dynamic>;
    final l = d['loan'] as Map<String, dynamic>;
    final inst = (d['instalments'] as List).cast<Map<String, dynamic>>();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 40), children: [
      SoftCard(child: Column(children: [
        PairRow('Customer', c['name'] as String, 'Mobile', c['mobile'] as String? ?? ''),
        PairRow('Address', c['address'] as String? ?? '', 'ID', '${c['idType'] ?? ''} ${c['idLast4'] ?? ''}'.trim()),
        PairRow('Sale date', dmy(d['createdAt'] as String?), 'Consent on phone', l['consentAt'] == null ? 'Not yet' : dmyhm(l['consentAt'] as String?)),
        PairRow('Price', rupees(l['totalAmount'] as num?), 'Down payment', rupees(l['downPayment'] as num?)),
        PairRow('EMI', '${rupees(l['emiAmount'] as num?)} × ${l['emiCount']}', 'First EMI', dmy(l['firstEmiDate'] as String?)),
      ])),
      const SizedBox(height: 16),
      const Text('EMI schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      SoftCard(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(children: [
          for (final i in inst)
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: i['paidAt'] != null ? success : ((i['dueDate'] as String).compareTo(today) < 0 ? danger : const Color(0xFFE5E7EB)),
                child: Text('${i['seq']}', style: TextStyle(color: i['paidAt'] != null || (i['dueDate'] as String).compareTo(today) < 0 ? Colors.white : ink, fontSize: 13)),
              ),
              title: Text('${dmy(i['dueDate'] as String)}  ·  ${rupees(i['amount'] as num)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              subtitle: Text(i['paidAt'] != null
                  ? 'Paid ${dmy(i['paidAt'] as String)} · ${i['method'] ?? ''}${(i['ref'] ?? '') != '' ? ' · ${i['ref']}' : ''}'
                  : ((i['paidAmount'] as num) > 0 ? 'Part paid ${rupees(i['paidAmount'] as num)}' : 'Due')),
            ),
        ]),
      ),
    ]);
  }
}

// ---------------- REMINDERS ----------------
class _RemindersTab extends StatefulWidget {
  const _RemindersTab({required this.deviceId});
  final String deviceId;
  @override
  State<_RemindersTab> createState() => _RemindersTabState();
}

class _RemindersTabState extends State<_RemindersTab> {
  List<Map<String, dynamic>>? _items;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final r = await Api.I.get('/api/devices/${widget.deviceId}/reminders') as Map<String, dynamic>;
    if (mounted) setState(() => _items = (r['items'] as List).cast<Map<String, dynamic>>());
  }

  @override
  Widget build(BuildContext context) {
    if (_items == null) return const Loading();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 40), children: [
      FilledButton.icon(icon: const Icon(Icons.notifications_active), label: Text(t('remind')), onPressed: () async {
        final r = await busy(context, () => Api.I.post('/api/devices/${widget.deviceId}/remind', {}), done: 'Reminder sent');
        if (r != null) _load();
      }),
      const SizedBox(height: 12),
      if (_items!.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No reminders yet. They are sent automatically before and after each due date.', textAlign: TextAlign.center, style: TextStyle(color: muted)))),
      for (final r in _items!)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(r['channel'] == 'sms' ? Icons.sms_outlined : Icons.phone_android, color: brand, size: 20),
              const SizedBox(width: 6),
              Text('${r['channel'] == 'sms' ? 'SMS' : 'On phone'} · ${r['kind']} · ${r['status']}', style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(dmyhm(r['at'] as String), style: const TextStyle(color: muted, fontSize: 12)),
            ]),
            const SizedBox(height: 6),
            Text(r['message'] as String),
          ])),
        ),
    ]);
  }
}

// ---------------- LOCATION ----------------
class _LocationTab extends StatefulWidget {
  const _LocationTab({required this.deviceId, required this.active});
  final String deviceId;
  final bool active;
  @override
  State<_LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<_LocationTab> {
  List<Map<String, dynamic>>? _items;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final r = await Api.I.get('/api/devices/${widget.deviceId}/locations') as Map<String, dynamic>;
    if (mounted) setState(() => _items = (r['items'] as List).cast<Map<String, dynamic>>());
  }

  @override
  Widget build(BuildContext context) {
    if (_items == null) return const Loading();
    final last = _items!.isEmpty ? null : _items!.first;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 40), children: [
      if (last == null)
        const SoftCard(child: Text('No location yet. The phone sends its location when it is locked, when its SIM is changed, or when you press Locate.'))
      else ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 320,
            child: FlutterMap(
              options: MapOptions(initialCenter: LatLng((last['lat'] as num).toDouble(), (last['lng'] as num).toDouble()), initialZoom: 15),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'in.hooplock.console'),
                MarkerLayer(markers: [
                  for (final p in _items!.take(20).toList().reversed)
                    Marker(
                      point: LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()),
                      width: 40, height: 40,
                      child: Icon(Icons.location_on, color: identical(p, last) ? danger : brand.withValues(alpha: .6), size: identical(p, last) ? 40 : 28),
                    ),
                ]),
                const RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Text('Last: ${timeAgo(last['at'] as String)} · ±${(last['accuracy'] as num?)?.round() ?? '?'} m', style: const TextStyle(fontWeight: FontWeight.w600))),
          TextButton.icon(
            icon: const Icon(Icons.map),
            label: const Text('Google Maps'),
            onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${last['lat']},${last['lng']}')),
          ),
        ]),
      ],
      const SizedBox(height: 10),
      if (widget.active)
        OutlinedButton.icon(icon: const Icon(Icons.refresh), label: const Text('Refresh'), onPressed: _load),
      const SizedBox(height: 10),
      for (final p in _items!)
        ListTile(
          dense: true,
          leading: const Icon(Icons.place_outlined, color: brand),
          title: Text('${(p['lat'] as num).toStringAsFixed(5)}, ${(p['lng'] as num).toStringAsFixed(5)}'),
          subtitle: Text('${dmyhm(p['at'] as String)} · ${p['reason']}'),
          onTap: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${p['lat']},${p['lng']}')),
        ),
    ]);
  }
}

// ---------------- HISTORY ----------------
class _HistoryTab extends StatefulWidget {
  const _HistoryTab({required this.deviceId, required this.onChanged});
  final String deviceId;
  final VoidCallback onChanged;
  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  List<Map<String, dynamic>>? _rows;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final r = await Api.I.get('/api/devices/${widget.deviceId}/events') as Map<String, dynamic>;
    final rows = <Map<String, dynamic>>[
      for (final e in (r['events'] as List)) {'kind': 'phone', 'title': e['type'], 'at': e['at'], 'data': e['data']},
      for (final a in (r['actions'] as List)) {'kind': 'shop', 'title': a['action'], 'at': a['at'], 'by': a['by'], 'data': a['data']},
    ]..sort((a, b) => (b['at'] as String).compareTo(a['at'] as String));
    if (mounted) setState(() => _rows = rows);
  }

  static const _labels = {
    'device.locked': 'Locked', 'device.unlocked': 'Unlocked', 'device.warning': 'Warning shown', 'device.restricted': 'Apps restricted',
    'device.enrolled': 'Phone enrolled', 'device.locate': 'Location requested', 'device.release': 'Release sent', 'device.remind': 'Reminder sent',
    'payment.record': 'Payment recorded', 'sale.create': 'Sale created', 'device.tamper': 'Tamper alert', 'device.mark_removed': 'Marked uninstalled',
    'sim_changed': 'SIM changed', 'boot': 'Phone restarted', 'consent': 'Customer accepted agreement', 'enrolled': 'Enrolled',
    'call_blocked': 'Blocked a call while locked', 'sms_command': 'Offline SMS command applied', 'admin_disable_requested': 'Tried to remove admin',
    'released': 'HoopLock removed from phone', 'back_online': 'Back online',
  };

  @override
  Widget build(BuildContext context) {
    if (_rows == null) return const Loading();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 40), children: [
      if (Api.I.user!.isOwner)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(icon: const Icon(Icons.phonelink_erase), label: const Text('Mark as uninstalled'), onPressed: () async {
            final r = await busy(context, () => Api.I.post('/api/devices/${widget.deviceId}/mark-removed', {}), done: 'Marked');
            if (r != null) { widget.onChanged(); _load(); }
          }),
        ),
      for (final r in _rows!)
        ListTile(
          leading: Icon(r['kind'] == 'phone' ? Icons.phone_android : Icons.storefront, color: (r['title'] as String).contains('tamper') || r['title'] == 'sim_changed' ? danger : brand),
          title: Text(_labels[r['title']] ?? '${r['title']}'),
          subtitle: Text([dmyhm(r['at'] as String), if (r['by'] != null) 'by ${r['by']}', if ((r['data'] as Map?)?['reason'] != null) '${r['data']['reason']}', if ((r['data'] as Map?)?['amount'] != null) rupees(r['data']['amount'] as num)].join(' · ')),
        ),
    ]);
  }
}

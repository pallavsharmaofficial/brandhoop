import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../i18n.dart';
import '../widgets.dart';

/// Super admin: all shops, their key balances, add keys, open a shop.
class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});
  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> {
  List<Map<String, dynamic>>? _items;
  Object? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await Api.I.get('/api/admin/merchants') as Map<String, dynamic>;
      if (mounted) setState(() { _items = (r['items'] as List).cast<Map<String, dynamic>>(); _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _add() async {
    final name = TextEditingController(), owner = TextEditingController(), phone = TextEditingController(), city = TextEditingController();
    final pass = TextEditingController(), keys = TextEditingController(text: '10'), iosKeys = TextEditingController(text: '0');
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('New shop'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Shop name')),
        const SizedBox(height: 10),
        TextField(controller: owner, decoration: const InputDecoration(labelText: 'Owner name')),
        const SizedBox(height: 10),
        TextField(controller: phone, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'Owner mobile (login)', counterText: '')),
        const SizedBox(height: 10),
        TextField(controller: pass, decoration: const InputDecoration(labelText: 'Owner password (min 8)')),
        const SizedBox(height: 10),
        TextField(controller: city, decoration: const InputDecoration(labelText: 'City')),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: keys, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Android keys'))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: iosKeys, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'iPhone keys'))),
        ]),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
        FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(100, 44)), onPressed: () => Navigator.pop(ctx, true), child: Text(t('save'))),
      ],
    ));
    if (ok != true || !mounted) return;
    final r = await busy(context, () => Api.I.post('/api/admin/merchants', {
          'name': name.text.trim(), 'ownerName': owner.text.trim(), 'phone': phone.text.trim(), 'city': city.text.trim(),
          'ownerPassword': pass.text, 'androidKeys': int.tryParse(keys.text) ?? 0, 'iosKeys': int.tryParse(iosKeys.text) ?? 0,
        }), done: 'Shop created');
    if (r != null) _load();
  }

  Future<void> _keys(Map<String, dynamic> m) async {
    final count = TextEditingController(text: '10'), reason = TextEditingController(text: 'Purchase');
    var platform = 'android';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, set) => AlertDialog(
      title: Text('Keys · ${m['name']}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        SegmentedButton<String>(
          segments: const [ButtonSegment(value: 'android', label: Text('Android')), ButtonSegment(value: 'ios', label: Text('iPhone'))],
          selected: {platform}, onSelectionChanged: (s) => set(() => platform = s.first),
        ),
        const SizedBox(height: 12),
        TextField(controller: count, keyboardType: const TextInputType.numberWithOptions(signed: true), decoration: const InputDecoration(labelText: 'Keys to add (negative to remove)')),
        const SizedBox(height: 10),
        TextField(controller: reason, decoration: const InputDecoration(labelText: 'Reason / payment ref')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
        FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(100, 44)), onPressed: () => Navigator.pop(ctx, true), child: Text(t('save'))),
      ],
    )));
    final n = int.tryParse(count.text.trim());
    if (ok != true || n == null || n == 0 || !mounted) return;
    final r = await busy(context, () => Api.I.post('/api/admin/merchants/${m['id']}/keys', {'platform': platform, 'count': n, 'reason': reason.text.trim()}), done: 'Keys updated');
    if (r != null) _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.reply_rounded, color: brand, size: 32), onPressed: () => Navigator.pop(context)),
          title: Text(t('shops')),
        ),
        floatingActionButton: FloatingActionButton.extended(backgroundColor: brand, foregroundColor: Colors.white, onPressed: _add, icon: const Icon(Icons.add_business), label: const Text('New shop')),
        body: PageBody(
          child: _error != null ? ErrorRetry(_error!, _load) : _items == null ? const Loading() : RefreshIndicator(
            color: brand,
            onRefresh: _load,
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 90), children: [
              for (final m in _items!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SoftCard(
                    onTap: () async {
                      await Api.I.actAs(m['id'] as String, m['name'] as String);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(m['name'] as String, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700))),
                        if (Api.I.actingMerchantId == m['id']) const Chip2('Open', success),
                        if (m['active'] != true) const Chip2('Disabled', danger),
                      ]),
                      Text('${m['ownerName']} · ${m['phone']} · ${m['city']}', style: const TextStyle(color: muted)),
                      PairRow('Devices', '${m['activeDevices']} active / ${m['devices']}', 'Keys A / iOS', '${m['androidKeys']} / ${m['iosKeys']}'),
                      Row(children: [
                        TextButton.icon(icon: const Icon(Icons.vpn_key), label: const Text('Add keys'), onPressed: () => _keys(m)),
                        const Spacer(),
                        TextButton(onPressed: () async {
                          final r = await busy(context, () => Api.I.patch('/api/admin/merchants/${m['id']}', {'active': m['active'] != true}));
                          if (r != null) _load();
                        }, child: Text(m['active'] == true ? 'Disable' : 'Enable', style: TextStyle(color: m['active'] == true ? danger : success))),
                      ]),
                    ]),
                  ),
                ),
            ]),
          ),
        ),
      );
}

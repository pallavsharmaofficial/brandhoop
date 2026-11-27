import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../i18n.dart';
import '../widgets.dart';
import 'detail.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key, this.initialTab = 0, this.status = 'all'});
  final int initialTab;
  final String status;
  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  static const _tabs = ['users', 'next_emi', 'high_risk'];
  late int _tab = widget.initialTab;
  late String _status = widget.status;
  String _platform = 'all';
  String _q = '';
  bool _searching = false;
  final List<Map<String, dynamic>> _items = [];
  bool _loading = false;
  bool _more = true;
  Object? _error;
  Timer? _debounce;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _reload();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _fetch();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _reload() {
    _items.clear();
    _more = true;
    _error = null;
    _fetch();
  }

  Future<void> _fetch() async {
    if (_loading || !_more) return;
    setState(() => _loading = true);
    try {
      final r = await Api.I.get('/api/customers', {
        'tab': _tabs[_tab], 'q': _q, 'status': _status, 'platform': _platform, 'limit': 30, 'offset': _items.length,
      }) as Map<String, dynamic>;
      final list = (r['items'] as List).cast<Map<String, dynamic>>();
      setState(() { _items.addAll(list); _more = list.length == 30; });
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _filter() async {
    final r = await showModalBottomSheet<(String, String)>(
      context: context,
      builder: (ctx) {
        var s = _status, p = _platform;
        return StatefulBuilder(builder: (ctx, set) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Wrap(spacing: 8, children: [
                for (final o in const ['all', 'active', 'inactive', 'locked', 'pending', 'removed', 'released'])
                  ChoiceChip(label: Text(o), selected: s == o, selectedColor: brand.withValues(alpha: .2), onSelected: (_) => set(() => s = o)),
              ]),
              const SizedBox(height: 12),
              const Text('Phone', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Wrap(spacing: 8, children: [
                for (final o in const ['all', 'android', 'ios'])
                  ChoiceChip(label: Text(o), selected: p == o, selectedColor: brand.withValues(alpha: .2), onSelected: (_) => set(() => p = o)),
              ]),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(ctx, (s, p)), child: const Text('Apply')),
            ]),
          ),
        ));
      },
    );
    if (r != null) {
      _status = r.$1;
      _platform = r.$2;
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _status != 'all' || _platform != 'all';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.reply_rounded, color: brand, size: 32), onPressed: () => Navigator.pop(context)),
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(hintText: t('search'), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 350), () { _q = v.trim(); _reload(); });
                },
              )
            : Text(t('list_title')),
        actions: [
          IconButton(icon: Icon(_searching ? Icons.close : Icons.search, size: 30), onPressed: () {
            setState(() => _searching = !_searching);
            if (!_searching && _q.isNotEmpty) { _q = ''; _reload(); }
          }),
          IconButton(icon: Icon(filtered ? Icons.filter_alt : Icons.filter_alt_outlined, size: 30, color: filtered ? brand : ink), onPressed: _filter),
        ],
      ),
      body: PageBody(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: OrangeTabs(labels: [t('users'), t('next_emi'), t('high_risk')], index: _tab, onChanged: (i) { setState(() => _tab = i); _reload(); }),
          ),
          Expanded(
            child: RefreshIndicator(
              color: brand,
              onRefresh: () async => _reload(),
              child: _error != null && _items.isEmpty
                  ? ListView(children: [ErrorRetry(_error!, _reload)])
                  : _items.isEmpty && !_loading
                      ? ListView(children: [Padding(padding: const EdgeInsets.all(48), child: Center(child: Text(t('no_customers'), style: const TextStyle(color: muted, fontSize: 16))))])
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: _items.length + (_loading ? 1 : 0),
                          itemBuilder: (c, i) => i >= _items.length ? const Loading() : _CustomerCard(_items[i], tab: _tabs[_tab], onReturn: _reload),
                        ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard(this.d, {required this.tab, required this.onReturn});
  final Map<String, dynamic> d;
  final String tab;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, _) = statusOf(d);
    final (lockLabel, lockColor) = lockOf(d['lockState'] as String?);
    final ios = d['platform'] == 'ios';
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Stack(clipBehavior: Clip.none, children: [
        SoftCard(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => DeviceDetailScreen(deviceId: d['deviceId'] as String)));
            onReturn();
          },
          padding: const EdgeInsets.fromLTRB(18, 26, 18, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CustomerAvatar(customerId: d['customerId'] as String, hasPhoto: d['hasPhoto'] == true),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Sync : ${timeAgo(d['lastSeenAt'] as String?)}', style: const TextStyle(color: muted, fontSize: 15)),
                  Text('Created: ${dmy(d['createdAt'] as String?)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 15)),
                ]),
              ),
              ConstrainedBox(constraints: const BoxConstraints(maxWidth: 104), child: FittedBox(child: BrandMark(ios ? 'apple' : (d['brand'] as String? ?? '')))),
            ]),
            const SizedBox(height: 10),
            if (ios)
              PairRow('Serial', d['serial'] as String? ?? '', 'Mobile number', d['mobile'] as String? ?? '')
            else
              PairRow('IMEI 1', d['imei1'] as String? ?? '', 'IMEI 2', d['imei2'] as String? ?? ''),
            if (tab == 'users' && !ios) Padding(padding: const EdgeInsets.only(top: 4), child: labelValue('Mobile number', d['mobile'] as String? ?? '')),
            if (tab == 'next_emi')
              PairRow('Next EMI', dmy(d['nextDueDate'] as String?), 'Amount', rupees(d['nextDueAmount'] as num?)),
            if (tab == 'high_risk')
              PairRow('Overdue', rupees(d['overdueAmount'] as num?), 'Days', '${d['overdueDays']}'),
          ]),
        ),
        Positioned(left: 44, top: -18, child: Chip2('$statusLabel${ios ? ' iOS' : ''}', brand)),
        Positioned(right: 44, top: -18, child: Chip2(lockLabel == 'Unlocked' ? 'Unlocked' : lockLabel, lockLabel == 'Unlocked' ? success : lockColor)),
      ]),
    );
  }
}

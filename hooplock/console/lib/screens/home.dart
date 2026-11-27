import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../i18n.dart';
import '../widgets.dart';
import 'admin.dart';
import 'customers.dart';
import 'manage.dart';
import 'new_sale.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _d;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (Api.I.merchantId == null) { setState(() { _d = null; _error = null; }); return; }
    try {
      final d = await Api.I.get('/api/dashboard') as Map<String, dynamic>;
      if (mounted) setState(() { _d = d; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _open(Widget w) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final api = Api.I;
    final admin = api.user!.isSuperAdmin;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: InkWell(onTap: () => _open(const ProfileScreen()), child: const CircleAvatar(backgroundColor: brand, child: Icon(Icons.person, color: Colors.white))),
        ),
        title: Text(api.shopName.isEmpty ? 'HoopLock' : api.shopName, overflow: TextOverflow.ellipsis),
        actions: [
          if (admin) IconButton(tooltip: t('shops'), icon: const Icon(Icons.storefront_outlined), onPressed: () => _open(const ShopsScreen())),
          IconButton(tooltip: 'Support', icon: const Icon(Icons.headset_mic_outlined), onPressed: () => launchUrl(Uri.parse('https://wa.me/'))),
        ],
      ),
      body: RefreshIndicator(
        color: brand,
        onRefresh: _load,
        child: PageBody(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
            _banner(),
            const SizedBox(height: 20),
            if (api.merchantId == null) ...[
              SoftCard(onTap: () => _open(const ShopsScreen()), child: const ListTile(leading: Icon(Icons.storefront, color: brand), title: Text('Choose a shop to manage'), trailing: Icon(Icons.chevron_right, color: brand))),
            ] else if (_error != null)
              ErrorRetry(_error!, _load)
            else if (_d == null)
              const Loading()
            else ...[
              _quickActions(),
              const SizedBox(height: 22),
              _stats(),
              const SizedBox(height: 18),
              _money(),
              const SizedBox(height: 10),
              _menu(Icons.people_alt_outlined, const Color(0xFFE8F0FF), t('customers'), () => _open(const CustomerListScreen())),
              _menu(Icons.assignment_outlined, const Color(0xFFE8F0FF), t('reports'), () => _open(const ReportsScreen())),
              if (api.user!.isOwner) _menu(Icons.tune, const Color(0xFFF3FCD9), t('settings'), () => _open(const ShopSettingsScreen())),
              if (api.user!.isOwner) _menu(Icons.badge_outlined, const Color(0xFFFFF0E5), t('staff'), () => _open(const StaffScreen())),
              _menu(Icons.vpn_key_outlined, const Color(0xFFFFF7D6), t('key_history'), () => _open(const KeyLedgerScreen())),
              if (api.user!.isOwner) _menu(Icons.history, const Color(0xFFEFE8FF), t('audit'), () => _open(const AuditScreen())),
              _menu(Icons.manage_accounts_outlined, const Color(0xFFF3FCD9), t('profile'), () => _open(const ProfileScreen())),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _banner() => Container(
        height: 150,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [Color(0xFFFF5A0A), Color(0xFFC2272D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Stack(children: [
          const Positioned(right: -6, bottom: -14, child: Icon(Icons.phonelink_lock_rounded, size: 140, color: Color(0x33FFFFFF))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Row(children: [Icon(Icons.lock_rounded, color: Colors.white), SizedBox(width: 6), Text('HoopLock', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))]),
            Spacer(),
            Text('SAFE · SECURE · SIMPLE', style: TextStyle(color: Color(0xFFFFE08A), fontWeight: FontWeight.w700, letterSpacing: 1)),
            SizedBox(height: 4),
            Text('EMI पर फ़ोन, पूरी सुरक्षा के साथ', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          ]),
        ]),
      );

  Widget _quickActions() {
    Widget big(String label, IconData icon, VoidCallback onTap) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(80),
              onTap: onTap,
              child: Container(
                height: 190,
                decoration: BoxDecoration(color: brand, borderRadius: BorderRadius.circular(80)),
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  Container(
                    width: 84, height: 84,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(icon, color: brand, size: 46),
                  ),
                  const Spacer(),
                  Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                  const Spacer(),
                ]),
              ),
            ),
          ),
        );
    return Row(children: [
      big(t('android'), Icons.add, () => _open(const NewSaleScreen(platform: 'android'))),
      big(t('iphone'), Icons.add, () => _open(const NewSaleScreen(platform: 'ios'))),
      big(t('collect'), Icons.currency_rupee, () => _open(const CustomerListScreen(initialTab: 1))),
    ]);
  }

  Widget _stats() {
    final d = _d!['devices'] as Map<String, dynamic>;
    final k = _d!['keys'] as Map<String, dynamic>;
    Widget tile(String n, String label, VoidCallback? onTap) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: SoftCard(
              onTap: onTap,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              child: Column(children: [
                FittedBox(child: Text(n, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: ink))),
                Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.15)),
              ]),
            ),
          ),
        );
    void list(String status) => _open(CustomerListScreen(status: status));
    return Column(children: [
      Row(children: [
        tile('${d['total']}', t('total'), () => list('all')),
        tile('${d['active']}', t('active'), () => list('active')),
        tile('${d['inactive']}', t('inactive'), () => list('inactive')),
      ]),
      Row(children: [
        tile('${d['removed']}', t('removed'), () => list('removed')),
        tile('${d['locked']}', t('locked'), () => list('locked')),
        tile('${k['android']}${(k['ios'] as int) > 0 ? ' / ${k['ios']}' : ''}', t('keys'), () => _open(const KeyLedgerScreen())),
      ]),
    ]);
  }

  Widget _money() {
    final m = _d!['money'] as Map<String, dynamic>;
    return SoftCard(
      child: Column(children: [
        PairRow('Overdue', rupees(m['overdueAmount'] as num), 'Overdue loans', '${m['overdueLoans']}'),
        PairRow('Due this week', rupees(m['dueThisWeek'] as num), 'Collected today', rupees(m['collectedToday'] as num)),
      ]),
    );
  }

  Widget _menu(IconData icon, Color bg, String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SoftCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: ink)),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600))),
            const Icon(Icons.chevron_right, color: brand, size: 30),
          ]),
        ),
      );
}

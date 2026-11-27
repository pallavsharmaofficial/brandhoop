import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'api.dart';

const brand = Color(0xFFFF5A0A);
const brandSoft = Color(0xFFFFF6F1);
const ink = Color(0xFF1C1C1E);
const muted = Color(0xFF6B7280);
const danger = Color(0xFFE5112B);
const success = Color(0xFF16B33F);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: brand, primary: brand, surface: Colors.white);
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: ink, elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
        titleTextStyle: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w500)),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: brand, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: brand, minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: brand, minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: brand, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
  );
}

// ---------- formatting ----------
final _inr = NumberFormat.decimalPattern('en_IN');
String rupees(num? v) => v == null ? '-' : '₹${_inr.format(v % 1 == 0 ? v.toInt() : v)}';
String num0(num? v) => v == null ? '-' : _inr.format(v % 1 == 0 ? v.toInt() : v);

String timeAgo(String? iso) {
  if (iso == null) return 'never';
  final d = DateTime.now().difference(DateTime.parse(iso).toLocal());
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes}m ago';
  if (d.inDays < 1) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  if (d.inDays < 30) return '${d.inDays ~/ 7}w ago';
  if (d.inDays < 365) return '${d.inDays ~/ 30}mo ago';
  return '${d.inDays ~/ 365}y ago';
}

String dmy(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  final d = DateTime.parse(iso).toLocal();
  return DateFormat('dd-MM-yyyy').format(d);
}

String dmyhm(String? iso) => iso == null ? '-' : DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.parse(iso).toLocal());

// ---------- status helpers ----------
bool isInactive(Map d) =>
    d['status'] == 'active' && (d['lastSeenAt'] == null || DateTime.now().difference(DateTime.parse(d['lastSeenAt'])).inDays >= 3);

(String, Color) statusOf(Map d) {
  switch (d['status']) {
    case 'pending':
      return ('Pending setup', const Color(0xFF8E8E93));
    case 'released':
      return ('Released', const Color(0xFF0A84FF));
    case 'removed':
      return ('Uninstalled', const Color(0xFF6B4EFF));
  }
  if (isInactive(d)) return ('Inactive', const Color(0xFFB45309));
  return ('Active', success);
}

(String, Color) lockOf(String? s) => switch (s) {
      'locked' => ('Locked', danger),
      'restricted' => ('Restricted', const Color(0xFFDC6803)),
      'warning' => ('Warning', const Color(0xFFF59E0B)),
      _ => ('Unlocked', success),
    };

// ---------- widgets ----------
class Chip2 extends StatelessWidget {
  const Chip2(this.label, this.color, {super.key});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6),
            boxShadow: [BoxShadow(color: color.withValues(alpha: .25), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      );
}

/// Orange segmented tabs like the reference design.
class OrangeTabs extends StatelessWidget {
  const OrangeTabs({super.key, required this.labels, required this.index, required this.onChanged});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        decoration: BoxDecoration(border: Border.all(color: brand, width: 1.5), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(i),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: i == index ? brand : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                  child: Text(labels[i], maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: i == index ? Colors.white : brand, fontSize: 15, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
        ]),
      );
}

class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFF6F1), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
              border: Border.all(color: brand, width: 1.2),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: padding,
            child: child,
          ),
        ),
      );
}

/// Two-column label/value block with a divider, as in the reference "IMEI 1 | IMEI 2" rows.
class PairRow extends StatelessWidget {
  const PairRow(this.l1, this.v1, this.l2, this.v2, {super.key, this.trailing2});
  final String l1, v1, l2, v2;
  final Widget? trailing2;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: IntrinsicHeight(
          child: Row(children: [
            Expanded(child: _lv(l1, v1, CrossAxisAlignment.start)),
            const VerticalDivider(color: brand, thickness: 1.5, width: 24),
            Expanded(child: trailing2 ?? _lv(l2, v2, CrossAxisAlignment.end)),
          ]),
        ),
      );
}

Widget _lv(String l, String v, CrossAxisAlignment a) => Column(crossAxisAlignment: a, children: [
      Text(l.toUpperCase(), style: const TextStyle(color: muted, fontSize: 13, letterSpacing: .3)),
      const SizedBox(height: 2),
      Text(v.isEmpty ? 'N/A' : v, textAlign: a == CrossAxisAlignment.end ? TextAlign.end : TextAlign.start,
          style: const TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w700)),
    ]);

Widget labelValue(String l, String v) => _lv(l, v, CrossAxisAlignment.start);

/// Phone brand wordmark in its usual colour.
class BrandMark extends StatelessWidget {
  const BrandMark(this.brandName, {super.key, this.size = 26});
  final String brandName;
  final double size;
  static const _colors = {
    'oppo': Color(0xFF046A38), 'vivo': Color(0xFF415FFF), 'realme': Color(0xFF1C1C1E), 'samsung': Color(0xFF1428A0),
    'xiaomi': Color(0xFFFF6900), 'redmi': Color(0xFFFF6900), 'poco': Color(0xFFFFC600), 'oneplus': Color(0xFFEB0028),
    'apple': Color(0xFF1C1C1E), 'iphone': Color(0xFF1C1C1E), 'motorola': Color(0xFF5C92FA), 'nothing': Color(0xFF1C1C1E),
    'iqoo': Color(0xFF1C1C1E), 'infinix': Color(0xFF00A651), 'tecno': Color(0xFF0071CE), 'google': Color(0xFF4285F4), 'nokia': Color(0xFF124191),
  };
  @override
  Widget build(BuildContext context) {
    final key = brandName.toLowerCase().trim();
    if (key.isEmpty) return const SizedBox.shrink();
    if (key == 'realme') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        color: const Color(0xFFFFC915),
        child: Text('realme', style: TextStyle(fontSize: size * .8, fontWeight: FontWeight.w600)),
      );
    }
    return Text(key == 'apple' ? ' iPhone' : key, style: TextStyle(color: _colors[key] ?? muted, fontSize: size, fontWeight: FontWeight.w700, letterSpacing: .5));
  }
}

class CustomerAvatar extends StatelessWidget {
  const CustomerAvatar({super.key, required this.customerId, required this.hasPhoto, this.size = 76});
  final String customerId;
  final bool hasPhoto;
  final double size;
  @override
  Widget build(BuildContext context) {
    final fallback = Container(color: brand, child: Icon(Icons.person, color: const Color(0xFFFFE6DA), size: size * .8));
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: brand, width: 2)),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(Api.I.uri('/api/customers/$customerId/photo').toString(), headers: Api.I.headers(), fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback)
            : fallback,
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  const ActionTile({super.key, required this.icon, required this.label, required this.onTap, this.enabled = true});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: enabled ? 1 : .45,
        child: SoftCard(
          onTap: enabled ? onTap : null,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: brand, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

void toast(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? danger : ink, behavior: SnackBarBehavior.floating));
}

/// Runs an API call with a spinner dialog and error toast. Returns null on failure.
Future<T?> busy<T>(BuildContext context, Future<T> Function() f, {String? done}) async {
  showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: brand)));
  try {
    final r = await f();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      if (done != null) toast(context, done);
    }
    return r;
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      toast(context, '$e', error: true);
    }
    return null;
  }
}

class Loading extends StatelessWidget {
  const Loading({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: brand)));
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry(this.error, this.onRetry, {super.key});
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ]),
        ),
      );
}

/// Max-width page body so the website looks right on a laptop too.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.maxWidth = 760});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child));
}

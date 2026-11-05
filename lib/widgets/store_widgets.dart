import 'package:flutter/material.dart';
import '../app/env.dart';
import '../data/live_shop.dart';

import '../app/theme.dart';
import '../core/dates.dart';
import '../domain/store_settings.dart';
import '../l10n/l10n.dart';
import '../util/launch.dart';

/// "Open now · closes 9:00 PM" or "Closed · opens tomorrow 10:00 AM".
class StoreStatusBadge extends StatelessWidget {
  const StoreStatusBadge(this.settings, {super.key, this.onDark = false});

  final StoreSettings settings;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    // The live storefront shows no "Open now" until the shop has given its hours.
    if (AppEnv.live && !LiveShop.hoursKnown) return const SizedBox.shrink();
    final DateTime now = DateTime.now();
    final bool open = settings.hours.isOpenAt(now);
    final ({DateTime at, bool opening})? next = settings.hours.nextChange(now);
    final String lang = context.lang;
    String detail = '';
    if (next != null) {
      final String t = Dates.time(next.at, lang);
      final bool sameDay = next.at.day == now.day && next.at.month == now.month;
      detail = next.opening
          ? (sameDay ? context.tr.storeOpensAt(t) : context.tr.storeOpensDay(context.tr.weekday(next.at.weekday), t))
          : context.tr.storeClosesAt(t);
    }
    final Color dot = open ? const Color(0xFF43A047) : const Color(0xFFE53935);
    final Color text = onDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(width: 9, height: 9, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '${open ? context.tr.storeOpenNow : context.tr.storeClosedNow}${detail.isEmpty ? '' : ' · $detail'}',
            style: TextStyle(color: text, fontWeight: FontWeight.w700, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Call, WhatsApp and Directions. A button whose number the owner has not
/// entered yet is simply not shown.
class ContactButtons extends StatelessWidget {
  const ContactButtons({super.key, required this.settings, this.whatsappText = '', this.onDark = false, this.compact = false});

  final StoreSettings settings;
  final String whatsappText;
  final bool onDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final List<Widget> buttons = <Widget>[
      if (settings.hasPhone)
        _btn(context, Icons.call_outlined, context.tr.call, () => Launch.call(settings.phone)),
      if (settings.hasWhatsapp)
        _btn(context, Icons.chat_outlined, context.tr.whatsapp, () => Launch.whatsapp(settings.whatsapp, text: whatsappText)),
      _btn(context, Icons.directions_outlined, context.tr.directions, () => Launch.maps(settings.mapsLink)),
    ];
    return Wrap(spacing: 8, runSpacing: 8, children: buttons);
  }

  Widget _btn(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final Color fg = onDark ? Colors.white : Theme.of(context).colorScheme.primary;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: fg),
      label: Text(label, style: TextStyle(color: fg)),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(compact ? 0 : 64, compact ? 40 : 46),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        side: BorderSide(color: onDark ? Colors.white54 : Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

/// The shop's address block used on Home, the Store screen and invoices.
class AddressLines extends StatelessWidget {
  const AddressLines(this.settings, {super.key, this.onDark = false});

  final StoreSettings settings;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final String lang = context.lang;
    final Color c = onDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final Color sub = onDark ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${settings.addressLine.of(lang)}, ${settings.cityOf(lang)}, ${settings.stateOf(lang)} ${settings.pincode}',
          style: TextStyle(color: c, fontWeight: FontWeight.w600, height: 1.3),
        ),
        if (!settings.landmark.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(settings.landmark.of(lang), style: TextStyle(color: sub, fontSize: 13)),
          ),
      ],
    );
  }
}

/// A row of reasons to trust a small-town shop's app.
class TrustBadges extends StatelessWidget {
  const TrustBadges({super.key});

  @override
  Widget build(BuildContext context) {
    final List<(IconData, String)> items = <(IconData, String)>[
      // The storefront says only that this is a shop you can walk into.
      if (!AppEnv.live) (Icons.verified_outlined, context.tr.trustGenuine),
      if (!AppEnv.live) (Icons.receipt_long_outlined, context.tr.trustGstBill),
      (Icons.storefront_outlined, context.tr.trustLocal),
      if (!AppEnv.live) (Icons.build_circle_outlined, context.tr.trustService),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final (IconData, String) i in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: BrandColors.indigo.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(i.$1, size: 16, color: BrandColors.indigo),
                const SizedBox(width: 6),
                Text(i.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
      ],
    );
  }
}

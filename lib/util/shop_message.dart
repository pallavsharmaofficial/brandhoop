import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/store_settings.dart';
import '../l10n/l10n.dart';
import '../state/data_cubits.dart';
import 'launch.dart';

/// Sends [text] to the shop on WhatsApp. This is how an order, an enquiry, a
/// repair or a visit reaches the shop in the live storefront, which has no
/// server of its own. If the shop's number is not set, or WhatsApp cannot open,
/// the message is shown so the customer can share or copy it instead of losing it.
Future<void> sendToShop(BuildContext context, String text) async {
  final StoreSettings store = context.read<StoreCubit>().state;
  if (store.hasWhatsapp && await Launch.whatsapp(store.whatsapp, text: text)) return;
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: Text(ctx.tr.liveShareTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(ctx.tr.liveShareBody),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(text),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr.close)),
        TextButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: text)),
          child: Text(ctx.tr.copy),
        ),
        FilledButton(
          onPressed: () {
            Launch.shareText(text);
            Navigator.pop(ctx);
          },
          child: Text(ctx.tr.share),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../data/live_shop.dart';
import '../../domain/store_settings.dart';
import '../../l10n/l10n.dart';
import '../../state/data_cubits.dart';
import '../../util/launch.dart';
import '../../util/shop_message.dart';
import '../../widgets/common.dart';

/// A strip of the shop's own photos (festival gifts, offers) from the shop file.
/// A photo that cannot be loaded simply leaves a quiet tile, never an error.
class LiveGalleryStrip extends StatelessWidget {
  const LiveGalleryStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final List<GalleryItem> items = LiveShop.gallery;
    if (items.isEmpty) return const SizedBox.shrink();
    final String lang = context.lang;
    return Section(
      title: context.tr.liveGalleryTitle,
      child: SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (BuildContext _, int _) => const SizedBox(width: 12),
          itemBuilder: (BuildContext _, int i) {
            final GalleryItem g = items[i];
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => showDialog<void>(
                context: context,
                builder: (BuildContext ctx) => Dialog(
                  insetPadding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(child: InteractiveViewer(child: Image.network(g.url, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox(height: 120, child: Icon(Icons.image_not_supported_outlined))))),
                      if (!g.caption.isEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(g.caption.of(lang), style: const TextStyle(fontWeight: FontWeight.w700))),
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr.close)),
                    ],
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 250,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Image.network(g.url, fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(color: Color(0x11000000))),
                      if (!g.caption.isEmpty)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(10, 22, 10, 10),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Colors.transparent, Colors.black87]),
                            ),
                            child: Text(g.caption.of(lang), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, height: 1.25)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// "Worried prices will go up?" and one tap to ask for today's best price.
class LiveWorryCard extends StatelessWidget {
  const LiveWorryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final StoreSettings store = context.watch<StoreCubit>().state;
    final String shop = store.name.of(context.lang);
    final bool hasPhone = store.phone.trim().isNotEmpty;
    return Card(
      color: BrandColors.saffronSoft.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(children: <Widget>[
              const Icon(Icons.trending_up, color: BrandColors.saffron),
              const SizedBox(width: 8),
              Expanded(child: Text(context.tr.liveWorryTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
            ]),
            const SizedBox(height: 6),
            Text(context.tr.liveWorryBody, style: const TextStyle(height: 1.4)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: BrandColors.saffron, foregroundColor: Colors.black87),
                  onPressed: () => sendToShop(context, context.tr.liveGenericAsk(shop)),
                  icon: const Icon(Icons.chat_outlined),
                  label: Text(context.tr.liveWorryCta),
                ),
                if (hasPhone)
                  OutlinedButton.icon(onPressed: () => Launch.call(store.phone), icon: const Icon(Icons.call), label: Text(context.tr.liveBargainBtn)),
                OutlinedButton.icon(onPressed: () => context.go(Routes.shop), icon: const Icon(Icons.storefront_outlined), label: Text(context.tr.navShop)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

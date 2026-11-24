import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/env.dart';
import '../../data/live_shop.dart';
import 'live_home.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../domain/offer.dart';
import '../../domain/product.dart';
import '../../domain/store_settings.dart';
import '../../l10n/l10n.dart';
import '../../state/cart_cubit.dart';
import '../../state/data_cubits.dart';
import '../../state/session_cubit.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/common.dart';
import '../../widgets/product_art.dart';
import '../../widgets/product_card.dart';
import '../../util/launch.dart';
import '../../util/shop_message.dart';
import '../../widgets/store_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Product> products = context.watch<ProductsCubit>().state.where((Product p) => p.active).toList();
    final StoreSettings store = context.watch<StoreCubit>().state;
    final List<Offer> offers = context
        .watch<OffersCubit>()
        .state
        .where((Offer o) => o.kind == OfferKind.banner && o.isLive(DateTime.now()))
        .toList();
    final String lang = context.lang;

    final List<Product> emiPhones = products
        .where((Product p) => p.category == ProductCategory.smartphone && p.noCostEmi && p.inStock)
        .toList()
      ..sort((Product a, Product b) => (b.featured ? 1 : 0).compareTo(a.featured ? 1 : 0));
    final List<Product> accessoryPicks = products
        .where((Product p) => p.category.group == ProductGroup.accessories && p.featured && p.inStock)
        .take(6)
        .toList();

    final Map<String, int> brandCount = <String, int>{};
    for (final Product p in products.where((Product p) => p.category == ProductCategory.smartphone && p.brand.trim().isNotEmpty)) {
      brandCount[p.brand] = (brandCount[p.brand] ?? 0) + 1;
    }
    final List<String> brands = brandCount.keys.toList()
      ..sort((String a, String b) => brandCount[b]!.compareTo(brandCount[a]!) != 0 ? brandCount[b]!.compareTo(brandCount[a]!) : a.compareTo(b));
    final List<Product> popular = products.where((Product p) => p.category == ProductCategory.smartphone).toList()
      ..sort((Product a, Product b) {
        final int f = (b.featured ? 1 : 0).compareTo(a.featured ? 1 : 0);
        if (f != 0) return f;
        return (b.imageUrls.isEmpty ? 0 : 1).compareTo(a.imageUrls.isEmpty ? 0 : 1);
      });

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: <Widget>[
            const BrandMark(size: 34),
            const SizedBox(width: 10),
            Flexible(child: Text(context.tr.appName, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: <Widget>[
          if (context.watch<SessionCubit>().state.isStaff)
            IconButton(
              tooltip: context.tr.openAdmin,
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () async {
                await context.read<SessionCubit>().setMode(AppMode.admin);
                if (context.mounted) context.go(Routes.adminDashboard);
              },
            ),
          const LanguageButton(),
          const _CartButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: MaxWidth(
        wideWidth: 1180,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: <Widget>[
            if (AppEnv.demo)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: InfoBanner(text: context.tr.demoBanner, icon: Icons.science_outlined, color: BrandColors.saffron),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _SearchBox(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: AppEnv.live ? _LiveHero(store: store) : _Hero(store: store),
            ),
            if (AppEnv.live) Padding(padding: const EdgeInsets.only(top: 16), child: _QuickActions(store: store)),
            if (offers.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 18), child: _OfferCarousel(offers: offers, lang: lang)),
            if (brands.length > 1)
              Section(
                title: context.tr.shopByBrand,
                child: _BrandRow(brands: brands.take(14).toList()),
              ),
            if (AppEnv.live && popular.isNotEmpty)
              Section(
                title: context.tr.popularPhones,
                action: context.tr.viewAll,
                onAction: () => context.go(Routes.shopWith(category: ProductCategory.smartphone.name)),
                child: SizedBox(
                  height: 300,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: popular.length.clamp(0, 12),
                    separatorBuilder: (BuildContext _, int _) => const SizedBox(width: 12),
                    itemBuilder: (BuildContext _, int i) => ProductCard(product: popular[i], settings: store, width: 176),
                  ),
                ),
              ),
            if (AppEnv.live) ...<Widget>[
              const LiveGalleryStrip(),
              const Padding(padding: EdgeInsets.only(top: 16), child: LiveWorryCard()),
            ],
            Section(
              title: context.tr.shopByCategory,
              child: _CategoryRow(),
            ),
            Section(
              title: context.tr.shopByBudget,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _budget(context, context.tr.budgetUnder10, null, 10000),
                  _budget(context, context.tr.budget10to15, 10000, 15000),
                  _budget(context, context.tr.budget15to20, 15000, 20000),
                  _budget(context, context.tr.budgetAbove20, 20000, null),
                ],
              ),
            ),
            if (emiPhones.isNotEmpty && (!AppEnv.live || store.emiRatesConfirmed))
              Section(
                title: context.tr.zeroEmiPhones,
                action: context.tr.viewAll,
                onAction: () => context.go(Routes.shopWith(category: ProductCategory.smartphone.name, emi: true)),
                child: SizedBox(
                  height: 300,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: emiPhones.length,
                    separatorBuilder: (BuildContext _, int _) => const SizedBox(width: 12),
                    itemBuilder: (BuildContext _, int i) => ProductCard(product: emiPhones[i], settings: store, width: 176),
                  ),
                ),
              ),
            Section(
              title: context.tr.ourServices,
              child: Row(
                children: <Widget>[
                  if (!AppEnv.live || LiveShop.repair) ...<Widget>[
                    Expanded(child: _ServiceTile(Icons.build_outlined, context.tr.serviceRepair, () => context.push(Routes.repair))),
                    const SizedBox(width: 10),
                  ],
                  if (!AppEnv.live || LiveShop.exchange) ...<Widget>[
                    Expanded(child: _ServiceTile(Icons.swap_horiz, context.tr.serviceExchange, () => context.push(Routes.exchange))),
                    const SizedBox(width: 10),
                  ],
                  Expanded(child: _ServiceTile(Icons.calculate_outlined, context.tr.serviceEmiCalc, () => context.push(Routes.calculator))),
                ],
              ),
            ),
            if (accessoryPicks.isNotEmpty)
              Section(
                title: context.tr.accessoryPicks,
                action: context.tr.viewAll,
                onAction: () => context.go(Routes.shopWith(group: ProductGroup.accessories.name)),
                child: GridView.count(
                  crossAxisCount: MediaQuery.sizeOf(context).width >= 1000 ? 5 : (MediaQuery.sizeOf(context).width > 560 ? 3 : 2),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                  children: <Widget>[
                    for (final Product p in accessoryPicks) ProductCard(product: p, settings: store),
                  ],
                ),
              ),
            Section(
              title: context.tr.whyBrandhoop,
              child: AppEnv.live
                  ? LayoutBuilder(builder: (BuildContext context, BoxConstraints box) {
                      final List<Widget> tiles = <Widget>[
                        _TrustTile(Icons.storefront_outlined, context.tr.homeTrustLocal, context.tr.homeTrustLocalSub),
                        _TrustTile(Icons.call_outlined, context.tr.homeTrustBargain, context.tr.homeTrustBargainSub),
                        _TrustTile(Icons.card_giftcard, context.tr.homeTrustGifts, context.tr.homeTrustGiftsSub),
                        _TrustTile(Icons.account_balance_wallet_outlined, context.tr.homeTrustEmi, context.tr.homeTrustEmiSub),
                      ];
                      if (box.maxWidth >= 720) {
                        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          for (int k = 0; k < tiles.length; k++) ...<Widget>[
                            if (k > 0) const SizedBox(width: 10),
                            Expanded(child: tiles[k]),
                          ],
                        ]);
                      }
                      return Column(children: <Widget>[
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Expanded(child: tiles[0]), const SizedBox(width: 10), Expanded(child: tiles[1])]),
                        const SizedBox(height: 10),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Expanded(child: tiles[2]), const SizedBox(width: 10), Expanded(child: tiles[3])]),
                      ]);
                    })
                  : Column(
                      children: <Widget>[
                        _Why(Icons.verified_outlined, context.tr.whyGenuineTitle, context.tr.whyGenuineBody),
                        _Why(Icons.storefront_outlined, context.tr.whyLocalTitle, context.tr.whyLocalBody),
                        _Why(Icons.account_balance_wallet_outlined, context.tr.whyPayTitle, context.tr.whyPayBody),
                        _Why(Icons.support_agent_outlined, context.tr.whySupportTitle, context.tr.whySupportBody),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: _VisitCard(store: store),
            ),
          ],
        ),
      ),
    );
  }

  Widget _budget(BuildContext context, String label, int? min, int? max) => ActionChip(
        label: Text(label),
        onPressed: () => context.go(Routes.shopWith(category: ProductCategory.smartphone.name, min: min, max: max)),
      );
}

class _CartButton extends StatelessWidget {
  const _CartButton();

  @override
  Widget build(BuildContext context) {
    final int n = context.watch<CartCubit>().count;
    return IconButton(
      tooltip: context.tr.cartTitle,
      onPressed: () => context.push(Routes.cart),
      icon: Badge(
        isLabelVisible: n > 0,
        label: Text('$n'),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.store});
  final StoreSettings store;

  @override
  Widget build(BuildContext context) {
    final String lang = context.lang;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[BrandColors.indigoDeep, BrandColors.indigo, Color(0xFF3F51B5)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            store.name.of(lang),
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            store.tagline.of(lang),
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 12),
          StoreStatusBadge(store, onDark: true),
          const SizedBox(height: 6),
          AddressLines(store, onDark: true),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.push(Routes.store),
                  style: FilledButton.styleFrom(backgroundColor: BrandColors.saffron, foregroundColor: Colors.black87),
                  icon: const Icon(Icons.storefront_outlined),
                  label: Text(context.tr.visitStore),
                ),
              ),
            ],
          ),
            ),
          ),
          const SizedBox(height: 10),
          ContactButtons(settings: store, onDark: true, compact: true),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextField(
        readOnly: false,
        textInputAction: TextInputAction.search,
        onSubmitted: (String q) => context.go(Routes.shopWith(q: q.trim())),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: context.tr.searchHint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.6)),
        ),
      );
}

const List<List<Color>> _offerColors = <List<Color>>[
  <Color>[Color(0xFF283593), Color(0xFF5C6BC0)],
  <Color>[Color(0xFFEF6C00), Color(0xFFFFB74D)],
  <Color>[Color(0xFF00695C), Color(0xFF4DB6AC)],
  <Color>[Color(0xFF6A1B9A), Color(0xFFBA68C8)],
];

class _OfferCarousel extends StatefulWidget {
  const _OfferCarousel({required this.offers, required this.lang});
  final List<Offer> offers;
  final String lang;

  @override
  State<_OfferCarousel> createState() => _OfferCarouselState();
}

class _OfferCarouselState extends State<_OfferCarousel> {
  PageController? _controller;
  int _page = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final double fraction = MediaQuery.sizeOf(context).width >= 900 ? 0.4 : 0.9;
    if (_controller == null || _controller!.viewportFraction != fraction) {
      _controller?.dispose();
      _controller = PageController(viewportFraction: fraction, initialPage: _page);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Offer> offers = widget.offers;
    final String lang = widget.lang;
    return Column(
      children: <Widget>[
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _controller,
            padEnds: MediaQuery.sizeOf(context).width < 900,
            onPageChanged: (int i) => setState(() => _page = i),
            itemCount: offers.length,
            itemBuilder: (BuildContext _, int i) {
              final Offer o = offers[i];
              final List<Color> c = _offerColors[o.colorSeed.abs() % _offerColors.length];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => context.go(o.id == 'o_exchange' ? Routes.exchange : Routes.shop),
                  child: Ink(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(colors: c, begin: Alignment.topLeft, end: Alignment.bottomRight),
                      image: o.imageUrl.isEmpty
                          ? null
                          : DecorationImage(
                              image: NetworkImage(o.imageUrl),
                              fit: BoxFit.cover,
                              colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.darken),
                              onError: (Object _, StackTrace? _) {},
                            ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          o.title.of(lang),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900, height: 1.2),
                        ),
                        if (!o.subtitle.isEmpty) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            o.subtitle.of(lang),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (offers.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (int i = 0; i < offers.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? BrandColors.indigo : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LiveHero extends StatelessWidget {
  const _LiveHero({required this.store});
  final StoreSettings store;

  @override
  Widget build(BuildContext context) {
    final String lang = context.lang;
    final String shop = store.name.of(lang);
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[BrandColors.indigoDeep, BrandColors.indigo, Color(0xFF3F51B5)],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(right: -30, top: -40, child: Container(width: 170, height: 170, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)))),
            Positioned(right: 14, bottom: 10, child: Icon(Icons.smartphone, size: 130, color: Colors.white.withValues(alpha: 0.10))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(shop, style: const TextStyle(color: BrandColors.saffronSoft, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                  const SizedBox(height: 8),
                  Text(
                    context.tr.heroLiveTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1.12),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Text(context.tr.heroLiveSub, style: const TextStyle(color: Colors.white70, height: 1.4)),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: () => context.go(Routes.shopWith(category: ProductCategory.smartphone.name)),
                        style: FilledButton.styleFrom(backgroundColor: BrandColors.saffron, foregroundColor: Colors.black87),
                        icon: const Icon(Icons.smartphone),
                        label: Text(context.tr.heroBrowse),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => sendToShop(context, context.tr.liveGenericAsk(shop)),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                        icon: const Icon(Icons.chat_outlined),
                        label: Text(context.tr.heroAsk),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  StoreStatusBadge(store, onDark: true),
                  const SizedBox(height: 4),
                  AddressLines(store, onDark: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.store});
  final StoreSettings store;

  @override
  Widget build(BuildContext context) {
    final String shop = store.name.of(context.lang);
    final List<Widget> items = <Widget>[
      _QuickAction(Icons.chat_outlined, context.tr.whatsapp, () => sendToShop(context, context.tr.liveGenericAsk(shop))),
      if (store.phone.trim().isNotEmpty) _QuickAction(Icons.call_outlined, context.tr.call, () => Launch.call(store.phone)),
      _QuickAction(Icons.directions_outlined, context.tr.directions, () => Launch.maps(store.mapsLink)),
      _QuickAction(Icons.storefront_outlined, context.tr.visitStore, () => context.push(Routes.store)),
    ];
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: items)),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: 78,
        child: Column(
          children: <Widget>[
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primaryContainer.withValues(alpha: 0.7)),
              child: Icon(icon, color: cs.primary),
            ),
            const SizedBox(height: 6),
            Text(label, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.15)),
          ],
        ),
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.brands});
  final List<String> brands;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: brands.length,
          separatorBuilder: (BuildContext _, int _) => const SizedBox(width: 8),
          itemBuilder: (BuildContext _, int i) => ActionChip(
            avatar: CircleAvatar(
              radius: 12,
              backgroundColor: BrandColors.indigo,
              child: Text(brands[i].characters.first.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
            ),
            label: Text(brands[i]),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            shape: const StadiumBorder(),
            onPressed: () => context.go(Routes.shopWith(category: ProductCategory.smartphone.name, brand: brands[i])),
          ),
        ),
      );
}

class _TrustTile extends StatelessWidget {
  const _TrustTile(this.icon, this.title, this.sub);
  final IconData icon;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: BrandColors.saffronSoft.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: BrandColors.saffron, size: 22),
              ),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, height: 1.2)),
              const SizedBox(height: 3),
              Text(sub, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35)),
            ],
          ),
        ),
      );
}

/// Real photos (free licence, docs/CREDITS.md) for the categories that have one.
const Map<ProductCategory, String> _categoryPhoto = <ProductCategory, String>{
  ProductCategory.smartphone: 'assets/img/cat_phones.jpg',
  ProductCategory.earphones: 'assets/img/cat_earbuds.jpg',
  ProductCategory.charger: 'assets/img/cat_wall.jpg',
  ProductCategory.powerBank: 'assets/img/cat_chargers.jpg',
  ProductCategory.cable: 'assets/img/cat_cable.jpg',
  ProductCategory.caseCover: 'assets/img/cat_case.jpg',
  ProductCategory.screenGuard: 'assets/img/cat_glass.jpg',
  ProductCategory.smartwatch: 'assets/img/cat_watch.jpg',
  ProductCategory.speaker: 'assets/img/cat_speaker.jpg',
  ProductCategory.memory: 'assets/img/cat_memory.jpg',
  ProductCategory.holder: 'assets/img/cat_stand.jpg',
};

class _CategoryRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<ProductCategory> cats = <ProductCategory>[
      ProductCategory.smartphone,
      ProductCategory.featurePhone,
      ProductCategory.earphones,
      ProductCategory.charger,
      ProductCategory.caseCover,
      ProductCategory.screenGuard,
      ProductCategory.powerBank,
      ProductCategory.smartwatch,
      ProductCategory.cable,
      ProductCategory.speaker,
      ProductCategory.memory,
      ProductCategory.holder,
    ];
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (BuildContext _, int _) => const SizedBox(width: 12),
        itemBuilder: (BuildContext _, int i) {
          final ProductCategory c = cats[i];
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.go(Routes.shopWith(category: c.name)),
            child: SizedBox(
              width: 76,
              child: Column(
                children: <Widget>[
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _categoryPhoto[c] == null
                        ? Icon(categoryIcon(c), color: Theme.of(context).colorScheme.primary)
                        : Image.asset(_categoryPhoto[c]!, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr.category(c),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.15),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              children: <Widget>[
                Icon(icon, color: BrandColors.saffron, size: 28),
                const SizedBox(height: 6),
                Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, height: 1.2)),
              ],
            ),
          ),
        ),
      );
}

class _Why extends StatelessWidget {
  const _Why(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: BrandColors.saffronSoft.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: BrandColors.saffron, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(body, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.store});
  final StoreSettings store;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.place_outlined, color: BrandColors.indigo),
                  const SizedBox(width: 8),
                  Text(context.tr.visitUsAnytime, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              AddressLines(store),
              const SizedBox(height: 8),
              StoreStatusBadge(store),
              const SizedBox(height: 12),
              ContactButtons(settings: store),
            ],
          ),
        ),
      );
}

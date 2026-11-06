import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/env.dart';
import '../../data/live_shop.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/validators.dart';
import '../../domain/lead.dart';
import '../../domain/product.dart';
import '../../domain/store_settings.dart';
import '../../l10n/l10n.dart';
import '../../services/app_services.dart';
import '../../services/emi_hint.dart';
import '../../state/cart_cubit.dart';
import '../../state/data_cubits.dart';
import '../../state/session_cubit.dart';
import '../../util/launch.dart';
import '../../util/shop_message.dart';
import '../../widgets/common.dart';
import '../../widgets/product_art.dart';
import '../../widgets/product_card.dart';
import '../../widgets/store_widgets.dart';
import '../auth/auth_gate.dart';
import 'emi_plans_sheet.dart';
import 'live_widgets.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  String? _variantId;
  final Set<String> _addons = <String>{};
  final TextEditingController _pin = TextEditingController();
  String? _pinResult;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Product> all = context.watch<ProductsCubit>().state;
    final Product? p = all.where((Product x) => x.id == widget.productId).firstOrNull;
    final StoreSettings store = context.watch<StoreCubit>().state;
    final SessionState session = context.watch<SessionCubit>().state;
    final String lang = context.lang;

    if (p == null || !p.active) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.inventory_2_outlined, title: context.tr.productNotFound),
      );
    }
    final ProductVariant v = p.variant(_variantId ?? '') ?? p.lead;
    final bool wished = session.user?.wishlist.contains(p.id) ?? false;
    final EmiHint? emi = EmiHint.forProduct(store, p, v.price);

    final List<Product> addons = p.isPhone
        ? all
            .where((Product a) => a.active && a.inStock && (a.id == 'ac_glass' || a.id == 'ac_case' || a.id == 'pr_screen'))
            .toList()
        : <Product>[];
    final int addonsTotal = addons.where((Product a) => _addons.contains(a.id)).fold(0, (int s, Product a) => s + a.minPrice);

    final List<Product> similar = all
        .where((Product x) => x.active && x.id != p.id && x.category == p.category && x.minPrice > v.price * 0.6 && x.minPrice < v.price * 1.5)
        .take(8)
        .toList();

    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          if (!AppEnv.live)
            IconButton(
              tooltip: context.tr.wishlist,
              icon: Icon(wished ? Icons.favorite : Icons.favorite_border, color: wished ? BrandColors.red : null),
              onPressed: () async {
                final user = await ensureSignedIn(context);
                if (user == null || !context.mounted) return;
                await context.read<AppServices>().profile.toggleWishlist(user, p.id);
              },
            ),
          IconButton(
            tooltip: context.tr.share,
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Launch.shareText(context.tr.shareProductText(p.name.of(lang), formatRupees(v.price), store.name.of(lang))),
          ),
          IconButton(
            onPressed: () => context.push(Routes.cart),
            icon: Badge(
              isLabelVisible: context.watch<CartCubit>().count > 0,
              label: Text('${context.watch<CartCubit>().count}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: p.callForBest
          ? LiveBargainBar(product: p, variant: v)
          : _BottomBar(
        product: p,
        variant: v,
        addonIds: _addons,
        addons: addons,
        onAdd: () => _add(context, p, v, buyNow: false),
        onBuy: () => _add(context, p, v, buyNow: true),
        askLabel: context.tr.askAboutThis,
        onAsk: () => _enquire(context, p, v, store),
        total: v.price + addonsTotal,
      ),
      body: _ProductLayout(
          children: <Widget>[
            AspectRatio(
              aspectRatio: 1.5,
              child: ProductArt(product: p, radius: 20),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(p.brand.toUpperCase(), style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 1, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(p.name.of(lang), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, height: 1.2)),
                  if (p.tags.contains('illustration'))
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: StatusPill(context.tr.liveIllustration, color: BrandColors.indigo, icon: Icons.photo_outlined),
                    ),
                  if (p.tags.contains('sample'))
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: StatusPill(context.tr.sampleListing, color: BrandColors.saffron, icon: Icons.science_outlined),
                    ),
                  const SizedBox(height: 12),
                  if (p.callForBest)
                    LiveReferencePrice(product: p, variant: v)
                  else ...<Widget>[
                    PriceBlock(price: v.price, mrp: v.mrp, large: true),
                    const SizedBox(height: 2),
                    Text(context.tr.inclGst, style: Theme.of(context).textTheme.bodySmall),
                  ],
                  if (p.variants.length > 1) ...<Widget>[
                    const SizedBox(height: 14),
                    Text(context.tr.chooseVariant, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final ProductVariant x in p.variants)
                          ChoiceChip(
                            label: Text(<String>[x.label, if (x.color.isNotEmpty) x.color].join(' · ')),
                            selected: x.id == v.id,
                            onSelected: x.inStock || p.callForBest ? (_) => setState(() => _variantId = x.id) : null,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (p.callForBest) ...<Widget>[
                    Text(context.tr.liveAskAvailability, style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (p.tags.contains('fit')) Text(context.tr.liveAskModel, style: Theme.of(context).textTheme.bodySmall),
                  ] else
                    _StockLine(variant: v),
                  if (AppEnv.live) LiveBenefitCard(product: p, variant: v),
                ],
              ),
            ),
            if (emi != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext _) => EmiPlansSheet(settings: store, product: p, price: v.price),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.credit_score_outlined, color: BrandColors.indigo),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  emi.zeroInterest ? context.tr.emiFromZero(formatRupees(emi.emi)) : context.tr.emiFrom(formatRupees(emi.emi)),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                ),
                                Text(context.tr.emiPartners, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (p.isPhone && store.reserveEnabled && v.price > store.reserveToken && (!AppEnv.live || LiveShop.reserve))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Card(
                  color: BrandColors.saffronSoft.withValues(alpha: 0.35),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(Icons.bookmark_added_outlined, color: BrandColors.saffron),
                            const SizedBox(width: 8),
                            Expanded(child: Text(context.tr.reserveTitle(formatRupees(store.reserveToken)), style: const TextStyle(fontWeight: FontWeight.w900))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(context.tr.reserveBody(context.tr.hoursCount(store.reserveHours)), style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4)),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: v.inStock ? () => _add(context, p, v, buyNow: true, reserve: true) : null,
                          child: Text(context.tr.reserveCta),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (AppEnv.live && !LiveShop.delivery)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.storefront_outlined),
                    title: Text(context.tr.pickupAnytime),
                  ),
                ),
              )
            else
            Section(
              title: context.tr.deliveryTitle,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(Icons.local_shipping_outlined, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(context.tr.deliveryLocal(store.cityOf(lang)), style: const TextStyle(height: 1.35))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(Icons.storefront_outlined, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(context.tr.pickupAnytime, style: const TextStyle(height: 1.35))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: _pin,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: InputDecoration(hintText: context.tr.enterPincode, counterText: '', isDense: true),
                              onSubmitted: (_) => _checkPin(context, store),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            style: FilledButton.styleFrom(minimumSize: const Size(80, 48)),
                            onPressed: () => _checkPin(context, store),
                            child: Text(context.tr.check),
                          ),
                        ],
                      ),
                      if (_pinResult != null)
                        Padding(padding: const EdgeInsets.only(top: 8), child: Text(_pinResult!, style: const TextStyle(fontWeight: FontWeight.w700))),
                    ],
                  ),
                ),
              ),
            ),
            if (addons.isNotEmpty)
              Section(
                title: context.tr.completeYourPhone,
                child: Card(
                  child: Column(
                    children: <Widget>[
                      for (final Product a in addons)
                        CheckboxListTile(
                          value: _addons.contains(a.id),
                          onChanged: (bool? on) => setState(() => on == true ? _addons.add(a.id) : _addons.remove(a.id)),
                          secondary: SizedBox(width: 44, height: 44, child: ProductArt(product: a, radius: 10, iconSize: 22)),
                          title: Text(a.name.of(lang), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          subtitle: Text(formatRupees(a.minPrice)),
                          controlAffinity: ListTileControlAffinity.trailing,
                        ),
                    ],
                  ),
                ),
              ),
            if (!p.description.isEmpty || p.highlights.isNotEmpty)
              Section(
                title: context.tr.aboutProduct,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (!p.description.isEmpty) Text(p.description.of(lang), style: const TextStyle(height: 1.45)),
                    for (final h in p.highlights)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Icon(Icons.check_circle_outline, size: 18, color: BrandColors.green),
                            const SizedBox(width: 8),
                            Expanded(child: Text(h.of(lang))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            if (p.specs.isNotEmpty)
              Section(
                title: context.tr.specifications,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: <Widget>[
                        for (final MapEntry<String, String> e in p.specs.entries) KeyValue(context.tr.specLabel(e.key), e.value),
                        if (p.warrantyMonths > 0) KeyValue(context.tr.warranty, context.tr.warrantyMonths(p.warrantyMonths)),
                      ],
                    ),
                  ),
                ),
              ),
            Section(title: context.tr.whyBuyFromUs, child: const TrustBadges()),
            if (similar.isNotEmpty)
              Section(
                title: context.tr.similarProducts,
                child: SizedBox(
                  height: 296,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: similar.length,
                    separatorBuilder: (BuildContext _, int _) => const SizedBox(width: 12),
                    itemBuilder: (BuildContext _, int i) => ProductCard(product: similar[i], settings: store, width: 172),
                  ),
                ),
              ),
          ],
      ),
    );
  }

  void _checkPin(BuildContext context, StoreSettings store) {
    final String pin = _pin.text.trim();
    if (!Validators.pincode(pin)) {
      setState(() => _pinResult = context.tr.errBadPincode);
      return;
    }
    setState(() {
      _pinResult = store.isLocalPincode(pin)
          ? context.tr.deliverySameDay
          : context.tr.deliveryCourier(formatRupees(store.courierFee), formatRupees(store.freeDeliveryAbove));
    });
  }

  Future<void> _add(BuildContext context, Product p, ProductVariant v, {required bool buyNow, bool reserve = false}) async {
    final CartCubit cart = context.read<CartCubit>();
    final List<Product> catalogue = context.read<ProductsCubit>().state;
    final GoRouter router = GoRouter.of(context);
    await cart.add(p.id, v.id);
    for (final String a in _addons) {
      final Product? ap = catalogue.where((Product x) => x.id == a).firstOrNull;
      if (ap != null) await cart.add(ap.id, ap.lead.id);
    }
    if (!context.mounted) return;
    if (buyNow) {
      unawaited(router.push(AppEnv.live ? Routes.cart : (reserve ? '${Routes.checkout}?mode=reserve' : Routes.checkout)));
    } else {
      toast(context, context.tr.addedToCart);
    }
  }

  Future<void> _enquire(BuildContext context, Product p, ProductVariant v, StoreSettings store) async {
    final String lang = context.lang;
    final String msg = context.tr.enquiryText(p.name.of(lang), v.label, formatRupees(v.price));
    if (AppEnv.live) return sendToShop(context, msg);
    final SessionState session = context.read<SessionCubit>().state;
    final AppServices services = context.read<AppServices>();
    final String ok = context.tr.weWillCallYou;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    String name = session.user?.displayName ?? '';
    String phone = session.user?.phone ?? '';
    if (session.user == null) {
      final ({String name, String phone})? c = await askContact(context, title: context.tr.askAboutThis);
      if (c == null) return;
      name = c.name;
      phone = c.phone;
    }
    await services.leads.capture(
      type: LeadType.enquiry,
      name: name,
      phone: phone,
      userId: session.user?.id,
      productId: p.id,
      productName: p.name.en,
      message: '${v.label}: ${formatRupees(v.price)}',
    );
    if (store.hasWhatsapp) {
      await Launch.whatsapp(store.whatsapp, text: msg);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(ok)));
    }
  }
}

class _StockLine extends StatelessWidget {
  const _StockLine({required this.variant});
  final ProductVariant variant;

  @override
  Widget build(BuildContext context) {
    final bool inStock = variant.inStock;
    final bool low = inStock && variant.stock <= 3;
    final Color c = !inStock ? BrandColors.red : (low ? const Color(0xFFEF6C00) : BrandColors.green);
    final String text = !inStock
        ? context.tr.outOfStock
        : (low ? context.tr.onlyFewLeft(variant.stock) : context.tr.inStockAtStore);
    return Row(
      children: <Widget>[
        Icon(inStock ? Icons.check_circle : Icons.remove_circle_outline, size: 18, color: c),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.product,
    required this.variant,
    required this.addonIds,
    required this.addons,
    required this.onAdd,
    required this.onBuy,
    required this.onAsk,
    required this.askLabel,
    required this.total,
  });

  final Product product;
  final ProductVariant variant;
  final Set<String> addonIds;
  final List<Product> addons;
  final VoidCallback onAdd;
  final VoidCallback onBuy;
  final VoidCallback onAsk;
  final String askLabel;
  final int total;

  @override
  Widget build(BuildContext context) {
    final bool ok = variant.inStock;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        ),
        child: MaxWidth(
          child: Row(
            children: <Widget>[
              IconButton.outlined(onPressed: onAsk, tooltip: askLabel, icon: const Icon(Icons.chat_outlined)),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: OutlinedButton(
                  onPressed: ok ? onAdd : null,
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text(context.tr.addToCart)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: FilledButton(
                  onPressed: ok ? onBuy : onAsk,
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text(ok ? '${context.tr.buyNow} · ${formatRupees(total)}' : context.tr.notifyMe, maxLines: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Phones: one column. Laptops: the photo on the left, everything else on the
/// right, so the price and the buttons sit beside the picture.
class _ProductLayout extends StatelessWidget {
  const _ProductLayout({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const EdgeInsets pad = EdgeInsets.fromLTRB(16, 8, 16, 24);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        if (c.maxWidth < 900) {
          return MaxWidth(child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: children));
        }
        return MaxWidth(
          wideWidth: 1180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: 5, child: ListView(padding: pad, children: <Widget>[children.first])),
              Expanded(flex: 6, child: ListView(padding: pad, children: children.sublist(1))),
            ],
          ),
        );
      },
    );
  }
}

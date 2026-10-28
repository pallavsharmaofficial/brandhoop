import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/emi.dart';
import '../../core/money.dart';
import '../../domain/address.dart';
import '../../domain/app_user.dart';
import '../../domain/emi_plan.dart';
import '../../domain/offer.dart';
import '../../domain/order.dart';
import '../../domain/payment.dart';
import '../../domain/product.dart';
import '../../domain/store_settings.dart';
import '../../l10n/l10n.dart';
import '../../services/app_services.dart';
import '../../services/checkout_service.dart';
import '../../services/emi_service.dart';
import '../../services/payment_gateway.dart';
import '../../services/payment_rules.dart';
import '../../services/pricing.dart';
import '../../state/cart_cubit.dart';
import '../../state/data_cubits.dart';
import '../../state/session_cubit.dart';
import '../../widgets/common.dart';
import 'payment_forms.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, this.reserve = false});

  /// Arrived from "Reserve this phone": start on pickup with the token option.
  final bool reserve;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Fulfilment? _fulfilment;
  String? _addressId;
  PayChoice? _choice;
  PayInstrument? _instrument;
  final TextEditingController _couponField = TextEditingController();
  String _coupon = '';
  bool _useCoins = false;

  String? _schemeId;
  int? _months;
  int? _down;
  bool _downOnline = true;
  bool _submitting = false;

  @override
  void dispose() {
    _couponField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? user = context.watch<SessionCubit>().state.user;
    final StoreSettings store = context.watch<StoreCubit>().state;
    final List<Offer> offers = context.watch<OffersCubit>().state;
    final Map<String, Product> catalogue = <String, Product>{
      for (final Product p in context.watch<ProductsCubit>().state) p.id: p,
    };
    final cart = context.watch<CartCubit>().state;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final Fulfilment fulfilment = _fulfilment ??
        (widget.reserve
            ? Fulfilment.pickup
            : (user.addresses.isNotEmpty ? Fulfilment.delivery : Fulfilment.pickup));
    final Address? address = fulfilment == Fulfilment.delivery
        ? (user.addresses.where((Address a) => a.id == _addressId).firstOrNull ?? user.defaultAddress)
        : null;

    final Quote q = Pricing.quote(
      cart: cart,
      catalogue: catalogue,
      settings: store,
      fulfilment: fulfilment,
      pincode: address?.pincode,
      offers: offers,
      couponCode: _coupon,
      coinsToUse: _useCoins ? user.coins : 0,
      coinBalance: user.coins,
      now: DateTime.now(),
    );

    if (q.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr.checkoutTitle)),
        body: EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: context.tr.cartEmpty,
          actionLabel: context.tr.startShopping,
          onAction: () => context.go(Routes.shop),
        ),
      );
    }

    final List<PayChoice> choices = PaymentRules.available(
      settings: store,
      quote: q,
      fulfilment: fulfilment,
      pincode: address?.pincode,
    );
    final PayChoice choice = (_choice != null && choices.contains(_choice))
        ? _choice!
        : (widget.reserve && choices.contains(PayChoice.reserve) ? PayChoice.reserve : choices.first);

    // EMI selections, kept inside what the chosen scheme allows.
    final List<EmiScheme> schemes = _schemesFor(store, q, choice);
    EmiScheme? scheme = schemes.where((EmiScheme s) => s.id == _schemeId).firstOrNull ?? schemes.firstOrNull;
    final int months = (scheme != null && scheme.tenures.contains(_months)) ? _months! : (scheme?.tenures.isNotEmpty == true ? scheme!.tenures[scheme.tenures.length > 1 ? 1 : 0] : 0);
    final int financeable = choice == PayChoice.cardEmi ? q.total : q.financeable;
    final int down = scheme == null || choice == PayChoice.cardEmi
        ? 0
        : PaymentRules.clampDown(scheme, financeable, _down ?? PaymentRules.minDownPayment(scheme, financeable));
    final int principal = financeable - down;
    final EmiQuote? emi = (scheme != null && months > 0 && principal > 0)
        ? Emi.quote(principal: principal, months: months, annualRatePct: scheme.annualRatePct)
        : null;

    final bool isEmi = choice == PayChoice.bajajEmi || choice == PayChoice.cardEmi;
    final int payNow = _amountNow(choice, q, store, principal);
    final bool needsInstrument = PaymentRules.isOnline(choice) ||
        choice == PayChoice.reserve ||
        choice == PayChoice.cardEmi ||
        (choice == PayChoice.bajajEmi && _downOnline && payNow > 0);
    final bool addressMissing = fulfilment == Fulfilment.delivery && address == null;
    final bool canSubmit = q.isValid && !addressMissing && !_submitting && (!needsInstrument || _instrument != null) && (!isEmi || emi != null);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr.checkoutTitle)),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
          ),
          child: MaxWidth(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(context.tr.orderTotal, style: Theme.of(context).textTheme.bodySmall),
                      Text(formatRupees(q.total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: canSubmit ? () => _submit(context, user, q, choice, scheme, months, down, address, fulfilment) : null,
                  child: Text(_cta(context, choice, payNow, store)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: <Widget>[
            if (q.issues.isNotEmpty) InfoBanner(text: context.tr.errStockChanged, icon: Icons.warning_amber_outlined, color: BrandColors.red, action: context.tr.viewCart, onAction: () => context.pop()),
            _step(context, '1', context.tr.howToReceive),
            Card(
              child: RadioGroup<Fulfilment>(
                groupValue: fulfilment,
                onChanged: (Fulfilment? v) => setState(() => _fulfilment = v),
                child: Column(
                  children: <Widget>[
                    RadioListTile<Fulfilment>(
                      value: Fulfilment.delivery,
                      title: Text(context.tr.fulfilDelivery),
                      subtitle: Text(context.tr.deliveryLocal(store.city)),
                      secondary: const Icon(Icons.local_shipping_outlined),
                    ),
                    const Divider(),
                    RadioListTile<Fulfilment>(
                      value: Fulfilment.pickup,
                      title: Text(context.tr.fulfilPickup),
                      subtitle: Text(context.tr.pickupAnytime),
                      secondary: const Icon(Icons.storefront_outlined),
                    ),
                  ],
                ),
              ),
            ),
            if (fulfilment == Fulfilment.delivery) ...<Widget>[
              const SizedBox(height: 10),
              _addressCard(context, user, address),
            ],
            _step(context, '2', context.tr.offersAndCoins),
            _couponCard(context, offers, q, user),
            _step(context, '3', context.tr.payWith),
            RadioGroup<PayChoice>(
              groupValue: choice,
              onChanged: (PayChoice? v) => setState(() {
                _choice = v;
                _instrument = null;
                _schemeId = null;
                _months = null;
                _down = null;
              }),
              child: Column(children: <Widget>[for (final PayChoice c in choices) _choiceTile(context, c, c == choice, store)]),
            ),
            if (choice == PayChoice.upi) _panel(InstrumentPicker(key: const ValueKey<String>('upi'), methods: const <PaymentMethod>[PaymentMethod.upi], onChanged: _setInstrument)),
            if (choice == PayChoice.card) _panel(InstrumentPicker(key: const ValueKey<String>('card'), methods: const <PaymentMethod>[PaymentMethod.card], onChanged: _setInstrument)),
            if (choice == PayChoice.netbanking) _panel(InstrumentPicker(key: const ValueKey<String>('nb'), methods: const <PaymentMethod>[PaymentMethod.netbanking], onChanged: _setInstrument)),
            if (choice == PayChoice.reserve) _panel(_reservePanel(context, store, q)),
            if (choice == PayChoice.bajajEmi) _panel(_bajajPanel(context, store, q, schemes, scheme, months, down, financeable, emi, payNow)),
            if (choice == PayChoice.cardEmi) _panel(_cardEmiPanel(context, store, q, schemes, scheme, months, emi)),
            if (choice == PayChoice.cashOnDelivery || choice == PayChoice.cashAtStore)
              _panel(InfoBanner(text: context.tr.payChoiceHint(choice), icon: Icons.payments_outlined)),
            _step(context, '4', context.tr.orderSummary),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: <Widget>[
                    for (final PricedLine l in q.lines)
                      KeyValue('${l.product.name.of(context.lang)} × ${l.qty}', formatRupees(l.total)),
                    const Divider(height: 18),
                    KeyValue(context.tr.subtotal, formatRupees(q.subtotal)),
                    if (q.couponDiscount > 0) KeyValue('${context.tr.coupon} ${q.coupon?.code ?? ''}', '-${formatRupees(q.couponDiscount)}', color: BrandColors.green),
                    if (q.coinsUsed > 0) KeyValue(context.tr.coinsUsed, '-${formatRupees(q.coinsUsed)}', color: BrandColors.green),
                    KeyValue(context.tr.deliveryFee, q.deliveryFee == 0 ? context.tr.freeLabel : formatRupees(q.deliveryFee)),
                    const Divider(height: 18),
                    KeyValue(context.tr.orderTotal, formatRupees(q.total), bold: true),
                    Align(alignment: Alignment.centerRight, child: Text(context.tr.inclGst, style: Theme.of(context).textTheme.bodySmall)),
                    if (q.savings > 0) ...<Widget>[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: StatusPill(context.tr.totalSavings(formatRupees(q.savings)), color: BrandColors.green, icon: Icons.savings_outlined),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- helpers ------------------------------------------------------------

  void _setInstrument(PayInstrument? i) {
    if (!mounted) return;
    if (i?.masked == _instrument?.masked && (i == null) == (_instrument == null)) {
      _instrument = i;
      return;
    }
    setState(() => _instrument = i);
  }

  List<EmiScheme> _schemesFor(StoreSettings s, Quote q, PayChoice c) {
    if (c == PayChoice.bajajEmi) {
      return s.schemesFor(q.financeable, provider: EmiProvider.bajaj).where((EmiScheme x) => !x.noCost || q.allNoCostEligible).toList();
    }
    if (c == PayChoice.cardEmi) {
      return s.schemesFor(q.total, provider: EmiProvider.bank).where((EmiScheme x) => !x.noCost || q.allNoCostEligible).toList();
    }
    return const <EmiScheme>[];
  }

  int _amountNow(PayChoice c, Quote q, StoreSettings s, int principal) {
    switch (c) {
      case PayChoice.upi:
      case PayChoice.card:
      case PayChoice.netbanking:
      case PayChoice.cardEmi:
        return q.total;
      case PayChoice.reserve:
        return s.reserveToken;
      case PayChoice.cashOnDelivery:
      case PayChoice.cashAtStore:
        return 0;
      case PayChoice.bajajEmi:
        return q.total - principal;
    }
  }

  String _cta(BuildContext context, PayChoice c, int payNow, StoreSettings s) {
    switch (c) {
      case PayChoice.upi:
      case PayChoice.card:
      case PayChoice.netbanking:
        return context.tr.payAmount(formatRupees(payNow));
      case PayChoice.cardEmi:
        return context.tr.payAmount(formatRupees(payNow));
      case PayChoice.reserve:
        return context.tr.reserveFor(formatRupees(payNow));
      case PayChoice.cashOnDelivery:
      case PayChoice.cashAtStore:
        return context.tr.placeOrder;
      case PayChoice.bajajEmi:
        return payNow > 0 && _downOnline ? context.tr.applyAndPay(formatRupees(payNow)) : context.tr.applyForEmi;
    }
  }

  Widget _step(BuildContext context, String n, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 20, 2, 8),
        child: Row(
          children: <Widget>[
            CircleAvatar(radius: 11, backgroundColor: Theme.of(context).colorScheme.primary, child: Text(n, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900))),
          ],
        ),
      );

  Widget _panel(Widget child) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Card(child: Padding(padding: const EdgeInsets.all(14), child: child)),
      );

  Widget _choiceTile(BuildContext context, PayChoice c, bool selected, StoreSettings store) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6), width: selected ? 2 : 1),
          ),
          child: RadioListTile<PayChoice>(
            value: c,
            title: Text(context.tr.payChoiceName(c), style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(context.tr.payChoiceHint(c, token: formatRupees(store.reserveToken))),
            secondary: Icon(_choiceIcon(c)),
          ),
        ),
      );

  IconData _choiceIcon(PayChoice c) {
    switch (c) {
      case PayChoice.upi:
        return Icons.qr_code_2;
      case PayChoice.card:
        return Icons.credit_card;
      case PayChoice.netbanking:
        return Icons.account_balance_outlined;
      case PayChoice.cashOnDelivery:
        return Icons.payments_outlined;
      case PayChoice.cashAtStore:
        return Icons.storefront_outlined;
      case PayChoice.reserve:
        return Icons.bookmark_added_outlined;
      case PayChoice.bajajEmi:
        return Icons.account_balance_wallet_outlined;
      case PayChoice.cardEmi:
        return Icons.credit_score_outlined;
    }
  }

  Widget _addressCard(BuildContext context, AppUser user, Address? selected) => Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: <Widget>[
              RadioGroup<String>(
                groupValue: selected?.id,
                onChanged: (String? v) => setState(() => _addressId = v),
                child: Column(
                  children: <Widget>[
                    for (final Address a in user.addresses)
                      RadioListTile<String>(
                        value: a.id,
                        title: Text('${a.label} · ${a.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${a.oneLine}\n${a.phone}'),
                        isThreeLine: true,
                      ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => context.push(Routes.address('new')),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: Text(context.tr.addAddress),
              ),
            ],
          ),
        ),
      );

  Widget _couponCard(BuildContext context, List<Offer> offers, Quote q, AppUser user) {
    final List<Offer> live = offers.where((Offer o) => o.isCoupon && o.isLive(DateTime.now())).toList();
    String? err;
    if (_coupon.isNotEmpty && q.couponError != null) {
      switch (q.couponError!) {
        case CouponError.notFound:
          err = context.tr.couponNotFound;
        case CouponError.notActive:
          err = context.tr.couponNotActive;
        case CouponError.minOrder:
          err = context.tr.couponMinOrder;
        case CouponError.notApplicable:
          err = context.tr.couponNotApplicable;
      }
    }
    final bool coinsPossible = user.coins > 0 && q.lines.any((PricedLine l) => l.product.category.group != ProductGroup.phones);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _couponField,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(labelText: context.tr.couponCode, errorText: err, isDense: true),
                    onSubmitted: (String v) => setState(() => _coupon = v.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(minimumSize: const Size(80, 48)),
                  onPressed: () => setState(() => _coupon = _couponField.text.trim()),
                  child: Text(context.tr.apply),
                ),
              ],
            ),
            if (q.coupon != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.check_circle, color: BrandColors.green, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(context.tr.couponApplied(q.coupon!.code, formatRupees(q.couponDiscount)), style: const TextStyle(color: BrandColors.green, fontWeight: FontWeight.w700))),
                    TextButton(
                      onPressed: () => setState(() {
                        _coupon = '';
                        _couponField.clear();
                      }),
                      child: Text(context.tr.remove),
                    ),
                  ],
                ),
              ),
            if (q.coupon == null && live.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    for (final Offer o in live)
                      ActionChip(
                        avatar: const Icon(Icons.local_offer_outlined, size: 16),
                        label: Text(o.code),
                        onPressed: () => setState(() {
                          _coupon = o.code;
                          _couponField.text = o.code;
                        }),
                      ),
                  ],
                ),
              ),
            if (coinsPossible)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr.useCoins(user.coins)),
                subtitle: Text(context.tr.coinsRule),
                value: _useCoins,
                onChanged: (bool v) => setState(() => _useCoins = v),
              ),
          ],
        ),
      ),
    );
  }

  Widget _reservePanel(BuildContext context, StoreSettings store, Quote q) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InfoBanner(text: context.tr.reserveExplain(formatRupees(store.reserveToken), context.tr.hoursCount(store.reserveHours), formatRupees(q.total - store.reserveToken)), icon: Icons.bookmark_added_outlined),
          const SizedBox(height: 12),
          InstrumentPicker(key: const ValueKey<String>('reserve'), methods: const <PaymentMethod>[PaymentMethod.upi, PaymentMethod.card], onChanged: _setInstrument),
        ],
      );

  Widget _schemeChips(BuildContext context, List<EmiScheme> schemes, EmiScheme? scheme, int months) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (schemes.length > 1) ...<Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final EmiScheme s in schemes)
                  ChoiceChip(
                    label: Text(s.name.of(context.lang)),
                    selected: s.id == scheme?.id,
                    onSelected: (_) => setState(() {
                      _schemeId = s.id;
                      _months = null;
                      _down = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Text(context.tr.chooseTenure, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final int m in scheme?.tenures ?? const <int>[])
                ChoiceChip(
                  label: Text(context.tr.monthsCount(m)),
                  selected: m == months,
                  onSelected: (_) => setState(() => _months = m),
                ),
            ],
          ),
        ],
      );

  Widget _emiSummary(BuildContext context, EmiQuote? emi, EmiScheme? scheme, int down) {
    if (emi == null || scheme == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: BrandColors.indigo.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text('${formatRupees(emi.emi)}${context.tr.perMonth} × ${emi.months}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
              if (scheme.noCost) StatusPill(context.tr.zeroInterest, color: BrandColors.green),
            ],
          ),
          const SizedBox(height: 6),
          if (down > 0) KeyValue(context.tr.downPayment, formatRupees(down)),
          KeyValue(context.tr.amountFinanced, formatRupees(emi.principal)),
          KeyValue(context.tr.interestRate, scheme.annualRatePct <= 0 ? '0%' : '${scheme.annualRatePct.toStringAsFixed(scheme.annualRatePct % 1 == 0 ? 0 : 1)}% ${context.tr.perYear}'),
          if (emi.totalInterest > 0) KeyValue(context.tr.totalInterest, formatRupees(emi.totalInterest)),
          if (scheme.processingFee > 0) KeyValue(context.tr.processingFeeLabel, formatRupees(scheme.processingFee)),
          KeyValue(context.tr.totalYouPay, formatRupees(down + emi.totalPayable + scheme.processingFee), bold: true),
          const SizedBox(height: 6),
          Text(context.tr.emiIndicative, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _bajajPanel(BuildContext context, StoreSettings store, Quote q, List<EmiScheme> schemes, EmiScheme? scheme, int months, int down, int financeable, EmiQuote? emi, int payNow) {
    if (scheme == null) return InfoBanner(text: context.tr.noEmiForThis);
    final int min = PaymentRules.minDownPayment(scheme, financeable);
    final int max = financeable - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _schemeChips(context, schemes, scheme, months),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(child: Text(context.tr.downPayment, style: const TextStyle(fontWeight: FontWeight.w800))),
            Text(formatRupees(down), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        if (max > min)
          Slider(
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: ((max - min) / 500).clamp(1, 200).round(),
            value: down.clamp(min, max).toDouble(),
            label: formatRupees(down),
            onChanged: (double v) => setState(() => _down = (v / 100).round() * 100),
          ),
        Text(context.tr.downPaymentMin(formatRupees(min)), style: Theme.of(context).textTheme.bodySmall),
        _emiSummary(context, emi, scheme, down),
        const SizedBox(height: 14),
        if (payNow > 0) ...<Widget>[
          Text(context.tr.payDownHow(formatRupees(payNow)), style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: <ButtonSegment<bool>>[
              ButtonSegment<bool>(value: true, label: Text(context.tr.payOnlineNow)),
              ButtonSegment<bool>(value: false, label: Text(context.tr.payAtStoreLater)),
            ],
            selected: <bool>{_downOnline},
            onSelectionChanged: (Set<bool> s) => setState(() {
              _downOnline = s.first;
              _instrument = null;
            }),
          ),
          if (_downOnline) ...<Widget>[
            const SizedBox(height: 12),
            InstrumentPicker(key: const ValueKey<String>('bajaj'), methods: const <PaymentMethod>[PaymentMethod.upi, PaymentMethod.card, PaymentMethod.netbanking], onChanged: _setInstrument),
          ],
        ],
        const SizedBox(height: 14),
        Text(context.tr.whatHappensNext, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        _stepRow('1', context.tr.bajajStep1),
        _stepRow('2', context.tr.bajajStep2),
        _stepRow('3', context.tr.bajajStep3),
        _stepRow('4', context.tr.bajajStep4),
      ],
    );
  }

  Widget _stepRow(String n, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(radius: 10, backgroundColor: BrandColors.saffron, child: Text(n, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black87))),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
          ],
        ),
      );

  Widget _cardEmiPanel(BuildContext context, StoreSettings store, Quote q, List<EmiScheme> schemes, EmiScheme? scheme, int months, EmiQuote? emi) {
    if (scheme == null) return InfoBanner(text: context.tr.noEmiForThis);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _schemeChips(context, schemes, scheme, months),
        _emiSummary(context, emi, scheme, 0),
        const SizedBox(height: 14),
        InstrumentPicker(key: const ValueKey<String>('cardemi'), methods: const <PaymentMethod>[PaymentMethod.card], onChanged: _setInstrument),
      ],
    );
  }

  Future<void> _submit(BuildContext context, AppUser user, Quote q, PayChoice choice, EmiScheme? scheme, int months, int down, Address? address, Fulfilment fulfilment) async {
    setState(() => _submitting = true);
    final AppServices services = context.read<AppServices>();
    final CartCubit cart = context.read<CartCubit>();
    final GoRouter router = GoRouter.of(context);
    final String? coupon = q.coupon?.code;
    final bool isBajaj = choice == PayChoice.bajajEmi;
    final bool online = !isBajaj || _downOnline;
    final CheckoutResult? r = await runBusy<CheckoutResult>(
      context,
      () => services.checkout.placeOrder(CheckoutRequest(
        customer: user,
        cart: cart.state,
        fulfilment: fulfilment,
        address: address,
        couponCode: coupon,
        coinsToUse: q.coinsUsed,
        choice: choice,
        emi: (choice == PayChoice.bajajEmi || choice == PayChoice.cardEmi) && scheme != null
            ? EmiSelection(schemeId: scheme.id, months: months, downPayment: down)
            : null,
        instrument: online ? _instrument : null,
      )),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (r == null) return;
    await cart.clear();
    final String fail = r.failure?.name ?? '';
    router.go('${Routes.orderDone(r.order.id)}${fail.isEmpty ? '' : '?fail=$fail'}');
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/emi.dart';
import '../../core/money.dart';
import '../../core/validators.dart';
import '../../domain/app_user.dart';
import '../../domain/emi_plan.dart';
import '../../domain/order.dart';
import '../../domain/payment.dart';
import '../../domain/product.dart';
import '../../domain/store_settings.dart';
import '../../l10n/l10n.dart';
import '../../services/app_services.dart';
import '../../services/emi_service.dart';
import '../../services/order_service.dart';
import '../../state/data_cubits.dart';
import '../../state/session_cubit.dart';
import '../../util/launch.dart';
import '../../widgets/common.dart';
import '../../widgets/product_art.dart';
import '../orders/invoice.dart';

class _PosLine {
  _PosLine(this.product, this.variant) : imeis = <TextEditingController>[TextEditingController()];

  final Product product;
  final ProductVariant variant;
  int qty = 1;
  final List<TextEditingController> imeis;

  void syncImeis() {
    while (imeis.length < qty) {
      imeis.add(TextEditingController());
    }
    while (imeis.length > qty) {
      imeis.removeLast().dispose();
    }
  }

  void dispose() {
    for (final TextEditingController c in imeis) {
      c.dispose();
    }
  }
}

class _PosPay {
  _PosPay(this.method, int amount) : amount = TextEditingController(text: '$amount');
  PaymentMethod method;
  final TextEditingController amount;
  final TextEditingController ref = TextEditingController();

  int get value => int.tryParse(amount.text) ?? 0;

  void dispose() {
    amount.dispose();
    ref.dispose();
  }
}

/// Ring up a sale at the counter. Everyone who buys here becomes an app
/// customer by their phone number, with their bill and warranty waiting.
class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _discount = TextEditingController();
  final List<_PosLine> _lines = <_PosLine>[];
  final List<_PosPay> _pays = <_PosPay>[];
  bool _bajaj = false;
  String? _schemeId;
  int _months = 6;

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _discount.dispose();
    for (final _PosLine l in _lines) {
      l.dispose();
    }
    for (final _PosPay p in _pays) {
      p.dispose();
    }
    super.dispose();
  }

  int get _subtotal => _lines.fold(0, (int s, _PosLine l) => s + l.variant.price * l.qty);
  int get _disc => int.tryParse(_discount.text) ?? 0;
  int get _total => (_subtotal - _disc).clamp(0, 1 << 30);
  int get _paid => _pays.fold(0, (int s, _PosPay p) => s + p.value);
  int get _financeable => _lines.where((_PosLine l) => l.product.isPhone).fold(0, (int s, _PosLine l) => s + l.variant.price * l.qty);

  @override
  Widget build(BuildContext context) {
    final StoreSettings store = context.watch<StoreCubit>().state;
    final List<EmiScheme> schemes = store.schemesFor(_financeable, provider: EmiProvider.bajaj);
    final EmiScheme? scheme = schemes.where((EmiScheme s) => s.id == _schemeId).firstOrNull ?? schemes.firstOrNull;
    final int principal = _total - _paid;
    final bool bajajOn = _bajaj && scheme != null;
    final EmiQuote? q = bajajOn && principal > 0 && principal <= _financeable
        ? Emi.quote(principal: principal, months: scheme.tenures.contains(_months) ? _months : scheme.tenures.first, annualRatePct: scheme.annualRatePct)
        : null;
    final bool balanced = bajajOn ? (principal > 0 && principal <= _financeable) : _paid == _total && _total > 0;
    final String lang = context.lang;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr.newSale)),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
          child: MaxWidth(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(context.tr.orderTotal, style: Theme.of(context).textTheme.bodySmall),
                      Text(formatRupees(_total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                    ],
                  ),
                ),
                FilledButton(onPressed: balanced && _lines.isNotEmpty ? () => _complete(context, scheme) : null, child: Text(context.tr.completeSale)),
              ],
            ),
          ),
        ),
      ),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: <Widget>[
            Section(
              title: context.tr.customer,
              padding: EdgeInsets.zero,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                      onChanged: (String v) async {
                        if (v.length == 10) {
                          final AppUser? u = await context.read<AppServices>().repos.users.byPhone(v);
                          if (u != null && u.name.isNotEmpty && _name.text.isEmpty) setState(() => _name.text = u.name);
                        }
                      },
                      decoration: InputDecoration(labelText: context.tr.mobileNumber, prefixText: '+91 ', counterText: ''),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: context.tr.yourName))),
                ],
              ),
            ),
            Section(
              title: context.tr.itemsHeader,
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < _lines.length; i++) _lineCard(context, i, lang),
                  OutlinedButton.icon(onPressed: () => _addItem(context), icon: const Icon(Icons.add_shopping_cart), label: Text(context.tr.addItem)),
                ],
              ),
            ),
            Section(
              title: context.tr.discount,
              child: TextField(
                controller: _discount,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(prefixText: '₹ ', helperText: context.tr.discountHelp(OrderService.maxStaffDiscountPct)),
              ),
            ),
            Section(
              title: context.tr.paymentHeader,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 8,
                        children: <Widget>[
                          ActionChip(avatar: const Icon(Icons.payments_outlined, size: 18), label: Text(context.tr.fullCash), onPressed: () => _fill(PaymentMethod.cash)),
                          ActionChip(avatar: const Icon(Icons.qr_code_2, size: 18), label: Text(context.tr.fullUpi), onPressed: () => _fill(PaymentMethod.upi)),
                          ActionChip(avatar: const Icon(Icons.credit_card, size: 18), label: Text(context.tr.fullCard), onPressed: () => _fill(PaymentMethod.card)),
                        ],
                      ),
                      for (int i = 0; i < _pays.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: <Widget>[
                              DropdownButton<PaymentMethod>(
                                value: _pays[i].method,
                                items: <DropdownMenuItem<PaymentMethod>>[
                                  for (final PaymentMethod m in <PaymentMethod>[PaymentMethod.cash, PaymentMethod.upi, PaymentMethod.card])
                                    DropdownMenuItem<PaymentMethod>(value: m, child: Text(context.tr.payMethod(m))),
                                ],
                                onChanged: (PaymentMethod? m) => setState(() => _pays[i].method = m ?? _pays[i].method),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: TextField(controller: _pays[i].amount, keyboardType: TextInputType.number, inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly], onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixText: '₹ ', isDense: true))),
                              IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _pays.removeAt(i).dispose())),
                            ],
                          ),
                        ),
                      TextButton.icon(onPressed: () => setState(() => _pays.add(_PosPay(PaymentMethod.cash, (_total - _paid).clamp(0, 1 << 30)))), icon: const Icon(Icons.add), label: Text(context.tr.addPayment)),
                      const Divider(),
                      KeyValue(context.tr.paidSoFar, formatRupees(_paid)),
                      if (!bajajOn) KeyValue(context.tr.balanceDue, formatRupees(_total - _paid), bold: true, color: _total - _paid == 0 ? BrandColors.green : BrandColors.red),
                    ],
                  ),
                ),
              ),
            ),
            if (_financeable > 0 && schemes.isNotEmpty && store.bajajEnabled)
              Section(
                title: context.tr.payMethodBajaj,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr.financeBalanceBajaj), subtitle: Text(context.tr.financeBalanceHint), value: _bajaj, onChanged: (bool v) => setState(() => _bajaj = v)),
                        if (_bajaj && scheme != null) ...<Widget>[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              for (final EmiScheme s in schemes) ChoiceChip(label: Text(s.name.of(lang)), selected: s.id == scheme.id, onSelected: (_) => setState(() => _schemeId = s.id)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: <Widget>[
                              for (final int m in scheme.tenures) ChoiceChip(label: Text(context.tr.monthsCount(m)), selected: m == (scheme.tenures.contains(_months) ? _months : scheme.tenures.first), onSelected: (_) => setState(() => _months = m)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (q != null) ...<Widget>[
                            KeyValue(context.tr.amountFinanced, formatRupees(q.principal)),
                            KeyValue(context.tr.monthlyEmi, '${formatRupees(q.emi)} × ${q.months}', bold: true),
                          ] else
                            Text(context.tr.financeNeedsDown, style: const TextStyle(color: BrandColors.red)),
                          const SizedBox(height: 6),
                          Text(context.tr.bajajCounterNote, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _fill(PaymentMethod m) => setState(() {
        for (final _PosPay p in _pays) {
          p.dispose();
        }
        _pays
          ..clear()
          ..add(_PosPay(m, _total));
        _bajaj = false;
      });

  Widget _lineCard(BuildContext context, int i, String lang) {
    final _PosLine l = _lines[i];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                SizedBox(width: 44, height: 44, child: ProductArt(product: l.product, radius: 10, iconSize: 22)),
                const SizedBox(width: 10),
                Expanded(child: Text('${l.product.name.of(lang)}\n${l.variant.label}', style: const TextStyle(fontWeight: FontWeight.w700))),
                Text(formatRupees(l.variant.price * l.qty), style: const TextStyle(fontWeight: FontWeight.w900)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _lines.removeAt(i).dispose())),
              ],
            ),
            Row(
              children: <Widget>[
                QtyStepper(qty: l.qty, max: l.variant.stock.clamp(1, 20), onChanged: (int n) => setState(() {
                      l.qty = n.clamp(1, 20);
                      l.syncImeis();
                    })),
                const SizedBox(width: 10),
                Text(context.tr.inStockCount(l.variant.stock), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (l.product.isPhone && !_bajaj)
              for (int k = 0; k < l.imeis.length; k++)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    controller: l.imeis[k],
                    keyboardType: TextInputType.number,
                    maxLength: 15,
                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'IMEI #${k + 1}',
                      counterText: '',
                      isDense: true,
                      suffixIcon: l.imeis[k].text.length == 15 ? Icon(Validators.imei(l.imeis[k].text) ? Icons.check_circle : Icons.error, color: Validators.imei(l.imeis[k].text) ? BrandColors.green : BrandColors.red) : null,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _addItem(BuildContext context) async {
    final List<Product> all = context.read<ProductsCubit>().state.where((Product p) => p.active).toList();
    final ({Product p, ProductVariant v})? pick = await showModalBottomSheet<({Product p, ProductVariant v})>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => _ItemPicker(products: all),
    );
    if (pick == null) return;
    setState(() {
      final _PosLine? same = _lines.where((_PosLine l) => l.product.id == pick.p.id && l.variant.id == pick.v.id).firstOrNull;
      if (same != null) {
        same.qty++;
        same.syncImeis();
      } else {
        _lines.add(_PosLine(pick.p, pick.v));
      }
      if (_pays.length == 1) _pays.first.amount.text = '$_total';
    });
  }

  Future<void> _complete(BuildContext context, EmiScheme? scheme) async {
    final AppServices services = context.read<AppServices>();
    final SessionState session = context.read<SessionCubit>().state;
    final StoreSettings store = context.read<StoreCubit>().state;
    final bool bajaj = _bajaj && scheme != null;
    final Order? o = await runBusy<Order>(
      context,
      () => services.orders.createWalkInSale(
        session.user,
        WalkInRequest(
          phone: _phone.text,
          name: _name.text,
          lines: <WalkInLine>[
            for (final _PosLine l in _lines)
              WalkInLine(
                productId: l.product.id,
                variantId: l.variant.id,
                qty: l.qty,
                imeis: l.product.isPhone && !bajaj ? l.imeis.map((TextEditingController c) => c.text.trim()).toList() : const <String>[],
              ),
          ],
          discount: _disc,
          payments: <WalkInPayment>[for (final _PosPay p in _pays) WalkInPayment(method: p.method, amount: p.value, reference: p.ref.text.trim())],
          emi: bajaj ? EmiSelection(schemeId: scheme.id, months: scheme.tenures.contains(_months) ? _months : scheme.tenures.first) : null,
        ),
      ),
    );
    if (o == null || !context.mounted) return;
    final String bill = Invoice.text(o, store, context.tr, context.lang);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: BrandColors.green, size: 48),
        title: Text(ctx.tr.saleDone(o.number)),
        content: Text(o.status == OrderStatus.delivered ? ctx.tr.saleDoneBody : ctx.tr.saleDoneEmiBody),
        actions: <Widget>[
          TextButton.icon(onPressed: () => Launch.whatsapp(o.customerPhone, text: bill), icon: const Icon(Icons.chat_outlined), label: Text(ctx.tr.sendBill)),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr.done)),
        ],
      ),
    );
    if (!context.mounted) return;
    if (o.status != OrderStatus.delivered) {
      context.go('/admin/order/${o.id}');
    } else {
      context.pop();
    }
  }
}

class _ItemPicker extends StatefulWidget {
  const _ItemPicker({required this.products});
  final List<Product> products;

  @override
  State<_ItemPicker> createState() => _ItemPickerState();
}

class _ItemPickerState extends State<_ItemPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final String q = _q.toLowerCase();
    final List<Product> list = widget.products.where((Product p) => q.isEmpty || '${p.name.en} ${p.name.hi} ${p.brand}'.toLowerCase().contains(q)).toList();
    final String lang = context.lang;
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (BuildContext c, ScrollController sc) => Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(autofocus: true, onChanged: (String v) => setState(() => _q = v), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: context.tr.searchHint)),
            ),
            Expanded(
              child: ListView(
                controller: sc,
                children: <Widget>[
                  for (final Product p in list)
                    for (final ProductVariant v in p.variants)
                      ListTile(
                        enabled: v.inStock,
                        leading: SizedBox(width: 40, height: 40, child: ProductArt(product: p, radius: 8, iconSize: 20)),
                        title: Text('${p.name.of(lang)} · ${v.label}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${formatRupees(v.price)} · ${context.tr.inStockCount(v.stock)}'),
                        onTap: () => Navigator.pop(context, (p: p, v: v)),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

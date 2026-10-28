import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/ids.dart';
import '../../core/money.dart';
import '../../domain/localized_text.dart';
import '../../domain/offer.dart';
import '../../domain/product.dart';
import '../../l10n/l10n.dart';
import '../../services/app_services.dart';
import '../../state/data_cubits.dart';
import '../../state/session_cubit.dart';
import '../../util/launch.dart';
import '../../widgets/common.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Offer> offers = context.watch<OffersCubit>().state.toList()..sort((Offer a, Offer b) => b.endsAt.compareTo(a.endsAt));
    final DateTime now = DateTime.now();
    final String lang = context.lang;
    final store = context.watch<StoreCubit>().state;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr.offersAndCoupons)),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => context.push(Routes.adminOffer('new')), icon: const Icon(Icons.add), label: Text(context.tr.addOffer)),
      body: MaxWidth(
        child: offers.isEmpty
            ? EmptyState(icon: Icons.local_offer_outlined, title: context.tr.noOffers, message: context.tr.noOffersHint)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: offers.length,
                separatorBuilder: (BuildContext c, int i) => const SizedBox(height: 10),
                itemBuilder: (BuildContext c, int i) {
                  final Offer o = offers[i];
                  final bool live = o.isLive(now);
                  return Card(
                    child: ListTile(
                      onTap: () => context.push(Routes.adminOffer(o.id)),
                      leading: Icon(o.isCoupon ? Icons.confirmation_number_outlined : Icons.campaign_outlined, color: live ? BrandColors.green : Colors.blueGrey),
                      title: Text(o.title.of(lang), style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(<String>[
                        if (o.isCoupon) '${o.code} · ${o.discountKind == DiscountKind.percent ? '${o.value}%' : formatRupees(o.value)}',
                        '${Dates.dateShort(o.startsAt, lang)} - ${Dates.dateShort(o.endsAt, lang)}',
                      ].join('\n')),
                      isThreeLine: o.isCoupon,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (store.name.en.isNotEmpty)
                            IconButton(
                              tooltip: context.tr.shareOffer,
                              icon: const Icon(Icons.share_outlined),
                              onPressed: () => Launch.shareText(o.isCoupon ? context.tr.offerShareCoupon(o.title.of(lang), o.code, store.name.of(lang)) : context.tr.offerShareBanner(o.title.of(lang), store.name.of(lang))),
                            ),
                          Switch(value: o.active, onChanged: (bool v) => runBusy(context, () => context.read<AppServices>().shopAdmin.saveOffer(context.read<SessionCubit>().state.user, o.copyWith(active: v)))),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class OfferEditScreen extends StatefulWidget {
  const OfferEditScreen({super.key, required this.offerId});

  final String offerId;

  @override
  State<OfferEditScreen> createState() => _OfferEditScreenState();
}

class _OfferEditScreenState extends State<OfferEditScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  Offer? _existing;
  bool _loaded = false;
  OfferKind _kind = OfferKind.coupon;
  DiscountKind _dk = DiscountKind.percent;
  final TextEditingController _titleEn = TextEditingController();
  final TextEditingController _titleHi = TextEditingController();
  final TextEditingController _subEn = TextEditingController();
  final TextEditingController _subHi = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _value = TextEditingController();
  final TextEditingController _min = TextEditingController(text: '0');
  final TextEditingController _max = TextEditingController(text: '0');
  final Set<ProductGroup> _groups = <ProductGroup>{};
  late DateTime _from = DateTime.now();
  late DateTime _to = DateTime.now().add(const Duration(days: 30));
  bool _active = true;

  bool get _isNew => widget.offerId == 'new';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final Offer? o = _isNew ? null : context.read<OffersCubit>().state.where((Offer x) => x.id == widget.offerId).firstOrNull;
    _existing = o;
    if (o != null) {
      _kind = o.kind;
      _dk = o.discountKind;
      _titleEn.text = o.title.en;
      _titleHi.text = o.title.hi;
      _subEn.text = o.subtitle.en;
      _subHi.text = o.subtitle.hi;
      _code.text = o.code;
      _value.text = '${o.value}';
      _min.text = '${o.minOrder}';
      _max.text = '${o.maxDiscount}';
      _groups.addAll(o.groups);
      _from = o.startsAt;
      _to = o.endsAt;
      _active = o.active;
    }
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[_titleEn, _titleHi, _subEn, _subHi, _code, _value, _min, _max]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String lang = context.lang;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? context.tr.addOffer : context.tr.editOffer),
        actions: <Widget>[
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final bool ok = await confirmDialog(context, title: context.tr.deleteOfferQ, destructive: true);
                if (!ok || !context.mounted) return;
                final user = context.read<SessionCubit>().state.user;
                final bool? done = await runBusy<bool>(context, () async {
                  await context.read<AppServices>().shopAdmin.deleteOffer(user, widget.offerId);
                  return true;
                });
                if (done == true && context.mounted) context.pop();
              },
            ),
        ],
      ),
      body: MaxWidth(
        width: 640,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              SegmentedButton<OfferKind>(
                showSelectedIcon: false,
                segments: <ButtonSegment<OfferKind>>[
                  ButtonSegment<OfferKind>(value: OfferKind.coupon, label: Text(context.tr.kindCoupon), icon: const Icon(Icons.confirmation_number_outlined)),
                  ButtonSegment<OfferKind>(value: OfferKind.banner, label: Text(context.tr.kindBanner), icon: const Icon(Icons.campaign_outlined)),
                ],
                selected: <OfferKind>{_kind},
                onSelectionChanged: (Set<OfferKind> s) => setState(() => _kind = s.first),
              ),
              const SizedBox(height: 14),
              TextFormField(controller: _titleEn, validator: (String? v) => (v ?? '').trim().isEmpty ? context.tr.required : null, decoration: InputDecoration(labelText: '${context.tr.offerTitle} (English)')),
              const SizedBox(height: 12),
              TextFormField(controller: _titleHi, decoration: InputDecoration(labelText: '${context.tr.offerTitle} (हिन्दी)')),
              const SizedBox(height: 12),
              TextFormField(controller: _subEn, decoration: InputDecoration(labelText: '${context.tr.offerSubtitle} (English)')),
              const SizedBox(height: 12),
              TextFormField(controller: _subHi, decoration: InputDecoration(labelText: '${context.tr.offerSubtitle} (हिन्दी)')),
              if (_kind == OfferKind.coupon) ...<Widget>[
                const SizedBox(height: 12),
                TextFormField(controller: _code, textCapitalization: TextCapitalization.characters, validator: (String? v) => (v ?? '').trim().length < 3 ? context.tr.required : null, decoration: InputDecoration(labelText: context.tr.couponCode)),
                const SizedBox(height: 12),
                SegmentedButton<DiscountKind>(
                  showSelectedIcon: false,
                  segments: <ButtonSegment<DiscountKind>>[
                    ButtonSegment<DiscountKind>(value: DiscountKind.percent, label: Text(context.tr.percentOff)),
                    ButtonSegment<DiscountKind>(value: DiscountKind.flat, label: Text(context.tr.flatOff)),
                  ],
                  selected: <DiscountKind>{_dk},
                  onSelectionChanged: (Set<DiscountKind> s) => setState(() => _dk = s.first),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(child: TextFormField(controller: _value, keyboardType: TextInputType.number, inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly], validator: (String? v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? context.tr.required : null, decoration: InputDecoration(labelText: _dk == DiscountKind.percent ? '%' : '₹'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: _min, keyboardType: TextInputType.number, inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: context.tr.minOrder, prefixText: '₹ '))),
                    if (_dk == DiscountKind.percent) ...<Widget>[
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _max, keyboardType: TextInputType.number, inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: context.tr.maxDiscount, prefixText: '₹ '))),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(context.tr.appliesTo, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    for (final ProductGroup g in ProductGroup.values) FilterChip(label: Text(context.tr.group(g)), selected: _groups.contains(g), onSelected: (bool on) => setState(() => on ? _groups.add(g) : _groups.remove(g))),
                  ],
                ),
                Padding(padding: const EdgeInsets.only(top: 6), child: Text(context.tr.appliesToHint, style: Theme.of(context).textTheme.bodySmall)),
              ],
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(child: OutlinedButton.icon(onPressed: () => _pick(true), icon: const Icon(Icons.event), label: Text('${context.tr.starts}: ${Dates.dateShort(_from, lang)}'))),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(onPressed: () => _pick(false), icon: const Icon(Icons.event_busy), label: Text('${context.tr.ends}: ${Dates.dateShort(_to, lang)}'))),
                ],
              ),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr.activeLabel), value: _active, onChanged: (bool v) => setState(() => _active = v)),
              const SizedBox(height: 8),
              FilledButton(onPressed: _save, child: Text(context.tr.save)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pick(bool start) async {
    final DateTime? d = await showDatePicker(context: context, initialDate: start ? _from : _to, firstDate: DateTime(2024), lastDate: DateTime(2035));
    if (d == null) return;
    setState(() {
      if (start) {
        _from = DateTime(d.year, d.month, d.day);
      } else {
        _to = DateTime(d.year, d.month, d.day, 23, 59);
      }
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final AppServices s = context.read<AppServices>();
    final Offer o = Offer(
      id: _existing?.id ?? newId('offer'),
      kind: _kind,
      title: LocalizedText(_titleEn.text.trim(), _titleHi.text.trim()),
      subtitle: LocalizedText(_subEn.text.trim(), _subHi.text.trim()),
      code: _kind == OfferKind.coupon ? _code.text.trim().toUpperCase() : '',
      discountKind: _dk,
      value: int.tryParse(_value.text) ?? 0,
      minOrder: int.tryParse(_min.text) ?? 0,
      maxDiscount: _dk == DiscountKind.percent ? (int.tryParse(_max.text) ?? 0) : 0,
      groups: _groups.toList(),
      startsAt: _from,
      endsAt: _to,
      active: _active,
      colorSeed: _existing?.colorSeed ?? DateTime.now().millisecond,
    );
    final user = context.read<SessionCubit>().state.user;
    final bool? ok = await runBusy<bool>(context, () async {
      await s.shopAdmin.saveOffer(user, o);
      return true;
    });
    if (ok == true && mounted) {
      toast(context, context.tr.saved);
      context.pop();
    }
  }
}

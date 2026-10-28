import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/validators.dart';
import '../../domain/localized_text.dart';
import '../../domain/repair.dart';
import '../../domain/store_settings.dart';
import '../../l10n/l10n.dart';
import '../../services/app_services.dart';
import '../../state/data_cubits.dart';
import '../../state/session_cubit.dart';
import '../../widgets/common.dart';

/// Everything the owner can change about the shop without a developer.
class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  late StoreSettings _s = context.read<StoreCubit>().state;
  final Map<String, TextEditingController> _c = <String, TextEditingController>{};

  TextEditingController _ctl(String key, String initial) => _c.putIfAbsent(key, () => TextEditingController(text: initial));

  @override
  void dispose() {
    for (final TextEditingController c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _text(String key, String label, String initial, {TextInputType? kb, int? maxLen, String? prefix, String? help, bool digits = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: _ctl(key, initial),
          keyboardType: kb,
          maxLength: maxLen,
          inputFormatters: digits ? <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : null,
          decoration: InputDecoration(labelText: label, prefixText: prefix, helperText: help, counterText: ''),
        ),
      );

  String _t(String key) => _c[key]?.text.trim() ?? '';
  int _i(String key, int fallback) => int.tryParse(_t(key)) ?? fallback;
  double _d(String key, double fallback) => double.tryParse(_t(key)) ?? fallback;

  @override
  Widget build(BuildContext context) {
    final String lang = context.lang;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr.shopSettings)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: MaxWidth(child: FilledButton(onPressed: _save, child: Text(context.tr.save))),
        ),
      ),
      body: MaxWidth(
        width: 720,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: <Widget>[
            Section(
              title: context.tr.setShopInfo,
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: <Widget>[
                  _text('nameEn', '${context.tr.shopName} (English)', _s.name.en),
                  _text('nameHi', '${context.tr.shopName} (हिन्दी)', _s.name.hi),
                  _text('tagEn', '${context.tr.tagline} (English)', _s.tagline.en),
                  _text('tagHi', '${context.tr.tagline} (हिन्दी)', _s.tagline.hi),
                  _text('phone', context.tr.shopPhone, _s.phone, kb: TextInputType.phone, maxLen: 10, prefix: '+91 ', help: context.tr.shopPhoneHelp),
                  _text('wa', context.tr.shopWhatsapp, _s.whatsapp, kb: TextInputType.phone, maxLen: 10, prefix: '+91 '),
                  _text('addrEn', '${context.tr.addressLabel} (English)', _s.addressLine.en),
                  _text('addrHi', '${context.tr.addressLabel} (हिन्दी)', _s.addressLine.hi),
                  _text('lmEn', '${context.tr.landmark} (English)', _s.landmark.en),
                  _text('lmHi', '${context.tr.landmark} (हिन्दी)', _s.landmark.hi),
                  Row(
                    children: <Widget>[
                      Expanded(child: _text('city', context.tr.cityTown, _s.city)),
                      const SizedBox(width: 12),
                      Expanded(child: _text('pin', context.tr.pincode, _s.pincode, kb: TextInputType.number, maxLen: 6)),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(child: _text('lat', context.tr.latitude, _s.latitude?.toString() ?? '', kb: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                      const SizedBox(width: 12),
                      Expanded(child: _text('lng', context.tr.longitude, _s.longitude?.toString() ?? '', kb: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                    ],
                  ),
                  _text('maps', context.tr.mapsLink, _s.mapsUrl, kb: TextInputType.url, help: context.tr.mapsLinkHelp),
                  _text('upi', context.tr.shopUpi, _s.upiId, help: context.tr.shopUpiHelp),
                  _text('gst', context.tr.shopGstin, _s.gstin, maxLen: 15),
                ],
              ),
            ),
            Section(
              title: context.tr.openingHours,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: <Widget>[
                      for (int d = 1; d <= 7; d++)
                        ListTile(
                          dense: true,
                          title: Text(context.tr.weekday(d), style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(_s.hours.of(d).closed ? context.tr.closed : '${Dates.minutes(_s.hours.of(d).openMinute, lang)} - ${Dates.minutes(_s.hours.of(d).closeMinute, lang)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (!_s.hours.of(d).closed) ...<Widget>[
                                TextButton(onPressed: () => _time(d, true), child: Text(context.tr.opens)),
                                TextButton(onPressed: () => _time(d, false), child: Text(context.tr.closes)),
                              ],
                              Switch(value: !_s.hours.of(d).closed, onChanged: (bool open) => setState(() => _s = _s.copyWith(hours: _s.hours.withDay(d, _s.hours.of(d).copyWith(closed: !open))))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Section(
              title: context.tr.deliveryAndOrders,
              child: Column(
                children: <Widget>[
                  _text('localPins', context.tr.localPincodes, _s.localPincodes.join(', '), help: context.tr.localPincodesHelp),
                  Row(
                    children: <Widget>[
                      Expanded(child: _text('localFee', context.tr.localDeliveryFee, '${_s.localDeliveryFee}', kb: TextInputType.number, digits: true, prefix: '₹ ')),
                      const SizedBox(width: 12),
                      Expanded(child: _text('courierFee', context.tr.courierFee, '${_s.courierFee}', kb: TextInputType.number, digits: true, prefix: '₹ ')),
                      const SizedBox(width: 12),
                      Expanded(child: _text('freeAbove', context.tr.freeDeliveryAbove, '${_s.freeDeliveryAbove}', kb: TextInputType.number, digits: true, prefix: '₹ ')),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(child: _text('token', context.tr.reserveTokenLabel, '${_s.reserveToken}', kb: TextInputType.number, digits: true, prefix: '₹ ')),
                      const SizedBox(width: 12),
                      Expanded(child: _text('resHours', context.tr.reserveHoursLabel, '${_s.reserveHours}', kb: TextInputType.number, digits: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _text('codLimit', context.tr.codLimit, '${_s.codLimit}', kb: TextInputType.number, digits: true, prefix: '₹ ')),
                    ],
                  ),
                  SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr.allowCod), value: _s.codEnabled, onChanged: (bool v) => setState(() => _s = _s.copyWith(codEnabled: v))),
                  SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr.allowReserve), value: _s.reserveEnabled, onChanged: (bool v) => setState(() => _s = _s.copyWith(reserveEnabled: v))),
                ],
              ),
            ),
            Section(
              title: context.tr.financeSettings,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  InfoBanner(text: context.tr.financeSettingsHint, icon: Icons.warning_amber_outlined, color: const Color(0xFFEF6C00)),
                  SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr.allowBajaj), value: _s.bajajEnabled, onChanged: (bool v) => setState(() => _s = _s.copyWith(bajajEnabled: v))),
                  SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr.allowCardEmi), value: _s.cardEmiEnabled, onChanged: (bool v) => setState(() => _s = _s.copyWith(cardEmiEnabled: v))),
                  SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr.allowAutopay), value: _s.autopayEnabled, onChanged: (bool v) => setState(() => _s = _s.copyWith(autopayEnabled: v))),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.tr.allowShopInstalments),
                    subtitle: Text(context.tr.allowShopInstalmentsHint),
                    value: _s.shopInstalmentsEnabled,
                    onChanged: (bool v) => setState(() => _s = _s.copyWith(shopInstalmentsEnabled: v)),
                  ),
                  SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr.ratesConfirmed), subtitle: Text(context.tr.ratesConfirmedHint), value: _s.emiRatesConfirmed, onChanged: (bool v) => setState(() => _s = _s.copyWith(emiRatesConfirmed: v))),
                  const SizedBox(height: 8),
                  for (final EmiScheme e in _s.emiSchemes) _schemeCard(context, e),
                ],
              ),
            ),
            Section(
              title: context.tr.targetsAndFees,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(child: _text('target', context.tr.monthlyTarget, '${_s.monthlyProfitTarget}', kb: TextInputType.number, digits: true, prefix: '₹ ')),
                      const SizedBox(width: 12),
                      Expanded(child: _text('baseline', context.tr.baselineProfit, '${_s.baselineMonthlyProfit}', kb: TextInputType.number, digits: true, prefix: '₹ ')),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(child: _text('cardFee', context.tr.cardFee, '${_s.cardFeePct}', kb: const TextInputType.numberWithOptions(decimal: true), digits: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _text('upiFee', context.tr.upiFee, '${_s.upiFeePct}', kb: const TextInputType.numberWithOptions(decimal: true), digits: true)),
                    ],
                  ),
                  SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr.profitAfterGst), subtitle: Text(context.tr.profitAfterGstHint), value: _s.profitExcludesGst, onChanged: (bool v) => setState(() => _s = _s.copyWith(profitExcludesGst: v))),
                  Row(
                    children: <Widget>[
                      Expanded(child: _text('earn', context.tr.coinsEarnPct, '${_s.coinsEarnPct}', kb: TextInputType.number, digits: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _text('refBonus', context.tr.referralBonus, '${_s.referralBonusCoins}', kb: TextInputType.number, digits: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _text('maxCoins', context.tr.maxCoinsPct, '${_s.maxCoinsPctOfOrder}', kb: TextInputType.number, digits: true)),
                    ],
                  ),
                ],
              ),
            ),
            Section(
              title: context.tr.repairPricesHeader,
              child: Wrap(
                spacing: 12,
                children: <Widget>[
                  for (final RepairIssue i in RepairIssue.values)
                    SizedBox(width: 150, child: _text('rep_${i.name}', context.tr.repairIssue(i), '${_s.repairPrice(i)}', kb: TextInputType.number, digits: true, prefix: '₹ ')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _schemeCard(BuildContext context, EmiScheme e) {
    final String lang = context.lang;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(e.name.of(lang), style: const TextStyle(fontWeight: FontWeight.w900))),
                Switch(value: e.enabled, onChanged: (bool v) => _setScheme(e.copyWith(enabled: v))),
              ],
            ),
            Row(
              children: <Widget>[
                if (!e.noCost) Expanded(child: _text('s_${e.id}_rate', '${context.tr.interestRate} %', '${e.annualRatePct}', kb: const TextInputType.numberWithOptions(decimal: true), digits: true)),
                if (e.noCost) Expanded(child: _text('s_${e.id}_lender', context.tr.lenderRateLabel, '${e.lenderRatePct}', kb: const TextInputType.numberWithOptions(decimal: true), digits: true)),
                const SizedBox(width: 10),
                Expanded(child: _text('s_${e.id}_min', context.tr.minPrice, '${e.minPrice}', kb: TextInputType.number, digits: true, prefix: '₹ ')),
                const SizedBox(width: 10),
                Expanded(child: _text('s_${e.id}_down', context.tr.minDownPct, '${e.minDownPaymentPct}', kb: TextInputType.number, digits: true)),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(child: _text('s_${e.id}_fee', context.tr.processingFeeLabel, '${e.processingFee}', kb: TextInputType.number, digits: true, prefix: '₹ ')),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: _text('s_${e.id}_tenures', context.tr.tenuresLabel, e.tenures.join(', '), help: context.tr.tenuresHelp)),
              ],
            ),
            if (e.noCost) Text(context.tr.noCostCostNote, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  void _setScheme(EmiScheme e) => setState(() => _s = _s.copyWith(emiSchemes: <EmiScheme>[for (final EmiScheme x in _s.emiSchemes) x.id == e.id ? e : x]));

  Future<void> _time(int d, bool open) async {
    final DayHours h = _s.hours.of(d);
    final int cur = open ? h.openMinute : h.closeMinute;
    final TimeOfDay? t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: cur ~/ 60, minute: cur % 60));
    if (t == null) return;
    final int m = t.hour * 60 + t.minute;
    setState(() => _s = _s.copyWith(hours: _s.hours.withDay(d, open ? h.copyWith(openMinute: m) : h.copyWith(closeMinute: m))));
  }

  Future<void> _save() async {
    for (final String k in <String>['phone', 'wa']) {
      final String v = _t(k);
      if (v.isNotEmpty && Validators.mobile(v) == null) {
        toast(context, context.tr.errBadPhone);
        return;
      }
    }
    if (_t('pin').isNotEmpty && !Validators.pincode(_t('pin'))) {
      toast(context, context.tr.errBadPincode);
      return;
    }
    final List<EmiScheme> schemes = <EmiScheme>[
      for (final EmiScheme e in _s.emiSchemes)
        e.copyWith(
          annualRatePct: e.noCost ? 0 : _d('s_${e.id}_rate', e.annualRatePct),
          lenderRatePct: e.noCost ? _d('s_${e.id}_lender', e.lenderRatePct) : e.lenderRatePct,
          minPrice: _i('s_${e.id}_min', e.minPrice),
          minDownPaymentPct: _i('s_${e.id}_down', e.minDownPaymentPct).clamp(0, 90),
          processingFee: _i('s_${e.id}_fee', e.processingFee),
          tenures: <int>{
            for (final String p in _t('s_${e.id}_tenures').split(RegExp(r'[,\s]+')))
              if ((int.tryParse(p) ?? 0) > 0 && (int.tryParse(p) ?? 0) <= 60) int.parse(p),
          }.toList()
            ..sort(),
        ),
    ];
    final StoreSettings next = _s.copyWith(
      name: LocalizedText(_t('nameEn'), _t('nameHi')),
      tagline: LocalizedText(_t('tagEn'), _t('tagHi')),
      phone: _t('phone'),
      whatsapp: _t('wa'),
      addressLine: LocalizedText(_t('addrEn'), _t('addrHi')),
      landmark: LocalizedText(_t('lmEn'), _t('lmHi')),
      city: _t('city'),
      pincode: _t('pin'),
      mapsUrl: _t('maps'),
      latitude: double.tryParse(_t('lat')),
      longitude: double.tryParse(_t('lng')),
      clearLocation: double.tryParse(_t('lat')) == null || double.tryParse(_t('lng')) == null,
      upiId: _t('upi'),
      gstin: _t('gst').toUpperCase(),
      localPincodes: _t('localPins').split(RegExp(r'[,\s]+')).where((String p) => p.isNotEmpty).toList(),
      localDeliveryFee: _i('localFee', _s.localDeliveryFee),
      courierFee: _i('courierFee', _s.courierFee),
      freeDeliveryAbove: _i('freeAbove', _s.freeDeliveryAbove),
      reserveToken: _i('token', _s.reserveToken),
      reserveHours: _i('resHours', _s.reserveHours),
      codLimit: _i('codLimit', _s.codLimit),
      emiSchemes: schemes,
      monthlyProfitTarget: _i('target', _s.monthlyProfitTarget),
      baselineMonthlyProfit: _i('baseline', _s.baselineMonthlyProfit),
      cardFeePct: _d('cardFee', _s.cardFeePct),
      upiFeePct: _d('upiFee', _s.upiFeePct),
      coinsEarnPct: _i('earn', _s.coinsEarnPct),
      referralBonusCoins: _i('refBonus', _s.referralBonusCoins),
      maxCoinsPctOfOrder: _i('maxCoins', _s.maxCoinsPctOfOrder).clamp(0, 100),
      repairPrices: <String, int>{for (final RepairIssue i in RepairIssue.values) i.name: _i('rep_${i.name}', _s.repairPrice(i))},
    );
    final AppServices services = context.read<AppServices>();
    final user = context.read<SessionCubit>().state.user;
    final bool? ok = await runBusy<bool>(context, () async {
      await services.shopAdmin.saveSettings(user, next);
      return true;
    });
    if (ok == true && mounted) {
      toast(context, context.tr.saved);
      context.pop();
    }
  }
}

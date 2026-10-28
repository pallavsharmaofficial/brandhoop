import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/emi.dart';
import '../../core/money.dart';
import '../../domain/emi_plan.dart';
import '../../domain/store_settings.dart';
import '../../l10n/l10n.dart';
import '../../services/emi_service.dart';
import '../../state/data_cubits.dart';
import '../../widgets/common.dart';

/// A free-standing EMI calculator: type a price, pick a scheme and a tenure,
/// see the monthly amount and every instalment. It never promises approval.
class EmiCalculatorScreen extends StatefulWidget {
  const EmiCalculatorScreen({super.key, this.initialPrice});

  final int? initialPrice;

  @override
  State<EmiCalculatorScreen> createState() => _EmiCalculatorScreenState();
}

class _EmiCalculatorScreenState extends State<EmiCalculatorScreen> {
  late final TextEditingController _price = TextEditingController(text: '${widget.initialPrice ?? 15000}');
  double _downPct = 10;
  int _months = 6;
  String? _schemeId;

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StoreSettings store = context.watch<StoreCubit>().state;
    final int price = int.tryParse(_price.text.replaceAll(',', '')) ?? 0;
    final List<EmiScheme> schemes = store.emiSchemes.where((EmiScheme s) => s.enabled).toList();
    final EmiScheme? scheme = schemes.where((EmiScheme s) => s.id == _schemeId).firstOrNull ?? schemes.firstOrNull;
    final int months = (scheme != null && scheme.tenures.contains(_months)) ? _months : (scheme?.tenures.first ?? _months);
    final int minDown = scheme == null ? 0 : (price * scheme.minDownPaymentPct / 100).ceil();
    int down = (price * _downPct / 100).round();
    if (down < minDown) down = minDown;
    if (down >= price) down = price > 0 ? price - 1 : 0;
    final int principal = price - down;
    final EmiQuote? q = (scheme != null && principal > 0)
        ? Emi.quote(principal: principal, months: months, annualRatePct: scheme.annualRatePct)
        : null;
    final bool inRange = scheme?.allows(price) ?? true;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr.serviceEmiCalc)),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: <Widget>[
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: context.tr.phonePrice, prefixText: '₹ '),
            ),
            const SizedBox(height: 16),
            Text(context.tr.emiScheme, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final EmiScheme s in schemes)
                  ChoiceChip(
                    label: Text(s.name.of(context.lang)),
                    selected: s.id == scheme?.id,
                    onSelected: (_) => setState(() => _schemeId = s.id),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(child: Text(context.tr.downPayment, style: const TextStyle(fontWeight: FontWeight.w800))),
                Text('${formatRupees(down)}  (${price == 0 ? 0 : (down * 100 / price).round()}%)', style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
            Slider(
              min: 0,
              max: 60,
              divisions: 12,
              value: _downPct,
              label: '${_downPct.round()}%',
              onChanged: (double v) => setState(() => _downPct = v),
            ),
            const SizedBox(height: 4),
            Text(context.tr.chooseTenure, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final int m in scheme?.tenures ?? const <int>[])
                  ChoiceChip(label: Text(context.tr.monthsCount(m)), selected: m == months, onSelected: (_) => setState(() => _months = m)),
              ],
            ),
            const SizedBox(height: 20),
            if (!inRange && scheme != null)
              InfoBanner(text: context.tr.priceOutsideScheme(formatRupees(scheme.minPrice)), icon: Icons.info_outline, color: const Color(0xFFEF6C00))
            else if (q != null && scheme != null) ...<Widget>[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(colors: <Color>[BrandColors.indigoDeep, BrandColors.indigo]),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(context.tr.monthlyEmi, style: const TextStyle(color: Colors.white70)),
                    Text(formatRupees(q.emi), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
                    Text('${context.tr.perMonth} × ${q.months}', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(child: _stat(context, context.tr.amountFinanced, formatRupees(q.principal))),
                        Expanded(child: _stat(context, context.tr.totalInterest, formatRupees(q.totalInterest))),
                        Expanded(child: _stat(context, context.tr.totalYouPay, formatRupees(down + q.totalPayable + scheme.processingFee))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              InfoBanner(text: context.tr.emiIndicative),
              if (!store.emiRatesConfirmed) ...<Widget>[
                const SizedBox(height: 8),
                InfoBanner(text: context.tr.emiRatesUnconfirmed, icon: Icons.warning_amber_outlined, color: const Color(0xFFEF6C00)),
              ],
              Section(
                title: context.tr.instalmentSchedule,
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  child: Column(
                    children: <Widget>[
                      for (final Instalment i in EmiService.buildSchedule(q, DateTime.now()))
                        ListTile(
                          dense: true,
                          leading: CircleAvatar(radius: 13, child: Text('${i.index}', style: const TextStyle(fontSize: 12))),
                          title: Text(Dates.date(i.dueDate, context.lang)),
                          trailing: Text(formatRupees(i.amount), style: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go(Routes.shopWith(category: 'smartphone', emi: scheme.noCost)),
                icon: const Icon(Icons.smartphone),
                label: Text(context.tr.browseEmiPhones),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ],
      );
}

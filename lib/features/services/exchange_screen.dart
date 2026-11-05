import 'package:flutter/material.dart';

import '../../app/env.dart';
import '../../util/shop_message.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/money.dart';
import '../../domain/lead.dart';
import '../../l10n/l10n.dart';
import '../../services/app_services.dart';
import '../../services/exchange_estimator.dart';
import '../../state/data_cubits.dart';
import '../../state/session_cubit.dart';
import '../../util/launch.dart';
import '../../widgets/common.dart';
import '../auth/auth_gate.dart';

class ExchangeScreen extends StatefulWidget {
  const ExchangeScreen({super.key});

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  final TextEditingController _brand = TextEditingController();
  final TextEditingController _model = TextEditingController();
  final TextEditingController _price = TextEditingController();
  PhoneAge _age = PhoneAge.y1to2;
  ScreenState _screen = ScreenState.perfect;
  BodyState _body = BodyState.perfect;
  bool _batteryWeak = false;
  bool _allWorking = true;
  bool _hasBill = true;

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _price.dispose();
    super.dispose();
  }

  String _ageLabel(BuildContext c, PhoneAge a) {
    switch (a) {
      case PhoneAge.under6m:
        return c.tr.ageUnder6;
      case PhoneAge.m6to12:
        return c.tr.age6to12;
      case PhoneAge.y1to2:
        return c.tr.age1to2;
      case PhoneAge.y2to3:
        return c.tr.age2to3;
      case PhoneAge.over3y:
        return c.tr.ageOver3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int price = int.tryParse(_price.text) ?? 0;
    final ExchangeEstimate e = ExchangeEstimator.estimate(ExchangeInput(
      originalPrice: price,
      age: _age,
      screen: _screen,
      body: _body,
      batteryWeak: _batteryWeak,
      allWorking: _allWorking,
      hasBill: _hasBill,
    ));
    return Scaffold(
      appBar: AppBar(title: Text(context.tr.serviceExchange)),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: <Widget>[
            Text(context.tr.exchangeIntro, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4)),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(child: TextField(controller: _brand, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: context.tr.brand))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _model, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: context.tr.model))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: context.tr.priceWhenNew, prefixText: '₹ '),
            ),
            const SizedBox(height: 16),
            Text(context.tr.howOld, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final PhoneAge a in PhoneAge.values) ChoiceChip(label: Text(_ageLabel(context, a)), selected: a == _age, onSelected: (_) => setState(() => _age = a)),
              ],
            ),
            const SizedBox(height: 16),
            Text(context.tr.screenCondition, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ChoiceChip(label: Text(context.tr.screenPerfect), selected: _screen == ScreenState.perfect, onSelected: (_) => setState(() => _screen = ScreenState.perfect)),
                ChoiceChip(label: Text(context.tr.screenScratches), selected: _screen == ScreenState.scratches, onSelected: (_) => setState(() => _screen = ScreenState.scratches)),
                ChoiceChip(label: Text(context.tr.screenCracked), selected: _screen == ScreenState.cracked, onSelected: (_) => setState(() => _screen = ScreenState.cracked)),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr.bodyDents), value: _body == BodyState.dents, onChanged: (bool v) => setState(() => _body = v ? BodyState.dents : BodyState.perfect)),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr.batteryWeak), value: _batteryWeak, onChanged: (bool v) => setState(() => _batteryWeak = v)),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr.allWorking), value: _allWorking, onChanged: (bool v) => setState(() => _allWorking = v)),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr.haveBill), value: _hasBill, onChanged: (bool v) => setState(() => _hasBill = v)),
            const SizedBox(height: 12),
            if (e.high > 0) ...<Widget>[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(colors: <Color>[Color(0xFF00695C), Color(0xFF26A69A)]),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(context.tr.estimatedValue, style: const TextStyle(color: Colors.white70)),
                    Text('${formatRupees(e.low)} - ${formatRupees(e.high)}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(context.tr.exchangeIndicative, style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => _send(context, e),
                icon: const Icon(Icons.send_outlined),
                label: Text(context.tr.sendToShop),
              ),
            ] else
              InfoBanner(text: context.tr.exchangeEnterPrice),
          ],
        ),
      ),
    );
  }

  Future<void> _send(BuildContext context, ExchangeEstimate e) async {
    if (AppEnv.live) {
      final String shop = context.read<StoreCubit>().state.name.of(context.lang);
      final String device = '${_brand.text.trim()} ${_model.text.trim()}'.trim();
      return sendToShop(
        context,
        context.tr.liveExchangeMsg(shop, device.isEmpty ? '-' : device, '${formatRupees(e.low)} - ${formatRupees(e.high)}'),
      );
    }
    final AppServices services = context.read<AppServices>();
    final SessionState session = context.read<SessionCubit>().state;
    final store = context.read<StoreCubit>().state;
    final String ok = context.tr.exchangeSent;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    String name = session.user?.displayName ?? '';
    String phone = session.user?.phone ?? '';
    if (session.user == null) {
      final ({String name, String phone})? c = await askContact(context, title: context.tr.serviceExchange);
      if (c == null) return;
      name = c.name;
      phone = c.phone;
    }
    final String device = '${_brand.text.trim()} ${_model.text.trim()}'.trim();
    await services.leads.capture(
      type: LeadType.exchange,
      name: name,
      phone: phone,
      userId: session.user?.id,
      productName: device.isEmpty ? 'Old phone' : device,
      message: '${formatRupees(e.low)} - ${formatRupees(e.high)}',
      details: <String, String>{
        'age': _age.name,
        'screen': _screen.name,
        'body': _body.name,
        'batteryWeak': '$_batteryWeak',
        'allWorking': '$_allWorking',
        'hasBill': '$_hasBill',
        'originalPrice': _price.text,
      },
    );
    messenger.showSnackBar(SnackBar(content: Text(ok)));
    if (store.hasWhatsapp) {
      await Launch.whatsapp(store.whatsapp, text: 'Exchange: $device, ${formatRupees(e.low)} - ${formatRupees(e.high)}');
    }
  }
}


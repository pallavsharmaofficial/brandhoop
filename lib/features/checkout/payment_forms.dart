import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/env.dart';
import '../../core/validators.dart';
import '../../domain/payment.dart';
import '../../l10n/l10n.dart';
import '../../services/payment_gateway.dart';
import '../../widgets/common.dart';

const List<String> upiApps = <String>['Google Pay', 'PhonePe', 'Paytm', 'BHIM'];

const List<String> banks = <String>[
  'State Bank of India',
  'HDFC Bank',
  'ICICI Bank',
  'Axis Bank',
  'Punjab National Bank',
  'Bank of Baroda',
  'Kotak Mahindra Bank',
];

/// Collects what is needed to pay by UPI, card or net banking and reports a
/// ready-to-use [PayInstrument] (or null while the form is incomplete).
/// Nothing typed here is kept beyond this widget.
class InstrumentPicker extends StatefulWidget {
  const InstrumentPicker({super.key, required this.methods, required this.onChanged});

  final List<PaymentMethod> methods;
  final ValueChanged<PayInstrument?> onChanged;

  @override
  State<InstrumentPicker> createState() => _InstrumentPickerState();
}

class _InstrumentPickerState extends State<InstrumentPicker> {
  late PaymentMethod _method = widget.methods.first;
  String? _app;
  String? _bank;
  final TextEditingController _upiId = TextEditingController();
  final TextEditingController _number = TextEditingController();
  final TextEditingController _expiry = TextEditingController();
  final TextEditingController _cvv = TextEditingController();
  final TextEditingController _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[_upiId, _number, _expiry, _cvv, _name]) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() {
    if (!mounted) return;
    PayInstrument? i;
    switch (_method) {
      case PaymentMethod.upi:
        final String id = _upiId.text.trim();
        if (id.isNotEmpty) {
          if (Validators.upiId(id)) i = PayInstrument.upiId(id);
        } else if (_app != null) {
          i = PayInstrument.upiApp(_app!);
        }
      case PaymentMethod.card:
      case PaymentMethod.cardEmi:
        if (Validators.cardNumber(_number.text) &&
            Validators.cardExpiry(_expiry.text, DateTime.now()) &&
            RegExp(r'^[0-9]{3,4}$').hasMatch(_cvv.text)) {
          i = PayInstrument.card(
            cardNumber: _number.text,
            cardExpiry: _expiry.text,
            cardCvv: _cvv.text,
            cardName: _name.text.trim(),
          );
        }
      case PaymentMethod.netbanking:
        if (_bank != null) i = PayInstrument.netbanking(_bank!);
      case PaymentMethod.cash:
      case PaymentMethod.bajajEmi:
        break;
    }
    widget.onChanged(i);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.methods.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SegmentedButton<PaymentMethod>(
              showSelectedIcon: false,
              segments: <ButtonSegment<PaymentMethod>>[
                for (final PaymentMethod m in widget.methods)
                  ButtonSegment<PaymentMethod>(value: m, label: Text(context.tr.payMethod(m))),
              ],
              selected: <PaymentMethod>{_method},
              onSelectionChanged: (Set<PaymentMethod> s) {
                setState(() => _method = s.first);
                _emit();
              },
            ),
          ),
        if (_method == PaymentMethod.upi) _upi(context),
        if (_method == PaymentMethod.card || _method == PaymentMethod.cardEmi) _card(context),
        if (_method == PaymentMethod.netbanking) _netbanking(context),
        if (AppEnv.demo)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: InfoBanner(text: context.tr.testPaymentHint, icon: Icons.science_outlined, color: const Color(0xFFFF8F00)),
          ),
      ],
    );
  }

  Widget _upi(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String a in upiApps)
                ChoiceChip(
                  label: Text(a),
                  selected: _app == a && _upiId.text.trim().isEmpty,
                  onSelected: (bool on) {
                    setState(() {
                      _app = on ? a : null;
                      if (on) _upiId.clear();
                    });
                    _emit();
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _upiId,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            onChanged: (_) {
              setState(() {});
              _emit();
            },
            decoration: InputDecoration(
              labelText: context.tr.orEnterUpiId,
              hintText: 'name@bank',
              errorText: _upiId.text.trim().isEmpty || Validators.upiId(_upiId.text) ? null : context.tr.errBadUpi,
            ),
          ),
        ],
      );

  Widget _card(BuildContext context) => Column(
        children: <Widget>[
          TextField(
            controller: _number,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(19), _GroupFormatter()],
            onChanged: (_) {
              setState(() {});
              _emit();
            },
            decoration: InputDecoration(
              labelText: context.tr.cardNumber,
              prefixIcon: const Icon(Icons.credit_card),
              errorText: _number.text.length >= 13 && !Validators.cardNumber(_number.text) ? context.tr.errBadCard : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _expiry,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4), _ExpiryFormatter()],
                  onChanged: (_) {
                    setState(() {});
                    _emit();
                  },
                  decoration: InputDecoration(
                    labelText: context.tr.cardExpiry,
                    hintText: 'MM/YY',
                    errorText: _expiry.text.length == 5 && !Validators.cardExpiry(_expiry.text, DateTime.now()) ? context.tr.errBadExpiry : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _cvv,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                  onChanged: (_) => _emit(),
                  decoration: const InputDecoration(labelText: 'CVV'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: context.tr.nameOnCard),
          ),
        ],
      );

  Widget _netbanking(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          for (final String b in <String>[...banks, if (AppEnv.demo) MockPaymentGateway.failingBank])
            ChoiceChip(
              label: Text(b),
              selected: _bank == b,
              onSelected: (bool on) {
                setState(() => _bank = on ? b : null);
                _emit();
              },
            ),
        ],
      );
}

class _GroupFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue v) {
    final String d = v.text.replaceAll(' ', '');
    final StringBuffer b = StringBuffer();
    for (int i = 0; i < d.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(d[i]);
    }
    final String s = b.toString();
    return TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue v) {
    final String d = v.text.replaceAll('/', '');
    final String s = d.length > 2 ? '${d.substring(0, 2)}/${d.substring(2)}' : d;
    return TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

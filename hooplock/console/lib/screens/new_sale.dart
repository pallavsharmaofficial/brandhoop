import 'dart:async';
import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../api.dart';
import '../i18n.dart';
import '../widgets.dart';
import 'detail.dart';

const phoneBrands = ['Samsung', 'Vivo', 'Oppo', 'Realme', 'Xiaomi', 'Redmi', 'Poco', 'OnePlus', 'Motorola', 'iQOO', 'Nothing', 'Infinix', 'Tecno', 'Google', 'Nokia', 'Other'];

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key, required this.platform});
  final String platform;
  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _form = GlobalKey<FormState>();
  int _step = 0;
  final name = TextEditingController(), mobile = TextEditingController(), alt = TextEditingController(), address = TextEditingController();
  final idLast4 = TextEditingController(), notes = TextEditingController();
  String idType = 'Aadhaar';
  String brandName = 'Samsung';
  final model = TextEditingController(), imei1 = TextEditingController(), imei2 = TextEditingController(), serial = TextEditingController();
  final total = TextEditingController(), down = TextEditingController(text: '0'), emi = TextEditingController(), count = TextEditingController(text: '6');
  final loanRef = TextEditingController();
  DateTime firstEmi = DateTime(DateTime.now().year, DateTime.now().month + 1, DateTime.now().day.clamp(1, 28));
  XFile? _photo;
  bool _saving = false;

  bool get ios => widget.platform == 'ios';

  @override
  void initState() {
    super.initState();
    if (ios) brandName = 'Apple';
    for (final c in [total, down, count]) {
      c.addListener(_suggestEmi);
    }
  }

  void _suggestEmi() {
    final t = double.tryParse(total.text), d = double.tryParse(down.text) ?? 0, n = int.tryParse(count.text);
    if (t != null && n != null && n > 0 && t > d) {
      final v = ((t - d) / n).ceil();
      if (emi.text != '$v') emi.text = '$v';
    }
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
  String? _mobile(String? v) => RegExp(r'^[6-9]\d{9}$').hasMatch(v?.trim() ?? '') ? null : '10-digit mobile number';
  String? _imei(String? v) => (v == null || v.isEmpty || RegExp(r'^\d{15}$').hasMatch(v)) ? null : 'IMEI is 15 digits';

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final r = await Api.I.post('/api/sales', {
        'platform': widget.platform,
        'customer': {
          'name': name.text.trim(), 'mobile': mobile.text.trim(), 'altMobile': alt.text.trim(), 'address': address.text.trim(),
          'idType': idType, 'idLast4': idLast4.text.trim(), 'notes': notes.text.trim(),
        },
        'device': {'brand': brandName, 'model': model.text.trim(), 'imei1': imei1.text.trim(), 'imei2': imei2.text.trim(), 'serial': serial.text.trim()},
        'loan': {
          'totalAmount': double.parse(total.text), 'downPayment': double.tryParse(down.text) ?? 0, 'emiAmount': double.parse(emi.text),
          'emiCount': int.parse(count.text), 'firstEmiDate': firstEmi.toIso8601String().substring(0, 10), 'loanRef': loanRef.text.trim(),
        },
      }) as Map<String, dynamic>;
      if (_photo != null) {
        final bytes = await _photo!.readAsBytes();
        await Api.I.put('/api/customers/${r['customerId']}/photo', {'dataBase64': base64Encode(bytes), 'type': 'image/jpeg'}).catchError((_) => null);
      }
      if (!mounted) return;
      if (r['enrollment'] != null) {
        await Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => EnrollQrScreen(deviceId: r['deviceId'] as String, customerName: name.text.trim(), initial: r['enrollment'] as Map<String, dynamic>)));
      } else {
        await Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DeviceDetailScreen(deviceId: r['deviceId'] as String)));
      }
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      Step(title: const Text('Customer'), isActive: _step >= 0, content: Column(children: [
        Row(children: [
          InkWell(
            onTap: () async {
              final x = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 640, imageQuality: 75);
              if (x != null) setState(() => _photo = x);
            },
            child: CircleAvatar(radius: 34, backgroundColor: brandSoft, child: Icon(_photo == null ? Icons.add_a_photo_outlined : Icons.check_circle, color: brand, size: 30)),
          ),
          const SizedBox(width: 14),
          Expanded(child: TextFormField(controller: name, validator: _req, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Customer name'))),
        ]),
        const SizedBox(height: 12),
        TextFormField(controller: mobile, validator: _mobile, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'Mobile (SIM in this phone)', counterText: '')),
        const SizedBox(height: 12),
        TextFormField(controller: alt, validator: (v) => (v ?? '').isEmpty ? null : _mobile(v), keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'Alternate mobile (family)', counterText: '')),
        const SizedBox(height: 12),
        TextFormField(controller: address, maxLines: 2, decoration: const InputDecoration(labelText: 'Address')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(initialValue: idType, decoration: const InputDecoration(labelText: 'ID proof'),
              items: const ['Aadhaar', 'PAN', 'Voter ID', 'Driving licence', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => idType = v!)),
          const SizedBox(width: 12),
          SizedBox(width: 120, child: TextFormField(controller: idLast4, maxLength: 4, decoration: const InputDecoration(labelText: 'Last 4', counterText: ''))),
        ]),
      ])),
      Step(title: const Text('Phone'), isActive: _step >= 1, content: Column(children: [
        if (!ios) DropdownButtonFormField<String>(initialValue: brandName, decoration: const InputDecoration(labelText: 'Brand'),
            items: phoneBrands.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => brandName = v!),
        const SizedBox(height: 12),
        TextFormField(controller: model, decoration: InputDecoration(labelText: ios ? 'Model (e.g. iPhone 16)' : 'Model')),
        const SizedBox(height: 12),
        if (ios)
          TextFormField(controller: serial, validator: _req, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Serial number (Settings › General › About)'))
        else ...[
          TextFormField(controller: imei1, validator: _imei, keyboardType: TextInputType.number, maxLength: 15, decoration: const InputDecoration(labelText: 'IMEI 1 (optional, read from phone at setup)', counterText: '')),
          const SizedBox(height: 12),
          TextFormField(controller: imei2, validator: _imei, keyboardType: TextInputType.number, maxLength: 15, decoration: const InputDecoration(labelText: 'IMEI 2 (optional)', counterText: '')),
        ],
      ])),
      Step(title: const Text('EMI'), isActive: _step >= 2, content: Column(children: [
        TextFormField(controller: total, validator: _req, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total price ₹')),
        const SizedBox(height: 12),
        TextFormField(controller: down, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Down payment ₹')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(controller: count, validator: _req, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Number of EMIs'))),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: emi, validator: _req, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'EMI amount ₹'))),
        ]),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('First EMI date'),
          subtitle: Text(dmy(firstEmi.toIso8601String())),
          trailing: const Icon(Icons.calendar_month, color: brand),
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: firstEmi, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 365)));
            if (d != null) setState(() => firstEmi = d);
          },
        ),
        TextFormField(controller: loanRef, decoration: const InputDecoration(labelText: 'Loan / bill number (optional)')),
        const SizedBox(height: 12),
        TextFormField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes (optional)')),
      ])),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.reply_rounded, color: brand, size: 32), onPressed: () => Navigator.pop(context)),
        title: Text('${t('new_sale')} · ${ios ? t('iphone') : t('android')}'),
      ),
      body: PageBody(
        child: Form(
          key: _form,
          child: Stepper(
            currentStep: _step,
            onStepTapped: (i) => setState(() => _step = i),
            onStepContinue: () => _step < 2 ? setState(() => _step++) : _submit(),
            onStepCancel: _step == 0 ? null : () => setState(() => _step--),
            controlsBuilder: (context, details) => Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(children: [
                Expanded(child: FilledButton(onPressed: _saving ? null : details.onStepContinue, child: Text(_step < 2 ? 'Next' : (ios ? 'Save sale' : 'Save & show QR')))),
                if (_step > 0) ...[const SizedBox(width: 12), Expanded(child: OutlinedButton(onPressed: details.onStepCancel, child: const Text('Back')))],
              ]),
            ),
            steps: steps,
          ),
        ),
      ),
    );
  }
}

/// Big QR to scan on the new phone's welcome screen.
class EnrollQrScreen extends StatefulWidget {
  const EnrollQrScreen({super.key, required this.deviceId, required this.customerName, this.initial});
  final String deviceId;
  final String customerName;
  final Map<String, dynamic>? initial;
  @override
  State<EnrollQrScreen> createState() => _EnrollQrScreenState();
}

class _EnrollQrScreenState extends State<EnrollQrScreen> {
  Map<String, dynamic>? _e;
  Timer? _poll;
  Timer? _tick;
  String _status = 'pending';
  final _ssid = TextEditingController(), _wifiPass = TextEditingController();

  @override
  void initState() {
    super.initState();
    _e = widget.initial;
    if (_e == null) _make();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _check());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() { _poll?.cancel(); _tick?.cancel(); super.dispose(); }

  Future<void> _make() async {
    try {
      final r = await Api.I.post('/api/devices/${widget.deviceId}/enrollment', {
        if (_ssid.text.trim().isNotEmpty) 'wifiSsid': _ssid.text.trim(),
        if (_wifiPass.text.isNotEmpty) 'wifiPassword': _wifiPass.text,
      }) as Map<String, dynamic>;
      if (mounted) setState(() => _e = r);
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
  }

  Future<void> _check() async {
    try {
      final d = await Api.I.get('/api/devices/${widget.deviceId}') as Map<String, dynamic>;
      if (d['status'] != _status && mounted) setState(() => _status = d['status'] as String);
      if (d['status'] == 'active') _poll?.cancel();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final expires = _e == null ? null : DateTime.parse(_e!['expiresAt'] as String);
    final left = expires?.difference(DateTime.now());
    final expired = left != null && left.isNegative;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.reply_rounded, color: brand, size: 32), onPressed: () => Navigator.pop(context)),
        title: Text(t('show_qr')),
      ),
      body: PageBody(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(widget.customerName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          if (_status == 'active') ...[
            const Icon(Icons.verified, color: success, size: 120),
            const Text('Phone enrolled and protected', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: success)),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DeviceDetailScreen(deviceId: widget.deviceId))), child: const Text('Open customer')),
          ] else if (_e == null)
            const Loading()
          else ...[
            Center(
              child: Opacity(
                opacity: expired ? .15 : 1,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: brand, width: 2), borderRadius: BorderRadius.circular(16)),
                  child: QrImageView(data: _e!['qr'] as String, size: 300, errorCorrectionLevel: QrErrorCorrectLevel.M),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(expired ? 'QR expired' : 'Valid for ${left!.inMinutes}:${(left.inSeconds % 60).toString().padLeft(2, '0')}',
                textAlign: TextAlign.center, style: TextStyle(color: expired ? danger : muted, fontWeight: FontWeight.w600)),
            if (expired) Padding(padding: const EdgeInsets.only(top: 8), child: FilledButton(onPressed: _make, child: const Text('Make a new QR'))),
            const SizedBox(height: 4),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: brand)),
              SizedBox(width: 8),
              Text('Waiting for the phone…', style: TextStyle(color: muted)),
            ]),
            const SizedBox(height: 20),
            const SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('How to set up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('1. New phone, or factory reset. Turn it on.\n'
                  '2. On the first "Welcome / Hi there" screen, tap the same spot 6 times. A QR scanner opens.\n'
                  '3. Connect to Wi-Fi if asked, and scan this QR.\n'
                  '4. The phone downloads HoopLock and sets itself up (2–3 minutes).\n'
                  '5. Hand the phone to the customer to read and accept the agreement, then finish normal setup.',
                  style: TextStyle(fontSize: 15, height: 1.5)),
            ])),
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('Add shop Wi-Fi to the QR (optional)'),
              children: [
                TextField(controller: _ssid, decoration: const InputDecoration(labelText: 'Wi-Fi name')),
                const SizedBox(height: 8),
                TextField(controller: _wifiPass, decoration: const InputDecoration(labelText: 'Wi-Fi password')),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: _make, child: const Text('Make QR with Wi-Fi')),
                const SizedBox(height: 8),
              ],
            ),
          ],
        ]),
      ),
    );
  }
}

import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../i18n.dart';
import '../widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  String? _error;

  Future<void> _submit() async {
    setState(() { _busy = true; _error = null; });
    try {
      await Api.I.login(_phone.text.trim(), _pass.text);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageBody(
          maxWidth: 440,
          child: ListView(padding: const EdgeInsets.all(24), children: [
            const SizedBox(height: 40),
            Center(
              child: Container(
                width: 92, height: 92,
                decoration: const BoxDecoration(color: brand, shape: BoxShape.circle),
                child: const Icon(Icons.lock_rounded, color: Colors.white, size: 52),
              ),
            ),
            const SizedBox(height: 16),
            const Center(child: Text('HoopLock', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: ink))),
            const Center(child: Text('EMI सुरक्षित · दुकान निश्चिंत', style: TextStyle(fontSize: 16, color: muted))),
            const SizedBox(height: 36),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: InputDecoration(labelText: t('mobile'), prefixIcon: const Icon(Icons.phone_android), counterText: ''),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _pass,
              obscureText: _hide,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: t('password'),
                prefixIcon: const Icon(Icons.key),
                suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _hide = !_hide)),
              ),
            ),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: danger))),
            const SizedBox(height: 22),
            FilledButton(onPressed: _busy ? null : _submit, child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(t('login'))),
            const SizedBox(height: 12),
            TextButton(onPressed: () => Lang.I.set(Lang.I.value == 'hi' ? 'en' : 'hi'), child: Text(t('language'))),
          ]),
        ),
      ),
    );
  }
}

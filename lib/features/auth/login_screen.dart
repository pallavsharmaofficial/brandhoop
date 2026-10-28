
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/env.dart';
import '../../app/routes.dart';
import '../../core/validators.dart';
import '../../data/demo_seed.dart';
import '../../domain/app_user.dart';
import '../../l10n/l10n.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../state/session_cubit.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/common.dart';

/// Mobile number, then the code. A first-time number may add a name and a
/// referral code. Pushed over whatever the person was doing, and popped back to
/// it with `true` when they are in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.next});

  /// Where to go afterwards when this was not pushed over another screen.
  final String? next;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _otp = TextEditingController();
  final TextEditingController _ref = TextEditingController();
  bool _codeSent = false;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    _ref.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final AppServices s = context.read<AppServices>();
    final bool? ok = await runBusy<bool>(context, () async {
      await s.auth.sendOtp(_phone.text);
      return true;
    });
    if (ok == true && mounted) setState(() => _codeSent = true);
  }

  Future<void> _verify() async {
    final AppServices s = context.read<AppServices>();
    final SessionCubit session = context.read<SessionCubit>();
    final AppUser? u = await runBusy<AppUser>(
      context,
      () => s.auth.verifyOtp(_phone.text, _otp.text, referralCode: _ref.text),
    );
    if (u == null || !mounted) return;
    session.signedInAs(u);
    _leave(u);
  }

  void _leave(AppUser u) {
    if (u.isStaff) {
      context.go(Routes.adminDashboard);
    } else if (widget.next != null && widget.next!.startsWith('/')) {
      // Sent here by a redirect: carry on to where they were going, keeping
      // whatever was under the sign-in screen (the cart) underneath.
      context.pushReplacement(widget.next!);
    } else if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(Routes.home);
    }
  }

  Future<void> _demo(String id) async {
    final AuthService auth = context.read<AppServices>().auth;
    if (auth is! LocalAuthService) return;
    final SessionCubit session = context.read<SessionCubit>();
    final AppUser? u = await auth.signInAs(id);
    if (u == null || !mounted) return;
    session.signedInAs(u);
    _leave(u);
  }

  @override
  Widget build(BuildContext context) {
    final bool phoneOk = Validators.mobile(_phone.text) != null;
    return Scaffold(
      appBar: AppBar(actions: const <Widget>[LanguageButton(), SizedBox(width: 12)]),
      body: MaxWidth(
        width: 480,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            const Center(child: BrandMark(size: 72)),
            const SizedBox(height: 16),
            Text(
              _codeSent ? context.tr.enterCode : context.tr.signInTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              _codeSent ? context.tr.codeSentTo(_phone.text) : context.tr.signInBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (!_codeSent) ...<Widget>[
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                autofocus: true,
                maxLength: 13,
                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => phoneOk ? _send() : null,
                decoration: InputDecoration(labelText: context.tr.mobileNumber, prefixText: '+91  ', counterText: ''),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: phoneOk ? _send : null, child: Text(context.tr.sendCode)),
            ] else ...<Widget>[
              TextField(
                controller: _otp,
                keyboardType: TextInputType.number,
                autofocus: true,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, letterSpacing: 8, fontWeight: FontWeight.w800),
                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _otp.text.length == 6 ? _verify() : null,
                decoration: InputDecoration(labelText: context.tr.sixDigitCode, counterText: ''),
              ),
              if (AppEnv.demo)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(context.tr.demoCodeHint(LocalAuthService.demoCode), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _ref,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: '${context.tr.referralCode} (${context.tr.optional})', prefixIcon: const Icon(Icons.card_giftcard_outlined)),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _otp.text.length == 6 ? _verify : null, child: Text(context.tr.verifyAndContinue)),
              TextButton(
                onPressed: () => setState(() {
                  _codeSent = false;
                  _otp.clear();
                }),
                child: Text(context.tr.changeNumber),
              ),
            ],
            if (AppEnv.demo && !_codeSent) ...<Widget>[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 12),
              Text(context.tr.tryAs, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ActionChip(avatar: const Icon(Icons.person_outline, size: 18), label: Text(context.tr.roleCustomer), onPressed: () => _demo('u_c0')),
                  ActionChip(avatar: const Icon(Icons.point_of_sale, size: 18), label: Text(context.tr.roleStaff), onPressed: () => _demo('u_staff')),
                  ActionChip(avatar: const Icon(Icons.manage_accounts_outlined, size: 18), label: Text(context.tr.roleManager), onPressed: () => _demo('u_manager')),
                  ActionChip(avatar: const Icon(Icons.admin_panel_settings_outlined, size: 18), label: Text(context.tr.roleOwner), onPressed: () => _demo('u_owner')),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.tr.demoAccountsHint(DemoSeed.ownerPhone, DemoSeed.customerPhone),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

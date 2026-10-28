import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/validators.dart';
import '../../domain/app_user.dart';
import '../../l10n/l10n.dart';
import '../../state/session_cubit.dart';

/// Returns the signed-in customer, sending a guest through sign-in first.
/// Null if they backed out.
Future<AppUser?> ensureSignedIn(BuildContext context) async {
  final SessionCubit session = context.read<SessionCubit>();
  if (session.state.user != null) return session.state.user;
  await context.push<bool>(Routes.login);
  return session.state.user;
}

/// Asks a guest for a name and number, so a shop can call them back.
Future<({String name, String phone})?> askContact(BuildContext context, {String? title}) async {
  final TextEditingController name = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final GlobalKey<FormState> key = GlobalKey<FormState>();
  final ({String name, String phone})? r = await showDialog<({String name, String phone})>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: Text(title ?? ctx.tr.yourDetails),
      content: Form(
        key: key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: ctx.tr.yourName),
              validator: (String? v) => (v ?? '').trim().isEmpty ? ctx.tr.required : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: ctx.tr.mobileNumber, prefixText: '+91 '),
              validator: (String? v) => Validators.mobile(v) == null ? ctx.tr.errBadPhone : null,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr.cancel)),
        FilledButton(
          onPressed: () {
            if (key.currentState!.validate()) {
              Navigator.pop(ctx, (name: name.text.trim(), phone: Validators.mobile(phone.text)!));
            }
          },
          child: Text(ctx.tr.send),
        ),
      ],
    ),
  );
  name.dispose();
  phone.dispose();
  return r;
}

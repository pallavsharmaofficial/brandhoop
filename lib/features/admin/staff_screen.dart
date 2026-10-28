import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme.dart';
import '../../core/permissions.dart';
import '../../domain/app_user.dart';
import '../../l10n/l10n.dart';
import '../../services/app_services.dart';
import '../../state/data_cubits.dart';
import '../../state/session_cubit.dart';
import '../../widgets/common.dart';

/// Who works here, and what each may do. Owner only.
class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<AppUser> staff = context.watch<UsersCubit>().state.where((AppUser u) => u.role != AppRole.customer).toList()
      ..sort((AppUser a, AppUser b) => b.role.index.compareTo(a.role.index));
    final SessionState session = context.watch<SessionCubit>().state;
    final AppServices services = context.read<AppServices>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr.staffTitle)),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _add(context, services, session), icon: const Icon(Icons.person_add_alt), label: Text(context.tr.addStaff)),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: <Widget>[
            InfoBanner(text: context.tr.staffExplain, icon: Icons.badge_outlined),
            const SizedBox(height: 12),
            for (final AppUser u in staff)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: u.active ? BrandColors.indigo : Colors.grey, child: Text(u.displayName.characters.first.toUpperCase(), style: const TextStyle(color: Colors.white))),
                    title: Text(u.displayName, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('+91 ${u.phone}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        StatusPill(u.active ? context.tr.role(u.role) : context.tr.disabled, color: u.active ? BrandColors.indigo : Colors.grey),
                        PopupMenuButton<String>(
                          onSelected: (String v) async {
                            if (v == 'off' || v == 'on') {
                              await runBusy(context, () => services.profile.setActive(session.user, u, v == 'on'));
                            } else {
                              final AppRole r = AppRole.values.firstWhere((AppRole x) => x.name == v);
                              await runBusy(context, () => services.profile.setRole(session.user, u.phone, r));
                            }
                          },
                          itemBuilder: (BuildContext c) => <PopupMenuEntry<String>>[
                            for (final AppRole r in RolePolicy.assignable)
                              if (r != u.role) PopupMenuItem<String>(value: r.name, child: Text(c.tr.makeRole(c.tr.role(r)))),
                            PopupMenuItem<String>(value: 'customer', child: Text(c.tr.makeRole(c.tr.roleCustomer))),
                            PopupMenuItem<String>(value: u.active ? 'off' : 'on', child: Text(u.active ? c.tr.disableAccount : c.tr.enableAccount)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Section(
              title: context.tr.whatEachRoleCanDo,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _role(context, AppRole.staff, context.tr.roleStaffCan),
                      _role(context, AppRole.manager, context.tr.roleManagerCan),
                      _role(context, AppRole.owner, context.tr.roleOwnerCan),
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

  Widget _role(BuildContext context, AppRole r, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(context.tr.role(r), style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4)),
          ],
        ),
      );

  Future<void> _add(BuildContext context, AppServices services, SessionState session) async {
    final TextEditingController phone = TextEditingController();
    final TextEditingController name = TextEditingController();
    AppRole role = AppRole.staff;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter set) => AlertDialog(
          title: Text(ctx.tr.addStaff),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: ctx.tr.yourName)),
              const SizedBox(height: 12),
              TextField(controller: phone, keyboardType: TextInputType.phone, maxLength: 10, inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: ctx.tr.mobileNumber, prefixText: '+91 ', counterText: '')),
              const SizedBox(height: 12),
              DropdownButtonFormField<AppRole>(
                initialValue: role,
                decoration: InputDecoration(labelText: ctx.tr.roleLabel),
                items: <DropdownMenuItem<AppRole>>[for (final AppRole r in RolePolicy.assignable) DropdownMenuItem<AppRole>(value: r, child: Text(ctx.tr.role(r)))],
                onChanged: (AppRole? v) => set(() => role = v ?? role),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.tr.add)),
          ],
        ),
      ),
    );
    final String p = phone.text;
    final String n = name.text;
    phone.dispose();
    name.dispose();
    if (ok != true || !context.mounted) return;
    final AppUser? u = await runBusy(context, () => services.profile.setRole(session.user, p, role, name: n));
    if (u != null && context.mounted) toast(context, context.tr.staffAdded);
  }
}

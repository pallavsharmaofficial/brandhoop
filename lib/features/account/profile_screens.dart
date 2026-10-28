import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/ids.dart';
import '../../core/validators.dart';
import '../../domain/address.dart';
import '../../domain/app_user.dart';
import '../../domain/product.dart';
import '../../domain/store_settings.dart';
import '../../l10n/l10n.dart';
import '../../services/app_services.dart';
import '../../state/data_cubits.dart';
import '../../state/session_cubit.dart';
import '../../util/launch.dart';
import '../../widgets/common.dart';
import '../../widgets/product_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name = TextEditingController(text: context.read<SessionCubit>().state.user?.name ?? '');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? u = context.watch<SessionCubit>().state.user;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr.myProfile)),
      body: MaxWidth(
        width: 520,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: context.tr.yourName)),
            const SizedBox(height: 12),
            TextField(readOnly: true, controller: TextEditingController(text: '+91 ${u?.phone ?? ''}'), decoration: InputDecoration(labelText: context.tr.mobileNumber, helperText: context.tr.phoneCannotChange)),
            const SizedBox(height: 12),
            TextField(readOnly: true, controller: TextEditingController(text: u?.referralCode ?? ''), decoration: InputDecoration(labelText: context.tr.myReferralCode)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: u == null
                  ? null
                  : () async {
                      final AppServices s = context.read<AppServices>();
                      await runBusy(context, () => s.profile.rename(u, _name.text));
                      if (context.mounted) toast(context, context.tr.saved);
                    },
              child: Text(context.tr.save),
            ),
          ],
        ),
      ),
    );
  }
}

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppUser? u = context.watch<SessionCubit>().state.user;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr.myAddresses)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.address('new')),
        icon: const Icon(Icons.add),
        label: Text(context.tr.addAddress),
      ),
      body: (u == null || u.addresses.isEmpty)
          ? EmptyState(icon: Icons.location_off_outlined, title: context.tr.noAddresses, message: context.tr.noAddressesHint)
          : MaxWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: <Widget>[
                  for (final Address a in u.addresses)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.home_outlined),
                          title: Text('${a.label} · ${a.name}', style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text('${a.oneLine}\n${a.phone}'),
                          isThreeLine: true,
                          onTap: () => context.push(Routes.address(a.id)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final bool ok = await confirmDialog(context, title: context.tr.deleteAddressQ, destructive: true);
                              if (ok && context.mounted) await context.read<AppServices>().profile.removeAddress(u, a.id);
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class AddressEditScreen extends StatefulWidget {
  const AddressEditScreen({super.key, required this.addressId});

  final String addressId;

  @override
  State<AddressEditScreen> createState() => _AddressEditScreenState();
}

class _AddressEditScreenState extends State<AddressEditScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final Address? _existing = context.read<SessionCubit>().state.user?.addresses.where((Address a) => a.id == widget.addressId).firstOrNull;
  late final TextEditingController _name = TextEditingController(text: _existing?.name ?? context.read<SessionCubit>().state.user?.name ?? '');
  late final TextEditingController _phone = TextEditingController(text: _existing?.phone ?? context.read<SessionCubit>().state.user?.phone ?? '');
  late final TextEditingController _line1 = TextEditingController(text: _existing?.line1 ?? '');
  late final TextEditingController _landmark = TextEditingController(text: _existing?.landmark ?? '');
  late final TextEditingController _area = TextEditingController(text: _existing?.area ?? '');
  late final TextEditingController _city = TextEditingController(text: _existing?.city ?? context.read<StoreCubit>().state.city);
  late final TextEditingController _pin = TextEditingController(text: _existing?.pincode ?? context.read<StoreCubit>().state.pincode);
  late final TextEditingController _state = TextEditingController(text: _existing?.state ?? 'Rajasthan');
  late String _label = _existing?.label ?? 'Home';

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[_name, _phone, _line1, _landmark, _area, _city, _pin, _state]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _req(String? v) => (v ?? '').trim().isEmpty ? context.tr.required : null;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_existing == null ? context.tr.addAddress : context.tr.editAddress)),
        body: MaxWidth(
          width: 560,
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    for (final (String, String) l in <(String, String)>[('Home', context.tr.addrHome), ('Shop', context.tr.addrShop), ('Work', context.tr.addrWork), ('Other', context.tr.addrOther)])
                      ChoiceChip(label: Text(l.$2), selected: _label == l.$1, onSelected: (_) => setState(() => _label = l.$1)),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(controller: _name, textCapitalization: TextCapitalization.words, validator: _req, decoration: InputDecoration(labelText: context.tr.fullName)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  validator: (String? v) => Validators.mobile(v) == null ? context.tr.errBadPhone : null,
                  decoration: InputDecoration(labelText: context.tr.mobileNumber, prefixText: '+91 '),
                ),
                const SizedBox(height: 12),
                TextFormField(controller: _line1, validator: _req, decoration: InputDecoration(labelText: context.tr.houseNoStreet)),
                const SizedBox(height: 12),
                TextFormField(controller: _area, validator: _req, decoration: InputDecoration(labelText: context.tr.colonyOrVillage)),
                const SizedBox(height: 12),
                TextFormField(controller: _landmark, decoration: InputDecoration(labelText: '${context.tr.landmark} (${context.tr.optional})')),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(child: TextFormField(controller: _city, validator: _req, decoration: InputDecoration(labelText: context.tr.cityTown))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _pin,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        validator: (String? v) => Validators.pincode(v) ? null : context.tr.errBadPincode,
                        decoration: InputDecoration(labelText: context.tr.pincode, counterText: ''),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(controller: _state, validator: _req, decoration: InputDecoration(labelText: context.tr.stateLabel)),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (!_form.currentState!.validate()) return;
                    final AppUser? u = context.read<SessionCubit>().state.user;
                    if (u == null) return;
                    final AppServices s = context.read<AppServices>();
                    final Address a = Address(
                      id: _existing?.id ?? newId('addr'),
                      label: _label,
                      name: _name.text.trim(),
                      phone: Validators.mobile(_phone.text)!,
                      line1: _line1.text.trim(),
                      landmark: _landmark.text.trim(),
                      area: _area.text.trim(),
                      city: _city.text.trim(),
                      pincode: _pin.text.trim(),
                      state: _state.text.trim(),
                    );
                    final AppUser? r = await runBusy(context, () => s.profile.saveAddress(u, a));
                    if (r != null && context.mounted) context.pop();
                  },
                  child: Text(context.tr.save),
                ),
              ],
            ),
          ),
        ),
      );
}

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppUser? u = context.watch<SessionCubit>().state.user;
    final List<Product> all = context.watch<ProductsCubit>().state;
    final StoreSettings store = context.watch<StoreCubit>().state;
    final List<Product> items = <Product>[
      for (final String id in u?.wishlist ?? const <String>[])
        ...all.where((Product p) => p.id == id && p.active),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(context.tr.wishlist)),
      body: items.isEmpty
          ? EmptyState(icon: Icons.favorite_border, title: context.tr.wishlistEmpty, message: context.tr.wishlistEmptyHint, actionLabel: context.tr.startShopping, onAction: () => context.go(Routes.shop))
          : MaxWidth(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 240, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 296),
                itemCount: items.length,
                itemBuilder: (BuildContext c, int i) => ProductCard(product: items[i], settings: store),
              ),
            ),
    );
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StoreSettings store = context.watch<StoreCubit>().state;
    final List<(String, String)> faq = <(String, String)>[
      (context.tr.faq1q, context.tr.faq1a),
      (context.tr.faq2q, context.tr.faq2a),
      (context.tr.faq3q, context.tr.faq3a),
      (context.tr.faq4q, context.tr.faq4a),
      (context.tr.faq5q, context.tr.faq5a),
      (context.tr.faq6q, context.tr.faq6a),
      (context.tr.faq7q, context.tr.faq7a),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(context.tr.helpAndFaq)),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(context.tr.needHelp, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(context.tr.helpBody),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(onPressed: () => context.push(Routes.store), icon: const Icon(Icons.storefront_outlined), label: Text(context.tr.visitStore)),
                    const SizedBox(height: 8),
                    if (store.hasPhone || store.hasWhatsapp)
                      Wrap(
                        spacing: 8,
                        children: <Widget>[
                          if (store.hasPhone) OutlinedButton.icon(onPressed: () => Launch.call(store.phone), icon: const Icon(Icons.call_outlined), label: Text(context.tr.call)),
                          if (store.hasWhatsapp) OutlinedButton.icon(onPressed: () => Launch.whatsapp(store.whatsapp), icon: const Icon(Icons.chat_outlined), label: Text(context.tr.whatsapp)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < faq.length; i++) ...<Widget>[
                    if (i > 0) const Divider(height: 1),
                    ExpansionTile(
                      shape: const Border(),
                      title: Text(faq[i].$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[Text(faq[i].$2, style: const TextStyle(height: 1.45))],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

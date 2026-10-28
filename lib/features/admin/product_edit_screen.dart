import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/ids.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../domain/finance.dart';
import '../../domain/localized_text.dart';
import '../../domain/product.dart';
import '../../l10n/l10n.dart';
import '../../services/app_services.dart';
import '../../state/data_cubits.dart';
import '../../state/session_cubit.dart';
import '../../widgets/common.dart';

class _VariantForm {
  _VariantForm({required this.id, String label = '', String color = '', int price = 0, int mrp = 0, int stock = 0, int cost = 0})
      : label = TextEditingController(text: label),
        color = TextEditingController(text: color),
        price = TextEditingController(text: price == 0 ? '' : '$price'),
        mrp = TextEditingController(text: mrp == 0 ? '' : '$mrp'),
        stock = TextEditingController(text: '$stock'),
        cost = TextEditingController(text: cost == 0 ? '' : '$cost');

  final String id;
  final TextEditingController label;
  final TextEditingController color;
  final TextEditingController price;
  final TextEditingController mrp;
  final TextEditingController stock;
  final TextEditingController cost;

  void dispose() {
    for (final TextEditingController c in <TextEditingController>[label, color, price, mrp, stock, cost]) {
      c.dispose();
    }
  }
}

class ProductEditScreen extends StatefulWidget {
  const ProductEditScreen({super.key, required this.productId});

  /// `new` for a fresh product.
  final String productId;

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  Product? _existing;
  bool _loaded = false;

  final TextEditingController _nameEn = TextEditingController();
  final TextEditingController _nameHi = TextEditingController();
  final TextEditingController _brand = TextEditingController();
  final TextEditingController _descEn = TextEditingController();
  final TextEditingController _descHi = TextEditingController();
  final TextEditingController _images = TextEditingController();
  final TextEditingController _tags = TextEditingController();
  final TextEditingController _warranty = TextEditingController(text: '12');
  final TextEditingController _gst = TextEditingController(text: '18');
  final Map<String, TextEditingController> _specs = <String, TextEditingController>{
    for (final String k in const <String>['ram', 'storage', 'display', 'battery', 'camera', 'chip', 'os']) k: TextEditingController(),
  };
  ProductCategory _category = ProductCategory.smartphone;
  bool _emi = false;
  bool _noCost = false;
  bool _featured = false;
  bool _active = true;
  final List<_VariantForm> _variants = <_VariantForm>[];

  bool get _isNew => widget.productId == 'new';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final Product? p = _isNew ? null : context.read<ProductsCubit>().state.where((Product x) => x.id == widget.productId).firstOrNull;
    _existing = p;
    final Map<String, int> costs = p == null ? const <String, int>{} : (context.read<CostsCubit>().state.where((CostEntry c) => c.productId == p.id).firstOrNull?.costs ?? const <String, int>{});
    if (p != null) {
      _nameEn.text = p.name.en;
      _nameHi.text = p.name.hi;
      _brand.text = p.brand;
      _descEn.text = p.description.en;
      _descHi.text = p.description.hi;
      _images.text = p.imageUrls.join('\n');
      _tags.text = p.tags.join(', ');
      _warranty.text = '${p.warrantyMonths}';
      _gst.text = p.gstRatePct.toStringAsFixed(p.gstRatePct % 1 == 0 ? 0 : 1);
      p.specs.forEach((String k, String v) => _specs.putIfAbsent(k, TextEditingController.new).text = v);
      _category = p.category;
      _emi = p.emiEligible;
      _noCost = p.noCostEmi;
      _featured = p.featured;
      _active = p.active;
      for (final ProductVariant v in p.variants) {
        _variants.add(_VariantForm(id: v.id, label: v.label, color: v.color, price: v.price, mrp: v.mrp, stock: v.stock, cost: costs[v.id] ?? 0));
      }
    } else {
      _variants.add(_VariantForm(id: newId('v')));
    }
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[_nameEn, _nameHi, _brand, _descEn, _descHi, _images, _tags, _warranty, _gst, ..._specs.values]) {
      c.dispose();
    }
    for (final _VariantForm v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  String? _req(String? v) => (v ?? '').trim().isEmpty ? context.tr.required : null;
  String? _num(String? v) => (int.tryParse((v ?? '').trim()) ?? 0) <= 0 ? context.tr.required : null;

  @override
  Widget build(BuildContext context) {
    final SessionState session = context.watch<SessionCubit>().state;
    final bool canCosts = session.can(Permission.viewCosts);
    final bool canEditCosts = session.can(Permission.editCosts);
    final double gst = double.tryParse(_gst.text) ?? 18;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? context.tr.addProduct : context.tr.editProduct),
        actions: <Widget>[
          if (!_isNew && _existing != null)
            IconButton(
              tooltip: _active ? context.tr.hide : context.tr.show,
              icon: Icon(_active ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _active = !_active),
            ),
        ],
      ),
      body: MaxWidth(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: <Widget>[
              TextFormField(controller: _nameEn, validator: _req, decoration: InputDecoration(labelText: '${context.tr.productName} (English)')),
              const SizedBox(height: 12),
              TextFormField(controller: _nameHi, decoration: InputDecoration(labelText: '${context.tr.productName} (हिन्दी)')),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(child: TextFormField(controller: _brand, validator: _req, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: context.tr.brand))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<ProductCategory>(
                      initialValue: _category,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: context.tr.categoryLabel),
                      items: <DropdownMenuItem<ProductCategory>>[
                        for (final ProductCategory c in ProductCategory.values) DropdownMenuItem<ProductCategory>(value: c, child: Text(context.tr.category(c), overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (ProductCategory? v) => setState(() => _category = v ?? _category),
                    ),
                  ),
                ],
              ),
              Section(
                title: context.tr.variantsHeader,
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < _variants.length; i++) _variantCard(context, i, canCosts, canEditCosts, gst),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _variants.add(_VariantForm(id: newId('v')))),
                      icon: const Icon(Icons.add),
                      label: Text(context.tr.addVariant),
                    ),
                  ],
                ),
              ),
              Section(
                title: context.tr.aboutProduct,
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  children: <Widget>[
                    TextFormField(controller: _descEn, maxLines: 3, decoration: InputDecoration(labelText: '${context.tr.description} (English)')),
                    const SizedBox(height: 12),
                    TextFormField(controller: _descHi, maxLines: 3, decoration: InputDecoration(labelText: '${context.tr.description} (हिन्दी)')),
                    const SizedBox(height: 12),
                    TextFormField(controller: _images, maxLines: 2, keyboardType: TextInputType.url, decoration: InputDecoration(labelText: context.tr.imageUrls, helperText: context.tr.imageUrlsHelp)),
                    const SizedBox(height: 12),
                    TextFormField(controller: _tags, decoration: InputDecoration(labelText: context.tr.tags, helperText: context.tr.tagsHelp)),
                  ],
                ),
              ),
              if (_category.group == ProductGroup.phones)
                Section(
                  title: context.tr.specifications,
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    children: <Widget>[
                      for (final MapEntry<String, TextEditingController> e in _specs.entries)
                        Padding(padding: const EdgeInsets.only(bottom: 10), child: TextFormField(controller: e.value, decoration: InputDecoration(labelText: context.tr.specLabel(e.key)))),
                    ],
                  ),
                ),
              Section(
                title: context.tr.sellingOptions,
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(child: TextFormField(controller: _warranty, keyboardType: TextInputType.number, inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: context.tr.warrantyMonthsLabel))),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: _gst, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: context.tr.gstRate, suffixText: '%'))),
                      ],
                    ),
                    SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr.emiEligible), value: _emi, onChanged: (bool v) => setState(() => _emi = v)),
                    if (_emi) SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr.noCostEligible), subtitle: Text(context.tr.noCostEligibleHint), value: _noCost, onChanged: (bool v) => setState(() => _noCost = v)),
                    SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr.featuredOnHome), value: _featured, onChanged: (bool v) => setState(() => _featured = v)),
                    SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr.visibleToCustomers), value: _active, onChanged: (bool v) => setState(() => _active = v)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => _save(context, session, canEditCosts), child: Text(context.tr.save)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _variantCard(BuildContext context, int i, bool canCosts, bool canEditCosts, double gst) {
    final _VariantForm v = _variants[i];
    final int price = int.tryParse(v.price.text) ?? 0;
    final int cost = int.tryParse(v.cost.text) ?? 0;
    final int margin = price - cost;
    final int net = margin > 0 ? margin - gstInside(margin, gst) : margin;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: TextFormField(controller: v.label, validator: _req, decoration: InputDecoration(labelText: context.tr.variantLabel, hintText: '6 GB + 128 GB'))),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: v.color, decoration: InputDecoration(labelText: context.tr.colorLabel))),
                if (_variants.length > 1) IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _variants.removeAt(i).dispose())),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(child: TextFormField(controller: v.price, validator: _num, keyboardType: TextInputType.number, inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly], onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: context.tr.sellingPrice, prefixText: '₹ '))),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: v.mrp, validator: _num, keyboardType: TextInputType.number, inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'MRP', prefixText: '₹ '))),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: v.stock, keyboardType: TextInputType.number, inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: context.tr.stockLabel))),
              ],
            ),
            if (canCosts) ...<Widget>[
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: v.cost,
                      readOnly: !canEditCosts,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(labelText: context.tr.costPrice, helperText: context.tr.costPriceHelp, prefixText: '₹ '),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: (net > 0 ? Colors.green : Colors.red).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(context.tr.profitPerUnit, style: Theme.of(context).textTheme.bodySmall),
                          Text(cost == 0 ? '-' : '${formatRupees(net)}  (${price == 0 ? 0 : (net * 100 / price).toStringAsFixed(1)}%)', style: const TextStyle(fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, SessionState session, bool canEditCosts) async {
    if (!_form.currentState!.validate()) return;
    final AppServices services = context.read<AppServices>();
    final DateTime now = DateTime.now();
    final String id = _existing?.id ?? newId('p');
    final List<ProductVariant> variants = <ProductVariant>[
      for (final _VariantForm v in _variants)
        ProductVariant(id: v.id, label: v.label.text.trim(), color: v.color.text.trim(), price: int.parse(v.price.text), mrp: int.parse(v.mrp.text), stock: int.tryParse(v.stock.text) ?? 0),
    ];
    final Product p = Product(
      id: id,
      name: LocalizedText(_nameEn.text.trim(), _nameHi.text.trim()),
      brand: _brand.text.trim(),
      category: _category,
      description: LocalizedText(_descEn.text.trim(), _descHi.text.trim()),
      highlights: _existing?.highlights ?? const <LocalizedText>[],
      specs: <String, String>{
        for (final MapEntry<String, TextEditingController> e in _specs.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
      },
      imageUrls: _images.text.split(RegExp(r'[\n,]')).map((String s) => s.trim()).where((String s) => s.startsWith('http')).toList(),
      variants: variants,
      warrantyMonths: int.tryParse(_warranty.text) ?? 12,
      gstRatePct: double.tryParse(_gst.text) ?? 18,
      emiEligible: _emi,
      noCostEmi: _emi && _noCost,
      featured: _featured,
      active: _active,
      tags: _tags.text.split(',').map((String s) => s.trim().toLowerCase()).where((String s) => s.isNotEmpty).toList(),
      createdAt: _existing?.createdAt ?? now,
    );
    final Map<String, int>? costs = canEditCosts
        ? <String, int>{for (final _VariantForm v in _variants) v.id: int.tryParse(v.cost.text) ?? 0}
        : null;
    final bool? ok = await runBusy<bool>(context, () async {
      await services.catalog.saveProduct(session.user, p, costs: costs);
      return true;
    });
    if (ok == true && context.mounted) {
      toast(context, context.tr.saved);
      context.pop();
    }
  }
}

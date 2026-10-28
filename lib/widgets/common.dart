import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/money.dart';
import '../l10n/l10n.dart';
import '../state/settings_cubit.dart';

/// Centres page content in a readable column on tablets and the web.
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, required this.child, this.width = 760});

  final Widget child;
  final double width;

  // heightFactor 1 makes the box exactly as tall as its child. Without it an
  // Align fills any bounded height, which in a bottom bar swallows the page.
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: width), child: child),
      );
}

class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 0),
  });

  final String title;
  final Widget child;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
                if (action != null && onAction != null)
                  TextButton(onPressed: onAction, child: Text(action!)),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.color, this.icon});

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Color c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[Icon(icon, size: 14, color: c), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircleAvatar(
              radius: 36,
              backgroundColor: t.colorScheme.primaryContainer,
              child: Icon(icon, size: 34, color: t.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            if (message != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(message!, textAlign: TextAlign.center, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class KeyValue extends StatelessWidget {
  const KeyValue(this.label, this.value, {super.key, this.bold = false, this.color});

  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final TextStyle? base = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(label, style: base?.copyWith(color: bold ? null : Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: bold ? FontWeight.w800 : null)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: base?.copyWith(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selling price large, MRP struck through, discount badge.
class PriceBlock extends StatelessWidget {
  const PriceBlock({super.key, required this.price, this.mrp, this.large = false});

  final int price;
  final int? mrp;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final ThemeData t = Theme.of(context);
    final int off = mrp == null ? 0 : discountPercent(mrp!, price);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 2,
      children: <Widget>[
        Text(
          formatRupees(price),
          style: (large ? t.textTheme.headlineSmall : t.textTheme.titleMedium)?.copyWith(fontWeight: FontWeight.w900),
        ),
        if (mrp != null && mrp! > price)
          Text(
            formatRupees(mrp!),
            style: t.textTheme.bodySmall?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: t.colorScheme.onSurfaceVariant,
              fontSize: large ? 15 : 12,
            ),
          ),
        if (off > 0)
          Text(
            '$off% ↓',
            style: TextStyle(color: const Color(0xFF2E7D32), fontWeight: FontWeight.w800, fontSize: large ? 15 : 12),
          ),
      ],
    );
  }
}

class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.qty, required this.onChanged, this.max = 5});

  final int qty;
  final ValueChanged<int> onChanged;
  final int max;

  @override
  Widget build(BuildContext context) {
    final ColorScheme c = Theme.of(context).colorScheme;
    Widget btn(IconData i, VoidCallback? f) => SizedBox(
          width: 36,
          height: 36,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(i, size: 18),
            onPressed: f,
          ),
        );
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          btn(Icons.remove, () => onChanged(qty - 1)),
          SizedBox(width: 28, child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))),
          btn(Icons.add, qty >= max ? null : () => onChanged(qty + 1)),
        ],
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.text, this.icon = Icons.info_outline, this.color, this.action, this.onAction});

  final String text;
  final IconData icon;
  final Color? color;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final Color c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35))),
          if (action != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

/// The two-letter language switch shown at the top of the main screens.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final bool hi = context.isHindi;
    return Tooltip(
      message: context.tr.switchLanguage,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.read<SettingsCubit>().toggleLanguage(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.translate, size: 16),
              const SizedBox(width: 6),
              // Show the language you will switch TO.
              Text(hi ? context.tr.languageShortEn : context.tr.languageShortHi, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Runs [job] behind a progress dialog. A failure is shown as a sentence and
/// returns null, so call sites read straight through.
Future<T?> runBusy<T>(BuildContext context, Future<T> Function() job) async {
  final NavigatorState nav = Navigator.of(context, rootNavigator: true);
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final AppLocalizationsHolder holder = AppLocalizationsHolder(context.tr);
  unawaited(showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (BuildContext _) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  ));
  try {
    final T r = await job();
    nav.pop();
    return r;
  } catch (e) {
    nav.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(holder.tr.error(e))));
    return null;
  }
}

/// Keeps the translations alive across an await without holding a BuildContext.
class AppLocalizationsHolder {
  const AppLocalizationsHolder(this.tr);
  final AppLocalizations tr;
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  String? confirmLabel,
  bool destructive = false,
}) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr.cancel)),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: const Color(0xFFC62828)) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel ?? context.tr.confirm),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// A text field dialog; returns the text or null if dismissed.
Future<String?> promptDialog(
  BuildContext context, {
  required String title,
  String? hint,
  String initial = '',
  TextInputType keyboard = TextInputType.text,
  int maxLines = 1,
}) async {
  final TextEditingController c = TextEditingController(text: initial);
  final String? v = await showDialog<String>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(context.tr.ok)),
      ],
    ),
  );
  c.dispose();
  return v;
}

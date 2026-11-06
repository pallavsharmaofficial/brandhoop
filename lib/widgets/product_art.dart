import 'package:flutter/material.dart';

import '../domain/product.dart';

const List<List<Color>> _palettes = <List<Color>>[
  <Color>[Color(0xFF3949AB), Color(0xFF7986CB)],
  <Color>[Color(0xFFEF6C00), Color(0xFFFFB74D)],
  <Color>[Color(0xFF00897B), Color(0xFF4DB6AC)],
  <Color>[Color(0xFF8E24AA), Color(0xFFBA68C8)],
  <Color>[Color(0xFFC62828), Color(0xFFEF9A9A)],
  <Color>[Color(0xFF1565C0), Color(0xFF64B5F6)],
  <Color>[Color(0xFF455A64), Color(0xFF90A4AE)],
  <Color>[Color(0xFF2E7D32), Color(0xFF81C784)],
];

IconData categoryIcon(ProductCategory c) {
  switch (c) {
    case ProductCategory.smartphone:
      return Icons.smartphone;
    case ProductCategory.featurePhone:
      return Icons.phone_android;
    case ProductCategory.tablet:
      return Icons.tablet_android;
    case ProductCategory.earphones:
      return Icons.headphones;
    case ProductCategory.charger:
      return Icons.electrical_services;
    case ProductCategory.cable:
      return Icons.cable;
    case ProductCategory.caseCover:
      return Icons.phone_iphone;
    case ProductCategory.screenGuard:
      return Icons.shield_outlined;
    case ProductCategory.powerBank:
      return Icons.battery_charging_full;
    case ProductCategory.smartwatch:
      return Icons.watch;
    case ProductCategory.speaker:
      return Icons.speaker;
    case ProductCategory.memory:
      return Icons.sd_card;
    case ProductCategory.holder:
      return Icons.stay_current_portrait;
    case ProductCategory.protection:
      return Icons.verified_user_outlined;
  }
}

/// A product picture. The shop's photo if it has one, otherwise a drawn
/// stand-in coloured by brand, so a catalogue with no photos still looks
/// deliberate.
class ProductArt extends StatelessWidget {
  const ProductArt({super.key, required this.product, this.radius = 12, this.iconSize});

  final Product product;
  final double radius;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final Widget art = _Art(product: product, iconSize: iconSize);
    if (product.imageUrls.isEmpty) return ClipRRect(borderRadius: BorderRadius.circular(radius), child: art);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        product.imageUrls.first,
        fit: BoxFit.cover,
        errorBuilder: (BuildContext c, Object e, StackTrace? s) => art,
        loadingBuilder: (BuildContext _, Widget child, ImageChunkEvent? p) =>
            p == null ? child : art,
      ),
    );
  }
}

class _Art extends StatelessWidget {
  const _Art({required this.product, this.iconSize});

  final Product product;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final List<Color> pal =
        _palettes[product.brand.codeUnits.fold(0, (int a, int b) => a + b) % _palettes.length];
    return LayoutBuilder(builder: (BuildContext _, BoxConstraints c) {
      final double side = c.biggest.shortestSide.isFinite ? c.biggest.shortestSide : 120;
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[pal[0].withValues(alpha: 0.16), pal[1].withValues(alpha: 0.30)],
          ),
        ),
        child: Center(
          child: product.isPhone && product.category == ProductCategory.smartphone
              ? CustomPaint(
                  size: Size(side * 0.36, side * 0.62),
                  painter: _PhonePainter(pal[0], product.brand),
                )
              : Icon(
                  categoryIcon(product.category),
                  size: iconSize ?? side * 0.42,
                  color: pal[0],
                ),
        ),
      );
    });
  }
}

/// A modern phone drawn in the brand's colour, used when the shop has no photo
/// of the product yet. It carries the brand name so it never passes for a
/// picture of one particular model.
class _PhonePainter extends CustomPainter {
  const _PhonePainter(this.color, this.label);
  final Color color;
  final String label;

  @override
  void paint(Canvas canvas, Size s) {
    final double r = s.width * 0.15;
    final RRect body = RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(r));
    canvas.drawRRect(
      body.shift(Offset(0, s.height * 0.025)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF3A3A44), Color(0xFF111116)],
        ).createShader(Offset.zero & s),
    );
    // Side button.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(s.width - 1.5, s.height * 0.28, 3, s.height * 0.12), const Radius.circular(2)),
      Paint()..color = const Color(0xFF55555F),
    );
    final Rect screen = Rect.fromLTWH(s.width * 0.045, s.height * 0.028, s.width * 0.91, s.height * 0.944);
    final RRect screenR = RRect.fromRectAndRadius(screen, Radius.circular(r * 0.78));
    canvas.drawRRect(
      screenR,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[color, Color.lerp(color, Colors.black, 0.45)!],
        ).createShader(screen),
    );
    // A soft diagonal glare.
    canvas.save();
    canvas.clipRRect(screenR);
    final Path glare = Path()
      ..moveTo(screen.left, screen.top + screen.height * 0.55)
      ..lineTo(screen.left, screen.top + screen.height * 0.25)
      ..lineTo(screen.right, screen.top)
      ..lineTo(screen.right, screen.top + screen.height * 0.3)
      ..close();
    canvas.drawPath(glare, Paint()..color = Colors.white.withValues(alpha: 0.10));
    canvas.restore();
    // Camera hole and status line.
    canvas.drawCircle(Offset(s.width / 2, screen.top + s.height * 0.032), s.width * 0.028, Paint()..color = const Color(0xFF0A0A0E));
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: label.toUpperCase(),
        style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: s.width * 0.15, fontWeight: FontWeight.w900, letterSpacing: s.width * 0.01),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: screen.width * 0.9);
    tp.paint(canvas, Offset((s.width - tp.width) / 2, screen.top + screen.height * 0.5 - tp.height / 2));
  }

  @override
  bool shouldRepaint(_PhonePainter old) => old.color != color || old.label != label;
}

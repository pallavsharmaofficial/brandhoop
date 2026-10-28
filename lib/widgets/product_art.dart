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
                  painter: _PhonePainter(pal[0]),
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

class _PhonePainter extends CustomPainter {
  const _PhonePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final RRect body = RRect.fromRectAndRadius(
      Offset.zero & s,
      Radius.circular(s.width * 0.16),
    );
    canvas.drawRRect(
      body.shift(Offset(0, s.height * 0.02)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(body, Paint()..color = color);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.07, s.height * 0.035, s.width * 0.86, s.height * 0.93),
        Radius.circular(s.width * 0.11),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.12, s.height * 0.07, s.width * 0.76, s.height * 0.86),
        Radius.circular(s.width * 0.08),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[color.withValues(alpha: 0.85), color.withValues(alpha: 0.35)],
        ).createShader(Offset.zero & s),
    );
    canvas.drawCircle(
      Offset(s.width / 2, s.height * 0.065),
      s.width * 0.03,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_PhonePainter old) => old.color != color;
}

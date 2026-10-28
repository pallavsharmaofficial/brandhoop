import 'package:flutter/material.dart';

import '../app/theme.dart';

/// The Brandhoop mark: a saffron hoop around a phone, drawn in code so it is
/// sharp at any size and needs no image file. tools/branding/make_icon.py draws
/// the same mark for the launcher icon.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 36, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _MarkPainter(onDark));
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.onDark);
  final bool onDark;

  @override
  void paint(Canvas canvas, Size s) {
    final double w = s.width;
    final Offset c = Offset(w / 2, w / 2);
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.11
      ..strokeCap = StrokeCap.round
      ..color = BrandColors.saffron;
    // An open hoop: a gap at the upper right, like a swoosh.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: w * 0.42),
      -0.35,
      5.75,
      false,
      ring,
    );
    final Paint body = Paint()..color = onDark ? Colors.white : BrandColors.indigo;
    final RRect phone = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: w * 0.30, height: w * 0.52),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(phone, body);
    final Paint screen = Paint()
      ..color = onDark ? BrandColors.indigo : Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c.translate(0, -w * 0.01), width: w * 0.22, height: w * 0.40),
        Radius.circular(w * 0.03),
      ),
      screen,
    );
    canvas.drawCircle(c.translate(0, w * 0.215), w * 0.018, screen);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.onDark != onDark;
}

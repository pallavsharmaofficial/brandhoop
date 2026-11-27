import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/palette.dart';
import 'motion.dart';

/// Two drawn phones with a soft glow, for the hero. They are an illustration, not a
/// picture of one model, so they carry no brand name. Painted in the palette.
class HeroPhones extends StatelessWidget {
  const HeroPhones({super.key, this.height = 150});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: height * 0.95,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(child: CustomPaint(painter: _GlowPainter())),
            Positioned(
              left: 0,
              bottom: height * 0.04,
              child: Floating(
                amplitude: 4,
                phase: 0.5,
                child: Transform.rotate(angle: -8 * math.pi / 180, child: _Phone(h: height * 0.74, back: true)),
              ),
            ),
            Positioned(
              right: 0,
              bottom: height * 0.12,
              child: Floating(
                amplitude: 6,
                child: Transform.rotate(angle: 7 * math.pi / 180, child: _Phone(h: height * 0.82)),
              ),
            ),
          ],
        ),
      );
}

class _GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final Offset c = Offset(s.width * 0.5, s.height * 0.55);
    canvas.drawCircle(
      c,
      s.shortestSide * 0.52,
      Paint()
        ..shader = RadialGradient(colors: <Color>[Palette.saffron500.withValues(alpha: 0.55), Palette.saffron500.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: s.shortestSide * 0.52)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(s.width * 0.5, s.height * 0.97), width: s.width * 0.8, height: s.height * 0.07),
      Paint()..color = Colors.black.withValues(alpha: 0.28)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _Phone extends StatelessWidget {
  const _Phone({required this.h, this.back = false});
  final double h;
  final bool back;

  @override
  Widget build(BuildContext context) => SizedBox(width: h * 0.48, height: h, child: CustomPaint(painter: _PhonePainter(back)));
}

class _PhonePainter extends CustomPainter {
  const _PhonePainter(this.back);
  final bool back;

  @override
  void paint(Canvas canvas, Size s) {
    final RRect body = RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(s.width * 0.17));
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: back ? <Color>[Palette.slate400, Palette.slate600] : <Color>[Palette.slate300, Palette.slate500],
        ).createShader(Offset.zero & s),
    );
    if (back) {
      // the rear of a phone: camera island and a small mark
      final Paint dark = Paint()..color = Palette.navy900;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s.width * 0.1, s.height * 0.05, s.width * 0.56, s.height * 0.2), Radius.circular(s.width * 0.12)), Paint()..color = Palette.navy700);
      canvas.drawCircle(Offset(s.width * 0.28, s.height * 0.115), s.width * 0.085, dark);
      canvas.drawCircle(Offset(s.width * 0.28, s.height * 0.19), s.width * 0.085, dark);
      canvas.drawCircle(Offset(s.width * 0.5, s.height * 0.15), s.width * 0.05, Paint()..color = Palette.saffron300);
      return;
    }
    final Rect screen = Rect.fromLTWH(s.width * 0.05, s.height * 0.03, s.width * 0.9, s.height * 0.94);
    final RRect sr = RRect.fromRectAndRadius(screen, Radius.circular(s.width * 0.13));
    canvas.drawRRect(
      sr,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Palette.navy500, Palette.navy800]).createShader(screen),
    );
    // a tiny store screen: banner, two tiles, a button
    final Paint white = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(screen.left + 7, screen.top + s.height * 0.1, screen.width - 14, s.height * 0.22), const Radius.circular(7)), Paint()..color = Palette.saffron500);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(screen.left + 7, screen.top + s.height * 0.36, screen.width * 0.43, s.height * 0.2), const Radius.circular(6)), white..color = Colors.white.withValues(alpha: 0.18));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(screen.center.dx + 2, screen.top + s.height * 0.36, screen.width * 0.43, s.height * 0.2), const Radius.circular(6)), white);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(screen.left + 7, screen.bottom - s.height * 0.16, screen.width - 14, s.height * 0.08), const Radius.circular(6)), Paint()..color = Palette.saffron400);
    canvas.drawCircle(Offset(s.width / 2, s.height * 0.05), s.width * 0.022, Paint()..color = Palette.navy900);
  }

  @override
  bool shouldRepaint(covariant _PhonePainter old) => old.back != back;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// A ring that fills to [value] (0 to 1), with [child] in the middle.
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, required this.child, this.size = 120, this.stroke = 12, this.color = BrandColors.saffron, this.track});

  final double value;
  final Widget child;
  final double size;
  final double stroke;
  final Color color;
  final Color? track;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(value.clamp(0, 1).toDouble(), stroke, color, track ?? Colors.white24),
          child: Center(child: child),
        ),
      );
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.v, this.stroke, this.color, this.track);
  final double v;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size s) {
    final Rect r = Rect.fromLTWH(stroke / 2, stroke / 2, s.width - stroke, s.height - stroke);
    final Paint base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, base..color = track);
    // Always show a sliver, so a month that has just begun still reads as a ring.
    final double sweep = math.max(v, 0.012) * math.pi * 2;
    canvas.drawArc(r, -math.pi / 2, sweep, false, base..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v || o.color != color || o.track != track;
}

class BarPoint {
  const BarPoint(this.label, this.value);
  final String label;
  final int value;
}

/// A compact bar chart for a short series, with the biggest bar labelled.
class BarChartMini extends StatelessWidget {
  const BarChartMini({super.key, required this.points, this.height = 120, this.color, this.format});

  final List<BarPoint> points;
  final double height;
  final Color? color;
  final String Function(int)? format;

  @override
  Widget build(BuildContext context) {
    final int maxV = points.fold(1, (int m, BarPoint p) => math.max(m, p.value.abs()));
    final Color c = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (int i = 0; i < points.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: (points[i].value.abs() / maxV).clamp(0.02, 1).toDouble(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: points[i].value < 0 ? BrandColors.red : (i == points.length - 1 ? BrandColors.saffron : c.withValues(alpha: 0.75)),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(points[i].label, style: const TextStyle(fontSize: 9), maxLines: 1, overflow: TextOverflow.clip),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A labelled horizontal bar with a value at the end.
class HBar extends StatelessWidget {
  const HBar({super.key, required this.label, required this.value, required this.max, required this.valueText, this.color});

  final String label;
  final int value;
  final int max;
  final String valueText;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                Text(valueText, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: max <= 0 ? 0 : (value / max).clamp(0, 1).toDouble(),
                color: color ?? Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      );
}

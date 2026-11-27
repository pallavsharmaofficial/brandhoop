import 'package:flutter/material.dart';

/// Small, quiet animations used across the app. Every one of them shows its final
/// state at once when the phone's "remove animations" setting is on.
bool _reduce(BuildContext c) => MediaQuery.maybeDisableAnimationsOf(c) ?? false;

/// Fades and lifts its child into place the first time it is built. Inside a lazy
/// list this happens as the item scrolls into view, so a page reveals itself as
/// the visitor moves down it.
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.delay = Duration.zero, this.rise = 14});

  final Widget child;
  final Duration delay;

  /// How far below its place the child starts, in logical pixels.
  final double rise;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (_reduce(context)) {
      _c.value = 1;
    } else if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _t,
        child: widget.child,
        builder: (BuildContext _, Widget? child) => Opacity(
          opacity: _t.value,
          child: Transform.translate(offset: Offset(0, (1 - _t.value) * widget.rise), child: child),
        ),
      );
}

/// Scales its child down a little while a finger or the mouse is pressed on it, and
/// lifts it slightly under the mouse. Taps still go to the child.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.pressedScale = 0.97, this.hoverScale = 1.015});

  final Widget child;
  final double pressedScale;
  final double hoverScale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final double s = _down ? widget.pressedScale : (_hover ? widget.hoverScale : 1);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _down = true),
        onPointerUp: (_) => setState(() => _down = false),
        onPointerCancel: (_) => setState(() => _down = false),
        child: AnimatedScale(
          scale: _reduce(context) ? 1 : s,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A slow up-and-down drift, for the hero's phones and chips. [phase] (0 to 1)
/// offsets the motion so several floating things do not move together.
class Floating extends StatefulWidget {
  const Floating({super.key, required this.child, this.amplitude = 6, this.phase = 0, this.period = const Duration(milliseconds: 3600)});

  final Widget child;
  final double amplitude;
  final double phase;
  final Duration period;

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period, value: widget.phase);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduce(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (BuildContext _, Widget? child) => Transform.translate(
          offset: Offset(0, (Curves.easeInOut.transform(_c.value) - 0.5) * 2 * widget.amplitude),
          child: child,
        ),
      );
}

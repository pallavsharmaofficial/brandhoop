import 'dart:convert';

enum Viewer3DEventType { ready, progress, load, error, fullscreen, scroll }

/// A message from site/viewer3d.html: `{source:'brandhoop-3d', type, ...}`.
class Viewer3DEvent {
  const Viewer3DEvent(this.type, {this.progress = 0, this.reason = '', this.delta = 0});

  final Viewer3DEventType type;

  /// 0..1, for [Viewer3DEventType.progress].
  final double progress;

  /// "no-webgl", "timeout", "script", "model-error"... for [Viewer3DEventType.error].
  final String reason;

  /// Pixels the host page should scroll down, for [Viewer3DEventType.scroll].
  final double delta;

  /// Reads a JSON string (webview JS channel) or a decoded map (postMessage).
  /// Anything that is not ours returns null.
  static Viewer3DEvent? parse(Object? raw) {
    try {
      final Object? m = raw is String ? jsonDecode(raw) : raw;
      if (m is! Map || m['source'] != 'brandhoop-3d') return null;
      final Viewer3DEventType? t = Viewer3DEventType.values.where((Viewer3DEventType e) => e.name == m['type']).firstOrNull;
      if (t == null) return null;
      final Object? v = m['value'];
      return Viewer3DEvent(
        t,
        progress: v is num ? v.toDouble().clamp(0.0, 1.0) : 0,
        reason: m['reason'] is String ? m['reason'] as String : '',
        delta: m['dy'] is num ? (m['dy'] as num).toDouble().clamp(-400.0, 400.0) : 0,
      );
    } on FormatException {
      return null;
    }
  }
}

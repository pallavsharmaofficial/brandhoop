import 'package:flutter/widgets.dart';

import 'viewer3d_event.dart';

export 'viewer3d_native.dart' if (dart.library.js_interop) 'viewer3d_web.dart' show buildPlatformViewer3D;

/// What a viewer needs to show: the page to open, whether it may take every
/// touch (full screen) or only horizontal drags (inline), and who to tell.
class Viewer3DRequest {
  const Viewer3DRequest({required this.uri, required this.fullscreen, required this.onEvent});

  final Uri uri;
  final bool fullscreen;
  final ValueChanged<Viewer3DEvent> onEvent;
}

/// Builds the viewer. The real one is an iframe (web) or a webview (Android);
/// tests pass a fake.
typedef Viewer3DBuilder = Widget Function(BuildContext context, Viewer3DRequest request);

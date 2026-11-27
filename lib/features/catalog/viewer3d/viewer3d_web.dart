import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'viewer3d_event.dart';
import 'viewer3d_view.dart';

/// The browser build: the viewer page in an iframe. The page talks back with
/// window.postMessage; only messages from the viewer page's origin are used.
Widget buildPlatformViewer3D(BuildContext context, Viewer3DRequest request) => _WebViewer(request: request);

class _WebViewer extends StatefulWidget {
  const _WebViewer({required this.request});
  final Viewer3DRequest request;

  @override
  State<_WebViewer> createState() => _WebViewerState();
}

class _WebViewerState extends State<_WebViewer> {
  StreamSubscription<web.MessageEvent>? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _created(Object element) {
    final web.HTMLIFrameElement frame = element as web.HTMLIFrameElement;
    frame
      ..src = widget.request.uri.toString()
      ..allow = 'fullscreen; xr-spatial-tracking; accelerometer; gyroscope'
      ..setAttribute('sandbox', 'allow-scripts allow-same-origin allow-popups allow-top-navigation-by-user-activation')
      ..setAttribute('loading', 'eager');
    frame.style
      ..border = '0'
      ..width = '100%'
      ..height = '100%'
      ..background = 'transparent';
    _sub = web.window.onMessage.listen((web.MessageEvent e) {
      // Only the page we embedded may talk to us: its origin is the viewer address's origin.
      if (e.origin != widget.request.uri.origin) return;
      final Viewer3DEvent? ev = Viewer3DEvent.parse(e.data.dartify());
      if (ev != null) widget.request.onEvent(ev);
    });
  }

  @override
  Widget build(BuildContext context) =>
      HtmlElementView.fromTagName(tagName: 'iframe', onElementCreated: _created);
}

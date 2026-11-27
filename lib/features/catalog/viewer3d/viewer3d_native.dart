import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'viewer3d_event.dart';
import 'viewer3d_view.dart';

/// The Android build: the viewer page in a webview, with a JS channel for events.
Widget buildPlatformViewer3D(BuildContext context, Viewer3DRequest request) => _NativeViewer(request: request);

class _NativeViewer extends StatefulWidget {
  const _NativeViewer({required this.request});
  final Viewer3DRequest request;

  @override
  State<_NativeViewer> createState() => _NativeViewerState();
}

class _NativeViewerState extends State<_NativeViewer> {
  late final WebViewController _c;

  @override
  void initState() {
    super.initState();
    final String host = widget.request.uri.host;
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel('Brandhoop3D', onMessageReceived: (JavaScriptMessage m) {
        final Viewer3DEvent? e = Viewer3DEvent.parse(m.message);
        if (e != null) widget.request.onEvent(e);
      })
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (NavigationRequest r) {
          final Uri u = Uri.parse(r.url);
          // AR: model-viewer asks for an intent:// link to Google's Scene Viewer.
          // The webview cannot open it, so hand the https form to the system.
          if (u.scheme == 'intent') {
            final Uri https = Uri.parse(r.url.replaceFirst('intent://', 'https://').split('#Intent').first);
            launchUrl(https, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          }
          if ((u.scheme == 'https' || u.scheme == 'blob') && (u.scheme == 'blob' || u.host == host)) return NavigationDecision.navigate;
          if (u.scheme == 'about') return NavigationDecision.navigate;
          return NavigationDecision.prevent;
        },
        onWebResourceError: (WebResourceError e) {
          if (e.isForMainFrame ?? true) widget.request.onEvent(const Viewer3DEvent(Viewer3DEventType.error, reason: 'network'));
        },
      ))
      ..loadRequest(widget.request.uri);
  }

  @override
  Widget build(BuildContext context) {
    // Inline: only sideways drags reach the page, so up/down still scrolls the
    // product page. Full screen: every touch (rotate, pinch zoom).
    final Set<Factory<OneSequenceGestureRecognizer>> gestures = widget.request.fullscreen
        ? const <Factory<OneSequenceGestureRecognizer>>{Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new)}
        : const <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(HorizontalDragGestureRecognizer.new),
            Factory<OneSequenceGestureRecognizer>(TapGestureRecognizer.new),
          };
    return WebViewWidget(controller: _c, gestureRecognizers: gestures);
  }
}

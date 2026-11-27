import '../../../data/live_shop.dart';
import '../../../domain/model3d.dart';

/// Where site/viewer3d.html lives: next to live/shop.json on the shop's site.
String get viewer3dPage => '${LiveShop.publishedUrl.replaceFirst(RegExp(r'live/shop\.json$'), '')}viewer3d.html';

/// The viewer page for one model. [mode] is `inline` (horizontal drag only, so the
/// page still scrolls) or `full` (free rotate, pinch zoom, AR). Labels travel in
/// the URL so the page needs no translation tables.
Uri viewer3dUri(
  Model3D m, {
  required String mode,
  required String alt,
  required String fullscreenLabel,
  required String arLabel,
  required String hint,
  String? page,
}) =>
    Uri.parse(page ?? viewer3dPage).replace(queryParameters: <String, String>{
      'src': m.glb,
      if (m.poster.isNotEmpty) 'poster': m.poster,
      'mode': mode,
      'alt': alt,
      'fs': fullscreenLabel,
      'arl': arLabel,
      'hint': hint,
    });

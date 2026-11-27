import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/model3d.dart';
import '../../domain/product.dart';
import '../../l10n/l10n.dart';
import '../../util/launch.dart';
import '../../widgets/product_art.dart';
import 'viewer3d/viewer3d_event.dart';
import 'viewer3d/viewer3d_url.dart';
import 'viewer3d/viewer3d_view.dart';

enum _Tab { photos, view3d }

/// The picture area of a product page. Phones that have a 3D model get a
/// "Photos | 3D View" switch; everything else keeps the plain photo.
///
/// 3D View first shows the poster with a 360 badge and a play button. The model
/// is downloaded only after a tap. If the model or WebGL fails, the page goes back
/// to the photos by itself.
class ProductMedia extends StatefulWidget {
  const ProductMedia({super.key, required this.product, this.viewerBuilder, this.radius = 20});

  final Product product;

  /// Replaces the real iframe/webview, for tests.
  final Viewer3DBuilder? viewerBuilder;
  final double radius;

  @override
  State<ProductMedia> createState() => _ProductMediaState();
}

class _ProductMediaState extends State<ProductMedia> {
  _Tab _tab = _Tab.photos;
  bool _started = false; // the person asked for 3D: now the model may load
  bool _loaded = false;
  bool _failed = false;
  double _progress = 0;

  Model3D? get _model => widget.product.model3d;

  Viewer3DBuilder get _build => widget.viewerBuilder ?? buildPlatformViewer3D;

  @override
  void didUpdateWidget(ProductMedia old) {
    super.didUpdateWidget(old);
    if (old.product.id != widget.product.id || old.product.model3d != widget.product.model3d) {
      _tab = _Tab.photos;
      _started = _loaded = _failed = false;
      _progress = 0;
    }
  }

  void _onEvent(Viewer3DEvent e) {
    if (!mounted) return;
    switch (e.type) {
      case Viewer3DEventType.progress:
        setState(() => _progress = e.progress);
      case Viewer3DEventType.load:
        setState(() => _loaded = true);
      case Viewer3DEventType.error:
        // No WebGL, a blocked or broken file, a timeout: back to the photos.
        setState(() {
          _failed = true;
          _started = false;
          _loaded = false;
          _tab = _Tab.photos;
        });
      case Viewer3DEventType.fullscreen:
        _openFullscreen();
      case Viewer3DEventType.scroll:
        // The viewer sits in an iframe that swallows touches, so it hands vertical drags up.
        final ScrollPosition? pos = Scrollable.maybeOf(context)?.position;
        if (pos != null) pos.jumpTo((pos.pixels + e.delta).clamp(pos.minScrollExtent, pos.maxScrollExtent));
      case Viewer3DEventType.ready:
        break;
    }
  }

  Uri _uri(Model3D m, String mode) => viewer3dUri(
        m,
        mode: mode,
        alt: widget.product.name.of(context.lang),
        fullscreenLabel: context.tr.media3dFullscreen,
        arLabel: context.tr.media3dAr,
        hint: context.tr.media3dDrag,
      );

  Future<void> _openFullscreen() async {
    final Model3D? m = _model;
    if (m == null) return;
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (BuildContext c) => _FullscreenViewer(
        uri: _uri(m, 'full'),
        title: widget.product.name.of(c.lang),
        builder: _build,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final Model3D? m = _model;
    final bool has3d = m != null && !_failed;
    final Widget photos = _Photos(product: widget.product, radius: widget.radius);
    if (m == null) {
      return AspectRatio(aspectRatio: 1.5, child: photos);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (has3d)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SegmentedButton<_Tab>(
              showSelectedIcon: false,
              segments: <ButtonSegment<_Tab>>[
                ButtonSegment<_Tab>(value: _Tab.photos, icon: const Icon(Icons.photo_library_outlined), label: Text(context.tr.mediaPhotos)),
                ButtonSegment<_Tab>(value: _Tab.view3d, icon: const Icon(Icons.threed_rotation), label: Text(context.tr.media3dView)),
              ],
              selected: <_Tab>{_tab},
              onSelectionChanged: (Set<_Tab> s) => setState(() => _tab = s.first),
            ),
          ),
        AspectRatio(
          aspectRatio: 1.15,
          child: has3d && _tab == _Tab.view3d ? _view3d(m) : photos,
        ),
        if (_failed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(context.tr.media3dFailed, key: const ValueKey<String>('media3dFailed'), style: Theme.of(context).textTheme.bodySmall),
          ),
        if (has3d && _tab == _Tab.view3d) _Credit(model: m),
      ],
    );
  }

  Widget _view3d(Model3D m) {
    final Widget poster = _Poster(model: m, product: widget.product, radius: widget.radius);
    if (!_started) {
      return GestureDetector(
        key: const ValueKey<String>('media3dPlay'),
        onTap: () => setState(() => _started = true),
        child: Semantics(button: true, label: context.tr.media3dPlay, child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            poster,
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(color: BrandColors.saffron, shape: BoxShape.circle, boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12)]),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 44),
              ),
            ),
            Positioned(left: 12, top: 12, child: _Badge360(label: context.tr.media3dTap)),
          ],
        )),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _build(context, Viewer3DRequest(uri: _uri(m, 'inline'), fullscreen: false, onEvent: _onEvent)),
          if (!_loaded)
            Positioned.fill(
              key: const ValueKey<String>('media3dLoading'),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  poster,
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.88), borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                            Text(context.tr.media3dLoading, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: BrandColors.indigo)),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(value: _progress > 0 ? _progress : null, color: BrandColors.saffron, backgroundColor: BrandColors.saffronSoft),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Photos extends StatefulWidget {
  const _Photos({required this.product, required this.radius});
  final Product product;
  final double radius;

  @override
  State<_Photos> createState() => _PhotosState();
}

class _PhotosState extends State<_Photos> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final List<String> urls = widget.product.imageUrls;
    if (urls.length < 2) return ProductArt(product: widget.product, radius: widget.radius);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: PageView.builder(
            itemCount: urls.length,
            onPageChanged: (int i) => setState(() => _page = i),
            itemBuilder: (BuildContext c, int i) => Semantics(
              label: c.tr.mediaPhotoOf('${i + 1}', '${urls.length}'),
              child: Image.network(
                urls[i],
                fit: BoxFit.cover,
                errorBuilder: (BuildContext _, Object e, StackTrace? s) => ProductArt(product: widget.product, radius: 0),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 8,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            for (int i = 0; i < urls.length; i++)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(shape: BoxShape.circle, color: i == _page ? BrandColors.saffron : Colors.white70),
              ),
          ]),
        ),
      ],
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.model, required this.product, required this.radius});
  final Model3D model;
  final Product product;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = ProductArt(product: product, radius: radius);
    if (model.poster.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(
        color: const Color(0xFFEEF1F8),
        child: Image.network(model.poster, fit: BoxFit.contain, errorBuilder: (BuildContext _, Object e, StackTrace? s) => fallback),
      ),
    );
  }
}

class _Badge360 extends StatelessWidget {
  const _Badge360({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.62), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          const Icon(Icons.threesixty, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
}

/// "3D model: TITLE by AUTHOR, LICENCE (SOURCE)" with links, when the
/// licence asks for a credit, and a note when the model is only a stand-in.
class _Credit extends StatelessWidget {
  const _Credit({required this.model});
  final Model3D model;

  @override
  Widget build(BuildContext context) {
    final TextStyle? small = Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    final String src = model.sourceName.isEmpty ? 'web' : model.sourceName;
    final String line = model.author.isEmpty
        ? context.tr.media3dCreditNoAuthor(model.title, model.license, src)
        : context.tr.media3dCredit(model.title, model.author, model.license, src);
    final bool showCredit = model.attributionRequired && model.hasCredit;
    if (!showCredit && model.exact && !model.generated) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        if (showCredit)
          Wrap(spacing: 8, children: <Widget>[
            InkWell(
              key: const ValueKey<String>('media3dCredit'),
              onTap: model.sourceUrl.isEmpty ? null : () => Launch.url(model.sourceUrl),
              child: Text(line, style: small?.copyWith(decoration: model.sourceUrl.isEmpty ? null : TextDecoration.underline)),
            ),
            if (model.licenseUrl.isNotEmpty)
              InkWell(
                onTap: () => Launch.url(model.licenseUrl),
                child: Text(context.tr.media3dLicenseTerms, style: small?.copyWith(decoration: TextDecoration.underline)),
              ),
          ]),
        if (model.generated)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(context.tr.media3dIllustrative, key: const ValueKey<String>('media3dIllustrative'), style: small?.copyWith(fontWeight: FontWeight.w700)),
          )
        else if (!model.exact)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(context.tr.media3dRepresentative, key: const ValueKey<String>('media3dRepresentative'), style: small?.copyWith(fontWeight: FontWeight.w700)),
          ),
      ]),
    );
  }
}

class _FullscreenViewer extends StatelessWidget {
  const _FullscreenViewer({required this.uri, required this.title, required this.builder});
  final Uri uri;
  final String title;
  final Viewer3DBuilder builder;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title), leading: IconButton(tooltip: context.tr.media3dClose, icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop())),
        body: SafeArea(
          child: builder(
            context,
            Viewer3DRequest(
              uri: uri,
              fullscreen: true,
              onEvent: (Viewer3DEvent e) {
                if (e.type == Viewer3DEventType.error && Navigator.of(context).canPop()) Navigator.of(context).pop();
              },
            ),
          ),
        ),
      );
}

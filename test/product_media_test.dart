import 'package:brandhoop/domain/localized_text.dart';
import 'package:brandhoop/domain/model3d.dart';
import 'package:brandhoop/domain/product.dart';
import 'package:brandhoop/features/catalog/product_media.dart';
import 'package:brandhoop/features/catalog/viewer3d/viewer3d_event.dart';
import 'package:brandhoop/features/catalog/viewer3d/viewer3d_view.dart';
import 'package:brandhoop/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Model3D _ccBy = Model3D(
  glb: 'https://example.com/models/p.glb',
  poster: 'https://example.com/models/p.webp',
  title: 'vivo V80 - Early Summer Green',
  author: 'Abdulkhaliq Alamery',
  license: 'CC BY 4.0',
  licenseUrl: 'https://creativecommons.org/licenses/by/4.0/',
  sourceName: 'Sketchfab',
  sourceUrl: 'https://sketchfab.com/3d-models/x',
);

Product _phone({Model3D? model}) => Product(
      id: 'vivo-v80-5g',
      name: const LocalizedText('vivo V80 5G'),
      brand: 'vivo',
      category: ProductCategory.smartphone,
      model3d: model,
      variants: const <ProductVariant>[ProductVariant(id: 'v1', label: '8 GB + 128 GB', price: 62999, mrp: 62999, stock: 1)],
      createdAt: DateTime(2026, 11, 27),
    );

/// A stand-in for the iframe/webview that remembers how often it was built and
/// lets the test play the page's messages.
class _FakeViewer {
  int builds = 0;
  ValueChanged<Viewer3DEvent>? send;
  Uri? uri;
  bool? fullscreen;

  Widget build(BuildContext c, Viewer3DRequest r) {
    builds++;
    send = r.onEvent;
    uri = r.uri;
    fullscreen = r.fullscreen;
    return const ColoredBox(key: ValueKey<String>('fakeViewer'), color: Colors.black12);
  }
}

Future<void> _pump(WidgetTester t, Product p, _FakeViewer v, {String lang = 'en'}) async {
  t.view.physicalSize = const Size(375, 812) * 2;
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  await t.pumpWidget(MaterialApp(
    locale: Locale(lang),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: ProductMedia(product: p, viewerBuilder: v.build))),
  ));
}

void main() {
  testWidgets('a product without a 3D model shows no 3D toggle', (WidgetTester t) async {
    final _FakeViewer v = _FakeViewer();
    await _pump(t, _phone(), v);
    expect(find.text('3D View'), findsNothing);
    expect(find.byType(SegmentedButton<Object>), findsNothing);
    expect(v.builds, 0);
  });

  testWidgets('3D is not downloaded until the person taps play', (WidgetTester t) async {
    final _FakeViewer v = _FakeViewer();
    await _pump(t, _phone(model: _ccBy), v);
    expect(find.text('Photos'), findsOneWidget);
    await t.tap(find.text('3D View'));
    await t.pump();
    expect(find.byKey(const ValueKey<String>('media3dPlay')), findsOneWidget);
    expect(find.byIcon(Icons.threesixty), findsOneWidget);
    expect(v.builds, 0, reason: 'poster only: no viewer yet');
    await t.tap(find.byKey(const ValueKey<String>('media3dPlay')));
    await t.pump();
    expect(v.builds, greaterThan(0));
    expect(v.fullscreen, isFalse);
    expect(v.uri!.queryParameters['src'], _ccBy.glb);
    expect(v.uri!.queryParameters['mode'], 'inline');
    expect(find.byKey(const ValueKey<String>('media3dLoading')), findsOneWidget);
    v.send!(const Viewer3DEvent(Viewer3DEventType.progress, progress: 0.5));
    await t.pump();
    expect(t.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 0.5);
    v.send!(const Viewer3DEvent(Viewer3DEventType.load));
    await t.pump();
    expect(find.byKey(const ValueKey<String>('media3dLoading')), findsNothing);
    expect(find.byKey(const ValueKey<String>('fakeViewer')), findsOneWidget);
  });

  testWidgets('credit line with links when the licence needs it', (WidgetTester t) async {
    final _FakeViewer v = _FakeViewer();
    await _pump(t, _phone(model: _ccBy), v);
    await t.tap(find.text('3D View'));
    await t.pump();
    expect(find.text('3D model: vivo V80 - Early Summer Green by Abdulkhaliq Alamery, CC BY 4.0 (Sketchfab)'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('media3dRepresentative')), findsNothing);
  });

  testWidgets('a stand-in model says so; CC0 needs no credit', (WidgetTester t) async {
    final _FakeViewer v = _FakeViewer();
    const Model3D sibling = Model3D(
      glb: 'https://example.com/m.glb',
      title: 'Sibling',
      author: 'A',
      license: 'CC0 1.0',
      attributionRequired: false,
      sourceName: 'Sketchfab',
      exact: false,
    );
    await _pump(t, _phone(model: sibling), v);
    await t.tap(find.text('3D View'));
    await t.pump();
    expect(find.byKey(const ValueKey<String>('media3dCredit')), findsNothing);
    expect(find.text('Representative model, colour may differ'), findsOneWidget);
  });

  testWidgets('a generated model is labelled illustrative, with no credit line', (WidgetTester t) async {
    final _FakeViewer v = _FakeViewer();
    const Model3D gen = Model3D(glb: 'https://example.com/g.glb', title: 'x', author: 'Brandhoop', license: 'CC0 1.0', attributionRequired: false, exact: false, generated: true);
    await _pump(t, _phone(model: gen), v);
    await t.tap(find.text('3D View'));
    await t.pump();
    expect(find.byKey(const ValueKey<String>('media3dIllustrative')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('media3dRepresentative')), findsNothing);
    expect(find.byKey(const ValueKey<String>('media3dCredit')), findsNothing);
    expect(Model3D.tryFromJson(gen.toJson())?.generated, isTrue);
  });

  testWidgets('an error (no WebGL, broken file) goes back to the photos by itself', (WidgetTester t) async {
    final _FakeViewer v = _FakeViewer();
    await _pump(t, _phone(model: _ccBy), v);
    await t.tap(find.text('3D View'));
    await t.pump();
    await t.tap(find.byKey(const ValueKey<String>('media3dPlay')));
    await t.pump();
    v.send!(const Viewer3DEvent(Viewer3DEventType.error, reason: 'no-webgl'));
    await t.pump();
    expect(find.byKey(const ValueKey<String>('fakeViewer')), findsNothing);
    expect(find.byKey(const ValueKey<String>('media3dFailed')), findsOneWidget);
    expect(find.text('3D View'), findsNothing, reason: 'the 3D tab is gone after a failure');
    expect(find.byKey(const ValueKey<String>('media3dCredit')), findsNothing);
  });

  testWidgets('Hindi labels', (WidgetTester t) async {
    final _FakeViewer v = _FakeViewer();
    await _pump(t, _phone(model: _ccBy), v, lang: 'hi');
    expect(find.text('3D व्यू'), findsOneWidget);
    await t.tap(find.text('3D व्यू'));
    await t.pump();
    expect(find.textContaining('3D मॉडल: vivo V80 - Early Summer Green, Abdulkhaliq Alamery द्वारा'), findsOneWidget);
  });

  testWidgets('a vertical drag on the viewer scrolls the product page', (WidgetTester t) async {
    final _FakeViewer v = _FakeViewer();
    final ScrollController sc = ScrollController();
    t.view.physicalSize = const Size(375, 500) * 2;
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ListView(controller: sc, children: <Widget>[ProductMedia(product: _phone(model: _ccBy), viewerBuilder: v.build), const SizedBox(height: 1500)]),
      ),
    ));
    await t.tap(find.text('3D View'));
    await t.pump();
    await t.tap(find.byKey(const ValueKey<String>('media3dPlay')));
    await t.pump();
    v.send!(const Viewer3DEvent(Viewer3DEventType.load));
    await t.pump();
    v.send!(const Viewer3DEvent(Viewer3DEventType.scroll, delta: 120));
    await t.pump();
    expect(sc.offset, 120);
    v.send!(const Viewer3DEvent(Viewer3DEventType.scroll, delta: -500));
    await t.pump();
    expect(sc.offset, 0, reason: 'never scrolls past the top');
  });

  testWidgets('the fullscreen request opens a full viewer that takes every touch', (WidgetTester t) async {
    final _FakeViewer v = _FakeViewer();
    await _pump(t, _phone(model: _ccBy), v);
    await t.tap(find.text('3D View'));
    await t.pump();
    await t.tap(find.byKey(const ValueKey<String>('media3dPlay')));
    await t.pump();
    v.send!(const Viewer3DEvent(Viewer3DEventType.load)); // no endless progress bar behind the route
    await t.pump();
    v.send!(const Viewer3DEvent(Viewer3DEventType.fullscreen));
    await t.pumpAndSettle();
    expect(v.fullscreen, isTrue);
    expect(v.uri!.queryParameters['mode'], 'full');
    expect(find.byIcon(Icons.close), findsOneWidget);
    await t.tap(find.byIcon(Icons.close));
    await t.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsNothing);
  });

  group('data', () {
    test('Model3D accepts only an https glb', () {
      expect(Model3D.tryFromJson(null), isNull);
      expect(Model3D.tryFromJson(<String, dynamic>{'glb': 'http://x/y.glb'}), isNull);
      expect(Model3D.tryFromJson(<String, dynamic>{'glb': 'javascript:alert(1)'}), isNull);
      expect(Model3D.tryFromJson(<String, dynamic>{'glb': 5}), isNull);
      expect(Model3D.tryFromJson(<String, dynamic>{'glb': 'https://x/y.glb'})?.exact, isTrue);
    });

    test('model3d survives a JSON round trip on the product', () {
      final Product p = _phone(model: _ccBy);
      expect(Product.fromJson(p.toJson()).model3d, _ccBy);
      expect(_phone().toJson().containsKey('model3d'), isFalse);
    });

    test('viewer messages: ours are read, anything else is ignored', () {
      expect(Viewer3DEvent.parse('{"source":"brandhoop-3d","type":"progress","value":0.4}')?.progress, 0.4);
      expect(Viewer3DEvent.parse(<String, dynamic>{'source': 'brandhoop-3d', 'type': 'error', 'reason': 'timeout'})?.reason, 'timeout');
      expect(Viewer3DEvent.parse('{"source":"brandhoop-3d","type":"scroll","dy":-30}')?.delta, -30);
      expect(Viewer3DEvent.parse('{"source":"other","type":"load"}'), isNull);
      expect(Viewer3DEvent.parse('not json'), isNull);
      expect(Viewer3DEvent.parse(<String, dynamic>{'source': 'brandhoop-3d', 'type': 'nope'}), isNull);
    });
  });
}

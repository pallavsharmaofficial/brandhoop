import 'package:equatable/equatable.dart';

import '../core/json.dart';

/// A 3D model of a phone, shown on the product page behind "3D View".
///
/// The file itself is a glb under site/models/ (see tools/models3d). Only the
/// product page's "3D View" tab ever downloads it, and only after a tap.
class Model3D extends Equatable {
  const Model3D({
    required this.glb,
    this.poster = '',
    this.title = '',
    this.author = '',
    this.license = '',
    this.licenseUrl = '',
    this.attributionRequired = true,
    this.sourceName = '',
    this.sourceUrl = '',
    this.exact = true,
    this.generated = false,
    this.sizeKb = 0,
  });

  /// https URL of the optimised .glb.
  final String glb;

  /// https URL of the still picture shown before the model is loaded.
  final String poster;
  final String title;
  final String author;

  /// "CC BY 4.0", "CC0 1.0".
  final String license;
  final String licenseUrl;
  final bool attributionRequired;

  /// "Sketchfab".
  final String sourceName;
  final String sourceUrl;

  /// True when the model is this very phone; false when it is a sibling shown as
  /// a stand-in ("Representative model, colour may differ").
  final bool exact;

  /// Built from the phone's published size and camera layout, not a real model of it.
  final bool generated;
  final int sizeKb;

  /// Credit line, as in the app: 3D model, title, author, licence, source.
  bool get hasCredit => title.isNotEmpty || author.isNotEmpty;

  Json toJson() => <String, dynamic>{
        'glb': glb,
        'poster': poster,
        'title': title,
        'author': author,
        'license': license,
        'licenseUrl': licenseUrl,
        'attributionRequired': attributionRequired,
        'sourceName': sourceName,
        'sourceUrl': sourceUrl,
        'exact': exact,
        if (generated) 'generated': true,
        'sizeKb': sizeKb,
      };

  /// Null for anything that is not an object with a usable https glb URL, so a
  /// half-edited shop.json never breaks the product page.
  static Model3D? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      return _read(Json.from(raw));
    } on TypeError {
      return null;
    }
  }

  static Model3D? _read(Json j) {
    final String glb = j.str('glb');
    final Uri? u = Uri.tryParse(glb);
    if (u == null || u.scheme != 'https') return null;
    return Model3D(
      glb: glb,
      poster: j.str('poster'),
      title: j.str('title'),
      author: j.str('author'),
      license: j.str('license'),
      licenseUrl: j.str('licenseUrl'),
      attributionRequired: j.flag('attributionRequired', true),
      sourceName: j.str('sourceName'),
      sourceUrl: j.str('sourceUrl'),
      exact: j.flag('exact', true),
      generated: j.flag('generated'),
      sizeKb: j.integer('sizeKb'),
    );
  }

  @override
  List<Object?> get props => <Object?>[glb, poster, title, author, license, licenseUrl, attributionRequired, sourceName, sourceUrl, exact, generated, sizeKb];
}

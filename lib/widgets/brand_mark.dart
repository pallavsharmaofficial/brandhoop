import 'package:flutter/material.dart';

/// The Brandhoop mark: a phone shaped like the letter B. It is the logo's own
/// artwork (assets/branding/logo-mark.png, drawn by tools/brand/make_assets.py
/// from the SVG in site/brand/logo), so it looks the same everywhere.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 36, this.onDark = false});

  final double size;

  /// Kept so existing callers still compile; the logo mark reads well on both.
  final bool onDark;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: Image.asset('assets/branding/logo-mark.png', fit: BoxFit.contain, filterQuality: FilterQuality.medium, semanticLabel: 'Brandhoop'),
      );
}

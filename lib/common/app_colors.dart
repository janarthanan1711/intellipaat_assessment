import 'package:flutter/painting.dart';

/// Colour tokens. Everything else is derived from [brand] by the theme's
/// `ColorScheme.fromSeed`; read colours from `Theme.of(context)` in widgets.
abstract final class AppColors {
  static const brand = Color(0xFF3949AB);
  static const success = Color(0xFF2E7D32);
}

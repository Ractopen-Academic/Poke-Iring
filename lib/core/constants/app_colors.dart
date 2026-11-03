import 'package:flutter/material.dart';

import '../theme/calico_theme_controller.dart';

/// AppColors encapsulates the Calico Cat Dark Theme Foundation as compile-time
/// constants for optimal performance and constant widget trees, while exposing
/// dynamic coat-mode palette properties for future runtime theme extensions.
class AppColors {
  AppColors._();

  // Calico Cat Dark Foundation Constants (Rich espresso & warm biscuit fur)
  static const Color primary = Color(0xFFE06D22);
  static const Color primaryDark = Color(0xFFD4621A);
  static const Color gingerSoft = Color(0xFFE27D30);
  static const Color gingerBorder = Color(0xFF352B25);

  static const Color calicoBlack = Color(0xFF181513);
  static const Color calicoCharcoal = Color(0xFF26201D);
  static const Color calicoMuted = Color(0xFFA69B91);
  static const Color calicoPink = Color(0xFFFFB4BE);

  static const Color secondary = Color(0xFF26201D);
  static const Color background = Color(0xFF181513);
  static const Color creamSurface = Color(0xFF26201D);
  static const Color surface = Color(0xFF221C19);
  static const Color textPrimary = Color(0xFFF7EFE8);
  static const Color textSecondary = Color(0xFFA69B91);
  static const Color border = Color(0xFF352B25);

  // Chrome & Navigation
  static const Color chromeSurface = Color(0xFF221C19);
  static const Color chromeTrack = Color(0xFF251F1C);
  static const Color chromeForeground = Color(0xFFF7EFE8);
  static const Color chromeMuted = Color(0xFFA69B91);
  static const Color chromeBorder = Color(0xFF352B25);

  // Mascot Fur Patches
  static const Color mascotBaseFur = Color(0xFFF7EFE8);
  static const Color mascotDarkPatch = Color(0xFF181513);
  static const Color mascotWarmPatch = Color(0xFFE06D22);

  // Form Fields & Progress Track
  static const Color fieldFill = Color(0xFF1A1614);
  static const Color progressTrack = Color(0xFF251F1C);

  // Dynamic Theme Controller Access
  static CalicoPalette get currentPalette =>
      CalicoThemeController.instance.palette;
  static bool get isCalicoWhite => CalicoThemeController.instance.isCalicoWhite;
}

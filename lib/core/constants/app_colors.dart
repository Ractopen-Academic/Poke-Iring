import 'package:flutter/material.dart';

import '../theme/calico_theme_controller.dart';

/// AppColors encapsulates the Calico Theme Foundations (Calico Dark & Calico Light).
/// Static constants preserve high-performance constant widget trees, while dynamic
/// getters delegate to CalicoThemeController for real-time theme inversion.
class AppColors {
  AppColors._();

  // Vibrant Calico Amber Brand Accents (WCAG AA compliant contrast)
  static const Color primary = Color(0xFFE06D22);
  static const Color primaryDark = Color(0xFFD4621A);
  static const Color gingerSoft = Color(0xFFE27D30);
  static const Color calicoAmber = Color(0xFFE27D30);
  static const Color calicoOrange = Color(0xFFE06D22);

  // Calico Dark Foundation Constants
  static const Color calicoBlack = Color(0xFF181513);
  static const Color calicoCharcoal = Color(0xFF26201D);
  static const Color calicoMuted = Color(0xFFB8ABA0);
  static const Color calicoPink = Color(0xFFFFB4BE);

  static const Color secondary = Color(0xFF26201D);
  static const Color background = Color(0xFF181513);
  static const Color creamSurface = Color(0xFF241E1A);
  static const Color surface = Color(0xFF241E1A);
  static const Color textPrimary = Color(0xFFF7EFE8);
  static const Color textSecondary = Color(0xFFB8ABA0);
  static const Color border = Color(0xFF352B25);
  static const Color gingerBorder = Color(0xFF352B25);

  // Chrome & Navigation
  static const Color chromeSurface = Color(0xFF241E1A);
  static const Color chromeTrack = Color(0xFF251F1C);
  static const Color chromeForeground = Color(0xFFF7EFE8);
  static const Color chromeMuted = Color(0xFFB8ABA0);
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

  // Dynamic Theme Palette Accessors (resolves to active mode: Calico Dark or Calico Light)
  static Color get dynamicBackground => currentPalette.background;
  static Color get dynamicSurface => currentPalette.surface;
  static Color get dynamicTextPrimary => currentPalette.textPrimary;
  static Color get dynamicTextSecondary => currentPalette.textSecondary;
  static Color get dynamicBorder => currentPalette.border;
  static Color get dynamicFieldFill => currentPalette.fieldFill;
  static Color get dynamicProgressTrack => currentPalette.progressTrack;
  static Color get dynamicChromeTrack => currentPalette.chromeTrack;
  static Color get dynamicChromeSurface => currentPalette.chromeSurface;
  static Color get dynamicChromeMuted => currentPalette.chromeMuted;
  static Color get dynamicSecondary => currentPalette.secondary;
  static Color get dynamicCalicoCharcoal => currentPalette.calicoCharcoal;
  static Color get dynamicCalicoBlack => currentPalette.calicoBlack;
  static Color get dynamicGingerBorder => currentPalette.gingerBorder;
  static Color get dynamicMascotBaseFur => currentPalette.mascotBaseFur;
  static Color get dynamicMascotDarkPatch => currentPalette.mascotDarkPatch;

  // Mode helpers
  static bool get isCalicoWhite => CalicoThemeController.instance.isCalicoLight;
  static bool get isCalicoLight => CalicoThemeController.instance.isCalicoLight;
  static bool get isCalicoDark => !CalicoThemeController.instance.isCalicoLight;
}

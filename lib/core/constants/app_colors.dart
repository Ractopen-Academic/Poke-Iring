import 'package:flutter/material.dart';

import '../theme/calico_theme_controller.dart';

/// AppColors encapsulates the Calico Cat Dark Theme Foundation as compile-time
/// constants for optimal performance and constant widget trees, while exposing
/// dynamic coat-mode palette properties for future runtime theme extensions.
class AppColors {
  AppColors._();

  // Calico Cat Dark Foundation Constants
  static const Color primary = Color(0xFFD96B27);
  static const Color primaryDark = Color(0xFFD4621A);
  static const Color gingerSoft = Color(0xFFE27D30);
  static const Color gingerBorder = Color(0xFF3D352F);

  static const Color calicoBlack = Color(0xFF1A1817);
  static const Color calicoCharcoal = Color(0xFF262220);
  static const Color calicoMuted = Color(0xFF9E9188);
  static const Color calicoPink = Color(0xFFFFB4BE);

  static const Color secondary = Color(0xFF262220);
  static const Color background = Color(0xFF1A1817);
  static const Color creamSurface = Color(0xFF262220);
  static const Color surface = Color(0xFF221F1E);
  static const Color textPrimary = Color(0xFFF6ECE0);
  static const Color textSecondary = Color(0xFFB8ABA0);
  static const Color border = Color(0xFF3A312B);

  // Chrome & Navigation
  static const Color chromeSurface = Color(0xFF221F1E);
  static const Color chromeTrack = Color(0xFF2E2723);
  static const Color chromeForeground = Color(0xFFF6ECE0);
  static const Color chromeMuted = Color(0xFF9E9188);
  static const Color chromeBorder = Color(0xFF3A312B);

  // Mascot Fur Patches
  static const Color mascotBaseFur = Color(0xFFF6ECE0);
  static const Color mascotDarkPatch = Color(0xFF1A1817);
  static const Color mascotWarmPatch = Color(0xFFD96B27);

  // Form Fields & Progress Track
  static const Color fieldFill = Color(0xFF1E1A18);
  static const Color progressTrack = Color(0xFF332B26);

  // Dynamic Theme Controller Access
  static CalicoPalette get currentPalette =>
      CalicoThemeController.instance.palette;
  static bool get isCalicoWhite => CalicoThemeController.instance.isCalicoWhite;
}

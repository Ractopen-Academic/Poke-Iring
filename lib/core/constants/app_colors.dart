import 'package:flutter/material.dart';

import '../theme/app_theme_mode.dart';

class AppColors {
  AppColors._();

  static bool get _isDark => AppThemeModeState.current == AppThemeMode.dark;

  static Color get primary =>
      _isDark ? const Color(0xFFFF9A55) : const Color(0xFFFF8C1A);
  static Color get primaryDark =>
      _isDark ? const Color(0xFFFFC28A) : const Color(0xFFE06D00);
  static Color get gingerSoft =>
      _isDark ? const Color(0xFF30231D) : const Color(0xFFFFEFE0);
  static Color get gingerBorder =>
      _isDark ? const Color(0xFF65442F) : const Color(0xFFFFCFA3);

  static Color get calicoBlack =>
      _isDark ? const Color(0xFF0D0D10) : const Color(0xFF1B1614);
  static Color get calicoCharcoal =>
      _isDark ? const Color(0xFF19191F) : const Color(0xFF2C2320);
  static Color get calicoMuted =>
      _isDark ? const Color(0xFFAAA2AD) : const Color(0xFFA6958B);
  static Color get calicoPink => const Color(0xFFFFB4BE);

  static Color get secondary =>
      _isDark ? const Color(0xFFD8CED7) : const Color(0xFF2C2320);
  static Color get background =>
      _isDark ? const Color(0xFF111116) : const Color(0xFFFFF9F2);
  static Color get creamSurface =>
      _isDark ? const Color(0xFF1D1D24) : const Color(0xFFFFF2E4);
  static Color get surface => _isDark ? const Color(0xFF1B1B22) : Colors.white;
  static Color get textPrimary =>
      _isDark ? const Color(0xFFF4EFF4) : const Color(0xFF1E1815);
  static Color get textSecondary =>
      _isDark ? const Color(0xFFB8AFBA) : const Color(0xFF6E5F57);
  static Color get border =>
      _isDark ? const Color(0xFF393640) : const Color(0xFFF2E3D3);
}

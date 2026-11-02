import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import 'app_theme_mode.dart';

// ─────────────────────────────────────────────
// Kawaii / Girly colour palette
// ─────────────────────────────────────────────
class GirlyColors {
  GirlyColors._();

  // Primary palette – sakura / pink-cat tones
  static const Color primary = Color(0xFFF48FB1); // medium-pink
  static const Color primaryDark = Color(0xFFE91E8C); // hot-pink accent
  static const Color primaryLight = Color(0xFFFCE4EC); // blush

  // Background & surfaces
  static const Color background = Color(0xFFFFA6C8); // saturated sakura pink
  static const Color surface = Color(0xFFFFFFFF);
  static const Color creamSurface = Color(0xFFFFCCDF); // rose cream
  static const Color navBar = Color(0xFFFFB6C1); // light-pink bar

  // Text
  static const Color textPrimary = Color(0xFF5D2B4A); // deep berry
  static const Color textSecondary = Color(0xFF9E6B82); // muted mauve

  // Accents & borders
  static const Color border = Color(0xFFF8BBD0); // pale rose border
  static const Color accent = Color(0xFFCE93D8); // soft lavender
  static const Color accentDark = Color(0xFF9C27B0); // plum
  static const Color highlightPink = Color(0xFFFF80AB); // bright sakura pink

  // Nav bar
  static const Color navSelected = Color(0xFFE91E8C); // hot-pink active
  static const Color navMuted = Color(0xFFE8A0B5); // muted pink
  static const Color navBarBg = Color(0xFF7B2D5E); // deep berry nav
}

// ─────────────────────────────────────────────
// Girly ThemeData factory
// ─────────────────────────────────────────────
class GirlyThemeData {
  GirlyThemeData._();

  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: GirlyColors.primary,
        primary: GirlyColors.primary,
        secondary: GirlyColors.accent,
        surface: GirlyColors.surface,
      ),
      scaffoldBackgroundColor: GirlyColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: GirlyColors.background,
        foregroundColor: GirlyColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: GirlyColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: GirlyColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: GirlyColors.border, width: 1.2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: GirlyColors.primaryDark,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 98),
      ),
    );
  }
}

class DarkThemeData {
  DarkThemeData._();

  static ThemeData build() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFFF9A55),
      onPrimary: Color(0xFF241308),
      secondary: Color(0xFFFFB4BE),
      onSecondary: Color(0xFF32151B),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: Color(0xFF1B1B22),
      onSurface: Color(0xFFF4EFF4),
      surfaceContainerHighest: Color(0xFF34323A),
      onSurfaceVariant: Color(0xFFCAC1CC),
      outline: Color(0xFF8F8994),
      outlineVariant: Color(0xFF49454F),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFE7E0E7),
      onInverseSurface: Color(0xFF303036),
      inversePrimary: Color(0xFF8A4F20),
      surfaceTint: Color(0xFFFF9A55),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surface,
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1B1B22),
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1B1B22),
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111116),
        foregroundColor: Color(0xFFF4EFF4),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFFF4EFF4),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border, width: 1.2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF29252D),
        contentTextStyle: const TextStyle(
          color: Color(0xFFF4EFF4),
          fontWeight: FontWeight.w700,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.creamSurface,
        hintStyle: TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFFFF9A55),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ValueNotifier – holds the selected app theme and persists it.
// ─────────────────────────────────────────────
class _GirlyNotifier extends ValueNotifier<AppThemeMode> {
  static const _prefKey = 'app_theme_mode';
  static const _legacyPrefKey = 'girly_theme_enabled';
  bool _hasLocalChange = false;

  _GirlyNotifier() : super(AppThemeModeState.current) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (_hasLocalChange) return;
    final storedMode = prefs.getString(_prefKey);
    final legacyGirly = prefs.getBool(_legacyPrefKey) ?? false;
    _setMode(
      AppThemeMode.values.firstWhere(
        (mode) => mode.name == storedMode,
        orElse: () => legacyGirly ? AppThemeMode.kawaii : AppThemeMode.normal,
      ),
    );
  }

  Future<void> toggle() async {
    final nextIndex = (value.index + 1) % AppThemeMode.values.length;
    await setMode(AppThemeMode.values[nextIndex]);
  }

  Future<void> setMode(AppThemeMode mode) async {
    _hasLocalChange = true;
    _setMode(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
    await prefs.setBool(_legacyPrefKey, mode == AppThemeMode.kawaii);
  }

  void _setMode(AppThemeMode mode) {
    AppThemeModeState.current = mode;
    value = mode;
  }
}

// ─────────────────────────────────────────────
// InheritedNotifier – rebuilds dependents when
// the notifier fires (i.e. on toggle).
// ─────────────────────────────────────────────
class _GirlyInherited extends InheritedNotifier<_GirlyNotifier> {
  const _GirlyInherited({
    required super.notifier,
    required super.child,
  });
}

// ─────────────────────────────────────────────
// Public provider widget
// ─────────────────────────────────────────────
class GirlyThemeProvider extends StatefulWidget {
  final Widget child;
  const GirlyThemeProvider({super.key, required this.child});

  @override
  State<GirlyThemeProvider> createState() => GirlyThemeProviderState();

  // Read the current state (does NOT register dependency).
  static GirlyThemeProviderState of(BuildContext context) {
    final state = context.findAncestorStateOfType<GirlyThemeProviderState>();
    assert(state != null, 'GirlyThemeProvider not found in widget tree');
    return state!;
  }

  /// Returns true if girly theme is active, or false outside a provider.
  static AppThemeMode mode(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_GirlyInherited>();
    return inherited?.notifier?.value ?? AppThemeModeState.current;
  }

  static bool isGirly(BuildContext context) {
    return mode(context) == AppThemeMode.kawaii;
  }

  static bool isDark(BuildContext context) {
    return mode(context) == AppThemeMode.dark;
  }
}

class GirlyThemeProviderState extends State<GirlyThemeProvider> {
  final _GirlyNotifier _notifier = _GirlyNotifier();

  bool get isGirlyMode => _notifier.value == AppThemeMode.kawaii;
  bool get isDarkMode => _notifier.value == AppThemeMode.dark;
  AppThemeMode get themeMode => _notifier.value;
  ValueListenable<AppThemeMode> get themeModeListenable => _notifier;

  Future<void> toggle() => _notifier.toggle();

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _GirlyInherited(
      notifier: _notifier,
      child: widget.child,
    );
  }
}

class AppThemeBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, AppThemeMode mode) builder;

  const AppThemeBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final themeMode = GirlyThemeProvider.of(context).themeModeListenable;
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) => builder(context, mode),
    );
  }
}

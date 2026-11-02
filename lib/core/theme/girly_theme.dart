import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// ─────────────────────────────────────────────
// ValueNotifier – holds the girly-mode bool and
// persists the preference.
// ─────────────────────────────────────────────
class _GirlyNotifier extends ValueNotifier<bool> {
  static const _prefKey = 'girly_theme_enabled';

  _GirlyNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getBool(_prefKey) ?? false;
  }

  Future<void> toggle() async {
    value = !value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
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
  static bool isGirly(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_GirlyInherited>();
    return inherited?.notifier?.value ?? false;
  }
}

class GirlyThemeProviderState extends State<GirlyThemeProvider> {
  final _GirlyNotifier _notifier = _GirlyNotifier();

  bool get isGirlyMode => _notifier.value;

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

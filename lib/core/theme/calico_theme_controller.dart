import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CalicoCoatMode {
  calicoDark,
  calicoLight,
  calicoPink,
  calicoWhite,
  system;

  String get label => switch (this) {
    CalicoCoatMode.calicoDark => 'Calico Dark',
    CalicoCoatMode.calicoLight => 'Calico Light',
    CalicoCoatMode.calicoPink => 'Calico Pink',
    CalicoCoatMode.calicoWhite => 'Calico White',
    CalicoCoatMode.system => 'System Default',
  };

  String get description => switch (this) {
    CalicoCoatMode.calicoDark =>
      'Deep charcoal/espresso base, warm cream text, amber accents',
    CalicoCoatMode.calicoLight =>
      'Warm cream/biscuit base, dark espresso text, amber accents',
    CalicoCoatMode.calicoPink =>
      'Soft pastel rose base, deep berry text, vibrant pink accents',
    CalicoCoatMode.calicoWhite =>
      'Porcelain snow base, dark charcoal text, ginger amber accents',
    CalicoCoatMode.system =>
      'Follows device OS appearance settings automatically',
  };

  Color get swatchColor => switch (this) {
    CalicoCoatMode.calicoDark => const Color(0xFFE06D22),
    CalicoCoatMode.calicoLight => const Color(0xFFD4A373),
    CalicoCoatMode.calicoPink => const Color(0xFFE24B76),
    CalicoCoatMode.calicoWhite => const Color(0xFFE0E0E0),
    CalicoCoatMode.system => const Color(0xFF78909C),
  };

  static CalicoCoatMode fromStorage(String? value) {
    return CalicoCoatMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => CalicoCoatMode.calicoDark,
    );
  }
}

@immutable
class CalicoPalette {
  final Color primary;
  final Color primaryDark;
  final Color gingerSoft;
  final Color gingerBorder;
  final Color calicoBlack;
  final Color calicoCharcoal;
  final Color calicoMuted;
  final Color pawPink;
  final Color secondary;
  final Color background;
  final Color creamSurface;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  final Color chromeSurface;
  final Color chromeTrack;
  final Color chromeForeground;
  final Color chromeMuted;
  final Color chromeBorder;

  final Color mascotBaseFur;
  final Color mascotDarkPatch;
  final Color mascotWarmPatch;

  final Color fieldFill;
  final Color progressTrack;

  const CalicoPalette({
    required this.primary,
    required this.primaryDark,
    required this.gingerSoft,
    required this.gingerBorder,
    required this.calicoBlack,
    required this.calicoCharcoal,
    required this.calicoMuted,
    required this.pawPink,
    required this.secondary,
    required this.background,
    required this.creamSurface,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.chromeSurface,
    required this.chromeTrack,
    required this.chromeForeground,
    required this.chromeMuted,
    required this.chromeBorder,
    required this.mascotBaseFur,
    required this.mascotDarkPatch,
    required this.mascotWarmPatch,
    required this.fieldFill,
    required this.progressTrack,
  });

  /// Calico Dark Theme Foundation
  /// Grounded in rich espresso, warm biscuit/cream, vibrant amber, and muted chestnut.
  static const calicoDark = CalicoPalette(
    primary: Color(0xFFE06D22),
    primaryDark: Color(0xFFD4621A),
    gingerSoft: Color(0xFFE27D30),
    gingerBorder: Color(0xFF352B25),
    calicoBlack: Color(0xFF181513),
    calicoCharcoal: Color(0xFF26201D),
    calicoMuted: Color(0xFFB8ABA0),
    pawPink: Color(0xFFFFB4BE),
    secondary: Color(0xFF26201D),
    background: Color(0xFF181513),
    creamSurface: Color(0xFF241E1A),
    surface: Color(0xFF241E1A),
    textPrimary: Color(0xFFF7EFE8),
    textSecondary: Color(0xFFB8ABA0),
    border: Color(0xFF352B25),
    chromeSurface: Color(0xFF241E1A),
    chromeTrack: Color(0xFF251F1C),
    chromeForeground: Color(0xFFF7EFE8),
    chromeMuted: Color(0xFFB8ABA0),
    chromeBorder: Color(0xFF352B25),
    mascotBaseFur: Color(0xFFF7EFE8),
    mascotDarkPatch: Color(0xFF181513),
    mascotWarmPatch: Color(0xFFE06D22),
    fieldFill: Color(0xFF1A1614),
    progressTrack: Color(0xFF251F1C),
  );

  /// Global Calico Light Theme (Reverse Palette)
  /// Warm off-white cream background, clean white card surface, deep espresso text, and amber accents.
  static const calicoLight = CalicoPalette(
    primary: Color(0xFFE06D22),
    primaryDark: Color(0xFFD4621A),
    gingerSoft: Color(0xFFF4ECE1),
    gingerBorder: Color(0xFFE3D8CC),
    calicoBlack: Color(0xFF1E1815),
    calicoCharcoal: Color(0xFF6B5E55),
    calicoMuted: Color(0xFF6B5E55),
    pawPink: Color(0xFFFFB4BE),
    secondary: Color(0xFFF4ECE1),
    background: Color(0xFFFBF6F0),
    creamSurface: Color(0xFFF4ECE1),
    surface: Colors.white,
    textPrimary: Color(0xFF1E1815),
    textSecondary: Color(0xFF6B5E55),
    border: Color(0xFFE3D8CC),
    chromeSurface: Colors.white,
    chromeTrack: Color(0xFFEFE6DC),
    chromeForeground: Color(0xFF1E1815),
    chromeMuted: Color(0xFF6B5E55),
    chromeBorder: Color(0xFFE3D8CC),
    mascotBaseFur: Colors.white,
    mascotDarkPatch: Color(0xFF1E1815),
    mascotWarmPatch: Color(0xFFE06D22),
    fieldFill: Colors.white,
    progressTrack: Color(0xFFEFE6DC),
  );

  /// Calico Pink Theme (Sakura / Soft Rose)
  static const calicoPink = CalicoPalette(
    primary: Color(0xFFE24B76),
    primaryDark: Color(0xFFC7365F),
    gingerSoft: Color(0xFFFCE4EC),
    gingerBorder: Color(0xFFF9C8D4),
    calicoBlack: Color(0xFF381A24),
    calicoCharcoal: Color(0xFF7A4E5C),
    calicoMuted: Color(0xFF7A4E5C),
    pawPink: Color(0xFFE24B76),
    secondary: Color(0xFFFCE4EC),
    background: Color(0xFFFFF0F5),
    creamSurface: Color(0xFFFDE8EF),
    surface: Colors.white,
    textPrimary: Color(0xFF381A24),
    textSecondary: Color(0xFF7A4E5C),
    border: Color(0xFFF9C8D4),
    chromeSurface: Colors.white,
    chromeTrack: Color(0xFFFCE4EC),
    chromeForeground: Color(0xFF381A24),
    chromeMuted: Color(0xFF7A4E5C),
    chromeBorder: Color(0xFFF9C8D4),
    mascotBaseFur: Color(0xFFFFF5F7),
    mascotDarkPatch: Color(0xFF381A24),
    mascotWarmPatch: Color(0xFFE24B76),
    fieldFill: Color(0xFFFFF7F9),
    progressTrack: Color(0xFFF8D7E0),
  );

  /// Calico White Theme (Pure Snow / Porcelain)
  static const calicoWhite = CalicoPalette(
    primary: Color(0xFFE06D22),
    primaryDark: Color(0xFFD4621A),
    gingerSoft: Color(0xFFF5EFEB),
    gingerBorder: Color(0xFFE1E8ED),
    calicoBlack: Color(0xFF14171A),
    calicoCharcoal: Color(0xFF5B7083),
    calicoMuted: Color(0xFF5B7083),
    pawPink: Color(0xFFFFB4BE),
    secondary: Color(0xFFF0F2F5),
    background: Color(0xFFF7F8FA),
    creamSurface: Color(0xFFF0F2F5),
    surface: Colors.white,
    textPrimary: Color(0xFF14171A),
    textSecondary: Color(0xFF5B7083),
    border: Color(0xFFE1E8ED),
    chromeSurface: Colors.white,
    chromeTrack: Color(0xFFEBF0F5),
    chromeForeground: Color(0xFF14171A),
    chromeMuted: Color(0xFF5B7083),
    chromeBorder: Color(0xFFE1E8ED),
    mascotBaseFur: Colors.white,
    mascotDarkPatch: Color(0xFF14171A),
    mascotWarmPatch: Color(0xFFE06D22),
    fieldFill: Colors.white,
    progressTrack: Color(0xFFE1E8ED),
  );

  static CalicoPalette of(CalicoCoatMode mode) => switch (mode) {
    CalicoCoatMode.calicoDark => calicoDark,
    CalicoCoatMode.calicoLight => calicoLight,
    CalicoCoatMode.calicoPink => calicoPink,
    CalicoCoatMode.calicoWhite => calicoWhite,
    CalicoCoatMode.system => _resolveSystem(),
  };

  static CalicoPalette _resolveSystem() {
    try {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.light ? calicoLight : calicoDark;
    } catch (_) {
      return calicoDark;
    }
  }
}

class CalicoThemeController extends ChangeNotifier {
  CalicoThemeController._();

  static final CalicoThemeController instance = CalicoThemeController._();
  static const String storageKey = 'pokeiring_calico_coat_mode_v1';

  CalicoCoatMode _mode = CalicoCoatMode.calicoDark;

  CalicoCoatMode get mode => _mode;

  CalicoCoatMode get effectiveMode {
    if (_mode == CalicoCoatMode.system) {
      try {
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.light
            ? CalicoCoatMode.calicoLight
            : CalicoCoatMode.calicoDark;
      } catch (_) {
        return CalicoCoatMode.calicoDark;
      }
    }
    return _mode;
  }

  CalicoPalette get palette => CalicoPalette.of(effectiveMode);
  bool get isCalicoLight =>
      effectiveMode == CalicoCoatMode.calicoLight ||
      effectiveMode == CalicoCoatMode.calicoPink ||
      effectiveMode == CalicoCoatMode.calicoWhite;
  bool get isCalicoPink => effectiveMode == CalicoCoatMode.calicoPink;
  bool get isCalicoWhite => effectiveMode == CalicoCoatMode.calicoWhite;
  bool get isCalicoDark => effectiveMode == CalicoCoatMode.calicoDark;

  Future<void> loadSavedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mode = CalicoCoatMode.fromStorage(prefs.getString(storageKey));
    } catch (_) {
      _mode = CalicoCoatMode.calicoDark;
    }
  }

  Future<void> setMode(CalicoCoatMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, mode.name);
    } catch (_) {}
  }

  @visibleForTesting
  void debugReset() {
    _mode = CalicoCoatMode.calicoDark;
  }
}

/// Repaints every mounted element in place when the coat changes, so tabs,
/// scroll offsets and open sheets survive the switch.
class CalicoThemeRebuildScope extends StatefulWidget {
  final WidgetBuilder builder;

  const CalicoThemeRebuildScope({super.key, required this.builder});

  @override
  State<CalicoThemeRebuildScope> createState() =>
      _CalicoThemeRebuildScopeState();
}

class _CalicoThemeRebuildScopeState extends State<CalicoThemeRebuildScope> {
  @override
  void initState() {
    super.initState();
    CalicoThemeController.instance.addListener(_handleCoatChanged);
  }

  @override
  void dispose() {
    CalicoThemeController.instance.removeListener(_handleCoatChanged);
    super.dispose();
  }

  void _handleCoatChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

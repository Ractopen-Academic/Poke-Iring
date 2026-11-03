import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CalicoCoatMode {
  calicoDark,
  calicoWhite;

  String get label => switch (this) {
    CalicoCoatMode.calicoDark => 'Calico Dark',
    CalicoCoatMode.calicoWhite => 'Calico White',
  };

  String get description => switch (this) {
    CalicoCoatMode.calicoDark => 'Obsidian chrome with marmalade orange',
    CalicoCoatMode.calicoWhite => 'Snowy white coat with cinnamon and cocoa',
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
  final Color calicoPink;
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
    required this.calicoPink,
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
  /// Grounded in charcoal slate, warm bisque cream, vibrant ochre, and muted chestnut.
  static const calicoDark = CalicoPalette(
    primary: Color(0xFFD96B27),
    primaryDark: Color(0xFFD4621A),
    gingerSoft: Color(0xFFE27D30),
    gingerBorder: Color(0xFF3D352F),
    calicoBlack: Color(0xFF1A1817),
    calicoCharcoal: Color(0xFF262220),
    calicoMuted: Color(0xFF9E9188),
    calicoPink: Color(0xFFFFB4BE),
    secondary: Color(0xFF262220),
    background: Color(0xFF1A1817),
    creamSurface: Color(0xFF262220),
    surface: Color(0xFF221F1E),
    textPrimary: Color(0xFFF6ECE0),
    textSecondary: Color(0xFFB8ABA0),
    border: Color(0xFF3A312B),
    chromeSurface: Color(0xFF221F1E),
    chromeTrack: Color(0xFF2E2723),
    chromeForeground: Color(0xFFF6ECE0),
    chromeMuted: Color(0xFF9E9188),
    chromeBorder: Color(0xFF3A312B),
    mascotBaseFur: Color(0xFFF6ECE0),
    mascotDarkPatch: Color(0xFF1A1817),
    mascotWarmPatch: Color(0xFFD96B27),
    fieldFill: Color(0xFF1E1A18),
    progressTrack: Color(0xFF332B26),
  );

  /// Calico White Coat
  static const calicoWhite = CalicoPalette(
    primary: Color(0xFF9E5E34),
    primaryDark: Color(0xFF7A4422),
    gingerSoft: Color(0xFFF4EDE5),
    gingerBorder: Color(0xFFDCC6B0),
    calicoBlack: Color(0xFF4A3124),
    calicoCharcoal: Color(0xFF73503D),
    calicoMuted: Color(0xFF8F7768),
    calicoPink: Color(0xFFF2B5B0),
    secondary: Color(0xFF73503D),
    background: Color(0xFFFCFAF7),
    creamSurface: Color(0xFFF6EFE8),
    surface: Colors.white,
    textPrimary: Color(0xFF3A261C),
    textSecondary: Color(0xFF7A6355),
    border: Color(0xFFE5D8CA),
    chromeSurface: Color(0xFFFFFCF9),
    chromeTrack: Color(0xFFEFE4D8),
    chromeForeground: Color(0xFF4A3124),
    chromeMuted: Color(0xFF8F7768),
    chromeBorder: Color(0xFFD9C3AC),
    mascotBaseFur: Colors.white,
    mascotDarkPatch: Color(0xFF6B4634),
    mascotWarmPatch: Color(0xFFC68B59),
    fieldFill: Color(0xFFF8F4EF),
    progressTrack: Color(0xFFEFE4D8),
  );

  static CalicoPalette of(CalicoCoatMode mode) => switch (mode) {
    CalicoCoatMode.calicoDark => calicoDark,
    CalicoCoatMode.calicoWhite => calicoWhite,
  };
}

class CalicoThemeController extends ChangeNotifier {
  CalicoThemeController._();

  static final CalicoThemeController instance = CalicoThemeController._();
  static const String storageKey = 'pokeiring_calico_coat_mode_v1';

  CalicoCoatMode _mode = CalicoCoatMode.calicoDark;

  CalicoCoatMode get mode => _mode;
  CalicoPalette get palette => CalicoPalette.of(_mode);
  bool get isCalicoWhite => _mode == CalicoCoatMode.calicoWhite;

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
    void markTree(Element element) {
      element.markNeedsBuild();
      element.visitChildren(markTree);
    }

    setState(() {});
    (context as Element).visitChildren(markTree);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

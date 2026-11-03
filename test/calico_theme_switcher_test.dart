import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/core/constants/app_colors.dart';
import 'package:pokeiring/core/theme/calico_theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Calico Dynamic Theme Switcher Tests', () {
    test('Palettes match exact specifications', () {
      final dark = CalicoPalette.calicoDark;
      expect(dark.background, const Color(0xFF181513));
      expect(dark.surface, const Color(0xFF241E1A));
      expect(dark.textPrimary, const Color(0xFFF7EFE8));
      expect(dark.textSecondary, const Color(0xFFB8ABA0));
      expect(dark.primary, const Color(0xFFE06D22));

      final light = CalicoPalette.calicoLight;
      expect(light.background, const Color(0xFFFBF6F0));
      expect(light.surface, const Color(0xFFFFFFFF));
      expect(light.textPrimary, const Color(0xFF1E1815));
      expect(light.textSecondary, const Color(0xFF6B5E55));
      expect(light.primary, const Color(0xFFE06D22));
    });

    test('CalicoThemeController updates mode and persists state', () async {
      final controller = CalicoThemeController.instance;

      await controller.setMode(CalicoCoatMode.calicoDark);
      expect(controller.mode, CalicoCoatMode.calicoDark);
      expect(controller.isCalicoDark, isTrue);
      expect(controller.isCalicoLight, isFalse);
      expect(AppColors.dynamicBackground, const Color(0xFF181513));
      expect(AppColors.dynamicTextPrimary, const Color(0xFFF7EFE8));

      await controller.setMode(CalicoCoatMode.calicoLight);
      expect(controller.mode, CalicoCoatMode.calicoLight);
      expect(controller.isCalicoLight, isTrue);
      expect(controller.isCalicoDark, isFalse);
      expect(AppColors.dynamicBackground, const Color(0xFFFBF6F0));
      expect(AppColors.dynamicTextPrimary, const Color(0xFF1E1815));

      await controller.setMode(CalicoCoatMode.system);
      expect(controller.mode, CalicoCoatMode.system);

      // Restore dark for subsequent tests
      await controller.setMode(CalicoCoatMode.calicoDark);
    });
  });
}

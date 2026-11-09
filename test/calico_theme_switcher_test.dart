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
      final pink = CalicoPalette.calicoPink;
      expect(pink.background, const Color(0xFFFFF0F5));
      expect(pink.surface, const Color(0xFFFFFFFF));
      expect(pink.textPrimary, const Color(0xFF381A24));
      expect(pink.primary, const Color(0xFFE24B76));

      final white = CalicoPalette.calicoWhite;
      expect(white.background, const Color(0xFFF7F8FA));
      expect(white.surface, const Color(0xFFFFFFFF));
      expect(white.textPrimary, const Color(0xFF14171A));
    });

    test('CalicoThemeController updates mode and persists state', () async {
      final controller = CalicoThemeController.instance;

      await controller.setMode(CalicoCoatMode.calicoDark);
      expect(controller.mode, CalicoCoatMode.calicoDark);
      expect(controller.isCalicoDark, isTrue);
      expect(controller.isCalicoLight, isFalse);
      expect(AppColors.dynamicBackground, const Color(0xFF181513));
      expect(AppColors.dynamicTextPrimary, const Color(0xFFF7EFE8));

      await controller.setMode(CalicoCoatMode.calicoPink);
      expect(controller.mode, CalicoCoatMode.calicoPink);
      expect(controller.isCalicoPink, isTrue);
      expect(AppColors.dynamicBackground, const Color(0xFFFFF0F5));
      expect(AppColors.dynamicTextPrimary, const Color(0xFF381A24));

      await controller.setMode(CalicoCoatMode.calicoWhite);
      expect(controller.mode, CalicoCoatMode.calicoWhite);
      expect(controller.isCalicoWhite, isTrue);
      expect(AppColors.dynamicBackground, const Color(0xFFF7F8FA));

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

    testWidgets('Theme switching preserves scroll offset without reset', (
      tester,
    ) async {
      final controller = CalicoThemeController.instance;
      await controller.setMode(CalicoCoatMode.calicoDark);

      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                return SingleChildScrollView(
                  key: const PageStorageKey<String>('test_preserved_scroll'),
                  controller: scrollController,
                  child: Column(
                    children: List.generate(
                      50,
                      (i) => SizedBox(
                        height: 60,
                        child: Text('Item $i', key: ValueKey('item_$i')),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Scroll down by 400 pixels
      scrollController.jumpTo(400);
      await tester.pump();
      expect(scrollController.offset, equals(400));

      // Switch theme mode
      await controller.setMode(CalicoCoatMode.calicoPink);
      await tester.pumpAndSettle();

      // Verify scroll offset is preserved
      expect(scrollController.offset, equals(400));
      expect(controller.mode, equals(CalicoCoatMode.calicoPink));

      // Restore
      await controller.setMode(CalicoCoatMode.calicoDark);
    });
  });
}

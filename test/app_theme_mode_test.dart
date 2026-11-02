import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/core/constants/app_colors.dart';
import 'package:pokeiring/core/theme/app_theme.dart';
import 'package:pokeiring/core/theme/app_theme_mode.dart';
import 'package:pokeiring/core/theme/girly_theme.dart';
import 'package:pokeiring/core/widgets/girly_theme_toggle.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppThemeModeState.current = AppThemeMode.normal;
  });

  testWidgets('theme toggle cycles and persists all three modes', (
    tester,
  ) async {
    await tester.pumpWidget(
      GirlyThemeProvider(
        child: AppThemeBuilder(
          builder: (context, mode) => MaterialApp(
            theme: switch (mode) {
              AppThemeMode.normal => AppTheme.lightTheme,
              AppThemeMode.kawaii => GirlyThemeData.build(),
              AppThemeMode.dark => DarkThemeData.build(),
            },
            home: Scaffold(
              body: Column(
                children: [
                  const GirlyThemeToggle(),
                  Builder(
                    builder: (context) {
                      return ColoredBox(
                        key: const Key('theme-surface'),
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: const SizedBox(width: 20, height: 20),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Normal'), findsOneWidget);
    expect(
      tester.widget<ColoredBox>(find.byKey(const Key('theme-surface'))).color,
      const Color(0xFFFFF9F2),
    );

    await tester.tap(find.byType(GirlyThemeToggle));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Kawaii'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(
      tester.widget<ColoredBox>(find.byKey(const Key('theme-surface'))).color,
      GirlyColors.background,
    );
    expect(
      GirlyThemeProvider.mode(tester.element(find.byType(GirlyThemeToggle))),
      AppThemeMode.kawaii,
    );
    for (final transform in tester.widgetList<Transform>(
      find.descendant(
        of: find.byType(GirlyThemeToggle),
        matching: find.byType(Transform),
      ),
    )) {
      expect(transform.transform[1], closeTo(0, 0.001));
    }

    await tester.tap(find.byType(GirlyThemeToggle));
    await tester.pumpAndSettle();
    expect(find.text('Dark'), findsOneWidget);
    expect(AppColors.background, const Color(0xFF111116));
    expect(
      tester.widget<ColoredBox>(find.byKey(const Key('theme-surface'))).color,
      const Color(0xFF111116),
    );

    await tester.tap(find.byType(GirlyThemeToggle));
    await tester.pumpAndSettle();
    expect(find.text('Normal'), findsOneWidget);
    expect(AppColors.background, const Color(0xFFFFF9F2));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_theme_mode'), AppThemeMode.normal.name);
  });
}

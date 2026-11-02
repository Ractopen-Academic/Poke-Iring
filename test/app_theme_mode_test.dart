import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/core/constants/app_colors.dart';
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
        child: const MaterialApp(
          home: Scaffold(
            body: Center(child: GirlyThemeToggle()),
          ),
        ),
      ),
    );

    expect(find.text('Normal'), findsOneWidget);

    await tester.tap(find.byType(GirlyThemeToggle));
    await tester.pumpAndSettle();
    expect(find.text('Kawaii'), findsOneWidget);
    expect(
        GirlyThemeProvider.mode(tester.element(find.byType(GirlyThemeToggle))),
        AppThemeMode.kawaii);

    await tester.tap(find.byType(GirlyThemeToggle));
    await tester.pumpAndSettle();
    expect(find.text('Dark'), findsOneWidget);
    expect(AppColors.background, const Color(0xFF111116));

    await tester.tap(find.byType(GirlyThemeToggle));
    await tester.pumpAndSettle();
    expect(find.text('Normal'), findsOneWidget);
    expect(AppColors.background, const Color(0xFFFFF9F2));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_theme_mode'), AppThemeMode.normal.name);
  });
}

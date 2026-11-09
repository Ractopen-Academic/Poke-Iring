import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/core/constants/app_version.dart';
import 'package:pokeiring/core/widgets/persistent_version_overlay.dart';

void main() {
  setUp(() {
    AppVersionOverlayController.instance.setCameraActive(false);
    AppVersionOverlayController.instance.setBottomNavActive(false);
  });

  group('PersistentVersionOverlay Widget Tests', () {
    testWidgets('renders persistent version watermark on normal screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PersistentVersionOverlay(
            child: Scaffold(body: Center(child: Text('Main Screen'))),
          ),
        ),
      );

      expect(find.text(AppVersion.releaseTag), findsOneWidget);
      expect(find.text('Main Screen'), findsOneWidget);
    });

    testWidgets('hides persistent version watermark when camera is active', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PersistentVersionOverlay(
            child: Scaffold(body: Center(child: Text('Camera Viewfinder'))),
          ),
        ),
      );

      expect(find.text(AppVersion.releaseTag), findsOneWidget);

      // Camera takes over
      AppVersionOverlayController.instance.setCameraActive(true);
      await tester.pump();

      expect(find.text(AppVersion.releaseTag), findsNothing);

      // Camera closed
      AppVersionOverlayController.instance.setCameraActive(false);
      await tester.pump();

      expect(find.text(AppVersion.releaseTag), findsOneWidget);
    });

    testWidgets(
      'adjusts vertical offset when bottom navigation bar is active',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PersistentVersionOverlay(
              child: Scaffold(body: Center(child: Text('Shell Screen'))),
            ),
          ),
        );

        final initialPositioned = tester.widget<Positioned>(
          find.byType(Positioned),
        );
        expect(initialPositioned.bottom, equals(12.0));

        // Bottom nav activated
        AppVersionOverlayController.instance.setBottomNavActive(true);
        await tester.pump();

        final updatedPositioned = tester.widget<Positioned>(
          find.byType(Positioned),
        );
        expect(updatedPositioned.bottom, equals(84.0));
      },
    );
  });
}

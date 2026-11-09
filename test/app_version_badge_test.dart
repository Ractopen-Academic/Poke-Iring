import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/core/constants/app_version.dart';
import 'package:pokeiring/core/widgets/app_version_badge.dart';
import 'package:pokeiring/core/widgets/lockout_views.dart';

void main() {
  group('AppVersionBadge Widget Tests', () {
    testWidgets('renders discreet version badge with releaseTag', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: AppVersionBadge())),
        ),
      );

      expect(find.byType(AppVersionBadge), findsOneWidget);
      expect(find.text(AppVersion.releaseTag), findsOneWidget);
    });

    testWidgets('NetworkErrorView displays AppVersionBadge in bottom left', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: NetworkErrorView(onRetry: () {})),
      );

      expect(find.byType(AppVersionBadge), findsOneWidget);
      expect(find.text(AppVersion.releaseTag), findsOneWidget);
    });

    testWidgets('MaintenanceLockoutView displays AppVersionBadge', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MaintenanceLockoutView(
            message: 'Server undergoing maintenance',
          ),
        ),
      );

      expect(find.byType(AppVersionBadge), findsOneWidget);
      expect(find.text(AppVersion.releaseTag), findsOneWidget);
    });

    testWidgets('VersionUpdateRequiredView displays AppVersionBadge', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VersionUpdateRequiredView(requiredVersion: '1.0.0'),
        ),
      );

      expect(find.byType(AppVersionBadge), findsOneWidget);
      expect(find.text(AppVersion.releaseTag), findsOneWidget);
    });
  });
}

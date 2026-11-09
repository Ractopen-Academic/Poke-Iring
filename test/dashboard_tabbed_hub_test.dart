import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/auth/domain/entities/auth_user.dart';
import 'package:pokeiring/features/auth/domain/repositories/auth_repository.dart';
import 'package:pokeiring/features/home/presentation/pages/dashboard_page.dart';
import 'package:pokeiring/features/home/presentation/widgets/dashboard_coat_theme_card.dart';
import 'package:pokeiring/features/home/presentation/widgets/dashboard_profile_card.dart';
import 'package:pokeiring/features/home/presentation/widgets/dashboard_stats_card.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();

  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthUser> signInWithEmailPassword(
    String email,
    String password,
  ) async => throw UnimplementedError();

  @override
  Future<AuthUser> registerWithEmailPassword(
    String email,
    String password, {
    String? nickname,
  }) async => throw UnimplementedError();

  @override
  Future<AuthUser> signInWithGoogle() async => throw UnimplementedError();

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> reloadCurrentUser() async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  const testUser = AuthUser(
    id: 'user_dev_0418',
    email: 'scout@pokeiring.app',
    displayName: 'Calico Scout',
    emailVerified: true,
  );

  final fakeAuth = _FakeAuthRepository();

  group('DashboardPage Tabbed Hub Widget Tests', () {
    testWidgets('renders Overview tab with License Card and Patrol Metrics', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardPage(user: testUser, authRepository: fakeAuth),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      // Top segmented pill buttons
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Explorer License Card
      expect(find.byType(DashboardProfileCard), findsOneWidget);
      expect(find.text('FELINE EXPLORER LICENSE'), findsOneWidget);
      expect(find.text('#IRING-USERDE'), findsOneWidget);

      // Contextualized Fitness Metrics
      expect(find.byType(DashboardStatsCard), findsOneWidget);
      expect(find.text('Territory Patrol Activity'), findsOneWidget);
      expect(find.text('Patrol Steps'), findsOneWidget);
      expect(find.text('Cat Treats'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('switches to Settings tab and renders Coat Mode swatches', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardPage(user: testUser, authRepository: fakeAuth),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      // Switch to Settings
      await tester.tap(find.text('Settings'));
      await tester.pump(const Duration(milliseconds: 250));

      // Coat Mode swatch selector
      expect(find.byType(DashboardCoatThemeCard), findsOneWidget);
      expect(find.text('Coat Mode (Theme)'), findsOneWidget);
      expect(find.text('Calico Dark'), findsWidgets);
      expect(find.text('Calico Light'), findsOneWidget);

      // Cache & Cloud Synchronization Group
      expect(find.text('Cache & Cloud Synchronization'), findsOneWidget);
      expect(find.text('Force Cloud Recache'), findsOneWidget);
      expect(find.text('Purge Offline & Test Cache'), findsOneWidget);

      // Sign Out Button
      expect(find.text('Sign Out'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('developer gesture (5 taps on version) unlocks dev tools', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardPage(user: testUser, authRepository: fakeAuth),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      // Switch to Settings
      await tester.tap(find.text('Settings'));
      await tester.pump(const Duration(milliseconds: 250));

      // Initially Developer & System Tools is hidden for non-admin
      expect(find.text('Developer & System Tools'), findsNothing);

      // Find build version footer and tap 5 times
      final footerFinder = find.byKey(const ValueKey('dashboard_dev_footer'));
      await tester.ensureVisible(footerFinder);
      await tester.pump(const Duration(milliseconds: 100));

      for (int i = 0; i < 5; i++) {
        await tester.tap(footerFinder);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 300));

      // Now Developer & System Tools should be revealed
      expect(find.text('Developer & System Tools'), findsOneWidget);
      expect(find.text('AI Vision Engine'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
    });
  });
}

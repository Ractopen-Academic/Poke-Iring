import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/auth/domain/entities/auth_user.dart';
import 'package:pokeiring/features/auth/domain/repositories/auth_repository.dart';
import 'package:pokeiring/features/dex/domain/entities/feline_dex_species.dart';
import 'package:pokeiring/features/dex/domain/entities/iring_dex_entry.dart';
import 'package:pokeiring/features/dex/presentation/widgets/cat_detail_sheet.dart';
import 'package:pokeiring/features/home/presentation/pages/dashboard_page.dart';
import 'package:pokeiring/features/scanner/data/datasources/firebase_sightings_datasource.dart';
import 'package:pokeiring/features/scanner/domain/entities/cat_sighting.dart';
import 'package:pokeiring/features/showcase/domain/entities/explorer_showcase_profile.dart';
import 'package:pokeiring/features/showcase/presentation/widgets/explorer_showcase_sheet.dart';
import 'package:pokeiring/features/showcase/presentation/widgets/showcase_card_item.dart';
import 'package:pokeiring/features/showcase/services/showcase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();
  @override
  AuthUser? get currentUser => null;
  @override
  Future<AuthUser> signInWithEmailPassword(String email, String password) =>
      throw UnimplementedError();
  @override
  Future<AuthUser> registerWithEmailPassword(String email, String password) =>
      throw UnimplementedError();
  @override
  Future<AuthUser> signInWithGoogle() => throw UnimplementedError();
  @override
  Future<void> sendEmailVerification() async {}
  @override
  Future<void> reloadCurrentUser() async {}
  @override
  Future<void> sendPasswordReset(String email) async {}
  @override
  Future<void> signOut() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testSighting = CatSighting(
    id: 'test-sighting-calico',
    userId: 'test-user-1',
    authorName: 'CalicoMaster',
    photoUrl: '',
    stickerUrl: '',
    latitude: 10.314,
    longitude: 123.972,
    geohash: 'w721x',
    barangay: 'Bankal',
    city: 'Lapu-Lapu City',
    region: 'Central Visayas',
    country: 'Philippines',
    breed: 'Calico (Puspin)',
    coatPattern: 'Calico',
    dominantColor: 'Tricolor',
    rarityMultiplier: 1.4,
    pawPoints: 120,
    quirk: 'Lounging peacefully in the courtyard.',
    boopsCount: 15,
    createdAt: DateTime(2026, 10, 30),
  );

  group('ShowcaseService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ShowcaseService.instance.init();
    });

    test('privacy toggle updates and persists state', () async {
      final service = ShowcaseService.instance;
      expect(service.isPublicShowcaseEnabled, isTrue);

      await service.setPublicShowcaseEnabled(false);
      expect(service.isPublicShowcaseEnabled, isFalse);

      await service.setPublicShowcaseEnabled(true);
      expect(service.isPublicShowcaseEnabled, isTrue);
    });

    test('pins and unpins sightings within 9 card limit', () async {
      final service = ShowcaseService.instance;

      // Pin sighting
      final pinned = await service.togglePinSighting(testSighting);
      expect(pinned, isTrue);
      expect(service.isSightingPinned(testSighting.id), isTrue);

      // Unpin sighting
      final unpinned = await service.togglePinSighting(testSighting);
      expect(unpinned, isFalse);
      expect(service.isSightingPinned(testSighting.id), isFalse);
    });

    test('enforces 9 card maximum showcase limit', () async {
      final service = ShowcaseService.instance;

      for (int i = 0; i < 9; i++) {
        final s = testSighting.copyWith(id: 'sighting_$i');
        await service.togglePinSighting(s);
      }

      expect(service.pinnedSightingIds.length, equals(9));

      final tenth = testSighting.copyWith(id: 'sighting_10');
      expect(
        () => service.togglePinSighting(tenth),
        throwsA(isA<StateError>()),
      );
    });

    test('generates public showcase profile for competitor', () async {
      final service = ShowcaseService.instance;
      final profile = await service.getProfile(
        targetUserId: 'competitor-1',
        currentUserId: 'my-user-id',
        displayName: 'WhiskersAce',
        avatarUrl: '',
        rank: 1,
        pawPoints: 1450,
      );

      expect(profile.displayName, equals('WhiskersAce'));
      expect(profile.rank, equals(1));
      expect(profile.isPublic, isTrue);
      expect(profile.hasShowcaseCards, isTrue);
    });

    test('respects private flag for private competitors', () async {
      final service = ShowcaseService.instance;
      final profile = await service.getProfile(
        targetUserId: 'competitor-private',
        currentUserId: 'my-user-id',
        displayName: 'ShadowProwler (Private)',
        avatarUrl: '',
        rank: 9,
        pawPoints: 340,
      );

      expect(profile.isPublic, isFalse);
    });
  });

  group('ShowcaseCardItem Widget', () {
    testWidgets('renders breed, points badge, location, and boop counter', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 320,
              child: ShowcaseCardItem(
                sighting: testSighting,
                index: 0,
                total: 5,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Spot #1 of 5'), findsOneWidget);
      expect(find.text('+120 pts'), findsOneWidget);
      expect(find.text('Calico (Puspin)'), findsOneWidget);
      expect(find.text('Calico'), findsOneWidget);
      expect(find.text('Bankal, Lapu-Lapu City'), findsOneWidget);
      expect(find.text('15 boops'), findsOneWidget);
    });
  });

  group('ExplorerShowcaseSheet Widget', () {
    testWidgets('renders public showcase header, stats, and cards', (
      tester,
    ) async {
      final publicProfile = ExplorerShowcaseProfile(
        userId: 'user-champion',
        displayName: 'CalicoQueen',
        rank: 1,
        pawPoints: 1250,
        dexDiscoveredCount: 8,
        totalBoops: 42,
        isPublic: true,
        showcaseCards: [testSighting],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ExplorerShowcaseSheet(profile: publicProfile)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('CalicoQueen'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('1250'), findsOneWidget);
      expect(find.text('8 / 16'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Feline Showcase'), findsOneWidget);
      expect(find.text('1 / 9 Cards'), findsOneWidget);
      expect(find.text('Close Showcase'), findsOneWidget);
    });

    testWidgets('renders private profile placeholder when isPublic is false', (
      tester,
    ) async {
      final privateProfile = ExplorerShowcaseProfile(
        userId: 'user-stealth',
        displayName: 'StealthWhiskers',
        rank: 4,
        pawPoints: 800,
        isPublic: false,
        showcaseCards: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ExplorerShowcaseSheet(profile: privateProfile)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('StealthWhiskers'), findsOneWidget);
      expect(find.text('Private Explorer Profile'), findsOneWidget);
      expect(
        find.text(
          'This explorer has chosen to keep their feline showcase and collection private.',
        ),
        findsOneWidget,
      );
      expect(find.text('Feline Showcase'), findsNothing);
    });
  });

  group('CatDetailSheet Showcase Actions', () {
    testWidgets('displays Pin to Showcase and Save Sticker buttons', (
      tester,
    ) async {
      final entry = IringDexEntry.fromSightings(
        species: FelineDexSpecies.canonicalSpecies[1], // Calico
        matchedSightings: [testSighting],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CatDetailSheet(entry: entry)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Pin to Showcase'), findsOneWidget);
      expect(find.text('Save Sticker'), findsOneWidget);
      expect(find.byTooltip('Share Card'), findsOneWidget);

      // Scroll into view and tap Pin to Showcase
      await tester.ensureVisible(find.text('Pin to Showcase'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pin to Showcase'));
      await tester.pumpAndSettle();

      expect(find.text('In Showcase'), findsOneWidget);
    });
  });

  group('DashboardPage Showcase Section', () {
    testWidgets('renders My Explorer Showcase slot count and View button', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await ShowcaseService.instance.init();

      const user = AuthUser(
        id: 'account-tester-id',
        email: 'account@pokeiring.test',
        displayName: 'AccountAce',
        photoUrl: '',
        emailVerified: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardPage(
              user: user,
              authRepository: _FakeAuthRepository(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Explorer Showcase & Privacy'), findsOneWidget);
      expect(find.text('My Explorer Showcase'), findsOneWidget);
      expect(find.text('0 of 9 slots pinned from Dex'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
      expect(find.text('Public Profile Showcase'), findsOneWidget);
    });
  });

  group('Real-Time User Cat Spawning', () {
    test(
      'saving sighting immediately emits to live broadcast stream',
      () async {
        SharedPreferences.setMockInitialValues({});
        final ds = FirebaseSightingsDataSource();

        final newlyDiscovered = CatSighting(
          id: 'live-snap-1',
          userId: 'live-explorer-1',
          authorName: 'Trailblazer',
          photoUrl: 'data:image/jpeg;base64,abc',
          stickerUrl: 'data:image/png;base64,xyz',
          latitude: 10.3188,
          longitude: 123.9788,
          geohash: 'w721x',
          barangay: 'Bankal',
          city: 'Lapu-Lapu City',
          region: 'Central Visayas',
          country: 'Philippines',
          breed: 'Tabby (Puspin)',
          coatPattern: 'Mackerel Tabby',
          dominantColor: 'Brown',
          rarityMultiplier: 1.0,
          pawPoints: 85,
          quirk: 'Snagged a quick photo near the plaza.',
          createdAt: DateTime.now(),
        );

        final streamFuture = ds
            .watchNearbySightings(latitude: 10.3188, longitude: 123.9788)
            .first;

        await ds.saveSighting(
          sighting: newlyDiscovered,
          originalBytes: Uint8List(0),
          stickerBytes: Uint8List(0),
        );

        final updatedList = await streamFuture;
        expect(updatedList.any((s) => s.id == 'live-snap-1'), isTrue);
        expect(updatedList.first.id, equals('live-snap-1'));
      },
    );
  });
}

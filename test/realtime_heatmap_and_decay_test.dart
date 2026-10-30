import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/auth/domain/entities/auth_user.dart';
import 'package:pokeiring/features/dex/presentation/widgets/personal_sighting_heatmap.dart';
import 'package:pokeiring/features/map/domain/entities/live_sighting.dart';
import 'package:pokeiring/features/map/presentation/widgets/cat_marker_avatar.dart';
import 'package:pokeiring/features/scanner/domain/entities/cat_sighting.dart';
import 'package:pokeiring/features/scanner/presentation/widgets/camera_viewfinder_reticle.dart';

void main() {
  const mockUser = AuthUser(
    id: 'test-user-1',
    email: 'test@pokeiring.app',
    displayName: 'Test Explorer',
  );

  group('Decay Lifecycle & Metallic Tiers Domain Logic', () {
    test('CatSighting calculates 0-10m fresh and 10-15m silhouette phases', () {
      final now = DateTime.now();

      // Fresh sighting (5 minutes old)
      final fresh = CatSighting(
        id: 'fresh-1',
        userId: 'u1',
        authorName: 'Explorer',
        photoUrl: '',
        stickerUrl: '',
        latitude: 10.314,
        longitude: 123.972,
        geohash: 'w721x',
        barangay: 'Bankal',
        city: 'Lapu-Lapu City',
        region: 'Central Visayas',
        country: 'Philippines',
        breed: 'Tabby',
        coatPattern: 'Tabby',
        dominantColor: 'Brown',
        rarityMultiplier: 1.0,
        pawPoints: 50,
        quirk: 'Playful',
        createdAt: now.subtract(const Duration(minutes: 5)),
      );

      expect(fresh.isExpired, isFalse);
      expect(fresh.isSilhouettePhase, isFalse);
      expect(fresh.spawnOpacity, equals(1.0));
      expect(fresh.metallicTier, equals('bronze'));

      // Silhouette phase (12 minutes old)
      final silhouette = fresh.copyWith(
        id: 'sil-1',
        createdAt: now.subtract(const Duration(minutes: 12)),
        rarityMultiplier: 1.6,
        pawPoints: 120,
      );

      expect(silhouette.isExpired, isFalse);
      expect(silhouette.isSilhouettePhase, isTrue);
      expect(silhouette.spawnOpacity, lessThan(1.0));
      expect(silhouette.spawnOpacity, greaterThan(0.30));
      expect(silhouette.metallicTier, equals('silver'));

      // Expired sighting (16 minutes old)
      final expired = fresh.copyWith(
        id: 'exp-1',
        createdAt: now.subtract(const Duration(minutes: 16)),
        rarityMultiplier: 2.2,
        pawPoints: 250,
      );

      expect(expired.isExpired, isTrue);
      expect(expired.spawnOpacity, equals(0.0));
      expect(expired.metallicTier, equals('gold'));
    });

    test('LiveSighting calculates decay and metallic tiers accurately', () {
      final now = DateTime.now();

      final liveFresh = LiveSighting(
        id: 'live-1',
        latitude: 10.314,
        longitude: 123.972,
        breed: 'Puspin',
        rarity: 'Common',
        confidence: 0.92,
        createdAt: now.subtract(const Duration(minutes: 3)),
        expiresAt: now.add(const Duration(minutes: 12)),
      );

      expect(liveFresh.isExpired, isFalse);
      expect(liveFresh.isSilhouettePhase, isFalse);
      expect(liveFresh.markerOpacity, equals(1.0));
      expect(liveFresh.metallicTier, equals('bronze'));

      final liveSilhouette = LiveSighting(
        id: 'live-2',
        latitude: 10.314,
        longitude: 123.972,
        breed: 'Siamese',
        rarity: 'Mythic',
        confidence: 0.96,
        createdAt: now.subtract(const Duration(minutes: 11)),
        expiresAt: now.add(const Duration(minutes: 4)),
      );

      expect(liveSilhouette.isSilhouettePhase, isTrue);
      expect(liveSilhouette.metallicTier, equals('gold'));
      expect(liveSilhouette.markerOpacity, lessThan(1.0));
    });
  });

  group('Presentation Widgets', () {
    testWidgets(
      'CatMarkerAvatar renders fresh vibrant avatar and tap callback',
      (tester) async {
        bool tapped = false;
        final now = DateTime.now();

        final sighting = CatSighting(
          id: 'sighting-avatar-test',
          userId: 'u1',
          authorName: 'Explorer',
          photoUrl: '',
          stickerUrl: '',
          latitude: 10.314,
          longitude: 123.972,
          geohash: 'w721x',
          barangay: 'Bankal',
          city: 'Lapu-Lapu City',
          region: 'Central Visayas',
          country: 'Philippines',
          breed: 'Calico',
          coatPattern: 'Calico',
          dominantColor: 'Tri-color',
          rarityMultiplier: 2.5,
          pawPoints: 220,
          quirk: 'Regal posture',
          createdAt: now.subtract(const Duration(minutes: 2)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: CatMarkerAvatar.fromSighting(
                  sighting: sighting,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(CatMarkerAvatar), findsOneWidget);
        expect(find.byIcon(Icons.pets), findsOneWidget);

        await tester.tap(find.byType(CatMarkerAvatar));
        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'CatMarkerAvatar renders shadow silhouette badge when 10+ mins old',
      (tester) async {
        final now = DateTime.now();

        final sighting = CatSighting(
          id: 'sighting-silhouette-test',
          userId: 'u1',
          authorName: 'Explorer',
          photoUrl: '',
          stickerUrl: '',
          latitude: 10.314,
          longitude: 123.972,
          geohash: 'w721x',
          barangay: 'Bankal',
          city: 'Lapu-Lapu City',
          region: 'Central Visayas',
          country: 'Philippines',
          breed: 'Midnight Puspin',
          coatPattern: 'Solid Black',
          dominantColor: 'Black',
          rarityMultiplier: 1.5,
          pawPoints: 110,
          quirk: 'Shadow stalker',
          createdAt: now.subtract(const Duration(minutes: 11)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: CatMarkerAvatar.fromSighting(
                  sighting: sighting,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.textContaining('Shadow'), findsOneWidget);
      },
    );

    testWidgets('CameraViewfinderReticle renders custom paint overlay', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: CameraViewfinderReticle(
                child: Center(child: Text('Viewfinder Area')),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Viewfinder Area'), findsOneWidget);
      expect(find.byType(CameraViewfinderReticle), findsOneWidget);
    });

    testWidgets(
      'PersonalSightingHeatmap renders header filters and empty state',
      (tester) async {
        bool scannerOpened = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PersonalSightingHeatmap(
                  sightings: const [],
                  user: mockUser,
                  onOpenScanner: () => scannerOpened = true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('0 Heatspots'), findsOneWidget);
        expect(find.text('All'), findsOneWidget);
        expect(find.text('Gold Tier'), findsOneWidget);
        expect(find.text('Silver Tier'), findsOneWidget);
        expect(find.text('Bronze Tier'), findsOneWidget);
        expect(find.text('No Personal Sightings Mapped Yet'), findsOneWidget);

        await tester.tap(find.text('Snap First Cat'));
        expect(scannerOpened, isTrue);
      },
    );
  });
}

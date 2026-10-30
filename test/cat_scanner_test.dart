import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pokeiring/core/services/ai_config_service.dart';
import 'package:pokeiring/features/auth/domain/entities/auth_user.dart';
import 'package:pokeiring/features/scanner/data/datasources/firebase_sightings_datasource.dart';
import 'package:pokeiring/features/scanner/data/services/sticker_generator_service.dart';
import 'package:pokeiring/features/scanner/domain/entities/cat_scan_result.dart';
import 'package:pokeiring/features/scanner/presentation/pages/cat_scanner_page.dart';
import 'package:pokeiring/features/scanner/presentation/widgets/paw_points_guide_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiConfigService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('retrieves, persists, and masks Gemini API key correctly', () async {
      final config = AiConfigService.instance;
      await config.init();

      // Initially no key set
      await config.clearApiKey();
      expect(config.hasKeySynchronous, isFalse);
      expect(config.maskedKey, contains('Not configured'));

      // Set key
      await config.setApiKey('AIzaSySampleKeyTesting9876');
      expect(await config.getApiKey(), equals('AIzaSySampleKeyTesting9876'));
      expect(config.maskedKey, equals('AIza••••9876'));

      // Clear key
      await config.clearApiKey();
      expect(await config.getApiKey(), isNull);
    });
  });

  group('CatScanResult', () {
    test('parses feline vision JSON response correctly', () {
      final json = {
        'is_cat': true,
        'confidence': 0.98,
        'breed': 'Calico (Puspin)',
        'coat_pattern': 'Calico',
        'dominant_color': 'Orange, Black & White',
        'rarity_multiplier': 1.4,
        'pattern_bonus_pts': 35,
        'quirk': 'Sunbathing on a sidewalk curb in Bankal.',
        'box_2d': [150, 200, 850, 800],
      };

      final result = CatScanResult.fromJson(json);

      expect(result.isCat, isTrue);
      expect(result.breed, equals('Calico (Puspin)'));
      expect(result.coatPattern, equals('Calico'));
      expect(result.rarityMultiplier, equals(1.4));
      expect(result.basePoints, equals(50));
      expect(result.patternBonus, equals(35));
      expect(result.totalPawPoints, equals(119)); // (50 + 35) * 1.4 = 119
      expect(result.boundingBox, isNotNull);
      expect(result.boundingBox!.left, closeTo(0.2, 0.01));
      expect(result.boundingBox!.top, closeTo(0.15, 0.01));
    });

    test('handles non-cat response correctly', () {
      final json = {
        'is_cat': false,
        'reason': 'Only parked motorcycle detected',
      };

      final result = CatScanResult.fromJson(json);
      expect(result.isCat, isFalse);
      expect(result.totalPawPoints, equals(0));
      expect(result.rejectionReason, equals('Only parked motorcycle detected'));
    });

    test('enforces max single sighting points cap', () {
      final json = {
        'is_cat': true,
        'confidence': 0.99,
        'breed': 'Rare Bengal Leopard',
        'coat_pattern': 'Rosetted',
        'dominant_color': 'Golden Leopard',
        'rarity_multiplier': 2.5,
        'pattern_bonus_pts': 50,
      };

      // (50 + 50) * 2.5 = 250 -> capped to 180
      final result = CatScanResult.fromJson(json);
      expect(
        result.totalPawPoints,
        equals(CatScanResult.maxSingleSightingPoints),
      );
      expect(result.totalPawPoints, equals(180));
    });

    test('exposes daily soft cap constant', () {
      expect(CatScanResult.dailyPawPointsSoftCap, equals(500));
    });
  });

  group('StickerGeneratorService', () {
    test(
      'crops image around bounding box and generates sticker png bytes',
      () async {
        // Create a test 200x200 image
        final testImg = img.Image(width: 200, height: 200);
        img.fill(testImg, color: img.ColorRgb8(245, 140, 40));
        final testBytes = Uint8List.fromList(img.encodeJpg(testImg));

        const scanResult = CatScanResult(
          isCat: true,
          boundingBox: Rect.fromLTRB(0.2, 0.2, 0.8, 0.8),
        );

        final service = StickerGeneratorService();
        final stickerBytes = await service.generateSticker(
          imageBytes: testBytes,
          scanResult: scanResult,
        );

        expect(stickerBytes, isNotEmpty);
        final decodedSticker = img.decodeImage(stickerBytes);
        expect(decodedSticker, isNotNull);
        expect(decodedSticker!.width, equals(320));
        expect(decodedSticker.height, equals(320));
      },
    );
  });

  group('FirebaseSightingsDataSource', () {
    test('streams fallback seed sightings and handles boops', () async {
      final dataSource = FirebaseSightingsDataSource();

      final sightings = await dataSource
          .watchNearbySightings(latitude: 10.3140, longitude: 123.9720)
          .first;

      expect(sightings, isNotEmpty);
      expect(sightings.first.city, equals('Lapu-Lapu City'));

      final target = sightings.first;
      final initialBoops = target.boopsCount;

      await dataSource.boopSighting(
        sightingId: target.id,
        userId: 'test-user-booper',
      );

      final updatedSightings = await dataSource
          .watchNearbySightings(latitude: 10.3140, longitude: 123.9720)
          .first;
      final updatedTarget = updatedSightings.firstWhere(
        (s) => s.id == target.id,
      );

      expect(updatedTarget.boopsCount, equals(initialBoops + 1));
      expect(updatedTarget.boopedBy, contains('test-user-booper'));
    });
  });

  group('CatScannerPage Widget', () {
    testWidgets('renders capture prompt and scoring matrix guide', (
      tester,
    ) async {
      const mockUser = AuthUser(
        id: 'test-explorer-id',
        email: 'explorer@pokeiring.test',
        displayName: 'WhiskersAce',
        photoUrl: '',
        emailVerified: true,
      );

      await tester.pumpWidget(
        const MaterialApp(home: CatScannerPage(user: mockUser)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cat Scanner & Vision'), findsOneWidget);
      expect(find.text('Spot a Neighborhood Cat'), findsOneWidget);
      expect(find.text('Snap Real-Time Cat Encounter'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsNothing);
      expect(find.text('Paw Points Scoring Matrix'), findsOneWidget);
      expect(find.text('Base Discovery'), findsOneWidget);
      expect(find.text('+50 pts'), findsOneWidget);
    });

    testWidgets('tapping help icon opens PawPointsGuideSheet', (tester) async {
      const mockUser = AuthUser(
        id: 'test-explorer-id',
        email: 'explorer@pokeiring.test',
        displayName: 'WhiskersAce',
        photoUrl: '',
        emailVerified: true,
      );

      await tester.pumpWidget(
        const MaterialApp(home: CatScannerPage(user: mockUser)),
      );

      await tester.pumpAndSettle();

      final helpButton = find.byTooltip('Points Calculation Guide');
      expect(helpButton, findsOneWidget);

      await tester.tap(helpButton);
      await tester.pumpAndSettle();

      expect(find.text('How Paw Points Work'), findsOneWidget);
      expect(find.text('Points Scoring Formula'), findsOneWidget);
      expect(find.text('Fair-Play Points Caps'), findsOneWidget);
      expect(find.text('180 pts cap'), findsOneWidget);
      expect(find.text('500 pts / day'), findsOneWidget);
      expect(find.text('Got It'), findsOneWidget);
    });
  });

  group('PawPointsGuideSheet Widget', () {
    testWidgets('renders guide sections and points caps info', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PawPointsGuideSheet())),
      );

      await tester.pumpAndSettle();

      expect(find.text('How Paw Points Work'), findsOneWidget);
      expect(find.text('Points Scoring Formula'), findsOneWidget);
      expect(find.text('Fair-Play Points Caps'), findsOneWidget);
      expect(find.text('Max Per Sighting'), findsOneWidget);
      expect(find.text('180 pts cap'), findsOneWidget);
      expect(find.text('Daily Sighting Soft Cap'), findsOneWidget);
      expect(find.text('500 pts / day'), findsOneWidget);
      expect(find.text('Got It'), findsOneWidget);
    });
  });
}

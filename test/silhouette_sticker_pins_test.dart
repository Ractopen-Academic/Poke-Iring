import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pokeiring/features/map/presentation/widgets/cat_marker_avatar.dart';
import 'package:pokeiring/features/scanner/data/services/sticker_generator_service.dart';
import 'package:pokeiring/features/scanner/domain/entities/cat_scan_result.dart';
import 'package:pokeiring/features/scanner/domain/entities/cat_sighting.dart';

void main() {
  group('Silhouette Sticker Pins & Scoring Matrix Tests', () {
    test('Multi-Factor Paw Points Scoring Matrix calculates accurately', () {
      final jsonPuspin = {
        'is_cat': true,
        'confidence': 0.96,
        'breed': 'Domestic Shorthair (Puspin)',
        'coat_pattern': 'Tabby',
        'dominant_color': 'Brown Tabby',
        'rarity_multiplier': 1.0,
        'pattern_bonus_pts': 15,
        'quirk': 'Relaxed neighborhood cat.',
      };
      final puspinResult = CatScanResult.fromJson(jsonPuspin);
      // Base (50) + Pattern (15) = 65 * 1.0 = 65 pts
      expect(puspinResult.basePoints, equals(50));
      expect(puspinResult.patternBonus, equals(15));
      expect(puspinResult.rarityMultiplier, equals(1.0));
      expect(puspinResult.totalPawPoints, equals(65));

      final jsonRare = {
        'is_cat': true,
        'confidence': 0.98,
        'breed': 'Bengal',
        'coat_pattern': 'Rosetted',
        'dominant_color': 'Golden Leopard',
        'rarity_multiplier': 2.0,
        'pattern_bonus_pts': 35,
        'quirk': 'Very agile leopard-like coat.',
      };
      final rareResult = CatScanResult.fromJson(jsonRare);
      // (50 + 35) * 2.0 = 170 pts
      expect(rareResult.basePoints, equals(50));
      expect(rareResult.patternBonus, equals(35));
      expect(rareResult.rarityMultiplier, equals(2.0));
      expect(rareResult.totalPawPoints, equals(170));
    });

    test(
      'StickerGeneratorService creates die-cut sticker and dark silhouette',
      () async {
        final service = StickerGeneratorService();

        // Create a dummy test image
        final testImg = img.Image(width: 200, height: 200, numChannels: 4);
        for (var y = 0; y < 200; y++) {
          for (var x = 0; x < 200; x++) {
            testImg.setPixelRgba(x, y, 180, 120, 80, 255);
          }
        }
        final inputBytes = Uint8List.fromList(img.encodeJpg(testImg));

        const scanResult = CatScanResult(
          isCat: true,
          breed: 'Puspin',
          boundingBox: Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
        );

        final vibrantSticker = await service.generateSticker(
          imageBytes: inputBytes,
          scanResult: scanResult,
          asSilhouette: false,
        );
        expect(vibrantSticker, isNotEmpty);

        final decodedVibrant = img.decodePng(vibrantSticker);
        expect(decodedVibrant, isNotNull);
        expect(decodedVibrant!.width, equals(320));
        expect(decodedVibrant.height, equals(320));
        expect(decodedVibrant.numChannels, equals(4));

        // Corner pixel must be transparent outside die-cut boundary
        final cornerPixel = decodedVibrant.getPixel(2, 2);
        expect(cornerPixel.a, equals(0));

        // Test silhouette generation
        final silhouetteSticker = await service.generateSticker(
          imageBytes: inputBytes,
          scanResult: scanResult,
          asSilhouette: true,
        );
        expect(silhouetteSticker, isNotEmpty);
        final decodedSilhouette = img.decodePng(silhouetteSticker);
        expect(decodedSilhouette, isNotNull);
        expect(decodedSilhouette!.numChannels, equals(4));
      },
    );

    testWidgets(
      'CatMarkerAvatar renders rarity multiplier tag and boop counter',
      (tester) async {
        bool boopTriggered = false;
        bool tapTriggered = false;

        final sighting = CatSighting(
          id: 'sighting-test-1',
          userId: 'u1',
          authorName: 'MactanExplorer',
          photoUrl: '',
          stickerUrl: '',
          latitude: 10.314,
          longitude: 123.972,
          geohash: 'w721',
          barangay: 'Bankal',
          city: 'Lapu-Lapu City',
          region: 'Central Visayas',
          country: 'Philippines',
          breed: 'Siamese',
          coatPattern: 'Colorpoint',
          dominantColor: 'Cream/Seal',
          rarityMultiplier: 1.6,
          pawPoints: 120,
          quirk: 'Vocal blue-eyed visitor.',
          boopsCount: 7,
          createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: CatMarkerAvatar.fromSighting(
                  sighting: sighting,
                  onTap: () => tapTriggered = true,
                  onBoop: () => boopTriggered = true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check Rarity Multiplier pill
        expect(find.text('1.6x'), findsOneWidget);

        // Check Boop counter pill
        expect(find.text('7'), findsOneWidget);
        expect(find.byIcon(Icons.favorite), findsOneWidget);

        // Tap Boop badge directly
        await tester.tap(find.byIcon(Icons.favorite));
        await tester.pump();
        expect(boopTriggered, isTrue);
        // Optimistic increment to 8
        expect(find.text('8'), findsOneWidget);

        // Tap main marker body
        await tester.tap(find.byType(CatMarkerAvatar));
        expect(tapTriggered, isTrue);

        await tester.pump(const Duration(milliseconds: 950));
      },
    );
  });
}

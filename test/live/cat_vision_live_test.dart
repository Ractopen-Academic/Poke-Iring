@Tags(['live'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pokeiring/core/services/ai_config_service.dart';
import 'package:pokeiring/features/dex/data/repositories/dex_repository_impl.dart';
import 'package:pokeiring/features/scanner/data/datasources/firebase_sightings_datasource.dart';
import 'package:pokeiring/features/scanner/data/datasources/gemini_vision_datasource.dart';
import 'package:pokeiring/features/scanner/data/repositories/cat_scanner_repository_impl.dart';
import 'package:pokeiring/features/scanner/domain/entities/cat_sighting.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LIVE end-to-end check of the real Gemini classifier against real photos.
///
/// Positives: random cat photos from TheCatAPI (https://thecatapi.com).
/// Negatives: dog photos from dog.ceo and human portraits from randomuser.me.
///
/// Skipped unless GEMINI_API_KEY is set. Run with:
///   GEMINI_API_KEY=... flutter test test/live/cat_vision_live_test.dart
///
/// NOTE: no TestWidgetsFlutterBinding here, because it blocks real HTTP.
void main() {
  final apiKey = Platform.environment['GEMINI_API_KEY'] ?? '';
  final skip = apiKey.isEmpty ? 'GEMINI_API_KEY not set' : null;
  final client = http.Client();
  late GeminiVisionDataSource ds;

  Future<List<String>> catUrls(int n) async {
    final res = await client.get(
      Uri.parse(
        'https://api.thecatapi.com/v1/images/search?limit=$n&mime_types=jpg,png',
      ),
    );
    final list = jsonDecode(res.body) as List;
    return list.map((e) => (e as Map)['url'] as String).take(n).toList();
  }

  Future<List<String>> dogUrls(int n) async {
    final res = await client.get(
      Uri.parse('https://dog.ceo/api/breeds/image/random/$n'),
    );
    return List<String>.from((jsonDecode(res.body) as Map)['message'] as List);
  }

  const peopleUrls = [
    'https://randomuser.me/api/portraits/men/32.jpg',
    'https://randomuser.me/api/portraits/women/44.jpg',
  ];

  Future<({bool isCat, double conf, String detail})> classify(
    String url,
  ) async {
    final img = await client.get(Uri.parse(url));
    expect(img.statusCode, 200, reason: 'download failed: $url');
    final r = await ds.analyzeCatPhoto(img.bodyBytes);
    await Future<void>.delayed(const Duration(seconds: 2)); // rate limit
    return (
      isCat: r.isCat,
      conf: r.confidence,
      detail: r.isCat
          ? '${r.breed} / ${r.coatPattern} / ${r.totalPawPoints} pts'
          : (r.rejectionReason ?? ''),
    );
  }

  setUpAll(() async {
    if (skip != null) return;
    SharedPreferences.setMockInitialValues({});
    final config = AiConfigService.instance;
    await config.init();
    await config.clearProxyUrl();
    await config.setApiKey(apiKey);
    ds = GeminiVisionDataSource(configService: config, httpClient: client);
  });

  tearDownAll(client.close);

  test(
    'real cat photos (TheCatAPI) are recognised as cats',
    () async {
      final urls = await catUrls(5);
      var hits = 0;
      for (final url in urls) {
        final r = await classify(url);
        // ignore: avoid_print
        print(
          '[CAT ] ${r.isCat ? 'PASS' : 'MISS'} ${r.conf} ${r.detail}  $url',
        );
        if (r.isCat) hits++;
      }
      // Allow at most one miss for odd crops / multi-animal stock photos.
      expect(hits, greaterThanOrEqualTo(urls.length - 1));
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 4)),
  );

  test(
    'dog photos are rejected',
    () async {
      for (final url in await dogUrls(3)) {
        final r = await classify(url);
        // ignore: avoid_print
        print('[DOG ] ${r.isCat ? 'FALSE+' : 'REJECT'} ${r.detail}  $url');
        expect(r.isCat, isFalse, reason: 'dog accepted as cat: $url');
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'photos of people are rejected',
    () async {
      for (final url in peopleUrls) {
        final r = await classify(url);
        // ignore: avoid_print
        print('[HUMN] ${r.isCat ? 'FALSE+' : 'REJECT'} ${r.detail}  $url');
        expect(r.isCat, isFalse, reason: 'person accepted as cat: $url');
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'purebred cat breeds (Siamese, Bengal) classify, save, and unlock matching Dex species',
    () async {
      final breedTargets = <({String imgUrl, String expectedDexName})>[
        (
          imgUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/16/Siamese_cat_Vaillante.JPG/330px-Siamese_cat_Vaillante.JPG',
          expectedDexName: 'Siamese',
        ),
        (
          imgUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/ba/Paintedcats_Red_Star_standing.jpg/330px-Paintedcats_Red_Star_standing.jpg',
          expectedDexName: 'Bengal',
        ),
      ];

      final sightingsDs = FirebaseSightingsDataSource();
      final repo = CatScannerRepositoryImpl(
        geminiDataSource: ds,
        firebaseDataSource: sightingsDs,
      );
      final dexRepo = DexRepositoryImpl(dataSource: sightingsDs);
      const userId = 'live-breed-e2e-user';

      for (final target in breedTargets) {
        final imgRes = await client.get(
          Uri.parse(target.imgUrl),
          headers: {'User-Agent': 'PokeIringTest/1.0 (pokeiring.app)'},
        );
        expect(imgRes.statusCode, 200);

        final scan = await repo.scanImage(imgRes.bodyBytes);
        // ignore: avoid_print
        print(
          '[BRED] expected=${target.expectedDexName} got=${scan.breed} / ${scan.coatPattern} conf=${scan.confidence} (${target.imgUrl})',
        );
        expect(scan.isCat, isTrue);

        final sticker = await repo.generateStickerCutout(
          imageBytes: imgRes.bodyBytes,
          scanResult: scan,
        );
        expect(sticker, isNotEmpty);

        await repo.saveSighting(
          sighting: CatSighting(
            id: 'live_${target.expectedDexName.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
            userId: userId,
            authorName: 'LiveTester',
            photoUrl: target.imgUrl,
            stickerUrl: '',
            latitude: 10.314,
            longitude: 123.972,
            geohash: 'w721x',
            barangay: 'Bankal',
            city: 'Lapu-Lapu City',
            region: 'Central Visayas',
            country: 'Philippines',
            breed: scan.breed,
            coatPattern: scan.coatPattern,
            dominantColor: scan.dominantColor,
            rarityMultiplier: scan.rarityMultiplier,
            pawPoints: scan.totalPawPoints,
            quirk: scan.quirk,
            createdAt: DateTime.now(),
          ),
          originalBytes: imgRes.bodyBytes,
          stickerBytes: sticker,
        );

        await Future<void>.delayed(const Duration(seconds: 13));
      }

      final entries = await dexRepo.getDexEntries(userId);
      final discoveredNames = entries
          .where((e) => e.isDiscovered)
          .map((e) => e.species.name)
          .toList();
      // ignore: avoid_print
      print('[DEX ] unlocked=$discoveredNames');
      expect(discoveredNames, contains('Siamese'));
      expect(discoveredNames, contains('Bengal'));
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

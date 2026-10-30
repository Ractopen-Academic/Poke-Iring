import 'package:flutter/foundation.dart';

import '../../domain/entities/cat_scan_result.dart';
import '../../domain/entities/cat_sighting.dart';
import '../../domain/repositories/cat_scanner_repository.dart';
import '../datasources/firebase_sightings_datasource.dart';
import '../datasources/gemini_vision_datasource.dart';
import '../services/sticker_generator_service.dart';

class CatScannerRepositoryImpl implements CatScannerRepository {
  final GeminiVisionDataSource _geminiDataSource;
  final FirebaseSightingsDataSource _firebaseDataSource;
  final StickerGeneratorService _stickerGenerator;

  CatScannerRepositoryImpl({
    GeminiVisionDataSource? geminiDataSource,
    FirebaseSightingsDataSource? firebaseDataSource,
    StickerGeneratorService? stickerGenerator,
  })  : _geminiDataSource = geminiDataSource ?? GeminiVisionDataSource(),
        _firebaseDataSource =
            firebaseDataSource ?? FirebaseSightingsDataSource(),
        _stickerGenerator = stickerGenerator ?? StickerGeneratorService();

  @override
  Future<CatScanResult> scanImage(Uint8List imageBytes) {
    return _geminiDataSource.analyzeCatPhoto(imageBytes);
  }

  @override
  Future<Uint8List> generateStickerCutout({
    required Uint8List imageBytes,
    required CatScanResult scanResult,
  }) {
    return _stickerGenerator.generateSticker(
      imageBytes: imageBytes,
      scanResult: scanResult,
    );
  }

  @override
  Future<CatSighting> saveSighting({
    required CatSighting sighting,
    required Uint8List originalBytes,
    required Uint8List stickerBytes,
  }) {
    return _firebaseDataSource.saveSighting(
      sighting: sighting,
      originalBytes: originalBytes,
      stickerBytes: stickerBytes,
    );
  }

  @override
  Stream<List<CatSighting>> watchNearbySightings({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) {
    return _firebaseDataSource.watchNearbySightings(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }

  @override
  Future<void> boopSighting({
    required String sightingId,
    required String userId,
  }) {
    return _firebaseDataSource.boopSighting(
      sightingId: sightingId,
      userId: userId,
    );
  }
}

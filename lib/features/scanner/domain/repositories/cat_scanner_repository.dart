import 'package:flutter/foundation.dart';

import '../entities/cat_scan_result.dart';
import '../entities/cat_sighting.dart';

abstract class CatScannerRepository {
  Future<CatScanResult> scanImage(Uint8List imageBytes);

  Future<Uint8List> generateStickerCutout({
    required Uint8List imageBytes,
    required CatScanResult scanResult,
  });

  Future<CatSighting> saveSighting({
    required CatSighting sighting,
    required Uint8List originalBytes,
    required Uint8List stickerBytes,
  });

  Stream<List<CatSighting>> watchNearbySightings({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  });

  Future<void> boopSighting({
    required String sightingId,
    required String userId,
  });
}

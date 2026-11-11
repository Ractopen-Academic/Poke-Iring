import 'package:latlong2/latlong.dart';

abstract class TilePrecacheService {
  Future<int> precacheArea({
    required LatLng center,
    required List<int> zoomLevels,
    int radiusTiles = 1,
  });

  /// Precaches tiles within a bounding box (e.g. customized rectangle crop)
  Future<int> precacheBoundingBox({
    required LatLng northEast,
    required LatLng southWest,
    required List<int> zoomLevels,
  });
}

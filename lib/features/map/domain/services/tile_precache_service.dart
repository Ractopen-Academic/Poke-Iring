import 'package:latlong2/latlong.dart';

abstract class TilePrecacheService {
  Future<int> precacheArea({
    required LatLng center,
    required List<int> zoomLevels,
    int radiusTiles = 1,
  });
}

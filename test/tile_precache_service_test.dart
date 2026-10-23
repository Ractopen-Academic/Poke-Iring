import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/map/data/services/tile_precache_service_impl.dart';

void main() {
  group('TilePrecacheServiceImpl coordinate math', () {
    test('calculates correct Web Mercator tile coordinates for Bankal, Lapu-Lapu City', () {
      const lat = 10.3140;
      const lon = 123.9720;
      const zoom = 16;

      final tileX = TilePrecacheServiceImpl.lonToTileX(lon, zoom);
      final tileY = TilePrecacheServiceImpl.latToTileY(lat, zoom);

      expect(tileX, equals(55336));
      expect(tileY, equals(30880));
    });

    test('calculates correct tile coordinates at zoom level 15', () {
      const lat = 10.3140;
      const lon = 123.9720;
      const zoom = 15;

      final tileX = TilePrecacheServiceImpl.lonToTileX(lon, zoom);
      final tileY = TilePrecacheServiceImpl.latToTileY(lat, zoom);

      expect(tileX, equals(27668));
      expect(tileY, equals(15440));
    });
  });
}

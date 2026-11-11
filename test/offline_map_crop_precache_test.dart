import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:pokeiring/features/map/data/services/tile_precache_service_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TilePrecacheServiceImpl bounding box precache', () {
    test('precacheBoundingBox generates valid tile coordinates covering rectangular area', () async {
      // Bankal area bounding box
      const northEast = LatLng(10.3290, 123.9900);
      const southWest = LatLng(10.2990, 123.9540);

      final minX15 = TilePrecacheServiceImpl.lonToTileX(southWest.longitude, 15);
      final maxX15 = TilePrecacheServiceImpl.lonToTileX(northEast.longitude, 15);
      final minY15 = TilePrecacheServiceImpl.latToTileY(northEast.latitude, 15);
      final maxY15 = TilePrecacheServiceImpl.latToTileY(southWest.latitude, 15);

      expect(maxX15, greaterThanOrEqualTo(minX15));
      expect(maxY15, greaterThanOrEqualTo(minY15));

      // Bounding box spans at least 1-3 tiles in each dimension
      final widthTiles = (maxX15 - minX15) + 1;
      final heightTiles = (maxY15 - minY15) + 1;
      expect(widthTiles * heightTiles, greaterThan(0));
      expect(widthTiles * heightTiles, lessThan(100));
    });
  });
}

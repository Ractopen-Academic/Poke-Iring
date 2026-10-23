import 'dart:math' as math;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/services/tile_precache_service.dart';

class TilePrecacheServiceImpl implements TilePrecacheService {
  final BaseCacheManager _cacheManager;
  final String urlTemplate;
  final List<String> subdomains;

  TilePrecacheServiceImpl({
    BaseCacheManager? cacheManager,
    this.urlTemplate = 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    this.subdomains = const ['a', 'b', 'c'],
  }) : _cacheManager = cacheManager ?? DefaultCacheManager();

  @override
  Future<int> precacheArea({
    required LatLng center,
    required List<int> zoomLevels,
    int radiusTiles = 1,
  }) async {
    final urls = <String>[];
    var subdomainIndex = 0;

    for (final z in zoomLevels) {
      final centerX = lonToTileX(center.longitude, z);
      final centerY = latToTileY(center.latitude, z);

      for (var dx = -radiusTiles; dx <= radiusTiles; dx++) {
        for (var dy = -radiusTiles; dy <= radiusTiles; dy++) {
          final x = centerX + dx;
          final y = centerY + dy;
          final subdomain = subdomains[subdomainIndex % subdomains.length];
          subdomainIndex++;

          final url = urlTemplate
              .replaceAll('{s}', subdomain)
              .replaceAll('{z}', z.toString())
              .replaceAll('{x}', x.toString())
              .replaceAll('{y}', y.toString());

          urls.add(url);
        }
      }
    }

    var cachedCount = 0;
    const batchSize = 4;
    for (var i = 0; i < urls.length; i += batchSize) {
      final batch = urls.skip(i).take(batchSize);
      final futures = batch.map((url) async {
        try {
          final fileInfo = await _cacheManager.getFileFromCache(url);
          if (fileInfo != null) {
            return true;
          }
          await _cacheManager
              .downloadFile(
                url,
                authHeaders: const {'User-Agent': 'com.ryme.pokeiring'},
              )
              .timeout(const Duration(milliseconds: 1800));
          return true;
        } catch (_) {
          return false;
        }
      });

      final results = await Future.wait(futures);
      cachedCount += results.where((r) => r).length;
    }

    return cachedCount;
  }

  static int lonToTileX(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * math.pow(2.0, zoom)).floor();
  }

  static int latToTileY(double lat, int zoom) {
    final latRad = lat * math.pi / 180.0;
    final n = math.pow(2.0, zoom);
    final mercator = math.log(math.tan(math.pi / 4.0 + latRad / 2.0));
    return ((1.0 - mercator / math.pi) / 2.0 * n).floor();
  }
}

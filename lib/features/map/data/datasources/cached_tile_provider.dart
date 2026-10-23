import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

class CachedTileProvider extends TileProvider {
  CachedTileProvider({Map<String, String>? headers})
    : super(
        headers:
            headers ??
            const {
              'User-Agent': 'PokeIringApp/1.0 (Mobile; Android; Contact: ractopen@users.noreply.github.com)',
            },
      );

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(
      getTileUrl(coordinates, options),
      headers: headers,
    );
  }
}

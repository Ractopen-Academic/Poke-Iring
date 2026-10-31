import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../domain/entities/explorer_territory.dart';
import 'ph_territory_catalog.dart';

typedef ReverseGeocodeResolver = Future<ExplorerTerritory?> Function(
  double latitude,
  double longitude,
);

class ReverseGeocodingService {
  static final ReverseGeocodingService _instance =
      ReverseGeocodingService._internal();

  static ReverseGeocodingService get instance => _instance;

  final ReverseGeocodeResolver? _customResolver;

  factory ReverseGeocodingService({ReverseGeocodeResolver? customResolver}) {
    if (customResolver != null) {
      return ReverseGeocodingService._internal(customResolver);
    }
    return _instance;
  }

  ReverseGeocodingService._internal([this._customResolver]);

  Future<ExplorerTerritory> resolveCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    // 1. Try custom resolver (for unit testing / mocked environments)
    if (_customResolver != null) {
      try {
        final resolved = await _customResolver(latitude, longitude);
        if (resolved != null) return resolved;
      } catch (_) {}
    }

    // 2. Try Nominatim reverse geocode via network if not in web/test environment
    if (!kIsWeb) {
      try {
        final onlineResolved = await _queryNominatim(latitude, longitude);
        if (onlineResolved != null) {
          return onlineResolved;
        }
      } catch (e) {
        debugPrint(
          'Reverse geocoding network error ($e). Using local fallback.',
        );
      }
    }

    // 3. Fall back to local catalog bounding boxes
    return PhTerritoryCatalog.resolveCoordinates(
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<ExplorerTerritory?> _queryNominatim(
    double latitude,
    double longitude,
  ) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);

      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&zoom=18&addressdetails=1',
      );

      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'PokeIring/1.0 (com.ryme.pokeiring)');
      request.headers.set('Accept', 'application/json');

      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final barangay =
              address['neighbourhood'] ??
              address['suburb'] ??
              address['village'] ??
              address['quarter'] ??
              address['residential'] ??
              address['hamlet'] ??
              'Poblacion';

          final city =
              address['city'] ??
              address['municipality'] ??
              address['town'] ??
              address['county'] ??
              'Lapu-Lapu City';

          final province =
              address['state'] ??
              address['province'] ??
              address['region'] ??
              'Cebu';

          final country = address['country'] ?? 'Philippines';

          return ExplorerTerritory(
            barangay: _cleanName(barangay.toString()),
            city: _cleanName(city.toString()),
            province: _cleanName(province.toString()),
            country: country.toString(),
            isHomeConfirmed: true,
            latitude: latitude,
            longitude: longitude,
          );
        }
      }
    } catch (_) {
      return null;
    } finally {
      client?.close();
    }
    return null;
  }

  String _cleanName(String raw) {
    if (raw.toLowerCase().startsWith('barangay ')) {
      return raw.substring(9).trim();
    }
    if (raw.toLowerCase().startsWith('brgy. ')) {
      return raw.substring(6).trim();
    }
    if (raw.toLowerCase().startsWith('brgy ')) {
      return raw.substring(5).trim();
    }
    return raw.trim();
  }
}

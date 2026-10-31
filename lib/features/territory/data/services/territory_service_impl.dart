import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/location_service_impl.dart';
import '../../domain/entities/explorer_territory.dart';
import '../../domain/services/territory_service.dart';
import '../datasources/firebase_territory_datasource.dart';
import '../datasources/reverse_geocoding_service.dart';

class TerritoryServiceImpl implements TerritoryService {
  static TerritoryServiceImpl? _instance;
  static TerritoryServiceImpl get instance =>
      _instance ??= TerritoryServiceImpl();

  final LocationService _locationService;
  final ReverseGeocodingService _geocodingService;
  final FirebaseTerritoryDataSource _territoryDataSource;
  final FirebaseFirestore? firestore;

  final Map<String, StreamController<ExplorerTerritory>> _controllers = {};
  final Map<String, ExplorerTerritory> _cache = {};

  TerritoryServiceImpl({
    LocationService? locationService,
    ReverseGeocodingService? geocodingService,
    FirebaseTerritoryDataSource? territoryDataSource,
    this.firestore,
  }) : _locationService = locationService ?? LocationServiceImpl(),
       _geocodingService = geocodingService ?? ReverseGeocodingService.instance,
       _territoryDataSource =
           territoryDataSource ?? FirebaseTerritoryDataSource.instance;

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  String _prefKey(String userId) => 'territory_$userId';

  @override
  Stream<ExplorerTerritory> watchTerritory(String userId) {
    if (!_controllers.containsKey(userId)) {
      _controllers[userId] = StreamController<ExplorerTerritory>.broadcast(
        onListen: () {
          getTerritory(userId).then((t) {
            if (_controllers[userId]?.isClosed == false) {
              _controllers[userId]?.add(t);
            }
          });
        },
      );
    }
    return _controllers[userId]!.stream;
  }

  @override
  Future<ExplorerTerritory> getTerritory(String userId) async {
    if (_cache.containsKey(userId)) {
      return _cache[userId]!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final barangay = prefs.getString('${_prefKey(userId)}_barangay');
      final city = prefs.getString('${_prefKey(userId)}_city');
      final province =
          prefs.getString('${_prefKey(userId)}_province') ?? 'Cebu';
      final region =
          prefs.getString('${_prefKey(userId)}_region') ?? 'Central Visayas';
      final country =
          prefs.getString('${_prefKey(userId)}_country') ?? 'Philippines';
      final isConfirmed =
          prefs.getBool('${_prefKey(userId)}_confirmed') ?? false;

      if (barangay != null && city != null) {
        final territory = ExplorerTerritory(
          barangay: barangay,
          city: city,
          province: province,
          region: region,
          country: country,
          isHomeConfirmed: isConfirmed,
        );
        _cache.putIfAbsent(userId, () => territory);
        return _cache[userId]!;
      }
    } catch (_) {}

    // Check Firestore if available
    if (_isFirebaseAvailable) {
      try {
        final doc = await _db.collection('users').doc(userId).get();
        final rawMap = doc.data()?['territory'] as Map<String, dynamic>?;
        if (rawMap != null) {
          final territory = ExplorerTerritory.fromMap(rawMap);
          _cache.putIfAbsent(userId, () => territory);
          return territory;
        }
      } catch (e) {
        debugPrint('Firestore read territory error: $e');
      }
    }

    final defaultTerritory = ExplorerTerritory.defaultTerritory;
    _cache.putIfAbsent(userId, () => defaultTerritory);
    return _cache[userId]!;
  }

  @override
  Future<void> updateTerritory(
    String userId,
    ExplorerTerritory territory,
  ) async {
    _cache[userId] = territory;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_prefKey(userId)}_barangay', territory.barangay);
      await prefs.setString('${_prefKey(userId)}_city', territory.city);
      await prefs.setString('${_prefKey(userId)}_province', territory.province);
      await prefs.setString('${_prefKey(userId)}_region', territory.region);
      await prefs.setString('${_prefKey(userId)}_country', territory.country);
      await prefs.setBool(
        '${_prefKey(userId)}_confirmed',
        territory.isHomeConfirmed,
      );
    } catch (_) {}

    // Synchronize to Firestore
    if (_isFirebaseAvailable) {
      try {
        await _db.collection('users').doc(userId).set({
          'territory': territory.toMap(),
          'barangay': territory.barangay,
          'city': territory.city,
          'province': territory.province,
          'region': territory.region,
          'country': territory.country,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore update territory error: $e');
      }
    }

    // Auto-register barangay to the city in the database if new
    await _territoryDataSource.registerBarangay(
      cityName: territory.city,
      barangayName: territory.barangay,
    );

    if (_controllers[userId]?.isClosed == false) {
      _controllers[userId]?.add(territory);
    }
  }

  @override
  Future<ExplorerTerritory> detectFromGps() async {
    try {
      final loc = await _locationService.getCurrentLocation();
      if (loc != null) {
        return await _geocodingService.resolveCoordinates(
          latitude: loc.latitude,
          longitude: loc.longitude,
        );
      }
    } catch (e) {
      debugPrint('detectFromGps error: $e');
    }

    return ExplorerTerritory.defaultTerritory;
  }
}

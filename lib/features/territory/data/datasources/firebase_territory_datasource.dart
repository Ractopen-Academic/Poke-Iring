import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ph_territory_catalog.dart';

class FirebaseTerritoryDataSource {
  static final FirebaseTerritoryDataSource instance =
      FirebaseTerritoryDataSource._internal();

  FirebaseFirestore? _firestore;
  final StreamController<List<PhCityTerritory>> _citiesController =
      StreamController<List<PhCityTerritory>>.broadcast();

  List<PhCityTerritory>? _cachedCities;

  static const String _collectionName = 'territories';
  static const String _localCacheKey = 'pokeiring_territory_catalog_v2';

  factory FirebaseTerritoryDataSource({FirebaseFirestore? firestore}) {
    if (firestore != null) {
      return FirebaseTerritoryDataSource._internal(firestore);
    }
    return instance;
  }

  FirebaseTerritoryDataSource._internal([this._firestore]);

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Stream<List<PhCityTerritory>> watchCities() {
    _startWatchingCities();
    return _citiesController.stream;
  }

  void _startWatchingCities() {
    if (_isFirebaseAvailable) {
      try {
        _db
            .collection(_collectionName)
            .snapshots()
            .listen(
              (snapshot) {
                if (snapshot.docs.isNotEmpty) {
                  final cities = snapshot.docs.map((doc) {
                    final data = doc.data();
                    return PhCityTerritory.fromMap(data);
                  }).toList();

                  _cachedCities = cities;
                  _persistLocalCache(cities);
                  if (!_citiesController.isClosed) {
                    _citiesController.add(cities);
                  }
                } else {
                  seedDefaultTerritoriesIfEmpty();
                }
              },
              onError: (err) {
                debugPrint('Firestore territory stream error: $err');
                _emitFallbackCities();
              },
            );
        return;
      } catch (e) {
        debugPrint('Failed to attach Firestore territory stream: $e');
      }
    }

    _emitFallbackCities();
  }

  Future<void> _emitFallbackCities() async {
    final cities = await getCities();
    if (!_citiesController.isClosed) {
      _citiesController.add(cities);
    }
  }

  Future<List<PhCityTerritory>> getCities({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCities != null && _cachedCities!.isNotEmpty) {
      return _cachedCities!;
    }

    // 1. Try reading from Firestore if available
    if (_isFirebaseAvailable) {
      try {
        final snap = await _db.collection(_collectionName).get();
        if (snap.docs.isNotEmpty) {
          final cities = snap.docs.map((doc) {
            final data = doc.data();
            return PhCityTerritory.fromMap(data);
          }).toList();

          _cachedCities = cities;
          await _persistLocalCache(cities);
          return cities;
        }
      } catch (e) {
        debugPrint('Firestore read territories error: $e');
      }
    }

    // 2. Try reading from local SharedPreferences cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_localCacheKey);
      if (list != null && list.isNotEmpty) {
        final cached = list.map((item) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          return PhCityTerritory.fromMap(map);
        }).toList();

        _cachedCities = cached;
        return cached;
      }
    } catch (_) {}

    // 3. Fall back to built-in default catalog
    final defaults = PhTerritoryCatalog.cities;
    _cachedCities = defaults;
    await _persistLocalCache(defaults);
    return defaults;
  }

  Future<void> seedDefaultTerritoriesIfEmpty({bool force = false}) async {
    final defaults = PhTerritoryCatalog.cities;
    _cachedCities = defaults;
    await _persistLocalCache(defaults);

    if (_isFirebaseAvailable) {
      try {
        final snap = await _db.collection(_collectionName).limit(1).get();
        if (force || snap.docs.isEmpty) {
          final batch = _db.batch();
          for (final city in defaults) {
            final docId = _generateDocId(city.city);
            final ref = _db.collection(_collectionName).doc(docId);
            batch.set(ref, city.toMap());
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint('Seeding Firestore territories skipped: $e');
      }
    }

    if (!_citiesController.isClosed) {
      _citiesController.add(defaults);
    }
  }

  Future<bool> registerBarangay({
    required String cityName,
    required String barangayName,
  }) async {
    final cleanBarangay = barangayName.trim();
    if (cleanBarangay.isEmpty) return false;

    final current = await getCities();
    final index = current.indexWhere(
      (c) => c.city.toLowerCase() == cityName.toLowerCase(),
    );

    if (index == -1) return false;

    final cityEntry = current[index];
    if (cityEntry.barangays.any(
      (b) => b.toLowerCase() == cleanBarangay.toLowerCase(),
    )) {
      return true; // Already registered
    }

    final updatedBarangays = [...cityEntry.barangays, cleanBarangay]..sort();
    final updatedCity = cityEntry.copyWith(barangays: updatedBarangays);

    final updatedList = List<PhCityTerritory>.from(current);
    updatedList[index] = updatedCity;

    _cachedCities = updatedList;
    await _persistLocalCache(updatedList);

    if (_isFirebaseAvailable) {
      try {
        final docId = _generateDocId(cityName);
        await _db
            .collection(_collectionName)
            .doc(docId)
            .set(updatedCity.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore register barangay error: $e');
      }
    }

    if (!_citiesController.isClosed) {
      _citiesController.add(updatedList);
    }

    return true;
  }

  Future<bool> addCityTerritory(PhCityTerritory territory) async {
    final current = await getCities();
    final updated = [
      ...current.where(
        (c) => c.city.toLowerCase() != territory.city.toLowerCase(),
      ),
      territory,
    ]..sort((a, b) => a.city.compareTo(b.city));

    _cachedCities = updated;
    await _persistLocalCache(updated);

    if (_isFirebaseAvailable) {
      try {
        final docId = _generateDocId(territory.city);
        await _db
            .collection(_collectionName)
            .doc(docId)
            .set(territory.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore add city error: $e');
      }
    }

    if (!_citiesController.isClosed) {
      _citiesController.add(updated);
    }

    return true;
  }

  String _generateDocId(String cityName) {
    return cityName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  Future<void> _persistLocalCache(List<PhCityTerritory> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = list.map((c) => jsonEncode(c.toMap())).toList();
      await prefs.setStringList(_localCacheKey, raw);
    } catch (_) {}
  }
}

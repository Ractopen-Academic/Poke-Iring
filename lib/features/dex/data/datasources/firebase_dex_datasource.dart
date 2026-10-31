import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/feline_dex_species.dart';

class FirebaseDexDataSource {
  static final FirebaseDexDataSource instance =
      FirebaseDexDataSource._internal();

  FirebaseFirestore? _firestore;
  final StreamController<List<FelineDexSpecies>> _speciesController =
      StreamController<List<FelineDexSpecies>>.broadcast();

  List<FelineDexSpecies>? _cachedSpecies;

  static const String _collectionName = 'dex_species';
  static const String _localCacheKey = 'pokeiring_dex_species_v1';

  factory FirebaseDexDataSource({FirebaseFirestore? firestore}) {
    if (firestore != null) {
      return FirebaseDexDataSource._internal(firestore);
    }
    return instance;
  }

  FirebaseDexDataSource._internal([this._firestore]);

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Stream<List<FelineDexSpecies>> watchSpecies() {
    _startWatchingSpecies();
    return _speciesController.stream;
  }

  void _startWatchingSpecies() {
    if (_isFirebaseAvailable) {
      try {
        _db
            .collection(_collectionName)
            .snapshots()
            .listen(
              (snapshot) {
                if (snapshot.docs.isNotEmpty) {
                  final speciesList =
                      snapshot.docs.map((doc) {
                          final data = doc.data();
                          return FelineDexSpecies.fromMap(data);
                        }).toList()
                        ..sort((a, b) => a.dexNumber.compareTo(b.dexNumber));

                  _cachedSpecies = speciesList;
                  _persistLocalCache(speciesList);
                  if (!_speciesController.isClosed) {
                    _speciesController.add(speciesList);
                  }
                } else {
                  seedDefaultSpeciesIfEmpty();
                }
              },
              onError: (err) {
                debugPrint('Firestore dex_species stream error: $err');
                _emitFallbackSpecies();
              },
            );
        return;
      } catch (e) {
        debugPrint('Failed to attach Firestore dex stream: $e');
      }
    }

    _emitFallbackSpecies();
  }

  Future<void> _emitFallbackSpecies() async {
    final species = await getSpecies();
    if (!_speciesController.isClosed) {
      _speciesController.add(species);
    }
  }

  Future<List<FelineDexSpecies>> getSpecies() async {
    if (_cachedSpecies != null && _cachedSpecies!.isNotEmpty) {
      return _cachedSpecies!;
    }

    final localCached = await _loadLocalCache();
    if (localCached.isNotEmpty) {
      _cachedSpecies = localCached;
    }

    if (_isFirebaseAvailable) {
      try {
        final snapshot = await _db.collection(_collectionName).get();
        if (snapshot.docs.isNotEmpty) {
          final speciesList = snapshot.docs.map((doc) {
            return FelineDexSpecies.fromMap(doc.data());
          }).toList()..sort((a, b) => a.dexNumber.compareTo(b.dexNumber));

          _cachedSpecies = speciesList;
          unawaited(_persistLocalCache(speciesList));
          return speciesList;
        } else {
          await seedDefaultSpeciesIfEmpty();
        }
      } catch (e) {
        debugPrint(
          'Firestore fetch species error ($e), fallback to cached/canonical',
        );
      }
    }

    if (_cachedSpecies != null && _cachedSpecies!.isNotEmpty) {
      return _cachedSpecies!;
    }

    _cachedSpecies = List<FelineDexSpecies>.from(
      FelineDexSpecies.canonicalSpecies,
    );
    return _cachedSpecies!;
  }

  Future<void> seedDefaultSpeciesIfEmpty() async {
    if (!_isFirebaseAvailable) return;

    try {
      final snapshot = await _db.collection(_collectionName).limit(1).get();
      if (snapshot.docs.isEmpty) {
        debugPrint('Seeding default Dex species to Firestore...');
        final batch = _db.batch();
        for (final species in FelineDexSpecies.canonicalSpecies) {
          final docRef = _db.collection(_collectionName).doc(species.id);
          batch.set(docRef, species.toMap());
        }
        await batch.commit();
        debugPrint(
          'Successfully seeded ${FelineDexSpecies.canonicalSpecies.length} Dex species',
        );
      }
    } catch (e) {
      debugPrint('Failed to seed default Dex species: $e');
    }
  }

  Future<void> upsertSpecies(FelineDexSpecies species) async {
    if (_cachedSpecies != null) {
      _cachedSpecies = List<FelineDexSpecies>.from(_cachedSpecies!);
      final index = _cachedSpecies!.indexWhere((s) => s.id == species.id);
      if (index >= 0) {
        _cachedSpecies![index] = species;
      } else {
        _cachedSpecies!.add(species);
      }
      _cachedSpecies!.sort((a, b) => a.dexNumber.compareTo(b.dexNumber));
      if (!_speciesController.isClosed) {
        _speciesController.add(List.unmodifiable(_cachedSpecies!));
      }
      unawaited(_persistLocalCache(_cachedSpecies!));
    }

    if (!_isFirebaseAvailable) return;

    try {
      await _db
          .collection(_collectionName)
          .doc(species.id)
          .set(species.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error upserting species ${species.id}: $e');
    }
  }

  Future<void> deleteSpecies(String speciesId) async {
    if (_cachedSpecies != null) {
      _cachedSpecies = List<FelineDexSpecies>.from(_cachedSpecies!);
      _cachedSpecies!.removeWhere((s) => s.id == speciesId);
      if (!_speciesController.isClosed) {
        _speciesController.add(List.unmodifiable(_cachedSpecies!));
      }
      unawaited(_persistLocalCache(_cachedSpecies!));
    }

    if (!_isFirebaseAvailable) return;

    try {
      await _db.collection(_collectionName).doc(speciesId).delete();
    } catch (e) {
      debugPrint('Error deleting species $speciesId: $e');
    }
  }

  Future<void> _persistLocalCache(List<FelineDexSpecies> speciesList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = speciesList.map((s) => s.toMap()).toList();
      await prefs.setString(_localCacheKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Failed to cache dex species locally: $e');
    }
  }

  Future<List<FelineDexSpecies>> _loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
      final raw = prefs.getString(_localCacheKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((e) => FelineDexSpecies.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to read local dex species cache: $e');
    }
    return [];
  }

  @visibleForTesting
  void resetCache() {
    _cachedSpecies = null;
  }
}

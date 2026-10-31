import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/tiered_achievement.dart';
import 'achievements_catalog.dart';

class FirebaseAchievementsDataSource {
  static final FirebaseAchievementsDataSource instance =
      FirebaseAchievementsDataSource._internal();

  FirebaseFirestore? _firestore;
  final StreamController<List<TieredAchievement>> _catalogController =
      StreamController<List<TieredAchievement>>.broadcast();

  List<TieredAchievement>? _cachedCatalog;

  static const String _collectionName = 'achievement_tracks';
  static const String _localCacheKey = 'pokeiring_achievements_catalog_v1';

  factory FirebaseAchievementsDataSource({FirebaseFirestore? firestore}) {
    if (firestore != null) {
      return FirebaseAchievementsDataSource._internal(firestore);
    }
    return instance;
  }

  FirebaseAchievementsDataSource._internal([this._firestore]);

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Stream<List<TieredAchievement>> watchCatalog() {
    _startWatchingCatalog();
    return _catalogController.stream;
  }

  void _startWatchingCatalog() {
    if (_isFirebaseAvailable) {
      try {
        _db
            .collection(_collectionName)
            .snapshots()
            .listen(
              (snapshot) {
                if (snapshot.docs.isNotEmpty) {
                  final tracks = snapshot.docs.map((doc) {
                    final data = doc.data();
                    return TieredAchievement.fromMap(data);
                  }).toList();

                  _cachedCatalog = List<TieredAchievement>.from(tracks);
                  _persistLocalCache(tracks);
                  if (!_catalogController.isClosed) {
                    _catalogController.add(tracks);
                  }
                } else {
                  seedDefaultCatalogIfEmpty();
                }
              },
              onError: (err) {
                debugPrint('Firestore achievement_tracks stream error: $err');
                _emitFallbackCatalog();
              },
            );
        return;
      } catch (e) {
        debugPrint('Failed to attach Firestore achievement stream: $e');
      }
    }

    _emitFallbackCatalog();
  }

  Future<void> _emitFallbackCatalog() async {
    final catalog = await getCatalog();
    if (!_catalogController.isClosed) {
      _catalogController.add(catalog);
    }
  }

  Future<List<TieredAchievement>> getCatalog() async {
    if (_cachedCatalog != null && _cachedCatalog!.isNotEmpty) {
      return _cachedCatalog!;
    }

    final localCached = await _loadLocalCache();
    if (localCached.isNotEmpty) {
      _cachedCatalog = List<TieredAchievement>.from(localCached);
    }

    if (_isFirebaseAvailable) {
      try {
        final snapshot = await _db
            .collection(_collectionName)
            .get()
            .timeout(const Duration(milliseconds: 1500));
        if (snapshot.docs.isNotEmpty) {
          final tracks = snapshot.docs.map((doc) {
            return TieredAchievement.fromMap(doc.data());
          }).toList();

          _cachedCatalog = List<TieredAchievement>.from(tracks);
          unawaited(_persistLocalCache(tracks));
          return _cachedCatalog!;
        } else {
          await seedDefaultCatalogIfEmpty();
        }
      } catch (e) {
        debugPrint(
          'Firestore fetch achievements error ($e), fallback to cached/default',
        );
      }
    }

    if (_cachedCatalog != null && _cachedCatalog!.isNotEmpty) {
      return _cachedCatalog!;
    }

    _cachedCatalog = List<TieredAchievement>.from(
      AchievementsCatalog.getInitialCatalog(),
    );
    return _cachedCatalog!;
  }

  Future<void> seedDefaultCatalogIfEmpty() async {
    if (!_isFirebaseAvailable) return;

    try {
      final snapshot = await _db.collection(_collectionName).limit(1).get();
      if (snapshot.docs.isEmpty) {
        debugPrint('Seeding default achievement tracks to Firestore...');
        final defaults = AchievementsCatalog.getInitialCatalog();
        final batch = _db.batch();
        for (final track in defaults) {
          final docRef = _db.collection(_collectionName).doc(track.id);
          batch.set(docRef, track.toMap());
        }
        await batch.commit();
        debugPrint('Successfully seeded ${defaults.length} achievement tracks');
      }
    } catch (e) {
      debugPrint('Failed to seed default achievement tracks: $e');
    }
  }

  Future<void> upsertTrack(TieredAchievement track) async {
    if (_cachedCatalog != null) {
      _cachedCatalog = List<TieredAchievement>.from(_cachedCatalog!);
      final index = _cachedCatalog!.indexWhere((t) => t.id == track.id);
      if (index >= 0) {
        _cachedCatalog![index] = track;
      } else {
        _cachedCatalog!.add(track);
      }
      if (!_catalogController.isClosed) {
        _catalogController.add(List.unmodifiable(_cachedCatalog!));
      }
      unawaited(_persistLocalCache(_cachedCatalog!));
    }

    if (!_isFirebaseAvailable) return;

    try {
      await _db
          .collection(_collectionName)
          .doc(track.id)
          .set(track.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error upserting achievement track ${track.id}: $e');
    }
  }

  Future<void> deleteTrack(String trackId) async {
    if (_cachedCatalog != null) {
      _cachedCatalog = List<TieredAchievement>.from(_cachedCatalog!);
      _cachedCatalog!.removeWhere((t) => t.id == trackId);
      if (!_catalogController.isClosed) {
        _catalogController.add(List.unmodifiable(_cachedCatalog!));
      }
      unawaited(_persistLocalCache(_cachedCatalog!));
    }

    if (!_isFirebaseAvailable) return;

    try {
      await _db.collection(_collectionName).doc(trackId).delete();
    } catch (e) {
      debugPrint('Error deleting achievement track $trackId: $e');
    }
  }

  Future<void> _persistLocalCache(List<TieredAchievement> tracks) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
      final jsonList = tracks.map((t) => t.toMap()).toList();
      await prefs.setString(_localCacheKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Failed to cache achievement tracks locally: $e');
    }
  }

  Future<List<TieredAchievement>> _loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
      final raw = prefs.getString(_localCacheKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((e) => TieredAchievement.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to read local achievement tracks cache: $e');
    }
    return [];
  }

  @visibleForTesting
  void resetCache() {
    _cachedCatalog = null;
  }
}

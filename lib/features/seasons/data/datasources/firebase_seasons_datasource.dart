import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/season_period.dart';
import '../../domain/entities/season_prestige_record.dart';

class FirebaseSeasonsDataSource {
  static final FirebaseSeasonsDataSource instance =
      FirebaseSeasonsDataSource._internal();

  FirebaseFirestore? _firestore;
  final StreamController<SeasonPeriod> _seasonController =
      StreamController<SeasonPeriod>.broadcast();

  SeasonPeriod? _cachedSeason;

  static const String _collectionName = 'seasons';
  static const String _activeDocId = 'active_season';
  static const String _localSeasonCacheKey = 'pokeiring_active_season_v1';

  factory FirebaseSeasonsDataSource({FirebaseFirestore? firestore}) {
    if (firestore != null) {
      return FirebaseSeasonsDataSource._internal(firestore);
    }
    return instance;
  }

  FirebaseSeasonsDataSource._internal([this._firestore]);

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Stream<SeasonPeriod> watchActiveSeason() {
    _startWatchingActiveSeason();
    return _seasonController.stream;
  }

  void _startWatchingActiveSeason() {
    if (_isFirebaseAvailable) {
      try {
        _db
            .collection(_collectionName)
            .doc(_activeDocId)
            .snapshots()
            .listen(
              (doc) {
                if (doc.exists && doc.data() != null) {
                  final season = SeasonPeriod.fromMap(doc.data()!);
                  _cachedSeason = season;
                  unawaited(_persistLocalCache(season));
                  if (!_seasonController.isClosed) {
                    _seasonController.add(season);
                  }
                } else {
                  seedActiveSeasonIfEmpty();
                }
              },
              onError: (err) {
                debugPrint('Firestore seasons stream error: $err');
                _emitFallbackSeason();
              },
            );
        return;
      } catch (e) {
        debugPrint('Failed to attach Firestore seasons stream: $e');
      }
    }

    _emitFallbackSeason();
  }

  Future<void> _emitFallbackSeason() async {
    final season = await getActiveSeason();
    if (!_seasonController.isClosed) {
      _seasonController.add(season);
    }
  }

  Future<SeasonPeriod> getActiveSeason() async {
    if (_cachedSeason != null) return _cachedSeason!;

    final localCached = await _loadLocalCache();
    if (localCached != null) {
      _cachedSeason = localCached;
    }

    if (_isFirebaseAvailable) {
      try {
        final doc = await _db
            .collection(_collectionName)
            .doc(_activeDocId)
            .get()
            .timeout(const Duration(milliseconds: 1500));

        if (doc.exists && doc.data() != null) {
          final season = SeasonPeriod.fromMap(doc.data()!);
          _cachedSeason = season;
          unawaited(_persistLocalCache(season));
          return season;
        } else {
          await seedActiveSeasonIfEmpty();
        }
      } catch (e) {
        debugPrint(
          'Firestore fetch active season error ($e), fallback to cached/default',
        );
      }
    }

    if (_cachedSeason != null) return _cachedSeason!;

    _cachedSeason = SeasonPeriod.defaultSeason1();
    return _cachedSeason!;
  }

  Future<void> seedActiveSeasonIfEmpty() async {
    if (!_isFirebaseAvailable) return;

    try {
      final docRef = _db.collection(_collectionName).doc(_activeDocId);
      final doc = await docRef.get();
      if (!doc.exists) {
        debugPrint('Seeding active season to Firestore...');
        final s1 = SeasonPeriod.defaultSeason1();
        await docRef.set(s1.toMap(), SetOptions(merge: true));
        debugPrint('Successfully seeded active season');
      }
    } catch (e) {
      debugPrint('Failed to seed active season: $e');
    }
  }

  Future<void> updateActiveSeason(SeasonPeriod season) async {
    _cachedSeason = season;
    if (!_seasonController.isClosed) {
      _seasonController.add(season);
    }
    unawaited(_persistLocalCache(season));

    if (!_isFirebaseAvailable) return;

    try {
      await _db
          .collection(_collectionName)
          .doc(_activeDocId)
          .set(season.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating active season: $e');
    }
  }

  Future<int?> fetchUserPrestige(String userId) async {
    if (!_isFirebaseAvailable) return null;

    try {
      final doc = await _db
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(milliseconds: 1500));
      if (doc.exists) {
        return (doc.data()?['mythicPrestige'] as num?)?.toInt();
      }
    } catch (e) {
      debugPrint('Error fetching user prestige from Firestore: $e');
    }
    return null;
  }

  Future<void> syncUserPrestige(String userId, int prestige) async {
    if (!_isFirebaseAvailable) return;

    try {
      await _db.collection('users').doc(userId).set({
        'mythicPrestige': prestige,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncing user prestige to Firestore: $e');
    }
  }

  Future<List<SeasonPrestigeRecord>?> fetchUserSeasonHistory(
    String userId,
  ) async {
    if (!_isFirebaseAvailable) return null;

    try {
      final doc = await _db
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(milliseconds: 1500));
      if (doc.exists) {
        final raw = doc.data()?['seasonHistory'] as List<dynamic>?;
        if (raw != null) {
          return raw
              .map(
                (r) => SeasonPrestigeRecord.fromMap(r as Map<String, dynamic>),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching user season history from Firestore: $e');
    }
    return null;
  }

  Future<void> syncUserSeasonHistory(
    String userId,
    List<SeasonPrestigeRecord> history,
  ) async {
    if (!_isFirebaseAvailable) return;

    try {
      final serialized = history.map((r) => r.toMap()).toList();
      await _db.collection('users').doc(userId).set({
        'seasonHistory': serialized,
        'completedSeasonsCount': history.length,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncing user season history to Firestore: $e');
    }
  }

  Future<void> _persistLocalCache(SeasonPeriod season) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
      await prefs.setString(_localSeasonCacheKey, jsonEncode(season.toMap()));
    } catch (e) {
      debugPrint('Failed to cache season locally: $e');
    }
  }

  Future<SeasonPeriod?> _loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
      final raw = prefs.getString(_localSeasonCacheKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return SeasonPeriod.fromMap(decoded);
      }
    } catch (e) {
      debugPrint('Failed to read local season cache: $e');
    }
    return null;
  }

  @visibleForTesting
  void resetCache() {
    _cachedSeason = null;
  }
}

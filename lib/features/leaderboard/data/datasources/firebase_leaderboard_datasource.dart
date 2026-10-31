import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/leaderboard_entry.dart';
import 'mock_leaderboard_datasource.dart';

class FirebaseLeaderboardDataSource {
  static final FirebaseLeaderboardDataSource instance =
      FirebaseLeaderboardDataSource._internal();

  FirebaseFirestore? _firestore;
  final MockLeaderboardDatasource _mockDatasource =
      const MockLeaderboardDatasource();

  List<LeaderboardEntry>? _cachedEntries;

  static const String _collectionName = 'users';
  static const String _localCacheKey = 'pokeiring_leaderboard_cache_v1';

  factory FirebaseLeaderboardDataSource({FirebaseFirestore? firestore}) {
    if (firestore != null) {
      return FirebaseLeaderboardDataSource._internal(firestore);
    }
    return instance;
  }

  FirebaseLeaderboardDataSource._internal([this._firestore]);

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Stream<List<LeaderboardEntry>> watchEntries({String? currentUserId}) {
    if (_isFirebaseAvailable) {
      try {
        return _db
            .collection(_collectionName)
            .snapshots()
            .map((snapshot) {
              if (snapshot.docs.isNotEmpty) {
                final entries = snapshot.docs.map((doc) {
                  return LeaderboardEntry.fromFirestore(
                    doc.id,
                    doc.data(),
                    currentUserId: currentUserId,
                  );
                }).toList();

                _cachedEntries = entries;
                unawaited(_persistLocalCache(entries));
                return entries;
              }
              return _getFallbackEntries(currentUserId);
            })
            .handleError((err) {
              debugPrint('Firestore leaderboard stream error: $err');
              return _getFallbackEntries(currentUserId);
            });
      } catch (e) {
        debugPrint('Failed to attach Firestore leaderboard stream: $e');
      }
    }

    return Stream.value(_getFallbackEntries(currentUserId));
  }

  Future<List<LeaderboardEntry>> fetchEntries({String? currentUserId}) async {
    if (_cachedEntries != null && _cachedEntries!.isNotEmpty) {
      return _markCurrentUser(_cachedEntries!, currentUserId);
    }

    final localCached = await _loadLocalCache();
    if (localCached.isNotEmpty) {
      _cachedEntries = localCached;
    }

    if (_isFirebaseAvailable) {
      try {
        final snapshot = await _db
            .collection(_collectionName)
            .limit(100)
            .get()
            .timeout(const Duration(milliseconds: 1500));
        if (snapshot.docs.isNotEmpty) {
          final entries = snapshot.docs.map((doc) {
            return LeaderboardEntry.fromFirestore(
              doc.id,
              doc.data(),
              currentUserId: currentUserId,
            );
          }).toList();

          _cachedEntries = entries;
          unawaited(_persistLocalCache(entries));
          return entries;
        } else {
          await seedDefaultUsersIfEmpty();
        }
      } catch (e) {
        debugPrint(
          'Firestore fetch users error ($e), fallback to cached/seeds',
        );
      }
    }

    if (_cachedEntries != null && _cachedEntries!.isNotEmpty) {
      return _markCurrentUser(_cachedEntries!, currentUserId);
    }

    return _getFallbackEntries(currentUserId);
  }

  Future<void> seedDefaultUsersIfEmpty() async {
    if (!_isFirebaseAvailable) return;

    try {
      final snapshot = await _db.collection(_collectionName).limit(1).get();
      if (snapshot.docs.isEmpty) {
        debugPrint('Seeding default leaderboard users to Firestore...');
        final seeds = _mockDatasource.getSeedEntries();
        final batch = _db.batch();

        for (final seed in seeds) {
          final docRef = _db.collection(_collectionName).doc(seed.userId);
          batch.set(docRef, {
            'displayName': seed.displayName,
            'avatarColorIndex': seed.avatarColorIndex,
            'totalPawPoints': seed.points,
            'totalSnaps': seed.catsSnapped,
            'distanceKm': seed.distanceKm,
            'mythicPaws': seed.mythicPaws,
            'barangay': seed.barangay,
            'city': seed.city,
            'region': seed.region,
            'country': seed.country,
            'territory': {
              'barangay': seed.barangay,
              'city': seed.city,
              'region': seed.region,
              'country': seed.country,
            },
          });
        }

        await batch.commit();
        debugPrint('Successfully seeded ${seeds.length} leaderboard users');
      }
    } catch (e) {
      debugPrint('Failed to seed default leaderboard users: $e');
    }
  }

  List<LeaderboardEntry> _getFallbackEntries(String? currentUserId) {
    final seeds = _mockDatasource.getSeedEntries();
    return _markCurrentUser(seeds, currentUserId);
  }

  List<LeaderboardEntry> _markCurrentUser(
    List<LeaderboardEntry> entries,
    String? currentUserId,
  ) {
    if (currentUserId == null || currentUserId.isEmpty) return entries;
    return entries.map((e) {
      final isCurrent = e.userId == currentUserId;
      if (e.isCurrentUser == isCurrent) return e;
      return e.copyWith(isCurrentUser: isCurrent);
    }).toList();
  }

  Future<void> _persistLocalCache(List<LeaderboardEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = entries.map((e) => e.toMap()).toList();
      await prefs.setString(_localCacheKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Failed to cache leaderboard locally: $e');
    }
  }

  Future<List<LeaderboardEntry>> _loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
      final raw = prefs.getString(_localCacheKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((e) => LeaderboardEntry.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to read local leaderboard cache: $e');
    }
    return [];
  }

  @visibleForTesting
  void resetCache() {
    _cachedEntries = null;
  }
}

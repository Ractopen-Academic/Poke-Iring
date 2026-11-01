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
    if (_firestore != null) return true;
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool get isCloudConnected => _isFirebaseAvailable;

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
              _cachedEntries = const [];
              unawaited(_clearLocalCache());
              return const <LeaderboardEntry>[];
            })
            .handleError((err) {
              debugPrint('Firestore leaderboard stream error: $err');
              return _cachedEntries ?? const <LeaderboardEntry>[];
            });
      } catch (e) {
        debugPrint('Failed to attach Firestore leaderboard stream: $e');
      }
      return Stream.value(_cachedEntries ?? const <LeaderboardEntry>[]);
    }

    return Stream.value(_getFallbackEntries(currentUserId));
  }

  Future<List<LeaderboardEntry>> fetchEntries({String? currentUserId}) async {
    if (_isFirebaseAvailable) {
      try {
        final snapshot = await _db
            .collection(_collectionName)
            .limit(100)
            .get()
            .timeout(const Duration(milliseconds: 2000));
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
        _cachedEntries = const [];
        unawaited(_clearLocalCache());
        return const <LeaderboardEntry>[];
      } catch (e) {
        debugPrint('Firestore fetch users error ($e), reading local cache');
        final localCached = await _loadLocalCache();
        if (localCached.isNotEmpty) {
          _cachedEntries = localCached;
          return _markCurrentUser(localCached, currentUserId);
        }
        return _markCurrentUser(
          _cachedEntries ?? const <LeaderboardEntry>[],
          currentUserId,
        );
      }
    }

    if (_cachedEntries != null && _cachedEntries!.isNotEmpty) {
      return _markCurrentUser(_cachedEntries!, currentUserId);
    }

    final localCached = await _loadLocalCache();
    if (localCached.isNotEmpty) {
      _cachedEntries = localCached;
      return _markCurrentUser(localCached, currentUserId);
    }

    return _getFallbackEntries(currentUserId);
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

  Future<void> _clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localCacheKey);
    } catch (_) {}
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

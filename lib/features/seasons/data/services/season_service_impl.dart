import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/season_period.dart';
import '../../domain/entities/season_prestige_record.dart';
import '../../domain/services/season_service.dart';
import '../datasources/firebase_seasons_datasource.dart';

class SeasonServiceImpl implements SeasonService {
  static SeasonServiceImpl? _instance;
  static SeasonServiceImpl get instance => _instance ??= SeasonServiceImpl();

  final FirebaseSeasonsDataSource _dataSource;

  final StreamController<SeasonPeriod> _seasonController =
      StreamController<SeasonPeriod>.broadcast();
  final Map<String, StreamController<int>> _prestigeControllers = {};
  final Map<String, StreamController<List<SeasonPrestigeRecord>>>
  _historyControllers = {};

  final Map<String, int> _cachedPrestige = {};
  final Map<String, List<SeasonPrestigeRecord>> _cachedHistory = {};

  String _prestigePrefKey(String userId) => 'mythic_prestige_$userId';
  String _historyPrefKey(String userId) => 'season_history_$userId';

  SeasonServiceImpl({FirebaseSeasonsDataSource? dataSource})
    : _dataSource = dataSource ?? FirebaseSeasonsDataSource.instance {
    _dataSource.watchActiveSeason().listen((season) {
      if (!_seasonController.isClosed) {
        _seasonController.add(season);
      }
    });
  }

  @override
  Stream<SeasonPeriod> watchCurrentSeason() {
    _initSeasonIfNeeded();
    return _seasonController.stream;
  }

  Future<void> _initSeasonIfNeeded() async {
    final s = await getCurrentSeason();
    if (!_seasonController.isClosed) {
      _seasonController.add(s);
    }
  }

  @override
  Future<SeasonPeriod> getCurrentSeason() async {
    return _dataSource.getActiveSeason();
  }

  @override
  Stream<int> watchMythicPrestige(String userId) {
    if (!_prestigeControllers.containsKey(userId)) {
      _prestigeControllers[userId] = StreamController<int>.broadcast(
        onListen: () {
          getMythicPrestige(userId).then((pts) {
            if (_prestigeControllers[userId]?.isClosed == false) {
              _prestigeControllers[userId]?.add(pts);
            }
          });
        },
      );
    }
    return _prestigeControllers[userId]!.stream;
  }

  @override
  Future<int> getMythicPrestige(String userId) async {
    // 1. Online-First: Try fetching user prestige directly from Cloud Firestore
    final cloudPts = await _dataSource.fetchUserPrestige(userId);
    if (cloudPts != null) {
      _cachedPrestige[userId] = cloudPts;
      unawaited(_persistPrestigeLocally(userId, cloudPts));
      return cloudPts;
    }

    // 2. In-Memory Cache
    if (_cachedPrestige.containsKey(userId)) {
      return _cachedPrestige[userId]!;
    }

    // 3. Persistent Local Cache (SharedPreferences)
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
      final pts = prefs.getInt(_prestigePrefKey(userId));
      if (pts != null) {
        _cachedPrestige[userId] = pts;
        return pts;
      }
    } catch (_) {}

    // 4. Built-in Fallback (Clean install 0 prestige)
    _cachedPrestige[userId] = 0;
    return 0;
  }

  @override
  Stream<List<SeasonPrestigeRecord>> watchSeasonHistory(String userId) {
    if (!_historyControllers.containsKey(userId)) {
      _historyControllers[userId] =
          StreamController<List<SeasonPrestigeRecord>>.broadcast(
            onListen: () {
              getSeasonHistory(userId).then((list) {
                if (_historyControllers[userId]?.isClosed == false) {
                  _historyControllers[userId]?.add(list);
                }
              });
            },
          );
    }
    return _historyControllers[userId]!.stream;
  }

  @override
  Future<List<SeasonPrestigeRecord>> getSeasonHistory(String userId) async {
    // 1. Online-First: Try fetching season rollover history from Cloud Firestore
    final cloudHistory = await _dataSource.fetchUserSeasonHistory(userId);
    if (cloudHistory != null && cloudHistory.isNotEmpty) {
      _cachedHistory[userId] = cloudHistory;
      unawaited(_persistHistoryLocally(userId, cloudHistory));
      return cloudHistory;
    }

    // 2. In-Memory Cache
    if (_cachedHistory.containsKey(userId) &&
        _cachedHistory[userId]!.isNotEmpty) {
      return _cachedHistory[userId]!;
    }

    // 3. Persistent Local Cache (SharedPreferences)
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
      final rawList = prefs.getStringList(_historyPrefKey(userId));
      if (rawList != null && rawList.isNotEmpty) {
        final records = rawList.map((str) {
          final map = jsonDecode(str) as Map<String, dynamic>;
          return SeasonPrestigeRecord.fromMap(map);
        }).toList();
        _cachedHistory[userId] = records;
        return records;
      }
    } catch (_) {}

    // 4. Built-in Fallback (Clean install empty history)
    _cachedHistory[userId] = <SeasonPrestigeRecord>[];
    return _cachedHistory[userId]!;
  }

  @override
  int calculatePlacementPoints(int currentPoints) {
    if (currentPoints >= 3000) return 1200; // Division 4 floor
    if (currentPoints >= 1500) return 700; // Division 3 floor
    if (currentPoints >= 700) return 350; // Division 2 floor
    if (currentPoints >= 300) return 150; // Division 2 early
    if (currentPoints >= 100) return 50; // Division 1 mid
    return 0; // Division 1 fresh
  }

  String _placementDivisionLabel(int placementPoints) {
    if (placementPoints >= 1200) return 'Division 4: Feline Ranger';
    if (placementPoints >= 700) return 'Division 3: Whiskers Tracker';
    if (placementPoints >= 150) return 'Division 2: Alley Prowler';
    return 'Division 1: Sleepy Kitten';
  }

  @override
  SeasonPrestigeRecord calculateRollover({
    required String userId,
    required SeasonPeriod season,
    required int currentPoints,
    required int currentRank,
    required String divisionTitle,
  }) {
    int bonus = 50;
    SeasonTrophyCrest crest = SeasonTrophyCrest.participant;

    if (currentRank <= 3) {
      bonus = 1000;
      crest = SeasonTrophyCrest.goldMythic;
    } else if (currentRank <= 10) {
      bonus = 500;
      crest = SeasonTrophyCrest.silverMythic;
    } else if (currentRank <= 50) {
      bonus = 200;
      crest = SeasonTrophyCrest.bronzeMythic;
    }

    final placementPoints = calculatePlacementPoints(currentPoints);
    final placementLabel = _placementDivisionLabel(placementPoints);

    return SeasonPrestigeRecord(
      seasonId: season.id,
      seasonNumber: season.number,
      seasonTitle: season.title,
      finalPoints: currentPoints,
      finalRank: currentRank,
      finalDivision: divisionTitle,
      prestigeEarned: currentPoints + bonus,
      trophyCrest: crest,
      completedAt: DateTime.now(),
      startingPlacementDivision: placementLabel,
      startingPlacementPoints: placementPoints,
    );
  }

  @override
  Future<SeasonPrestigeRecord> completeSeasonRollover({
    required String userId,
    required int currentPoints,
    required int currentRank,
    required String divisionTitle,
  }) async {
    final season = await getCurrentSeason();
    final record = calculateRollover(
      userId: userId,
      season: season,
      currentPoints: currentPoints,
      currentRank: currentRank,
      divisionTitle: divisionTitle,
    );

    // 1. Update and persist Prestige
    final currentPrestige = await getMythicPrestige(userId);
    final newPrestige = currentPrestige + record.prestigeEarned;
    _cachedPrestige[userId] = newPrestige;

    // 2. Append to history
    final history = await getSeasonHistory(userId);
    final updatedHistory = [
      record,
      ...history.where((r) => r.seasonId != season.id),
    ];
    _cachedHistory[userId] = updatedHistory;

    unawaited(_persistPrestigeLocally(userId, newPrestige));
    unawaited(_persistHistoryLocally(userId, updatedHistory));

    // Cloud sync to Firestore
    unawaited(_dataSource.syncUserPrestige(userId, newPrestige));
    unawaited(_dataSource.syncUserSeasonHistory(userId, updatedHistory));

    // 3. Advance Season
    final nextNumber = season.number + 1;
    final now = DateTime.now();
    final nextSeason = SeasonPeriod(
      id: 'season_$nextNumber',
      number: nextNumber,
      title: 'Season $nextNumber: Monsoon Whiskers',
      description: 'Prowl sheltered alleys and discover rare felines during rainy season.',
      startsAt: now,
      endsAt: now.add(const Duration(days: 60)),
      status: SeasonStatus.active,
    );

    await _dataSource.updateActiveSeason(nextSeason);

    // 4. Notify streams
    if (_prestigeControllers[userId]?.isClosed == false) {
      _prestigeControllers[userId]?.add(newPrestige);
    }
    if (_historyControllers[userId]?.isClosed == false) {
      _historyControllers[userId]?.add(updatedHistory);
    }

    return record;
  }

  @override
  Future<void> simulateSeasonEnd() async {
    final current = await getCurrentSeason();
    final ended = current.copyWith(
      endsAt: DateTime.now().subtract(const Duration(minutes: 1)),
      status: SeasonStatus.completed,
    );
    await _dataSource.updateActiveSeason(ended);
  }

  @override
  Future<void> resetToSeason1() async {
    final s1 = SeasonPeriod.defaultSeason1();
    await _dataSource.updateActiveSeason(s1);
  }

  Future<void> _persistPrestigeLocally(String userId, int pts) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
      await prefs.setInt(_prestigePrefKey(userId), pts);
    } catch (_) {}
  }

  Future<void> _persistHistoryLocally(
    String userId,
    List<SeasonPrestigeRecord> history,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
      final rawHistory = history.map((r) => jsonEncode(r.toMap())).toList();
      await prefs.setStringList(_historyPrefKey(userId), rawHistory);
    } catch (_) {}
  }

  @visibleForTesting
  void resetLocalCache() {
    _cachedPrestige.clear();
    _cachedHistory.clear();
  }
}

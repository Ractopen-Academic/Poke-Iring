import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/season_period.dart';
import '../../domain/entities/season_prestige_record.dart';
import '../../domain/services/season_service.dart';

class SeasonServiceImpl implements SeasonService {
  static SeasonServiceImpl? _instance;
  static SeasonServiceImpl get instance => _instance ??= SeasonServiceImpl();

  final StreamController<SeasonPeriod> _seasonController =
      StreamController<SeasonPeriod>.broadcast();
  final Map<String, StreamController<int>> _prestigeControllers = {};
  final Map<String, StreamController<List<SeasonPrestigeRecord>>>
  _historyControllers = {};

  SeasonPeriod? _cachedSeason;
  final Map<String, int> _cachedPrestige = {};
  final Map<String, List<SeasonPrestigeRecord>> _cachedHistory = {};

  static const String _seasonPrefKey = 'active_season_period_v1';
  String _prestigePrefKey(String userId) => 'mythic_prestige_$userId';
  String _historyPrefKey(String userId) => 'season_history_$userId';

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
    if (_cachedSeason != null) return _cachedSeason!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_seasonPrefKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final season = SeasonPeriod.fromMap(decoded);
        _cachedSeason = season;
        return season;
      }
    } catch (_) {}

    final defaultSeason = SeasonPeriod.defaultSeason1();
    _cachedSeason = defaultSeason;
    return defaultSeason;
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
    if (_cachedPrestige.containsKey(userId)) {
      return _cachedPrestige[userId]!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final pts = prefs.getInt(_prestigePrefKey(userId)) ?? 0;
      _cachedPrestige.putIfAbsent(userId, () => pts);
      return _cachedPrestige[userId]!;
    } catch (_) {}

    _cachedPrestige.putIfAbsent(userId, () => 0);
    return _cachedPrestige[userId]!;
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
    if (_cachedHistory.containsKey(userId)) {
      return _cachedHistory[userId]!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_historyPrefKey(userId));
      if (rawList != null) {
        final records = rawList.map((str) {
          final map = jsonDecode(str) as Map<String, dynamic>;
          return SeasonPrestigeRecord.fromMap(map);
        }).toList();
        _cachedHistory.putIfAbsent(userId, () => records);
        return _cachedHistory[userId]!;
      }
    } catch (_) {}

    _cachedHistory.putIfAbsent(userId, () => <SeasonPrestigeRecord>[]);
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

    if (currentRank > 0 && currentRank <= 3) {
      bonus = 1000;
      crest = SeasonTrophyCrest.goldMythic;
    } else if ((currentRank > 0 && currentRank <= 10) ||
        currentPoints >= 3000) {
      bonus = 500;
      crest = SeasonTrophyCrest.silverMythic;
    } else if ((currentRank > 0 && currentRank <= 25) || currentPoints >= 700) {
      bonus = 250;
      crest = SeasonTrophyCrest.bronzeMythic;
    }

    final totalPrestige = currentPoints + bonus;
    final placementPts = calculatePlacementPoints(currentPoints);

    return SeasonPrestigeRecord(
      seasonId: season.id,
      seasonNumber: season.number,
      seasonTitle: season.title,
      finalPoints: currentPoints,
      finalRank: currentRank,
      finalDivision: divisionTitle,
      prestigeEarned: totalPrestige,
      trophyCrest: crest,
      completedAt: DateTime.now(),
      startingPlacementDivision: _placementDivisionLabel(placementPts),
      startingPlacementPoints: placementPts,
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

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prestigePrefKey(userId), newPrestige);
      final rawHistory = updatedHistory
          .map((r) => jsonEncode(r.toMap()))
          .toList();
      await prefs.setStringList(_historyPrefKey(userId), rawHistory);
    } catch (_) {}

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

    _cachedSeason = nextSeason;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_seasonPrefKey, jsonEncode(nextSeason.toMap()));
    } catch (_) {}

    // 4. Notify streams
    if (!_seasonController.isClosed) {
      _seasonController.add(nextSeason);
    }
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
    _cachedSeason = ended;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_seasonPrefKey, jsonEncode(ended.toMap()));
    } catch (_) {}

    if (!_seasonController.isClosed) {
      _seasonController.add(ended);
    }
  }

  @override
  Future<void> resetToSeason1() async {
    final s1 = SeasonPeriod.defaultSeason1();
    _cachedSeason = s1;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_seasonPrefKey, jsonEncode(s1.toMap()));
    } catch (_) {}

    if (!_seasonController.isClosed) {
      _seasonController.add(s1);
    }
  }
}

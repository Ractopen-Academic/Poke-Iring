import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../achievements/data/repositories/achievements_repository_impl.dart';
import '../../../health/services/explorer_health_service.dart';
import '../../domain/entities/paw_quest.dart';
import '../../domain/repositories/paw_quests_repository.dart';

class PawQuestsRepositoryImpl implements PawQuestsRepository {
  static final PawQuestsRepositoryImpl _instance =
      PawQuestsRepositoryImpl._internal();

  static PawQuestsRepositoryImpl get instance => _instance;

  final FirebaseFirestore? _firestore;
  StreamSubscription<ExplorerHealthSnapshot>? _healthSubscription;

  final Map<String, StreamController<List<PawQuest>>> _userControllers = {};

  factory PawQuestsRepositoryImpl({FirebaseFirestore? firestore}) {
    if (firestore != null) {
      return PawQuestsRepositoryImpl._internal(firestore);
    }
    return _instance;
  }

  PawQuestsRepositoryImpl._internal([this._firestore]);

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<List<PawQuest>> watchQuests(String userId) {
    if (!_userControllers.containsKey(userId)) {
      _userControllers[userId] = StreamController<List<PawQuest>>.broadcast();
    }

    _listenToHealthService(userId);
    _emitQuests(userId);

    return _userControllers[userId]!.stream;
  }

  void _listenToHealthService(String userId) {
    _healthSubscription?.cancel();
    _healthSubscription = ExplorerHealthService.instance.stream.listen((snap) {
      syncHealthProgress(
        userId: userId,
        stepsToday: snap.stepsToday,
        distanceKm: snap.distanceKm,
      );
    });

    final latest = ExplorerHealthService.instance.latest;
    if (latest.stepsToday > 0 || latest.distanceKm > 0) {
      syncHealthProgress(
        userId: userId,
        stepsToday: latest.stepsToday,
        distanceKm: latest.distanceKm,
      );
    }
  }

  Future<void> _emitQuests(String userId) async {
    try {
      final quests = await _generateQuests(userId);
      final controller = _userControllers[userId];
      if (controller != null && !controller.isClosed) {
        controller.add(quests);
      }
    } catch (e) {
      debugPrint('Error generating quests: $e');
    }
  }

  Future<List<PawQuest>> _generateQuests(String userId) async {
    final now = DateTime.now();
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {}

    // 1. Midnight expiration for daily quests
    final midnightToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final dateKey =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    // 2. Sunday midnight expiration for weekly quests
    final daysUntilSunday = DateTime.sunday - now.weekday;
    final sundayMidnight = DateTime(
      now.year,
      now.month,
      now.day + daysUntilSunday,
      23,
      59,
      59,
    );
    final weekNumber = ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7)
        .ceil();
    final weekKey = '${now.year}_w$weekNumber';

    final dailyDefs = [
      _QuestDef(
        id: 'daily_steps_$dateKey',
        title: 'Morning Prowl',
        description: 'Walk 1,500 steps today to map neighborhood cat spots.',
        category: QuestCategory.daily,
        type: QuestType.steps,
        targetValue: 1500,
        rewardPawPoints: 40,
        expiresAt: midnightToday,
      ),
      _QuestDef(
        id: 'daily_dist_$dateKey',
        title: 'Cartographer Step',
        description: 'Cover 1.2 km exploring local feline territory.',
        category: QuestCategory.daily,
        type: QuestType.distance,
        targetValue: 1.2,
        rewardPawPoints: 60,
        expiresAt: midnightToday,
      ),
      _QuestDef(
        id: 'daily_bounty_$dateKey',
        title: 'Puspin Discovery',
        description: 'Photograph and catalog a native Puspin or Calico cat.',
        category: QuestCategory.daily,
        type: QuestType.scanBreed,
        targetValue: 1,
        rewardPawPoints: 50,
        expiresAt: midnightToday,
        targetBreed: 'Puspin',
      ),
    ];

    final weeklyDefs = [
      _QuestDef(
        id: 'weekly_steps_$weekKey',
        title: 'Territory Wanderer',
        description: 'Accumulate 10,000 steps during your weekly patrols.',
        category: QuestCategory.weekly,
        type: QuestType.steps,
        targetValue: 10000,
        rewardPawPoints: 200,
        expiresAt: sundayMidnight,
      ),
      _QuestDef(
        id: 'weekly_boop_$weekKey',
        title: 'Friendly Neighbor',
        description: 'Boop 5 community cat sighting pins on the live map.',
        category: QuestCategory.weekly,
        type: QuestType.boopSightings,
        targetValue: 5,
        rewardPawPoints: 150,
        expiresAt: sundayMidnight,
      ),
    ];

    final allDefs = [...dailyDefs, ...weeklyDefs];
    final quests = <PawQuest>[];

    for (final def in allDefs) {
      final progressKey = 'quest_progress_${userId}_${def.id}';
      final claimedKey = 'quest_claimed_${userId}_${def.id}';

      final progress = prefs?.getDouble(progressKey) ?? 0.0;
      final isClaimed = prefs?.getBool(claimedKey) ?? false;

      quests.add(
        PawQuest(
          id: def.id,
          title: def.title,
          description: def.description,
          category: def.category,
          type: def.type,
          targetValue: def.targetValue,
          currentValue: progress,
          rewardPawPoints: def.rewardPawPoints,
          isClaimed: isClaimed,
          expiresAt: def.expiresAt,
          targetBreed: def.targetBreed,
        ),
      );
    }

    return quests;
  }

  @override
  Future<void> syncHealthProgress({
    required String userId,
    required int stepsToday,
    required double distanceKm,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final dateKey =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final weekNumber = ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7)
          .ceil();
      final weekKey = '${now.year}_w$weekNumber';

      // Daily Steps
      await prefs.setDouble(
        'quest_progress_${userId}_daily_steps_$dateKey',
        stepsToday.toDouble(),
      );
      // Daily Distance
      await prefs.setDouble(
        'quest_progress_${userId}_daily_dist_$dateKey',
        distanceKm,
      );

      // Weekly Steps (capped at stepsToday if local mock, or cumulative)
      final weeklyKey = 'quest_progress_${userId}_weekly_steps_$weekKey';
      final currentWeekly = prefs.getDouble(weeklyKey) ?? 0.0;
      if (stepsToday.toDouble() > currentWeekly) {
        await prefs.setDouble(weeklyKey, stepsToday.toDouble());
      }

      await _emitQuests(userId);
    } catch (_) {}
  }

  @override
  Future<void> recordCatScan({
    required String userId,
    required String breed,
    required DateTime timestamp,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey =
          '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}';
      final bountyKey = 'quest_progress_${userId}_daily_bounty_$dateKey';

      final current = prefs.getDouble(bountyKey) ?? 0.0;
      await prefs.setDouble(bountyKey, current + 1.0);

      await _emitQuests(userId);
    } catch (_) {}
  }

  @override
  Future<void> recordBoop({required String userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final weekNumber = ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7)
          .ceil();
      final weekKey = '${now.year}_w$weekNumber';
      final boopKey = 'quest_progress_${userId}_weekly_boop_$weekKey';

      final current = prefs.getDouble(boopKey) ?? 0.0;
      await prefs.setDouble(boopKey, current + 1.0);

      await _emitQuests(userId);
    } catch (_) {}
  }

  @override
  Future<int> claimReward({
    required String userId,
    required String questId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final claimedKey = 'quest_claimed_${userId}_$questId';

    final isAlreadyClaimed = prefs.getBool(claimedKey) ?? false;
    if (isAlreadyClaimed) {
      return 0;
    }

    final quests = await _generateQuests(userId);
    final quest = quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw ArgumentError('Quest not found: $questId'),
    );

    if (!quest.isCompleted) {
      return 0;
    }

    // 1. Mark claimed locally
    await prefs.setBool(claimedKey, true);

    unawaited(
      AchievementsRepositoryImpl.instance.recordProgressMetric(
        userId: userId,
        metricKey: 'mastery_quests_claimed',
        incrementBy: 1,
      ),
    );
    unawaited(
      AchievementsRepositoryImpl.instance.recordProgressMetric(
        userId: userId,
        metricKey: 'mastery_paw_points',
        incrementBy: quest.rewardPawPoints.toDouble(),
      ),
    );

    // 2. Increment user total Paw Points in Firestore if available
    if (_isFirebaseAvailable) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db.collection('users').doc(userId).set({
          'totalPawPoints': FieldValue.increment(quest.rewardPawPoints),
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firebase claimReward error ($e). Claimed locally.');
      }
    }

    await _emitQuests(userId);
    return quest.rewardPawPoints;
  }
}

class _QuestDef {
  final String id;
  final String title;
  final String description;
  final QuestCategory category;
  final QuestType type;
  final double targetValue;
  final int rewardPawPoints;
  final DateTime expiresAt;
  final String? targetBreed;

  const _QuestDef({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.targetValue,
    required this.rewardPawPoints,
    required this.expiresAt,
    this.targetBreed,
  });
}

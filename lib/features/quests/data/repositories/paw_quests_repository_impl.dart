import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../achievements/data/repositories/achievements_repository_impl.dart';
import '../../../health/services/explorer_health_service.dart';
import '../../domain/entities/paw_quest.dart';
import '../../domain/entities/quest_template.dart';
import '../../domain/repositories/paw_quests_repository.dart';
import '../datasources/firebase_quest_datasource.dart';

class PawQuestsRepositoryImpl implements PawQuestsRepository {
  static final PawQuestsRepositoryImpl _instance =
      PawQuestsRepositoryImpl._internal();

  static PawQuestsRepositoryImpl get instance => _instance;

  final FirebaseFirestore? _firestore;
  final FirebaseQuestDataSource _questDataSource;
  StreamSubscription<ExplorerHealthSnapshot>? _healthSubscription;

  final Map<String, StreamController<List<PawQuest>>> _userControllers = {};

  factory PawQuestsRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseQuestDataSource? questDataSource,
  }) {
    if (firestore != null || questDataSource != null) {
      return PawQuestsRepositoryImpl._internal(firestore, questDataSource);
    }
    return _instance;
  }

  PawQuestsRepositoryImpl._internal([
    this._firestore,
    FirebaseQuestDataSource? questDataSource,
  ]) : _questDataSource = questDataSource ?? FirebaseQuestDataSource.instance {
    _questDataSource.watchQuestPool().listen((_) {
      for (final uid in _userControllers.keys) {
        _emitQuests(uid);
      }
    });
  }

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

    // 1. Fetch active pool from datasource
    final pool = await _questDataSource.getQuestPool();
    final activeTemplates = pool.where((t) => t.isActive).toList();
    final effectivePool = activeTemplates.isNotEmpty
        ? activeTemplates
        : QuestTemplate.defaultCatalog();

    // 2. Midnight expiration for daily quests
    final midnightToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final dateKey =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    // 3. Sunday midnight expiration for weekly quests
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

    // Seeded selection for daily quests
    final activeDaily = effectivePool
        .where((t) => t.category == QuestCategory.daily)
        .toList();
    final dailyRandom = Random(dateKey.hashCode);
    activeDaily.shuffle(dailyRandom);

    final stepsTpl = activeDaily.firstWhere(
      (t) => t.type == QuestType.steps,
      orElse: () => QuestTemplate.defaultCatalog()[0],
    );
    final distTpl = activeDaily.firstWhere(
      (t) => t.type == QuestType.distance && t.id != stepsTpl.id,
      orElse: () => QuestTemplate.defaultCatalog()[3],
    );
    final encounterTpl = activeDaily.firstWhere(
      (t) => t.id != stepsTpl.id && t.id != distTpl.id,
      orElse: () => QuestTemplate.defaultCatalog()[6],
    );

    final selectedDaily = [stepsTpl, distTpl, encounterTpl];

    // Seeded selection for weekly quests
    final activeWeekly = effectivePool
        .where((t) => t.category == QuestCategory.weekly)
        .toList();
    final weeklyRandom = Random(weekKey.hashCode);
    activeWeekly.shuffle(weeklyRandom);
    final selectedWeekly = activeWeekly.take(2).toList();

    final quests = <PawQuest>[];

    // Build Daily Quests
    for (final tpl in selectedDaily) {
      final instanceId = '${tpl.id}_$dateKey';
      final legacyStepsKey = tpl.type == QuestType.steps
          ? 'daily_steps_$dateKey'
          : null;
      final legacyDistKey = tpl.type == QuestType.distance
          ? 'daily_dist_$dateKey'
          : null;
      final legacyBountyKey = tpl.type == QuestType.scanBreed
          ? 'daily_bounty_$dateKey'
          : null;

      final progress =
          prefs?.getDouble('quest_progress_${userId}_$instanceId') ??
          (legacyStepsKey != null
              ? prefs?.getDouble('quest_progress_${userId}_$legacyStepsKey')
              : null) ??
          (legacyDistKey != null
              ? prefs?.getDouble('quest_progress_${userId}_$legacyDistKey')
              : null) ??
          (legacyBountyKey != null
              ? prefs?.getDouble('quest_progress_${userId}_$legacyBountyKey')
              : null) ??
          0.0;

      final isClaimed =
          prefs?.getBool('quest_claimed_${userId}_$instanceId') ??
          (legacyStepsKey != null
              ? prefs?.getBool('quest_claimed_${userId}_$legacyStepsKey')
              : null) ??
          false;

      quests.add(
        PawQuest(
          id: instanceId,
          title: tpl.title,
          description: tpl.description,
          category: tpl.category,
          type: tpl.type,
          targetValue: tpl.targetValue,
          currentValue: progress,
          rewardPawPoints: tpl.rewardPawPoints,
          isClaimed: isClaimed,
          expiresAt: midnightToday,
          targetBreed: tpl.targetBreed,
        ),
      );
    }

    // Build Weekly Quests
    for (final tpl in selectedWeekly) {
      final instanceId = '${tpl.id}_$weekKey';
      final legacyStepsKey = tpl.type == QuestType.steps
          ? 'weekly_steps_$weekKey'
          : null;
      final legacyBoopKey = tpl.type == QuestType.boopSightings
          ? 'weekly_boop_$weekKey'
          : null;

      final progress =
          prefs?.getDouble('quest_progress_${userId}_$instanceId') ??
          (legacyStepsKey != null
              ? prefs?.getDouble('quest_progress_${userId}_$legacyStepsKey')
              : null) ??
          (legacyBoopKey != null
              ? prefs?.getDouble('quest_progress_${userId}_$legacyBoopKey')
              : null) ??
          0.0;

      final isClaimed =
          prefs?.getBool('quest_claimed_${userId}_$instanceId') ??
          (legacyStepsKey != null
              ? prefs?.getBool('quest_claimed_${userId}_$legacyStepsKey')
              : null) ??
          false;

      quests.add(
        PawQuest(
          id: instanceId,
          title: tpl.title,
          description: tpl.description,
          category: tpl.category,
          type: tpl.type,
          targetValue: tpl.targetValue,
          currentValue: progress,
          rewardPawPoints: tpl.rewardPawPoints,
          isClaimed: isClaimed,
          expiresAt: sundayMidnight,
          targetBreed: tpl.targetBreed,
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

      // Weekly Steps
      final weeklyKey = 'quest_progress_${userId}_weekly_steps_$weekKey';
      final currentWeekly = prefs.getDouble(weeklyKey) ?? 0.0;
      if (stepsToday.toDouble() > currentWeekly) {
        await prefs.setDouble(weeklyKey, stepsToday.toDouble());
      }

      // Also update matching quest instances
      final quests = await _generateQuests(userId);
      for (final q in quests) {
        if (q.category == QuestCategory.daily && q.type == QuestType.steps) {
          await prefs.setDouble(
            'quest_progress_${userId}_${q.id}',
            stepsToday.toDouble(),
          );
        } else if (q.category == QuestCategory.daily &&
            q.type == QuestType.distance) {
          await prefs.setDouble('quest_progress_${userId}_${q.id}', distanceKm);
        } else if (q.category == QuestCategory.weekly &&
            q.type == QuestType.steps) {
          final cur =
              prefs.getDouble('quest_progress_${userId}_${q.id}') ?? 0.0;
          if (stepsToday.toDouble() > cur) {
            await prefs.setDouble(
              'quest_progress_${userId}_${q.id}',
              stepsToday.toDouble(),
            );
          }
        }
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

      final quests = await _generateQuests(userId);
      for (final q in quests) {
        if (q.type == QuestType.scanBreed || q.type == QuestType.scanCat) {
          if (q.targetBreed == null ||
              q.targetBreed!.toLowerCase() == breed.toLowerCase() ||
              breed.toLowerCase().contains(q.targetBreed!.toLowerCase())) {
            final cur =
                prefs.getDouble('quest_progress_${userId}_${q.id}') ?? 0.0;
            await prefs.setDouble(
              'quest_progress_${userId}_${q.id}',
              cur + 1.0,
            );
          }
        }
      }

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

      final quests = await _generateQuests(userId);
      for (final q in quests) {
        if (q.type == QuestType.boopSightings) {
          final cur =
              prefs.getDouble('quest_progress_${userId}_${q.id}') ?? 0.0;
          await prefs.setDouble('quest_progress_${userId}_${q.id}', cur + 1.0);
        }
      }

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
      (q) =>
          q.id == questId ||
          (questId.startsWith('daily_steps_') &&
              q.category == QuestCategory.daily &&
              q.type == QuestType.steps) ||
          (questId.startsWith('daily_dist_') &&
              q.category == QuestCategory.daily &&
              q.type == QuestType.distance) ||
          (questId.startsWith('weekly_steps_') &&
              q.category == QuestCategory.weekly &&
              q.type == QuestType.steps),
      orElse: () => throw ArgumentError('Quest not found: $questId'),
    );

    if (!quest.isCompleted) {
      return 0;
    }

    // 1. Mark claimed locally
    await prefs.setBool(claimedKey, true);
    await prefs.setBool('quest_claimed_${userId}_${quest.id}', true);

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

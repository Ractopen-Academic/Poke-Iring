import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../health/services/explorer_health_service.dart';
import '../../domain/entities/achievement_tier.dart';
import '../../domain/entities/explorer_title.dart';
import '../../domain/entities/tiered_achievement.dart';
import '../../domain/repositories/achievements_repository.dart';
import '../datasources/firebase_achievements_datasource.dart';

class AchievementsRepositoryImpl implements AchievementsRepository {
  static final AchievementsRepositoryImpl _instance =
      AchievementsRepositoryImpl._internal();

  static AchievementsRepositoryImpl get instance => _instance;

  final FirebaseFirestore? _firestore;
  final FirebaseAchievementsDataSource _dataSource;
  StreamSubscription<ExplorerHealthSnapshot>? _healthSubscription;
  final Map<String, StreamSubscription<List<TieredAchievement>>>
  _catalogSubscriptions = {};

  final Map<String, StreamController<List<TieredAchievement>>>
  _achievementsControllers = {};
  final Map<String, StreamController<List<ExplorerTitle>>> _titlesControllers =
      {};
  final Map<String, StreamController<ExplorerTitle?>>
  _equippedTitleControllers = {};

  factory AchievementsRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAchievementsDataSource? dataSource,
  }) {
    if (firestore != null || dataSource != null) {
      return AchievementsRepositoryImpl._internal(firestore, dataSource);
    }
    return _instance;
  }

  AchievementsRepositoryImpl._internal([
    this._firestore,
    FirebaseAchievementsDataSource? dataSource,
  ]) : _dataSource = dataSource ?? FirebaseAchievementsDataSource.instance;

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<List<TieredAchievement>> watchAchievements(String userId) {
    if (!_achievementsControllers.containsKey(userId)) {
      _achievementsControllers[userId] =
          StreamController<List<TieredAchievement>>.broadcast();
    }

    _listenToHealthService(userId);
    _listenToCatalogUpdates(userId);
    _emitState(userId);

    return _achievementsControllers[userId]!.stream;
  }

  void _listenToCatalogUpdates(String userId) {
    _catalogSubscriptions[userId]?.cancel();
    _catalogSubscriptions[userId] = _dataSource.watchCatalog().listen((_) {
      _emitState(userId);
    });
  }

  @override
  Stream<List<ExplorerTitle>> watchTitles(String userId) {
    if (!_titlesControllers.containsKey(userId)) {
      _titlesControllers[userId] =
          StreamController<List<ExplorerTitle>>.broadcast();
    }
    _emitState(userId);
    return _titlesControllers[userId]!.stream;
  }

  @override
  Stream<ExplorerTitle?> watchEquippedTitle(String userId) {
    if (!_equippedTitleControllers.containsKey(userId)) {
      _equippedTitleControllers[userId] =
          StreamController<ExplorerTitle?>.broadcast();
    }
    _emitState(userId);
    return _equippedTitleControllers[userId]!.stream;
  }

  void _listenToHealthService(String userId) {
    _healthSubscription?.cancel();
    _healthSubscription = ExplorerHealthService.instance.stream.listen((
      snapshot,
    ) async {
      await setProgressMetric(
        userId: userId,
        metricKey: 'movement_steps',
        value: snapshot.stepsToday.toDouble(),
      );
      await setProgressMetric(
        userId: userId,
        metricKey: 'movement_distance',
        value: snapshot.distanceKm,
      );
      await setProgressMetric(
        userId: userId,
        metricKey: 'movement_calories',
        value: snapshot.caloriesBurned,
      );
    });
  }

  Future<void> _emitState(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
      final catalog = await _dataSource.getCatalog();

      final equippedTitleId =
          prefs.getString('user_equipped_title_$userId') ??
          'title_novice_scout';

      final List<TieredAchievement> updatedTracks = [];
      final List<ExplorerTitle> allTitles = [
        ExplorerTitle(
          id: 'title_novice_scout',
          name: 'Novice Scout',
          description: 'Initial title for beginning feline explorers.',
          rarity: TitleRarity.common,
          tier: AchievementTier.bronze,
          isEquipped: equippedTitleId == 'title_novice_scout',
          unlockedAt: DateTime(2026, 1, 1),
        ),
      ];

      for (final track in catalog) {
        final progressKey = 'achievement_progress_${userId}_${track.id}';
        final savedProgress = prefs.getDouble(progressKey) ?? 0.0;

        final updatedMilestones = track.milestones.map((milestone) {
          final claimedKey =
              'achievement_claimed_${userId}_${track.id}_${milestone.tier.name}';
          final isClaimed = prefs.getBool(claimedKey) ?? false;
          final isUnlocked = milestone.isUnlocked(savedProgress);

          if (milestone.rewardTitle != null) {
            allTitles.add(
              milestone.rewardTitle!.copyWith(
                unlockedAt: isUnlocked ? DateTime.now() : null,
                isEquipped: equippedTitleId == milestone.rewardTitle!.id,
              ),
            );
          }

          return milestone.copyWith(isClaimed: isClaimed);
        }).toList();

        updatedTracks.add(
          track.copyWith(
            currentProgress: savedProgress,
            milestones: updatedMilestones,
          ),
        );
      }

      // Check title unlock count to update mastery_titles_unlocked
      final unlockedTitlesCount = allTitles
          .where((t) => t.isUnlocked)
          .length
          .toDouble();
      final titlesProgressKey =
          'achievement_progress_${userId}_mastery_titles_unlocked';
      if ((prefs.getDouble(titlesProgressKey) ?? 0.0) < unlockedTitlesCount) {
        await prefs.setDouble(titlesProgressKey, unlockedTitlesCount);
      }

      if (_achievementsControllers.containsKey(userId) &&
          !_achievementsControllers[userId]!.isClosed) {
        _achievementsControllers[userId]!.add(updatedTracks);
      }

      if (_titlesControllers.containsKey(userId) &&
          !_titlesControllers[userId]!.isClosed) {
        _titlesControllers[userId]!.add(allTitles);
      }

      if (_equippedTitleControllers.containsKey(userId) &&
          !_equippedTitleControllers[userId]!.isClosed) {
        final equipped = allTitles.firstWhere(
          (t) => t.id == equippedTitleId,
          orElse: () => allTitles.first,
        );
        _equippedTitleControllers[userId]!.add(equipped);
      }
    } catch (e) {
      debugPrint('AchievementsRepositoryImpl emitState error: $e');
    }
  }

  @override
  Future<void> recordProgressMetric({
    required String userId,
    required String metricKey,
    required double incrementBy,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
      final progressKey = 'achievement_progress_${userId}_$metricKey';
      final current = prefs.getDouble(progressKey) ?? 0.0;
      await prefs.setDouble(progressKey, current + incrementBy);
      await _emitState(userId);
    } catch (_) {}
  }

  @override
  Future<void> setProgressMetric({
    required String userId,
    required String metricKey,
    required double value,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
      final progressKey = 'achievement_progress_${userId}_$metricKey';
      final current = prefs.getDouble(progressKey) ?? 0.0;
      if (value > current) {
        await prefs.setDouble(progressKey, value);
        await _emitState(userId);
      }
    } catch (_) {}
  }

  @override
  Future<int> claimMilestoneReward({
    required String userId,
    required String achievementId,
    required AchievementTier tier,
  }) async {
    final prefs = await SharedPreferences.getInstance().timeout(
      const Duration(milliseconds: 300),
    );
    final claimedKey =
        'achievement_claimed_${userId}_${achievementId}_${tier.name}';

    final isAlreadyClaimed = prefs.getBool(claimedKey) ?? false;
    if (isAlreadyClaimed) {
      return 0;
    }

    final catalog = await _dataSource.getCatalog();
    final track = catalog.firstWhere(
      (t) => t.id == achievementId,
      orElse: () => throw ArgumentError('Track not found: $achievementId'),
    );

    final progressKey = 'achievement_progress_${userId}_$achievementId';
    final currentProgress = prefs.getDouble(progressKey) ?? 0.0;

    final milestone = track.milestones.firstWhere(
      (m) => m.tier == tier,
      orElse: () => throw ArgumentError('Milestone tier not found: $tier'),
    );

    if (!milestone.isUnlocked(currentProgress)) {
      return 0;
    }

    // Mark claimed
    await prefs.setBool(claimedKey, true);

    // Sync Paw Points reward with Firestore if available
    if (_isFirebaseAvailable) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db.collection('users').doc(userId).set({
          'totalPawPoints': FieldValue.increment(milestone.rewardPawPoints),
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firebase claimMilestoneReward sync error: $e');
      }
    }

    await _emitState(userId);
    return milestone.rewardPawPoints;
  }

  @override
  Future<void> equipTitle({
    required String userId,
    required String titleId,
  }) async {
    final prefs = await SharedPreferences.getInstance().timeout(
      const Duration(milliseconds: 300),
    );
    await prefs.setString('user_equipped_title_$userId', titleId);

    if (_isFirebaseAvailable) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db.collection('users').doc(userId).set({
          'equippedTitleId': titleId,
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firebase equipTitle sync error: $e');
      }
    }

    await _emitState(userId);
  }

  @override
  Future<void> syncUserProgress(String userId) async {
    await _emitState(userId);
  }
}

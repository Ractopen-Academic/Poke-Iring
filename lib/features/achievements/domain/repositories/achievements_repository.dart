import '../entities/achievement_tier.dart';
import '../entities/explorer_title.dart';
import '../entities/tiered_achievement.dart';

abstract class AchievementsRepository {
  Stream<List<TieredAchievement>> watchAchievements(String userId);

  Stream<List<ExplorerTitle>> watchTitles(String userId);

  Stream<ExplorerTitle?> watchEquippedTitle(String userId);

  Future<int> claimMilestoneReward({
    required String userId,
    required String achievementId,
    required AchievementTier tier,
  });

  Future<void> equipTitle({required String userId, required String titleId});

  Future<void> recordProgressMetric({
    required String userId,
    required String metricKey,
    required double incrementBy,
  });

  Future<void> setProgressMetric({
    required String userId,
    required String metricKey,
    required double value,
  });

  Future<void> syncUserProgress(String userId);
}

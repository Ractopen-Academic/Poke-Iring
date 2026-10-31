import '../entities/season_period.dart';
import '../entities/season_prestige_record.dart';

abstract class SeasonService {
  Stream<SeasonPeriod> watchCurrentSeason();
  Future<SeasonPeriod> getCurrentSeason();

  Stream<int> watchMythicPrestige(String userId);
  Future<int> getMythicPrestige(String userId);

  Stream<List<SeasonPrestigeRecord>> watchSeasonHistory(String userId);
  Future<List<SeasonPrestigeRecord>> getSeasonHistory(String userId);

  int calculatePlacementPoints(int currentPoints);

  SeasonPrestigeRecord calculateRollover({
    required String userId,
    required SeasonPeriod season,
    required int currentPoints,
    required int currentRank,
    required String divisionTitle,
  });

  Future<SeasonPrestigeRecord> completeSeasonRollover({
    required String userId,
    required int currentPoints,
    required int currentRank,
    required String divisionTitle,
  });

  Future<void> simulateSeasonEnd();
  Future<void> resetToSeason1();
}

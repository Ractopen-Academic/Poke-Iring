import '../entities/paw_quest.dart';

abstract class PawQuestsRepository {
  Stream<List<PawQuest>> watchQuests(String userId);

  Future<void> syncHealthProgress({
    required String userId,
    required int stepsToday,
    required double distanceKm,
  });

  Future<void> recordCatScan({
    required String userId,
    required String breed,
    required DateTime timestamp,
  });

  Future<void> recordBoop({required String userId});

  Future<int> claimReward({required String userId, required String questId});
}

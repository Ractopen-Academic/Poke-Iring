import '../entities/leaderboard_entry.dart';
import '../entities/leaderboard_query.dart';

abstract class LeaderboardRepository {
  Future<List<LeaderboardEntry>> getLeaderboard({
    required LeaderboardFilter filter,
    required String currentUserId,
  });

  Future<LeaderboardEntry?> getUserStanding({
    required String userId,
    required LeaderboardFilter filter,
  });
}

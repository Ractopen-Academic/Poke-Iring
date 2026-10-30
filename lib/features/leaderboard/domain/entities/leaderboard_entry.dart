import 'leaderboard_query.dart';
import 'leaderboard_tier.dart';

class LeaderboardEntry {
  final String id;
  final int rank;
  final String userId;
  final String displayName;
  final int avatarColorIndex;
  final String barangay;
  final String city;
  final String country;
  final int points;
  final int catsSnapped;
  final double distanceKm;
  final int mythicPaws;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.id,
    required this.rank,
    required this.userId,
    required this.displayName,
    this.avatarColorIndex = 0,
    required this.barangay,
    required this.city,
    required this.country,
    required this.points,
    required this.catsSnapped,
    required this.distanceKm,
    this.mythicPaws = 0,
    this.isCurrentUser = false,
  });

  LeaderboardTier get tier => LeaderboardTier.fromPoints(points);

  double scoreForCategory(LeaderboardCategory category) {
    switch (category) {
      case LeaderboardCategory.overall:
        return points.toDouble();
      case LeaderboardCategory.snaps:
        return catsSnapped.toDouble();
      case LeaderboardCategory.distance:
        return distanceKm;
    }
  }

  String formattedScore(LeaderboardCategory category) {
    switch (category) {
      case LeaderboardCategory.overall:
        return '$points pts';
      case LeaderboardCategory.snaps:
        return '$catsSnapped cats';
      case LeaderboardCategory.distance:
        return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  LeaderboardEntry copyWith({
    String? id,
    int? rank,
    String? userId,
    String? displayName,
    int? avatarColorIndex,
    String? barangay,
    String? city,
    String? country,
    int? points,
    int? catsSnapped,
    double? distanceKm,
    int? mythicPaws,
    bool? isCurrentUser,
  }) {
    return LeaderboardEntry(
      id: id ?? this.id,
      rank: rank ?? this.rank,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarColorIndex: avatarColorIndex ?? this.avatarColorIndex,
      barangay: barangay ?? this.barangay,
      city: city ?? this.city,
      country: country ?? this.country,
      points: points ?? this.points,
      catsSnapped: catsSnapped ?? this.catsSnapped,
      distanceKm: distanceKm ?? this.distanceKm,
      mythicPaws: mythicPaws ?? this.mythicPaws,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}

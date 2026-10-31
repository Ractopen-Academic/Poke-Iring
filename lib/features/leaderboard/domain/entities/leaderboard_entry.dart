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
  final String region;
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
    this.region = 'Central Visayas',
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rank': rank,
      'userId': userId,
      'displayName': displayName,
      'avatarColorIndex': avatarColorIndex,
      'barangay': barangay,
      'city': city,
      'region': region,
      'country': country,
      'points': points,
      'catsSnapped': catsSnapped,
      'distanceKm': distanceKm,
      'mythicPaws': mythicPaws,
      'isCurrentUser': isCurrentUser,
    };
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      id: map['id'] as String? ?? '',
      rank: (map['rank'] as num?)?.toInt() ?? 0,
      userId: map['userId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Explorer',
      avatarColorIndex: (map['avatarColorIndex'] as num?)?.toInt() ?? 0,
      barangay: map['barangay'] as String? ?? '',
      city: map['city'] as String? ?? '',
      region: map['region'] as String? ?? 'Central Visayas',
      country: map['country'] as String? ?? 'Philippines',
      points: (map['points'] as num?)?.toInt() ?? 0,
      catsSnapped: (map['catsSnapped'] as num?)?.toInt() ?? 0,
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      mythicPaws: (map['mythicPaws'] as num?)?.toInt() ?? 0,
      isCurrentUser: map['isCurrentUser'] as bool? ?? false,
    );
  }

  factory LeaderboardEntry.fromFirestore(
    String id,
    Map<String, dynamic> data, {
    String? currentUserId,
  }) {
    final territory = data['territory'] as Map<String, dynamic>?;
    final barangay =
        (data['barangay'] as String?) ??
        (territory?['barangay'] as String?) ??
        'Bankal';
    final city =
        (data['city'] as String?) ??
        (territory?['city'] as String?) ??
        'Lapu-Lapu City';
    final region =
        (data['region'] as String?) ??
        (territory?['region'] as String?) ??
        'Central Visayas';
    final country =
        (data['country'] as String?) ??
        (territory?['country'] as String?) ??
        'Philippines';

    final points =
        (data['totalPawPoints'] as num?)?.toInt() ??
        (data['pawPoints'] as num?)?.toInt() ??
        0;
    final snaps =
        (data['totalSnaps'] as num?)?.toInt() ??
        (data['catsSnapped'] as num?)?.toInt() ??
        0;
    final distanceMeters =
        (data['totalDistanceMeters'] as num?)?.toDouble() ?? 0.0;
    final distanceKm =
        (data['distanceKm'] as num?)?.toDouble() ?? (distanceMeters / 1000.0);
    final mythicPaws = (data['mythicPaws'] as num?)?.toInt() ?? 0;
    final displayName =
        (data['displayName'] as String?) ??
        (data['name'] as String?) ??
        'Explorer ${id.substring(0, id.length > 5 ? 5 : id.length)}';

    return LeaderboardEntry(
      id: id,
      rank: 0,
      userId: id,
      displayName: displayName,
      avatarColorIndex: (data['avatarColorIndex'] as num?)?.toInt() ?? 0,
      barangay: barangay,
      city: city,
      region: region,
      country: country,
      points: points,
      catsSnapped: snaps,
      distanceKm: distanceKm,
      mythicPaws: mythicPaws,
      isCurrentUser: currentUserId != null && id == currentUserId,
    );
  }

  LeaderboardEntry copyWith({
    String? id,
    int? rank,
    String? userId,
    String? displayName,
    int? avatarColorIndex,
    String? barangay,
    String? city,
    String? region,
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
      region: region ?? this.region,
      country: country ?? this.country,
      points: points ?? this.points,
      catsSnapped: catsSnapped ?? this.catsSnapped,
      distanceKm: distanceKm ?? this.distanceKm,
      mythicPaws: mythicPaws ?? this.mythicPaws,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}

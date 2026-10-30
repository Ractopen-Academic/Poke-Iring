enum LeaderboardCategory {
  overall,
  snaps,
  distance;

  String get label {
    switch (this) {
      case LeaderboardCategory.overall:
        return 'Paw Points';
      case LeaderboardCategory.snaps:
        return 'Most Snapped';
      case LeaderboardCategory.distance:
        return 'Most Walked';
    }
  }
}

enum LeaderboardScope {
  barangay,
  city,
  region,
  national,
  global;

  String get label {
    switch (this) {
      case LeaderboardScope.barangay:
        return 'Barangay';
      case LeaderboardScope.city:
        return 'City';
      case LeaderboardScope.region:
        return 'Region';
      case LeaderboardScope.national:
        return 'National';
      case LeaderboardScope.global:
        return 'Global';
    }
  }

  int get poolCapacity {
    switch (this) {
      case LeaderboardScope.barangay:
        return 50;
      case LeaderboardScope.city:
        return 150;
      case LeaderboardScope.region:
        return 300;
      case LeaderboardScope.national:
        return 300;
      case LeaderboardScope.global:
        return 500;
    }
  }
}

class LeaderboardFilter {
  final LeaderboardCategory category;
  final LeaderboardScope scope;
  final String barangay;
  final String city;
  final String region;
  final String country;
  final int limit;
  final int offset;

  const LeaderboardFilter({
    this.category = LeaderboardCategory.overall,
    this.scope = LeaderboardScope.barangay,
    this.barangay = 'Bankal',
    this.city = 'Lapu-Lapu City',
    this.region = 'Central Visayas',
    this.country = 'Philippines',
    this.limit = 50,
    this.offset = 0,
  });

  LeaderboardFilter copyWith({
    LeaderboardCategory? category,
    LeaderboardScope? scope,
    String? barangay,
    String? city,
    String? region,
    String? country,
    int? limit,
    int? offset,
  }) {
    return LeaderboardFilter(
      category: category ?? this.category,
      scope: scope ?? this.scope,
      barangay: barangay ?? this.barangay,
      city: city ?? this.city,
      region: region ?? this.region,
      country: country ?? this.country,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}

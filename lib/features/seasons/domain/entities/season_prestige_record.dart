enum SeasonTrophyCrest {
  goldMythic,
  silverMythic,
  bronzeMythic,
  participant;

  String get label {
    switch (this) {
      case SeasonTrophyCrest.goldMythic:
        return 'Gold Mythic Paw';
      case SeasonTrophyCrest.silverMythic:
        return 'Silver Mythic Paw';
      case SeasonTrophyCrest.bronzeMythic:
        return 'Bronze Mythic Paw';
      case SeasonTrophyCrest.participant:
        return 'Stray Pioneer Ribbon';
    }
  }

  String get badgeAssetOrIcon {
    switch (this) {
      case SeasonTrophyCrest.goldMythic:
        return 'Gold Crest';
      case SeasonTrophyCrest.silverMythic:
        return 'Silver Crest';
      case SeasonTrophyCrest.bronzeMythic:
        return 'Bronze Crest';
      case SeasonTrophyCrest.participant:
        return 'Participant';
    }
  }
}

class SeasonPrestigeRecord {
  final String seasonId;
  final int seasonNumber;
  final String seasonTitle;
  final int finalPoints;
  final int finalRank;
  final String finalDivision;
  final int prestigeEarned;
  final SeasonTrophyCrest trophyCrest;
  final DateTime completedAt;
  final String startingPlacementDivision;
  final int startingPlacementPoints;

  const SeasonPrestigeRecord({
    required this.seasonId,
    required this.seasonNumber,
    required this.seasonTitle,
    required this.finalPoints,
    required this.finalRank,
    required this.finalDivision,
    required this.prestigeEarned,
    required this.trophyCrest,
    required this.completedAt,
    required this.startingPlacementDivision,
    required this.startingPlacementPoints,
  });

  Map<String, dynamic> toMap() {
    return {
      'seasonId': seasonId,
      'seasonNumber': seasonNumber,
      'seasonTitle': seasonTitle,
      'finalPoints': finalPoints,
      'finalRank': finalRank,
      'finalDivision': finalDivision,
      'prestigeEarned': prestigeEarned,
      'trophyCrest': trophyCrest.name,
      'completedAt': completedAt.toIso8601String(),
      'startingPlacementDivision': startingPlacementDivision,
      'startingPlacementPoints': startingPlacementPoints,
    };
  }

  factory SeasonPrestigeRecord.fromMap(Map<String, dynamic> map) {
    return SeasonPrestigeRecord(
      seasonId: map['seasonId'] as String? ?? 'season_1',
      seasonNumber: map['seasonNumber'] as int? ?? 1,
      seasonTitle: map['seasonTitle'] as String? ?? 'Season 1',
      finalPoints: map['finalPoints'] as int? ?? 0,
      finalRank: map['finalRank'] as int? ?? 0,
      finalDivision: map['finalDivision'] as String? ?? 'Division 1',
      prestigeEarned: map['prestigeEarned'] as int? ?? 0,
      trophyCrest: SeasonTrophyCrest.values.firstWhere(
        (c) => c.name == map['trophyCrest'],
        orElse: () => SeasonTrophyCrest.participant,
      ),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : DateTime.now(),
      startingPlacementDivision:
          map['startingPlacementDivision'] as String? ?? 'Division 1',
      startingPlacementPoints: map['startingPlacementPoints'] as int? ?? 0,
    );
  }
}

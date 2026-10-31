import '../../../scanner/domain/entities/cat_sighting.dart';

class ExplorerShowcaseProfile {
  static const int maxShowcaseSlots = 9;

  final String userId;
  final String displayName;
  final String avatarUrl;
  final int rank;
  final String tierTitle;
  final int pawPoints;
  final int dexDiscoveredCount;
  final int totalDexSpecies;
  final int totalBoops;
  final String territory;
  final bool isPublic;
  final int mythicPrestigePoints;
  final int completedSeasonsCount;
  final List<CatSighting> showcaseCards;

  const ExplorerShowcaseProfile({
    required this.userId,
    required this.displayName,
    this.avatarUrl = '',
    required this.rank,
    this.tierTitle = 'Scout',
    required this.pawPoints,
    this.dexDiscoveredCount = 0,
    this.totalDexSpecies = 16,
    this.totalBoops = 0,
    this.territory = 'Bankal, Lapu-Lapu City',
    this.isPublic = true,
    this.mythicPrestigePoints = 0,
    this.completedSeasonsCount = 0,
    this.showcaseCards = const [],
  });

  bool get hasShowcaseCards => showcaseCards.isNotEmpty;

  ExplorerShowcaseProfile copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    int? rank,
    String? tierTitle,
    int? pawPoints,
    int? dexDiscoveredCount,
    int? totalDexSpecies,
    int? totalBoops,
    String? territory,
    bool? isPublic,
    int? mythicPrestigePoints,
    int? completedSeasonsCount,
    List<CatSighting>? showcaseCards,
  }) {
    return ExplorerShowcaseProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rank: rank ?? this.rank,
      tierTitle: tierTitle ?? this.tierTitle,
      pawPoints: pawPoints ?? this.pawPoints,
      dexDiscoveredCount: dexDiscoveredCount ?? this.dexDiscoveredCount,
      totalDexSpecies: totalDexSpecies ?? this.totalDexSpecies,
      totalBoops: totalBoops ?? this.totalBoops,
      territory: territory ?? this.territory,
      isPublic: isPublic ?? this.isPublic,
      mythicPrestigePoints: mythicPrestigePoints ?? this.mythicPrestigePoints,
      completedSeasonsCount:
          completedSeasonsCount ?? this.completedSeasonsCount,
      showcaseCards: showcaseCards ?? this.showcaseCards,
    );
  }
}

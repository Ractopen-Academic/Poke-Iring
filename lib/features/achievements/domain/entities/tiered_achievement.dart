import 'achievement_tier.dart';
import 'explorer_title.dart';

enum AchievementCategory {
  all(label: 'All'),
  movement(label: 'Movement'),
  discovery(label: 'Discovery'),
  environment(label: 'Environment'),
  community(label: 'Community'),
  collection(label: 'Collection'),
  mastery(label: 'Mastery');

  final String label;
  const AchievementCategory({required this.label});
}

class AchievementMilestone {
  final AchievementTier tier;
  final double targetValue;
  final int rewardPawPoints;
  final ExplorerTitle? rewardTitle;
  final bool isClaimed;

  const AchievementMilestone({
    required this.tier,
    required this.targetValue,
    required this.rewardPawPoints,
    this.rewardTitle,
    this.isClaimed = false,
  });

  bool isUnlocked(double currentProgress) => currentProgress >= targetValue;

  AchievementMilestone copyWith({
    AchievementTier? tier,
    double? targetValue,
    int? rewardPawPoints,
    ExplorerTitle? rewardTitle,
    bool? isClaimed,
  }) {
    return AchievementMilestone(
      tier: tier ?? this.tier,
      targetValue: targetValue ?? this.targetValue,
      rewardPawPoints: rewardPawPoints ?? this.rewardPawPoints,
      rewardTitle: rewardTitle ?? this.rewardTitle,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tier': tier.name,
      'targetValue': targetValue,
      'rewardPawPoints': rewardPawPoints,
      'rewardTitle': rewardTitle?.toMap(),
      'isClaimed': isClaimed,
    };
  }

  factory AchievementMilestone.fromMap(Map<String, dynamic> map) {
    return AchievementMilestone(
      tier: AchievementTier.fromName(map['tier'] as String? ?? 'bronze'),
      targetValue: (map['targetValue'] as num?)?.toDouble() ?? 0.0,
      rewardPawPoints: (map['rewardPawPoints'] as num?)?.toInt() ?? 0,
      rewardTitle: map['rewardTitle'] != null
          ? ExplorerTitle.fromMap(map['rewardTitle'] as Map<String, dynamic>)
          : null,
      isClaimed: map['isClaimed'] as bool? ?? false,
    );
  }
}

class TieredAchievement {
  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final double currentProgress;
  final String unit;
  final List<AchievementMilestone> milestones;

  const TieredAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.currentProgress = 0.0,
    required this.unit,
    required this.milestones,
  });

  AchievementMilestone get nextMilestone {
    for (final m in milestones) {
      if (!m.isUnlocked(currentProgress)) {
        return m;
      }
    }
    return milestones.last;
  }

  AchievementTier? get highestUnlockedTier {
    AchievementTier? highest;
    for (final m in milestones) {
      if (m.isUnlocked(currentProgress)) {
        highest = m.tier;
      }
    }
    return highest;
  }

  AchievementTier get currentDisplayTier {
    return highestUnlockedTier ?? milestones.first.tier;
  }

  bool get isMaxTier {
    return milestones.every((m) => m.isUnlocked(currentProgress));
  }

  bool get hasClaimableMilestone {
    return milestones.any((m) => m.isUnlocked(currentProgress) && !m.isClaimed);
  }

  int get claimableCount {
    return milestones
        .where((m) => m.isUnlocked(currentProgress) && !m.isClaimed)
        .length;
  }

  int get unlockedMilestonesCount {
    return milestones.where((m) => m.isUnlocked(currentProgress)).length;
  }

  double get progressFraction {
    final next = nextMilestone;
    if (next.targetValue <= 0) return 1.0;
    return (currentProgress / next.targetValue).clamp(0.0, 1.0);
  }

  String get progressFormatted {
    final next = nextMilestone;
    if (unit == 'km') {
      return '${currentProgress.toStringAsFixed(1)} / ${next.targetValue.toStringAsFixed(1)} $unit';
    } else {
      return '${currentProgress.toInt()} / ${next.targetValue.toInt()} $unit';
    }
  }

  TieredAchievement copyWith({
    String? id,
    String? title,
    String? description,
    AchievementCategory? category,
    double? currentProgress,
    String? unit,
    List<AchievementMilestone>? milestones,
  }) {
    return TieredAchievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      currentProgress: currentProgress ?? this.currentProgress,
      unit: unit ?? this.unit,
      milestones: milestones ?? this.milestones,
    );
  }
}

import 'achievement_tier.dart';

enum TitleRarity { common, rare, epic, legendary }

class ExplorerTitle {
  final String id;
  final String name;
  final String description;
  final TitleRarity rarity;
  final AchievementTier tier;
  final bool isEquipped;
  final DateTime? unlockedAt;

  const ExplorerTitle({
    required this.id,
    required this.name,
    required this.description,
    this.rarity = TitleRarity.common,
    this.tier = AchievementTier.bronze,
    this.isEquipped = false,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  ExplorerTitle copyWith({
    String? id,
    String? name,
    String? description,
    TitleRarity? rarity,
    AchievementTier? tier,
    bool? isEquipped,
    DateTime? unlockedAt,
  }) {
    return ExplorerTitle(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      rarity: rarity ?? this.rarity,
      tier: tier ?? this.tier,
      isEquipped: isEquipped ?? this.isEquipped,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rarity': rarity.name,
      'tier': tier.name,
      'isEquipped': isEquipped,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory ExplorerTitle.fromMap(Map<String, dynamic> map) {
    return ExplorerTitle(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      rarity: TitleRarity.values.firstWhere(
        (r) => r.name == map['rarity'],
        orElse: () => TitleRarity.common,
      ),
      tier: AchievementTier.fromName(map['tier'] as String? ?? 'bronze'),
      isEquipped: map['isEquipped'] as bool? ?? false,
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.tryParse(map['unlockedAt'] as String)
          : null,
    );
  }
}

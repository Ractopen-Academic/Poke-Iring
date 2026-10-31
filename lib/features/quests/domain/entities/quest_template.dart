import 'paw_quest.dart';

class QuestTemplate {
  final String id;
  final String title;
  final String description;
  final QuestCategory category;
  final QuestType type;
  final double targetValue;
  final int rewardPawPoints;
  final String? targetBreed;
  final bool isActive;
  final int weight;

  const QuestTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.targetValue,
    required this.rewardPawPoints,
    this.targetBreed,
    this.isActive = true,
    this.weight = 10,
  });

  QuestTemplate copyWith({
    String? id,
    String? title,
    String? description,
    QuestCategory? category,
    QuestType? type,
    double? targetValue,
    int? rewardPawPoints,
    String? targetBreed,
    bool? isActive,
    int? weight,
  }) {
    return QuestTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      rewardPawPoints: rewardPawPoints ?? this.rewardPawPoints,
      targetBreed: targetBreed ?? this.targetBreed,
      isActive: isActive ?? this.isActive,
      weight: weight ?? this.weight,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'type': type.name,
      'targetValue': targetValue,
      'rewardPawPoints': rewardPawPoints,
      'targetBreed': targetBreed,
      'isActive': isActive,
      'weight': weight,
    };
  }

  factory QuestTemplate.fromMap(Map<String, dynamic> map) {
    return QuestTemplate(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Exploration Quest',
      description: map['description'] as String? ?? '',
      category: QuestCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => QuestCategory.daily,
      ),
      type: QuestType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => QuestType.steps,
      ),
      targetValue: (map['targetValue'] as num?)?.toDouble() ?? 1000.0,
      rewardPawPoints: map['rewardPawPoints'] as int? ?? 50,
      targetBreed: map['targetBreed'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      weight: map['weight'] as int? ?? 10,
    );
  }

  static List<QuestTemplate> defaultCatalog() {
    return const [
      // Daily Movement
      QuestTemplate(
        id: 'tpl_morning_prowl',
        title: 'Morning Prowl',
        description: 'Walk 1,500 steps today to map neighborhood cat spots.',
        category: QuestCategory.daily,
        type: QuestType.steps,
        targetValue: 1500,
        rewardPawPoints: 40,
        weight: 10,
      ),
      QuestTemplate(
        id: 'tpl_afternoon_stride',
        title: 'Afternoon Stride',
        description:
            'Take 2,500 steps exploring alleyways and park perimeters.',
        category: QuestCategory.daily,
        type: QuestType.steps,
        targetValue: 2500,
        rewardPawPoints: 50,
        weight: 10,
      ),
      QuestTemplate(
        id: 'tpl_night_patrol',
        title: 'Dusk Wanderer',
        description: 'Walk 3,000 steps during cool dusk feline roaming hours.',
        category: QuestCategory.daily,
        type: QuestType.steps,
        targetValue: 3000,
        rewardPawPoints: 60,
        weight: 8,
      ),
      // Daily Distance
      QuestTemplate(
        id: 'tpl_cartographer_step',
        title: 'Cartographer Step',
        description: 'Cover 1.2 km exploring local feline territory.',
        category: QuestCategory.daily,
        type: QuestType.distance,
        targetValue: 1.2,
        rewardPawPoints: 50,
        weight: 10,
      ),
      QuestTemplate(
        id: 'tpl_alley_route',
        title: 'Alley Route',
        description: 'Walk 2.0 km charting stray routes through your barangay.',
        category: QuestCategory.daily,
        type: QuestType.distance,
        targetValue: 2.0,
        rewardPawPoints: 65,
        weight: 9,
      ),
      QuestTemplate(
        id: 'tpl_perimeter_trek',
        title: 'Perimeter Trek',
        description: 'Cover 2.5 km inspecting nearby community landmarks.',
        category: QuestCategory.daily,
        type: QuestType.distance,
        targetValue: 2.5,
        rewardPawPoints: 75,
        weight: 7,
      ),
      // Daily Encounter & Social
      QuestTemplate(
        id: 'tpl_puspin_discovery',
        title: 'Puspin Discovery',
        description: 'Photograph and catalog a native Puspin street cat.',
        category: QuestCategory.daily,
        type: QuestType.scanBreed,
        targetValue: 1,
        rewardPawPoints: 50,
        targetBreed: 'Puspin',
        weight: 10,
      ),
      QuestTemplate(
        id: 'tpl_calico_whispers',
        title: 'Calico Whispers',
        description: 'Spot and catalog a tricolor Calico pattern cat.',
        category: QuestCategory.daily,
        type: QuestType.scanBreed,
        targetValue: 1,
        rewardPawPoints: 60,
        targetBreed: 'Calico',
        weight: 8,
      ),
      QuestTemplate(
        id: 'tpl_tabby_tracker',
        title: 'Tabby Tracker',
        description: 'Scan and identify a striped or classic Tabby cat.',
        category: QuestCategory.daily,
        type: QuestType.scanBreed,
        targetValue: 1,
        rewardPawPoints: 50,
        targetBreed: 'Tabby',
        weight: 10,
      ),
      QuestTemplate(
        id: 'tpl_friendly_neighbor',
        title: 'Friendly Neighbor',
        description: 'Boop 3 community cat sighting pins on the live map.',
        category: QuestCategory.daily,
        type: QuestType.boopSightings,
        targetValue: 3,
        rewardPawPoints: 40,
        weight: 10,
      ),
      // Weekly Milestones
      QuestTemplate(
        id: 'tpl_territory_wanderer',
        title: 'Territory Wanderer',
        description: 'Accumulate 12,000 steps during your weekly patrols.',
        category: QuestCategory.weekly,
        type: QuestType.steps,
        targetValue: 12000,
        rewardPawPoints: 200,
        weight: 10,
      ),
      QuestTemplate(
        id: 'tpl_stray_guardian_steps',
        title: 'Stray Vanguard',
        description: 'Log 20,000 steps this week guarding local feline paths.',
        category: QuestCategory.weekly,
        type: QuestType.steps,
        targetValue: 20000,
        rewardPawPoints: 350,
        weight: 8,
      ),
      QuestTemplate(
        id: 'tpl_weekly_distance_master',
        title: 'Barangay Scout',
        description: 'Cover 8.0 km total on foot charting feline territory.',
        category: QuestCategory.weekly,
        type: QuestType.distance,
        targetValue: 8.0,
        rewardPawPoints: 250,
        weight: 10,
      ),
      QuestTemplate(
        id: 'tpl_weekly_boop_marathon',
        title: 'Community Pillar',
        description: 'Boop 8 community cat sightings on the live map.',
        category: QuestCategory.weekly,
        type: QuestType.boopSightings,
        targetValue: 8,
        rewardPawPoints: 180,
        weight: 10,
      ),
      QuestTemplate(
        id: 'tpl_multi_breed_chronicler',
        title: 'Species Chronicler',
        description: 'Scan and catalog 4 cat sightings into your Iring-Dex.',
        category: QuestCategory.weekly,
        type: QuestType.scanBreed,
        targetValue: 4,
        rewardPawPoints: 300,
        weight: 8,
      ),
    ];
  }
}

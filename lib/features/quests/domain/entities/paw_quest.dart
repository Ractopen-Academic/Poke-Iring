enum QuestCategory { daily, weekly }

enum QuestType {
  steps,
  distance,
  scanCat,
  scanBreed,
  boopSightings,
  goldenHour,
}

class PawQuest {
  final String id;
  final String title;
  final String description;
  final QuestCategory category;
  final QuestType type;
  final double targetValue;
  final double currentValue;
  final int rewardPawPoints;
  final bool isClaimed;
  final DateTime expiresAt;
  final String? targetBreed;

  const PawQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.targetValue,
    this.currentValue = 0.0,
    required this.rewardPawPoints,
    this.isClaimed = false,
    required this.expiresAt,
    this.targetBreed,
  });

  bool get isCompleted => currentValue >= targetValue;

  double get progressFraction {
    if (targetValue <= 0) return 1.0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  String get progressFormatted {
    if (type == QuestType.distance) {
      return '${currentValue.toStringAsFixed(1)} / ${targetValue.toStringAsFixed(1)} km';
    } else if (type == QuestType.steps) {
      return '${currentValue.toInt()} / ${targetValue.toInt()} steps';
    } else {
      return '${currentValue.toInt()} / ${targetValue.toInt()}';
    }
  }

  Duration get remainingTime {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String get remainingFormatted {
    final diff = remainingTime;
    if (diff.inDays > 0) {
      return '${diff.inDays}d ${diff.inHours % 24}h';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m';
    } else {
      return '${diff.inMinutes}m';
    }
  }

  PawQuest copyWith({
    String? id,
    String? title,
    String? description,
    QuestCategory? category,
    QuestType? type,
    double? targetValue,
    double? currentValue,
    int? rewardPawPoints,
    bool? isClaimed,
    DateTime? expiresAt,
    String? targetBreed,
  }) {
    return PawQuest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      rewardPawPoints: rewardPawPoints ?? this.rewardPawPoints,
      isClaimed: isClaimed ?? this.isClaimed,
      expiresAt: expiresAt ?? this.expiresAt,
      targetBreed: targetBreed ?? this.targetBreed,
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
      'currentValue': currentValue,
      'rewardPawPoints': rewardPawPoints,
      'isClaimed': isClaimed,
      'expiresAt': expiresAt.toIso8601String(),
      'targetBreed': targetBreed,
    };
  }

  factory PawQuest.fromMap(Map<String, dynamic> map) {
    return PawQuest(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: QuestCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => QuestCategory.daily,
      ),
      type: QuestType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => QuestType.steps,
      ),
      targetValue: (map['targetValue'] as num?)?.toDouble() ?? 1.0,
      currentValue: (map['currentValue'] as num?)?.toDouble() ?? 0.0,
      rewardPawPoints: (map['rewardPawPoints'] as num?)?.toInt() ?? 50,
      isClaimed: map['isClaimed'] as bool? ?? false,
      expiresAt: map['expiresAt'] != null
          ? DateTime.tryParse(map['expiresAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      targetBreed: map['targetBreed']?.toString(),
    );
  }
}

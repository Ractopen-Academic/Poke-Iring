enum SeasonStatus { active, calculating, completed }

class SeasonPeriod {
  final String id;
  final int number;
  final String title;
  final String description;
  final DateTime startsAt;
  final DateTime endsAt;
  final SeasonStatus status;

  const SeasonPeriod({
    required this.id,
    required this.number,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.endsAt,
    this.status = SeasonStatus.active,
  });

  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(endsAt)) return Duration.zero;
    return endsAt.difference(now);
  }

  bool get isEnded => DateTime.now().isAfter(endsAt);

  int get remainingDays => remainingTime.inDays;
  int get remainingHours => remainingTime.inHours % 24;
  int get remainingMinutes => remainingTime.inMinutes % 60;

  String get remainingFormatted {
    if (isEnded) return 'Season Ended';
    if (remainingDays > 0) {
      return '$remainingDays days, ${remainingHours}h remaining';
    }
    if (remainingHours > 0) {
      return '${remainingHours}h ${remainingMinutes}m remaining';
    }
    return '${remainingMinutes}m remaining';
  }

  static SeasonPeriod defaultSeason1() {
    final now = DateTime.now();
    return SeasonPeriod(
      id: 'season_1',
      number: 1,
      title: 'Season 1: Sunshine Strays',
      description: 'Document sunny street cats and establish neighborhood territory control.',
      startsAt: now.subtract(const Duration(days: 18)),
      endsAt: now.add(const Duration(days: 12, hours: 4)),
      status: SeasonStatus.active,
    );
  }

  SeasonPeriod copyWith({
    String? id,
    int? number,
    String? title,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
    SeasonStatus? status,
  }) {
    return SeasonPeriod(
      id: id ?? this.id,
      number: number ?? this.number,
      title: title ?? this.title,
      description: description ?? this.description,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'title': title,
      'description': description,
      'startsAt': startsAt.toIso8601String(),
      'endsAt': endsAt.toIso8601String(),
      'status': status.name,
    };
  }

  factory SeasonPeriod.fromMap(Map<String, dynamic> map) {
    return SeasonPeriod(
      id: map['id'] as String? ?? 'season_1',
      number: map['number'] as int? ?? 1,
      title: map['title'] as String? ?? 'Season 1: Sunshine Strays',
      description: map['description'] as String? ?? '',
      startsAt: map['startsAt'] != null
          ? DateTime.parse(map['startsAt'] as String)
          : DateTime.now().subtract(const Duration(days: 18)),
      endsAt: map['endsAt'] != null
          ? DateTime.parse(map['endsAt'] as String)
          : DateTime.now().add(const Duration(days: 12)),
      status: SeasonStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SeasonStatus.active,
      ),
    );
  }
}

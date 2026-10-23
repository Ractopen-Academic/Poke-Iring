class LiveSighting {
  final String id;
  final double latitude;
  final double longitude;
  final String breed;
  final String rarity;
  final double confidence;
  final String thumbnailUrl;
  final DateTime createdAt;
  final DateTime expiresAt;

  const LiveSighting({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.breed,
    required this.rarity,
    required this.confidence,
    this.thumbnailUrl = '',
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remainingTime {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String get remainingFormatted {
    final duration = remainingTime;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'breed': breed,
      'rarity': rarity,
      'confidence': confidence,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory LiveSighting.fromMap(Map<String, dynamic> map, String docId) {
    return LiveSighting(
      id: docId,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      breed: map['breed'] as String? ?? 'Domestic Shorthair',
      rarity: map['rarity'] as String? ?? 'Common',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.9,
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? DateTime.tryParse(map['expiresAt'].toString()) ??
                DateTime.now().add(const Duration(minutes: 10))
          : DateTime.now().add(const Duration(minutes: 10)),
    );
  }
}

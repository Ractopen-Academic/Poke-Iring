class CatSighting {
  final String id;
  final String userId;
  final String authorName;
  final String photoUrl;
  final String stickerUrl;
  final double latitude;
  final double longitude;
  final String geohash;
  final String barangay;
  final String city;
  final String region;
  final String country;
  final String breed;
  final String coatPattern;
  final String dominantColor;
  final double rarityMultiplier;
  final int pawPoints;
  final String quirk;
  final int boopsCount;
  final List<String> boopedBy;
  final DateTime createdAt;

  const CatSighting({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.photoUrl,
    required this.stickerUrl,
    required this.latitude,
    required this.longitude,
    required this.geohash,
    required this.barangay,
    required this.city,
    required this.region,
    required this.country,
    required this.breed,
    required this.coatPattern,
    required this.dominantColor,
    required this.rarityMultiplier,
    required this.pawPoints,
    required this.quirk,
    this.boopsCount = 0,
    this.boopedBy = const [],
    required this.createdAt,
  });

  CatSighting copyWith({
    String? id,
    String? userId,
    String? authorName,
    String? photoUrl,
    String? stickerUrl,
    double? latitude,
    double? longitude,
    String? geohash,
    String? barangay,
    String? city,
    String? region,
    String? country,
    String? breed,
    String? coatPattern,
    String? dominantColor,
    double? rarityMultiplier,
    int? pawPoints,
    String? quirk,
    int? boopsCount,
    List<String>? boopedBy,
    DateTime? createdAt,
  }) {
    return CatSighting(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      photoUrl: photoUrl ?? this.photoUrl,
      stickerUrl: stickerUrl ?? this.stickerUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geohash: geohash ?? this.geohash,
      barangay: barangay ?? this.barangay,
      city: city ?? this.city,
      region: region ?? this.region,
      country: country ?? this.country,
      breed: breed ?? this.breed,
      coatPattern: coatPattern ?? this.coatPattern,
      dominantColor: dominantColor ?? this.dominantColor,
      rarityMultiplier: rarityMultiplier ?? this.rarityMultiplier,
      pawPoints: pawPoints ?? this.pawPoints,
      quirk: quirk ?? this.quirk,
      boopsCount: boopsCount ?? this.boopsCount,
      boopedBy: boopedBy ?? this.boopedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Total lifespan of a live sighting spawn on the active map.
  static const Duration totalSpawnDuration = Duration(minutes: 15);

  /// Duration before the fresh sticker turns into a mystery silhouette.
  static const Duration activeStickerDuration = Duration(minutes: 10);

  /// Age of the sighting since discovery.
  Duration get age => DateTime.now().difference(createdAt);

  /// Whether the spawn has surpassed the 15-minute live map lifespan.
  bool get isExpired => age > totalSpawnDuration;

  /// Whether the spawn is in the 10-15 minute decaying silhouette phase.
  bool get isSilhouettePhase {
    final elapsed = age;
    return elapsed >= activeStickerDuration && elapsed <= totalSpawnDuration;
  }

  /// Remaining time the sighting remains active on the live radar.
  Duration get remainingSpawnTime {
    final diff = totalSpawnDuration - age;
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Formatted remaining countdown string (e.g. "8m 42s").
  String get remainingFormatted {
    final diff = remainingSpawnTime;
    final minutes = diff.inMinutes;
    final seconds = diff.inSeconds % 60;
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  /// Visual opacity during the 10-15 minute silhouette phase (fading from 1.0 to 0.35).
  double get spawnOpacity {
    if (age < activeStickerDuration) return 1.0;
    if (age > totalSpawnDuration) return 0.0;
    final decayElapsed = age - activeStickerDuration;
    final decayWindow = totalSpawnDuration - activeStickerDuration;
    final ratio = (decayElapsed.inMilliseconds / decayWindow.inMilliseconds)
        .clamp(0.0, 1.0);
    return (1.0 - (ratio * 0.65)).clamp(0.35, 1.0);
  }

  /// Metallic rarity tier: 'gold' (Mythic), 'silver' (Rare), 'bronze' (Common).
  String get metallicTier {
    if (rarityMultiplier >= 2.0 || pawPoints >= 200) {
      return 'gold';
    } else if (rarityMultiplier >= 1.4 || pawPoints >= 100) {
      return 'silver';
    } else {
      return 'bronze';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'authorName': authorName,
      'photoUrl': photoUrl,
      'stickerUrl': stickerUrl,
      'latitude': latitude,
      'longitude': longitude,
      'geohash': geohash,
      'barangay': barangay,
      'city': city,
      'region': region,
      'country': country,
      'breed': breed,
      'coatPattern': coatPattern,
      'dominantColor': dominantColor,
      'rarityMultiplier': rarityMultiplier,
      'pawPoints': pawPoints,
      'quirk': quirk,
      'boopsCount': boopsCount,
      'boopedBy': boopedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CatSighting.fromMap(Map<String, dynamic> map) {
    return CatSighting(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      authorName: map['authorName']?.toString() ?? 'Explorer',
      photoUrl: map['photoUrl']?.toString() ?? '',
      stickerUrl: map['stickerUrl']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      geohash: map['geohash']?.toString() ?? '',
      barangay: map['barangay']?.toString() ?? 'Local Territory',
      city: map['city']?.toString() ?? 'Lapu-Lapu City',
      region: map['region']?.toString() ?? 'Central Visayas',
      country: map['country']?.toString() ?? 'Philippines',
      breed: map['breed']?.toString() ?? 'Domestic Shorthair',
      coatPattern: map['coatPattern']?.toString() ?? 'Tabby',
      dominantColor: map['dominantColor']?.toString() ?? 'Mixed',
      rarityMultiplier: (map['rarityMultiplier'] as num?)?.toDouble() ?? 1.0,
      pawPoints: (map['pawPoints'] as num?)?.toInt() ?? 50,
      quirk: map['quirk']?.toString() ?? '',
      boopsCount: (map['boopsCount'] as num?)?.toInt() ?? 0,
      boopedBy:
          (map['boopedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is String
                ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
                : DateTime.now())
          : DateTime.now(),
    );
  }
}

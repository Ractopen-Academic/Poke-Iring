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

class ExplorerTerritory {
  final String barangay;
  final String city;
  final String province;
  final String region;
  final String country;
  final bool isHomeConfirmed;
  final double? latitude;
  final double? longitude;
  final DateTime? lockedAt;

  const ExplorerTerritory({
    required this.barangay,
    required this.city,
    this.province = 'Cebu',
    this.region = 'Central Visayas',
    this.country = 'Philippines',
    this.isHomeConfirmed = false,
    this.latitude,
    this.longitude,
    this.lockedAt,
  });

  static const defaultTerritory = ExplorerTerritory(
    barangay: 'Bankal',
    city: 'Lapu-Lapu City',
    province: 'Cebu',
    region: 'Central Visayas',
    country: 'Philippines',
    isHomeConfirmed: true,
    latitude: 10.3140,
    longitude: 123.9720,
    lockedAt: null,
  );

  String get shortLabel => '$barangay, $city';
  String get fullLabel => '$barangay, $city, $province';

  bool get isChangeLocked {
    if (lockedAt == null) return false;
    final diff = DateTime.now().difference(lockedAt!);
    return diff.inDays < 365;
  }

  int get daysUntilChangeAvailable {
    if (!isChangeLocked || lockedAt == null) return 0;
    final elapsedDays = DateTime.now().difference(lockedAt!).inDays;
    return (365 - elapsedDays).clamp(1, 365);
  }

  DateTime? get nextChangeAvailableDate {
    if (lockedAt == null) return null;
    return lockedAt!.add(const Duration(days: 365));
  }

  String get nextChangeDateFormatted {
    final next = nextChangeAvailableDate;
    if (next == null) return 'Available now';
    return '${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
  }

  ExplorerTerritory copyWith({
    String? barangay,
    String? city,
    String? province,
    String? region,
    String? country,
    bool? isHomeConfirmed,
    double? latitude,
    double? longitude,
    DateTime? lockedAt,
  }) {
    return ExplorerTerritory(
      barangay: barangay ?? this.barangay,
      city: city ?? this.city,
      province: province ?? this.province,
      region: region ?? this.region,
      country: country ?? this.country,
      isHomeConfirmed: isHomeConfirmed ?? this.isHomeConfirmed,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lockedAt: lockedAt ?? this.lockedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'barangay': barangay,
      'city': city,
      'province': province,
      'region': region,
      'country': country,
      'isHomeConfirmed': isHomeConfirmed,
      'latitude': latitude,
      'longitude': longitude,
      'lockedAt': lockedAt?.toIso8601String(),
    };
  }

  factory ExplorerTerritory.fromMap(Map<String, dynamic> map) {
    return ExplorerTerritory(
      barangay: map['barangay'] as String? ?? 'Bankal',
      city: map['city'] as String? ?? 'Lapu-Lapu City',
      province: map['province'] as String? ?? 'Cebu',
      region: map['region'] as String? ?? 'Central Visayas',
      country: map['country'] as String? ?? 'Philippines',
      isHomeConfirmed: map['isHomeConfirmed'] as bool? ?? false,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      lockedAt: DateTime.tryParse(map['lockedAt'] as String? ?? ''),
    );
  }
}

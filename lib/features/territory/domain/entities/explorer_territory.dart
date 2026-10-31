class ExplorerTerritory {
  final String barangay;
  final String city;
  final String province;
  final String region;
  final String country;
  final bool isHomeConfirmed;
  final double? latitude;
  final double? longitude;

  const ExplorerTerritory({
    required this.barangay,
    required this.city,
    this.province = 'Cebu',
    this.region = 'Central Visayas',
    this.country = 'Philippines',
    this.isHomeConfirmed = false,
    this.latitude,
    this.longitude,
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
  );

  String get shortLabel => '$barangay, $city';
  String get fullLabel => '$barangay, $city, $province';

  ExplorerTerritory copyWith({
    String? barangay,
    String? city,
    String? province,
    String? region,
    String? country,
    bool? isHomeConfirmed,
    double? latitude,
    double? longitude,
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
    );
  }
}

import '../../domain/entities/explorer_territory.dart';

class PhCityTerritory {
  final String city;
  final String province;
  final String region;
  final List<String> barangays;

  const PhCityTerritory({
    required this.city,
    required this.province,
    this.region = 'Central Visayas',
    required this.barangays,
  });

  Map<String, dynamic> toMap() {
    return {
      'city': city,
      'province': province,
      'region': region,
      'barangays': barangays,
    };
  }

  factory PhCityTerritory.fromMap(Map<String, dynamic> map) {
    return PhCityTerritory(
      city: map['city'] as String? ?? 'Lapu-Lapu City',
      province: map['province'] as String? ?? 'Cebu',
      region: map['region'] as String? ?? 'Central Visayas',
      barangays:
          (map['barangays'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Poblacion'],
    );
  }

  PhCityTerritory copyWith({
    String? city,
    String? province,
    String? region,
    List<String>? barangays,
  }) {
    return PhCityTerritory(
      city: city ?? this.city,
      province: province ?? this.province,
      region: region ?? this.region,
      barangays: barangays ?? this.barangays,
    );
  }
}

class PhTerritoryCatalog {
  PhTerritoryCatalog._();

  static const List<PhCityTerritory> cities = [
    // Cebu Province (Central Visayas)
    PhCityTerritory(
      city: 'Lapu-Lapu City',
      province: 'Cebu',
      region: 'Central Visayas',
      barangays: [
        'Bankal',
        'Basak',
        'Buaya',
        'Gun-ob',
        'Ibo',
        'Mactan',
        'Marigondon',
        'Pajac',
        'Pajo',
        'Poblacion',
        'Pusok',
        'Subabasbas',
        'Canjulao',
        'Looc',
      ],
    ),
    PhCityTerritory(
      city: 'Cebu City',
      province: 'Cebu',
      region: 'Central Visayas',
      barangays: [
        'Lahug',
        'Banilad',
        'Guadalupe',
        'Mabolo',
        'Kasambagan',
        'Apas',
        'Kamputhaw',
        'Talamban',
        'Labangon',
        'Pardo',
        'Capitol Site',
        'Sambag I',
        'Sambag II',
      ],
    ),
    PhCityTerritory(
      city: 'Mandaue City',
      province: 'Cebu',
      region: 'Central Visayas',
      barangays: [
        'Tipolo',
        'Subangdaku',
        'Bakilid',
        'Banilad',
        'Casuntingan',
        'Maguikay',
        'Centro',
        'Guizo',
        'Ibabao-Estancia',
        'Cabancalan',
      ],
    ),

    // Metro Manila (National Capital Region)
    PhCityTerritory(
      city: 'Taguig City',
      province: 'Metro Manila',
      region: 'National Capital Region',
      barangays: [
        'Fort Bonifacio (BGC)',
        'Western Bicutan',
        'Ususan',
        'Pinagsama',
        'Central Signal',
        'Upper Bicutan',
      ],
    ),
    PhCityTerritory(
      city: 'Makati City',
      province: 'Metro Manila',
      region: 'National Capital Region',
      barangays: [
        'Bel-Air',
        'Poblacion',
        'San Lorenzo',
        'Legazpi Village',
        'Pio del Pilar',
        'Bangkal',
      ],
    ),
    PhCityTerritory(
      city: 'Quezon City',
      province: 'Metro Manila',
      region: 'National Capital Region',
      barangays: [
        'Diliman',
        'Katipunan',
        'New Manila',
        'Cubao',
        'Commonwealth',
        'Batasan Hills',
        'Tandang Sora',
      ],
    ),
    PhCityTerritory(
      city: 'Manila City',
      province: 'Metro Manila',
      region: 'National Capital Region',
      barangays: [
        'Malate',
        'Ermita',
        'Intramuros',
        'Santa Cruz',
        'Sampaloc',
        'Binondo',
        'Paco',
      ],
    ),
    PhCityTerritory(
      city: 'Pasig City',
      province: 'Metro Manila',
      region: 'National Capital Region',
      barangays: [
        'Kapasigan',
        'San Antonio',
        'Ugong',
        'Oranbo',
        'Kapitolyo',
        'Maybunga',
        'Caniogan',
      ],
    ),

    // Mindanao
    PhCityTerritory(
      city: 'Davao City',
      province: 'Davao del Sur',
      region: 'Davao Region',
      barangays: [
        'Poblacion',
        'Buhangin',
        'Talomo',
        'Matina Crossing',
        'Agdao',
        'Toril',
      ],
    ),
    PhCityTerritory(
      city: 'Cagayan de Oro City',
      province: 'Misamis Oriental',
      region: 'Northern Mindanao',
      barangays: [
        'Carmen',
        'Macasandig',
        'Nazareth',
        'Kauswagan',
        'Lapasan',
        'Poblacion',
      ],
    ),

    // Western Visayas
    PhCityTerritory(
      city: 'Iloilo City',
      province: 'Iloilo',
      region: 'Western Visayas',
      barangays: [
        'Jaro',
        'Mandurriao',
        'Molo',
        'La Paz',
        'City Proper',
        'Villa Arevalo',
      ],
    ),
    PhCityTerritory(
      city: 'Bacolod City',
      province: 'Negros Occidental',
      region: 'Western Visayas',
      barangays: [
        'Mandalagan',
        'Villamonte',
        'Mansilingan',
        'Singcang',
        'Bata',
        'Tangub',
      ],
    ),

    // Northern Luzon
    PhCityTerritory(
      city: 'Baguio City',
      province: 'Benguet',
      region: 'Cordillera Administrative Region',
      barangays: [
        'Session Road',
        'Burnham - Legarda',
        'Camp 7',
        'Loakan Proper',
        'Irisan',
        'Mines View',
      ],
    ),
    PhCityTerritory(
      city: 'Angeles City',
      province: 'Pampanga',
      region: 'Central Luzon',
      barangays: [
        'Balibago',
        'Malabañas',
        'Cutcut',
        'Sto. Rosario',
        'Pulung Maragul',
      ],
    ),
  ];

  static ExplorerTerritory resolveCoordinates({
    required double latitude,
    required double longitude,
  }) {
    // Lapu-Lapu City / Mactan Island
    if (longitude >= 123.94 &&
        longitude <= 124.05 &&
        latitude >= 10.25 &&
        latitude <= 10.36) {
      if (latitude >= 10.305 &&
          latitude <= 10.325 &&
          longitude >= 123.965 &&
          longitude <= 123.995) {
        return ExplorerTerritory(
          barangay: 'Bankal',
          city: 'Lapu-Lapu City',
          province: 'Cebu',
          country: 'Philippines',
          isHomeConfirmed: true,
          latitude: latitude,
          longitude: longitude,
        );
      }
      return ExplorerTerritory(
        barangay: 'Basak',
        city: 'Lapu-Lapu City',
        province: 'Cebu',
        country: 'Philippines',
        isHomeConfirmed: true,
        latitude: latitude,
        longitude: longitude,
      );
    }

    // Cebu City
    if (longitude >= 123.85 &&
        longitude < 123.92 &&
        latitude >= 10.28 &&
        latitude <= 10.38) {
      return ExplorerTerritory(
        barangay: 'Lahug',
        city: 'Cebu City',
        province: 'Cebu',
        country: 'Philippines',
        isHomeConfirmed: true,
        latitude: latitude,
        longitude: longitude,
      );
    }

    // Mandaue City
    if (longitude >= 123.92 &&
        longitude < 123.94 &&
        latitude >= 10.31 &&
        latitude <= 10.36) {
      return ExplorerTerritory(
        barangay: 'Tipolo',
        city: 'Mandaue City',
        province: 'Cebu',
        country: 'Philippines',
        isHomeConfirmed: true,
        latitude: latitude,
        longitude: longitude,
      );
    }

    // Davao City
    if (longitude >= 125.55 &&
        longitude <= 125.68 &&
        latitude >= 7.05 &&
        latitude <= 7.15) {
      return ExplorerTerritory(
        barangay: 'Poblacion',
        city: 'Davao City',
        province: 'Davao del Sur',
        country: 'Philippines',
        isHomeConfirmed: true,
        latitude: latitude,
        longitude: longitude,
      );
    }

    // Baguio City
    if (longitude >= 120.57 &&
        longitude <= 120.62 &&
        latitude >= 16.38 &&
        latitude <= 16.44) {
      return ExplorerTerritory(
        barangay: 'Session Road',
        city: 'Baguio City',
        province: 'Benguet',
        country: 'Philippines',
        isHomeConfirmed: true,
        latitude: latitude,
        longitude: longitude,
      );
    }

    // Default fallback
    return ExplorerTerritory.defaultTerritory.copyWith(
      latitude: latitude,
      longitude: longitude,
    );
  }
}

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
}

class PhTerritoryCatalog {
  PhTerritoryCatalog._();

  static const List<PhCityTerritory> cities = [
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
      ],
    ),
    PhCityTerritory(
      city: 'Taguig City',
      province: 'Metro Manila',
      region: 'National Capital Region',
      barangays: [
        'Fort Bonifacio (BGC)',
        'Western Bicutan',
        'Ususan',
        'Pinagsama',
      ],
    ),
    PhCityTerritory(
      city: 'Makati City',
      province: 'Metro Manila',
      region: 'National Capital Region',
      barangays: ['Bel-Air', 'Poblacion', 'San Lorenzo', 'Legazpi Village'],
    ),
    PhCityTerritory(
      city: 'Quezon City',
      province: 'Metro Manila',
      region: 'National Capital Region',
      barangays: ['Diliman', 'Katipunan', 'New Manila', 'Cubao'],
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

    // Default fallback
    return ExplorerTerritory.defaultTerritory.copyWith(
      latitude: latitude,
      longitude: longitude,
    );
  }
}

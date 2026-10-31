import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/core/services/location_service.dart';
import 'package:pokeiring/features/map/domain/entities/user_location.dart';
import 'package:pokeiring/features/territory/data/datasources/firebase_territory_datasource.dart';
import 'package:pokeiring/features/territory/data/datasources/ph_territory_catalog.dart';
import 'package:pokeiring/features/territory/data/datasources/reverse_geocoding_service.dart';
import 'package:pokeiring/features/territory/data/services/territory_service_impl.dart';
import 'package:pokeiring/features/territory/domain/entities/explorer_territory.dart';
import 'package:pokeiring/features/territory/presentation/widgets/territory_selection_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockLocationService implements LocationService {
  final UserLocation? mockLocation;

  _MockLocationService([this.mockLocation]);

  @override
  Future<UserLocation?> getCurrentLocation() async => mockLocation;

  @override
  Future<LocationAccessStatus> checkStatus() async =>
      LocationAccessStatus.granted;

  @override
  Future<LocationAccessStatus> requestPermission() async =>
      LocationAccessStatus.granted;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Stream<bool> get onServiceStatusChanged => const Stream.empty();

  @override
  Stream<UserLocation> get onLocationChanged => const Stream.empty();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PhCityTerritory Entity', () {
    test('serializes toMap and fromMap cleanly', () {
      const city = PhCityTerritory(
        city: 'Iloilo City',
        province: 'Iloilo',
        region: 'Western Visayas',
        barangays: ['Jaro', 'Molo', 'Mandurriao'],
      );

      final map = city.toMap();
      final restored = PhCityTerritory.fromMap(map);

      expect(restored.city, equals('Iloilo City'));
      expect(restored.province, equals('Iloilo'));
      expect(restored.region, equals('Western Visayas'));
      expect(restored.barangays, contains('Jaro'));
      expect(restored.barangays.length, equals(3));
    });

    test('default catalog provides national coverage across PH regions', () {
      final cities = PhTerritoryCatalog.cities;
      expect(cities.length, greaterThanOrEqualTo(12));

      // Visayas, NCR, Mindanao, Luzon
      expect(cities.any((c) => c.region == 'Central Visayas'), isTrue);
      expect(cities.any((c) => c.region == 'National Capital Region'), isTrue);
      expect(cities.any((c) => c.region == 'Davao Region'), isTrue);
      expect(
        cities.any((c) => c.region == 'Cordillera Administrative Region'),
        isTrue,
      );
    });
  });

  group('FirebaseTerritoryDataSource', () {
    test(
      'loads default cities and registers new barangay dynamically',
      () async {
        final dataSource = FirebaseTerritoryDataSource.instance;
        final cities = await dataSource.getCities(forceRefresh: true);

        expect(cities, isNotEmpty);
        expect(cities.any((c) => c.city == 'Lapu-Lapu City'), isTrue);

        // Register new barangay 'Suba-Basbas Extension' to Lapu-Lapu City
        final registered = await dataSource.registerBarangay(
          cityName: 'Lapu-Lapu City',
          barangayName: 'Suba-Basbas Extension',
        );
        expect(registered, isTrue);

        final refreshed = await dataSource.getCities(forceRefresh: true);
        final lapuLapu = refreshed.firstWhere(
          (c) => c.city == 'Lapu-Lapu City',
        );
        expect(lapuLapu.barangays, contains('Suba-Basbas Extension'));
      },
    );

    test('adds custom city territory to catalog', () async {
      final dataSource = FirebaseTerritoryDataSource.instance;
      const customCity = PhCityTerritory(
        city: 'Zamboanga City',
        province: 'Zamboanga del Sur',
        region: 'Zamboanga Peninsula',
        barangays: ['Pasonanca', 'Tetuan', 'Santa Maria'],
      );

      final added = await dataSource.addCityTerritory(customCity);
      expect(added, isTrue);

      final cities = await dataSource.getCities(forceRefresh: true);
      expect(cities.any((c) => c.city == 'Zamboanga City'), isTrue);
    });
  });

  group('ReverseGeocodingService', () {
    test('resolves coordinates via custom resolver when provided', () async {
      final service = ReverseGeocodingService(
        customResolver: (lat, lon) async {
          return const ExplorerTerritory(
            barangay: 'San Antonio',
            city: 'Pasig City',
            province: 'Metro Manila',
            country: 'Philippines',
            isHomeConfirmed: true,
          );
        },
      );

      final territory = await service.resolveCoordinates(
        latitude: 14.5830,
        longitude: 121.0630,
      );

      expect(territory.city, equals('Pasig City'));
      expect(territory.barangay, equals('San Antonio'));
      expect(territory.province, equals('Metro Manila'));
    });

    test(
      'falls back to local catalog bounding box when resolver yields null',
      () async {
        final service = ReverseGeocodingService(
          customResolver: (lat, lon) async => null,
        );

        final territory = await service.resolveCoordinates(
          latitude: 10.3140,
          longitude: 123.9720,
        );

        expect(territory.city, equals('Lapu-Lapu City'));
        expect(territory.barangay, equals('Bankal'));
      },
    );
  });

  group('TerritoryServiceImpl GPS Integration', () {
    test('detectFromGps uses reverse geocoder with location service', () async {
      final mockLocation = UserLocation(
        latitude: 10.3300,
        longitude: 123.9050,
        heading: 0,
        accuracy: 5,
        speed: 0,
        altitude: 10,
        timestamp: DateTime.now(),
      );

      final mockGeocoding = ReverseGeocodingService(
        customResolver: (lat, lon) async {
          return const ExplorerTerritory(
            barangay: 'Guadalupe',
            city: 'Cebu City',
            province: 'Cebu',
            country: 'Philippines',
            isHomeConfirmed: true,
          );
        },
      );

      final service = TerritoryServiceImpl(
        locationService: _MockLocationService(mockLocation),
        geocodingService: mockGeocoding,
      );

      final detected = await service.detectFromGps();
      expect(detected.city, equals('Cebu City'));
      expect(detected.barangay, equals('Guadalupe'));
    });
  });

  group('TerritorySelectionSheet Presentation Widget', () {
    testWidgets('renders database cities and handles selection', (
      tester,
    ) async {
      ExplorerTerritory? savedTerritory;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TerritorySelectionSheet.show(
                  context,
                  userId: 'test_territory_user',
                  currentTerritory: ExplorerTerritory.defaultTerritory,
                  onSaved: (t) => savedTerritory = t,
                ),
                child: const Text('Open Territory Picker'),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Territory Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Home Neighborhood'), findsOneWidget);
      expect(find.textContaining('cities in database'), findsOneWidget);
      expect(find.text('Detect Neighborhood from GPS'), findsOneWidget);
      expect(find.text('Add Barangay'), findsOneWidget);

      // Save
      await tester.tap(find.text('Set as Home Territory'));
      await tester.pumpAndSettle();

      expect(savedTerritory, isNotNull);
      expect(savedTerritory!.city, equals('Lapu-Lapu City'));
    });
  });
}

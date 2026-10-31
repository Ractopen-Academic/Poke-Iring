import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokeiring/core/services/location_service.dart';
import 'package:pokeiring/features/auth/domain/entities/auth_user.dart';
import 'package:pokeiring/features/auth/domain/repositories/auth_repository.dart';
import 'package:pokeiring/features/home/presentation/pages/dashboard_page.dart';
import 'package:pokeiring/features/map/domain/entities/user_location.dart';
import 'package:pokeiring/features/territory/data/datasources/reverse_geocoding_service.dart';
import 'package:pokeiring/features/territory/data/services/territory_service_impl.dart';
import 'package:pokeiring/features/territory/domain/entities/explorer_territory.dart';

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

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();

  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthUser> signInWithEmailPassword(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<AuthUser> registerWithEmailPassword(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<AuthUser> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> reloadCurrentUser() async {}

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Autonomous GPS Territory Detection & Auto-Sync Engine', () {
    test('autoDetectAndSync acquires GPS, reverse geocodes, and syncs confirmed territory', () async {
      final mockLocation = _MockLocationService(
        UserLocation(
          latitude: 10.3300,
          longitude: 123.9050,
          accuracy: 5.0,
          timestamp: DateTime.now(),
        ),
      );

      final service = TerritoryServiceImpl(
        locationService: mockLocation,
        geocodingService: ReverseGeocodingService(
          customResolver: (lat, lon) async => const ExplorerTerritory(
            barangay: 'Lahug',
            city: 'Cebu City',
            province: 'Cebu',
            region: 'Central Visayas',
            country: 'Philippines',
            isHomeConfirmed: false,
          ),
        ),
      );

      final events = <ExplorerTerritory>[];
      final sub = service.watchTerritory('pilot_user').listen(events.add);

      final synced = await service.autoDetectAndSync('pilot_user');

      expect(synced, isNotNull);
      expect(synced!.barangay, equals('Lahug'));
      expect(synced.city, equals('Cebu City'));
      expect(synced.isHomeConfirmed, isTrue);
      expect(synced.latitude, equals(10.3300));
      expect(synced.longitude, equals(123.9050));

      final stored = await service.getTerritory('pilot_user');
      expect(stored.barangay, equals('Lahug'));
      expect(stored.isHomeConfirmed, isTrue);

      await Future.delayed(const Duration(milliseconds: 10));
      expect(events.any((e) => e.barangay == 'Lahug'), isTrue);

      await sub.cancel();
    });

    test(
      'autoDetectAndSync returns null gracefully when location is unavailable',
      () async {
        final mockLocation = _MockLocationService(null);
        final service = TerritoryServiceImpl(locationService: mockLocation);

        final synced = await service.autoDetectAndSync('offline_user');
        expect(synced, isNull);

        // Fallback default should remain intact
        final territory = await service.getTerritory('offline_user');
        expect(
          territory.barangay,
          equals(ExplorerTerritory.defaultTerritory.barangay),
        );
      },
    );

    testWidgets('DashboardPage renders active territory and auto-sync action', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      const testUser = AuthUser(
        id: 'dashboard_test_user',
        email: 'cat.explorer@iring.ph',
        displayName: 'Cat Pilot',
      );

      final mockLocation = _MockLocationService(
        UserLocation(
          latitude: 10.3140,
          longitude: 123.9720,
          accuracy: 4.0,
          timestamp: DateTime.now(),
        ),
      );

      final service = TerritoryServiceImpl(
        locationService: mockLocation,
        geocodingService: ReverseGeocodingService(
          customResolver: (lat, lon) async =>
              ExplorerTerritory.defaultTerritory,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardPage(
            user: testUser,
            authRepository: _FakeAuthRepository(),
            territoryService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Active Territory'), findsOneWidget);
      expect(find.text('Auto-Sync'), findsOneWidget);
      expect(find.textContaining('Bankal'), findsOneWidget);
    });
  });
}

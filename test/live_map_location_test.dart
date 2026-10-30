import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/core/services/location_service.dart';
import 'package:pokeiring/features/map/domain/entities/user_location.dart';
import 'package:pokeiring/features/map/presentation/pages/live_map_page.dart';

class FakeLocationService implements LocationService {
  final StreamController<UserLocation> _controller =
      StreamController<UserLocation>.broadcast();
  UserLocation? currentLocation;

  @override
  Future<LocationAccessStatus> checkStatus() async =>
      LocationAccessStatus.granted;

  @override
  Future<LocationAccessStatus> requestPermission() async =>
      LocationAccessStatus.granted;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Stream<bool> get onServiceStatusChanged => const Stream.empty();

  @override
  Future<UserLocation?> getCurrentLocation() async => currentLocation;

  @override
  Stream<UserLocation> get onLocationChanged => _controller.stream;

  void emitLocation(UserLocation loc) {
    currentLocation = loc;
    _controller.add(loc);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('LiveMapPage Location Integration', () {
    testWidgets('displays coordinates banner when location is provided', (
      tester,
    ) async {
      final fakeService = FakeLocationService();
      fakeService.currentLocation = UserLocation(
        latitude: 10.3155,
        longitude: 123.9788,
        heading: 45.0,
        accuracy: 3.0,
        speed: 1.0,
        altitude: 12.0,
        timestamp: DateTime(2026, 10, 30, 12, 0, 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LiveMapPage(
            locationService: fakeService,
            isMapActive: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('10.3155, 123.9788'), findsOneWidget);

      fakeService.dispose();
    });

    testWidgets('updates coordinates display when location stream emits updates', (
      tester,
    ) async {
      final fakeService = FakeLocationService();
      fakeService.currentLocation = UserLocation(
        latitude: 10.3150,
        longitude: 123.9700,
        heading: 0.0,
        accuracy: 4.0,
        speed: 0.0,
        altitude: 10.0,
        timestamp: DateTime(2026, 10, 30, 12, 0, 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LiveMapPage(
            locationService: fakeService,
            isMapActive: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('10.3150, 123.9700'), findsOneWidget);

      fakeService.emitLocation(
        UserLocation(
          latitude: 10.3200,
          longitude: 123.9800,
          heading: 90.0,
          accuracy: 2.0,
          speed: 1.5,
          altitude: 10.0,
          timestamp: DateTime(2026, 10, 30, 12, 1, 0),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('10.3200, 123.9800'), findsOneWidget);

      fakeService.dispose();
    });
  });
}

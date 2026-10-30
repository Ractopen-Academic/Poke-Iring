import 'dart:async';

import '../../features/map/domain/entities/user_location.dart';

enum LocationAccessStatus {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

abstract class LocationService {
  Future<LocationAccessStatus> checkStatus();
  Future<LocationAccessStatus> requestPermission();
  Future<bool> openLocationSettings();
  Future<bool> openAppSettings();
  Stream<bool> get onServiceStatusChanged;
  Future<UserLocation?> getCurrentLocation();
  Stream<UserLocation> get onLocationChanged;
}

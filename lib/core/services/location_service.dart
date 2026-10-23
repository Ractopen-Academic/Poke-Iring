import 'dart:async';

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
}

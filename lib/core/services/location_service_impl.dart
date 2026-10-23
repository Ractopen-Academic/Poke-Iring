import 'package:geolocator/geolocator.dart';

import 'location_service.dart';

class LocationServiceImpl implements LocationService {
  @override
  Future<LocationAccessStatus> checkStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationAccessStatus.serviceDisabled;
    }

    final permission = await Geolocator.checkPermission();
    return _mapPermission(permission);
  }

  @override
  Future<LocationAccessStatus> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationAccessStatus.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return _mapPermission(permission);
  }

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Stream<bool> get onServiceStatusChanged {
    return Geolocator.getServiceStatusStream().map(
      (status) => status == ServiceStatus.enabled,
    );
  }

  LocationAccessStatus _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationAccessStatus.granted;
      case LocationPermission.deniedForever:
        return LocationAccessStatus.permanentlyDenied;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return LocationAccessStatus.denied;
    }
  }
}

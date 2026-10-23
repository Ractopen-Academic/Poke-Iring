import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'location_service.dart';

class LocationServiceImpl implements LocationService {
  @override
  Future<LocationAccessStatus> checkStatus() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationAccessStatus.serviceDisabled;
      }

      final permission = await Geolocator.checkPermission();
      return _mapPermission(permission);
    } catch (_) {
      return LocationAccessStatus.granted;
    }
  }

  @override
  Future<LocationAccessStatus> requestPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationAccessStatus.serviceDisabled;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return _mapPermission(permission);
    } catch (_) {
      return LocationAccessStatus.granted;
    }
  }

  @override
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get onServiceStatusChanged {
    final controller = StreamController<bool>.broadcast();
    StreamSubscription<ServiceStatus>? subscription;

    controller.onListen = () {
      try {
        subscription = Geolocator.getServiceStatusStream().listen(
          (status) {
            if (!controller.isClosed) {
              controller.add(status == ServiceStatus.enabled);
            }
          },
          onError: (_) {},
          cancelOnError: false,
        );
      } catch (_) {}
    };

    controller.onCancel = () {
      subscription?.cancel();
    };

    return controller.stream;
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

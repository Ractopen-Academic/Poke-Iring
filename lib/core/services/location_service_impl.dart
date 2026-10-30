import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../features/map/domain/entities/user_location.dart';
import 'location_service.dart';

class LocationServiceImpl implements LocationService {
  Future<bool> _isPlatformChannelReady() async {
    if (kIsWeb) return false;
    try {
      await Geolocator.isLocationServiceEnabled();
      return true;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<LocationAccessStatus> checkStatus() async {
    if (kIsWeb) return LocationAccessStatus.granted;
    try {
      final ready = await _isPlatformChannelReady();
      if (!ready) return LocationAccessStatus.granted;

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
    if (kIsWeb) return LocationAccessStatus.granted;
    try {
      final ready = await _isPlatformChannelReady();
      if (!ready) return LocationAccessStatus.granted;

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
    if (kIsWeb) return false;
    try {
      final ready = await _isPlatformChannelReady();
      if (!ready) return false;
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> openAppSettings() async {
    if (kIsWeb) return false;
    try {
      final ready = await _isPlatformChannelReady();
      if (!ready) return false;
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get onServiceStatusChanged {
    final controller = StreamController<bool>.broadcast();
    StreamSubscription<ServiceStatus>? subscription;

    controller.onListen = () async {
      final ready = await _isPlatformChannelReady();
      if (!ready || controller.isClosed) return;

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

  @override
  Future<UserLocation?> getCurrentLocation() async {
    if (kIsWeb) return UserLocation.fallback();

    try {
      final ready = await _isPlatformChannelReady();
      if (!ready) return UserLocation.fallback();

      final status = await checkStatus();
      if (status != LocationAccessStatus.granted) {
        return UserLocation.fallback();
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 4),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position != null) {
        return _mapPosition(position);
      }

      return UserLocation.fallback();
    } catch (_) {
      return UserLocation.fallback();
    }
  }

  @override
  Stream<UserLocation> get onLocationChanged {
    final controller = StreamController<UserLocation>.broadcast();
    StreamSubscription<Position>? subscription;

    controller.onListen = () async {
      if (kIsWeb) {
        if (!controller.isClosed) {
          controller.add(UserLocation.fallback());
        }
        return;
      }

      final ready = await _isPlatformChannelReady();
      if (!ready || controller.isClosed) {
        if (!controller.isClosed) {
          controller.add(UserLocation.fallback());
        }
        return;
      }

      try {
        final status = await checkStatus();
        if (status != LocationAccessStatus.granted) {
          if (!controller.isClosed) {
            controller.add(UserLocation.fallback());
          }
          return;
        }

        const settings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        );

        subscription = Geolocator.getPositionStream(
          locationSettings: settings,
        ).listen(
          (position) {
            if (!controller.isClosed) {
              controller.add(_mapPosition(position));
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

  UserLocation _mapPosition(Position position) {
    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      heading: position.heading,
      accuracy: position.accuracy,
      speed: position.speed,
      altitude: position.altitude,
      timestamp: position.timestamp,
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

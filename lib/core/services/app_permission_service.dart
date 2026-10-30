import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppPermissionState {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unavailable,
}

class AppPermissionService {
  const AppPermissionService();

  Future<AppPermissionState> checkLocation() async {
    if (kIsWeb) return AppPermissionState.granted;

    final status = await Permission.location.status;
    return _mapPermissionStatus(status);
  }

  Future<AppPermissionState> requestLocation() async {
    if (kIsWeb) return AppPermissionState.granted;

    final status = await Permission.location.request();
    return _mapPermissionStatus(status);
  }

  Future<AppPermissionState> checkCamera() async {
    if (kIsWeb) return AppPermissionState.granted;

    final status = await Permission.camera.status;
    return _mapPermissionStatus(status);
  }

  Future<AppPermissionState> requestCamera() async {
    if (kIsWeb) return AppPermissionState.granted;

    final status = await Permission.camera.request();
    return _mapPermissionStatus(status);
  }

  Future<void> openAppSettingsIfNeeded() async {
    if (!kIsWeb) {
      await openAppSettings();
    }
  }

  AppPermissionState _mapPermissionStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return AppPermissionState.granted;
      case PermissionStatus.denied:
        return AppPermissionState.denied;
      case PermissionStatus.permanentlyDenied:
        return AppPermissionState.permanentlyDenied;
      case PermissionStatus.restricted:
        return AppPermissionState.restricted;
      case PermissionStatus.limited:
      case PermissionStatus.provisional:
        return AppPermissionState.granted;
    }
  }
}

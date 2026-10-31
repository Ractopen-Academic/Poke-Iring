import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_permission_service.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../home/presentation/pages/main_navigation_shell.dart';
import '../../../splash/presentation/pages/app_bootstrap_page.dart';

class PermissionGate extends StatefulWidget {
  final AuthUser user;
  final AuthRepository authRepository;

  const PermissionGate({
    super.key,
    required this.user,
    required this.authRepository,
  });

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  final AppPermissionService _permissionService = const AppPermissionService();
  bool _isLoading = true;
  bool _needsLocation = false;
  bool _needsCamera = false;
  String _message = 'Checking permissions...';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final locationState = await _permissionService.checkLocation();
    final cameraState = await _permissionService.checkCamera();

    if (!mounted) return;

    setState(() {
      _needsLocation = locationState != AppPermissionState.granted;
      _needsCamera = cameraState != AppPermissionState.granted;
      _isLoading = false;
      if (_needsLocation || _needsCamera) {
        _message =
            'Poke: Iring needs camera and location to track cat sightings.';
      } else {
        _message = 'Ready to explore.';
      }
    });
  }

  Future<void> _requestAllPermissions() async {
    setState(() {
      _isLoading = true;
      _message = 'Requesting access...';
    });

    final locationResult = await _permissionService.requestLocation();
    final cameraResult = await _permissionService.requestCamera();

    if (!mounted) return;

    final needsLocation = locationResult != AppPermissionState.granted;
    final needsCamera = cameraResult != AppPermissionState.granted;

    if (needsLocation || needsCamera) {
      setState(() {
        _isLoading = false;
        _needsLocation = needsLocation;
        _needsCamera = needsCamera;
        _message = 'Permissions are still required for nearby cat discovery.';
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _needsLocation = false;
      _needsCamera = false;
      _message = 'All set.';
    });
  }

  Future<void> _openSettings() async {
    await _permissionService.openAppSettingsIfNeeded();
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required bool required,
    required bool granted,
  }) {
    final accent = granted ? AppColors.primary : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              granted ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (required) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Required',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading && !_needsLocation && !_needsCamera) {
      return AppBootstrapPage(
        onReady: (context, result) => MainNavigationShell(
          user: widget.user,
          authRepository: widget.authRepository,
          initialOnline: result.isOnline,
          initialLocationStatus: result.locationStatus,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Before you explore',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildPermissionTile(
                    title: 'Location access',
                    subtitle: 'Needed to log nearby cat sightings and map your route.',
                    required: true,
                    granted: !_needsLocation,
                  ),
                  _buildPermissionTile(
                    title: 'Camera access',
                    subtitle:
                        'Needed to capture a cat photo for your Iring-dex.',
                    required: true,
                    granted: !_needsCamera,
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading)
                    const CircularProgressIndicator(strokeWidth: 2)
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _requestAllPermissions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Allow access',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _openSettings,
                      child: const Text('Open app settings'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

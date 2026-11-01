import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_permission_service.dart';
import '../../../../core/widgets/calico_ui_kit.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/widgets/calico_login_mascot.dart';
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
  String _message = 'Checking explorer gear...';

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
        _message = 'Enable GPS patrol tracking and camera scanning so you can spot neighborhood cats.';
      } else {
        _message = 'Ready to explore.';
      }
    });
  }

  Future<void> _requestAllPermissions() async {
    setState(() {
      _isLoading = true;
      _message = 'Requesting explorer access...';
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
        _message = 'Both camera and location permissions are needed for live cat discovery.';
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
    required IconData icon,
    required String title,
    required String subtitle,
    required bool required,
    required bool granted,
  }) {
    final accent = granted ? AppColors.primary : AppColors.calicoCharcoal;

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: granted ? AppColors.gingerSoft.withAlpha(140) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: granted ? AppColors.gingerBorder : AppColors.border,
          width: 1.3,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: granted ? AppColors.calicoBlack : AppColors.creamSurface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: granted
                    ? AppColors.primary.withAlpha(120)
                    : AppColors.border,
              ),
            ),
            child: Icon(
              granted ? Icons.check_circle_rounded : icon,
              color: granted ? AppColors.primary : accent,
              size: 21,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
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
                          color: granted
                              ? AppColors.primary.withAlpha(28)
                              : AppColors.calicoBlack,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          granted ? 'Granted' : 'Required',
                          style: TextStyle(
                            fontSize: 10,
                            color: granted
                                ? AppColors.primaryDark
                                : Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
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
      body: CalicoAmbientBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.calicoBlack,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(110),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'PATROL GEAR CHECK',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Transform.translate(
                      offset: const Offset(0, 10),
                      child: const CalicoLoginMascot(),
                    ),
                    CalicoSpotCard(
                      padding: const EdgeInsets.all(22),
                      borderRadius: 26,
                      borderColor: AppColors.gingerBorder.withAlpha(150),
                      child: Column(
                        children: [
                          const Text(
                            'Before you explore',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildPermissionTile(
                            icon: Icons.explore_outlined,
                            title: 'Location access',
                            subtitle: 'Pins nearby street cat sightings and charts your barangay patrol.',
                            required: true,
                            granted: !_needsLocation,
                          ),
                          _buildPermissionTile(
                            icon: Icons.photo_camera_outlined,
                            title: 'Camera access',
                            subtitle: 'Captures cat sightings and classifies coats for your Iring-Dex.',
                            required: true,
                            granted: !_needsCamera,
                          ),
                          const SizedBox(height: 8),
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primary,
                              ),
                            )
                          else ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _requestAllPermissions,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Allow Explorer Access',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _openSettings,
                              child: const Text(
                                'Open browser or device settings',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

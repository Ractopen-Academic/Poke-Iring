import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_version.dart';
import '../../features/auth/presentation/widgets/calico_login_mascot.dart';
import 'app_version_badge.dart';

class NetworkErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const NetworkErrorView({super.key, this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      body: CalicoAmbientBackdrop(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withAlpha(24),
                            border: Border.all(
                              color: AppColors.primary.withAlpha(60),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.wifi_off_rounded,
                            size: 42,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Connection Error',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dynamicTextPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          message ?? 'Server or network error. Poke: Iring is an online game and requires an active internet connection to load live territories, sightings, and feline data.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: AppColors.dynamicTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text(
                              'Retry Connection',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(left: 16, bottom: 12, child: AppVersionBadge()),
            ],
          ),
        ),
      ),
    );
  }
}

class MaintenanceLockoutView extends StatelessWidget {
  final String message;
  final VoidCallback? onRefresh;

  const MaintenanceLockoutView({
    super.key,
    required this.message,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      body: CalicoAmbientBackdrop(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 120,
                          height: 100,
                          child: CalicoLoginMascot(),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withAlpha(24),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withAlpha(80),
                            ),
                          ),
                          child: const Text(
                            'Maintenance in Progress',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Paws on Pause',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dynamicTextPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: AppColors.dynamicTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (onRefresh != null)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: onRefresh,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text(
                                'Check Status Again',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: BorderSide(
                                  color: AppColors.primary.withAlpha(120),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(left: 16, bottom: 12, child: AppVersionBadge()),
            ],
          ),
        ),
      ),
    );
  }
}

class VersionUpdateRequiredView extends StatelessWidget {
  final String requiredVersion;

  const VersionUpdateRequiredView({super.key, required this.requiredVersion});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      body: CalicoAmbientBackdrop(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withAlpha(24),
                            border: Border.all(
                              color: AppColors.primary.withAlpha(60),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.system_update_rounded,
                            size: 42,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'App Update Required',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dynamicTextPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Poke: Iring version $requiredVersion or higher is required to continue playing. Your current installed build is ${AppVersion.semanticVersion}. Please download the latest update.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: AppColors.dynamicTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(left: 16, bottom: 12, child: AppVersionBadge()),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountSuspendedLockoutView extends StatelessWidget {
  final bool isPermanentBan;
  final String reason;
  final DateTime? suspendedUntil;
  final VoidCallback onSignOut;
  final VoidCallback? onRefresh;

  const AccountSuspendedLockoutView({
    super.key,
    required this.isPermanentBan,
    required this.reason,
    this.suspendedUntil,
    required this.onSignOut,
    this.onRefresh,
  });

  String get _timeRemainingFormatted {
    if (suspendedUntil == null) return '';
    final now = DateTime.now();
    if (now.isAfter(suspendedUntil!)) {
      return 'Suspension expired. You can retry logging in.';
    }
    final diff = suspendedUntil!.difference(now);
    if (diff.inDays > 0) {
      final hours = diff.inHours % 24;
      return '${diff.inDays}d ${hours}h remaining';
    }
    if (diff.inHours > 0) {
      final mins = diff.inMinutes % 60;
      return '${diff.inHours}h ${mins}m remaining';
    }
    return '${diff.inMinutes}m remaining';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      body: CalicoAmbientBackdrop(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFDC2626).withAlpha(24),
                            border: Border.all(
                              color: const Color(0xFFDC2626).withAlpha(70),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            isPermanentBan
                                ? Icons.block_rounded
                                : Icons.schedule_rounded,
                            size: 40,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withAlpha(20),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFFDC2626).withAlpha(60),
                            ),
                          ),
                          child: Text(
                            isPermanentBan
                                ? 'Account Suspended Indefinitely'
                                : 'Temporary Patrol Suspension',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          isPermanentBan
                              ? 'Access Revoked'
                              : 'Patrol Access Paused',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dynamicTextPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.dynamicSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.dynamicBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Moderation Notice:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.dynamicTextSecondary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reason.isNotEmpty
                                    ? reason
                                    : 'Account flagged for safety or fair-play violations.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: AppColors.dynamicTextPrimary,
                                ),
                              ),
                              if (!isPermanentBan && suspendedUntil != null) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 13,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _timeRemainingFormatted,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFF59E0B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'For questions or dispute appeals, contact operations administration at admin@iring.ph.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.4,
                            color: AppColors.dynamicTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (onRefresh != null && !isPermanentBan) ...[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: onRefresh,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text(
                                'Check Status',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.dynamicTextPrimary,
                                side: BorderSide(color: AppColors.dynamicBorder),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: onSignOut,
                            icon: const Icon(Icons.logout_rounded, size: 16),
                            label: const Text(
                              'Sign Out Explorer',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(left: 16, bottom: 12, child: AppVersionBadge()),
            ],
          ),
        ),
      ),
    );
  }
}

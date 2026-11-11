import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_version.dart';
import '../../../../core/services/remote_config_service.dart';
import '../../../../core/widgets/lockout_views.dart';
import '../../../permissions/presentation/pages/permission_gate.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../home/presentation/pages/main_navigation_shell.dart';
import '../widgets/calico_login_mascot.dart';
import 'email_verification_page.dart';
import 'login_page.dart';

class AuthGate extends StatefulWidget {
  final AuthRepository authRepository;

  const AuthGate({super.key, required this.authRepository});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _skippedVerification = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GlobalAppConfig>(
      stream: RemoteConfigService.instance.streamConfig(),
      initialData: RemoteConfigService.instance.config,
      builder: (context, configSnapshot) {
        final config =
            configSnapshot.data ?? RemoteConfigService.instance.config;

        if (config.maintenanceMode) {
          return MaintenanceLockoutView(
            message: config.maintenanceMessage,
            onRefresh: () => setState(() {}),
          );
        }

        if (RemoteConfigService.instance.hasSuccessfullySynced &&
            !RemoteConfigService.isVersionSupported(
              AppVersion.semanticVersion,
              config.minAppVersion,
            )) {
          return VersionUpdateRequiredView(
            requiredVersion: config.minAppVersion,
          );
        }

        return StreamBuilder<AuthUser?>(
          stream: widget.authRepository.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: AppColors.dynamicBackground,
                body: CalicoAmbientBackdrop(
                  child: Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.dynamicPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            final user = snapshot.data;
            if (user != null && user.isNotEmpty) {
              if (!user.emailVerified && !_skippedVerification) {
                return EmailVerificationPage(
                  user: user,
                  authRepository: widget.authRepository,
                  onSkip: () => setState(() => _skippedVerification = true),
                );
              }
              if (Firebase.apps.isEmpty) {
                return PermissionGate(
                  user: user,
                  authRepository: widget.authRepository,
                );
              }

              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.id)
                    .snapshots(),
                builder: (context, userDocSnap) {
                  if (userDocSnap.hasData &&
                      userDocSnap.data != null &&
                      userDocSnap.data!.exists) {
                    final data = userDocSnap.data!.data() ?? {};
                    final status = data['status'] as String? ?? 'active';
                    final reason = data['banReason'] as String? ?? '';
                    final suspendedUntilRaw = data['suspendedUntil'];
                    DateTime? suspendedUntil;
                    if (suspendedUntilRaw is Timestamp) {
                      suspendedUntil = suspendedUntilRaw.toDate();
                    } else if (suspendedUntilRaw is String &&
                        suspendedUntilRaw.isNotEmpty) {
                      suspendedUntil = DateTime.tryParse(suspendedUntilRaw);
                    }

                    if (status == 'banned') {
                      return AccountSuspendedLockoutView(
                        isPermanentBan: true,
                        reason: reason,
                        onSignOut: () async {
                          MainNavigationShell.resetSession();
                          await widget.authRepository.signOut();
                        },
                      );
                    }

                    if (status == 'suspended' && suspendedUntil != null) {
                      if (DateTime.now().isBefore(suspendedUntil)) {
                        return AccountSuspendedLockoutView(
                          isPermanentBan: false,
                          reason: reason,
                          suspendedUntil: suspendedUntil,
                          onRefresh: () => setState(() {}),
                          onSignOut: () async {
                            MainNavigationShell.resetSession();
                            await widget.authRepository.signOut();
                          },
                        );
                      }
                    }
                  }

                  return PermissionGate(
                    user: user,
                    authRepository: widget.authRepository,
                  );
                },
              );
            }

            // Reset skip state and navigation session when signed out
            MainNavigationShell.resetSession();
            if (_skippedVerification) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _skippedVerification = false);
              });
            }

            return LoginPage(authRepository: widget.authRepository);
          },
        );
      },
    );
  }
}

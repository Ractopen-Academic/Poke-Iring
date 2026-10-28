import 'package:flutter/material.dart';

import '../../../home/presentation/pages/main_navigation_shell.dart';
import '../../../splash/presentation/pages/app_bootstrap_page.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'email_verification_page.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  final AuthRepository authRepository;

  const AuthGate({super.key, required this.authRepository});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthUser?>(
      stream: authRepository.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user != null && user.isNotEmpty) {
          if (!user.emailVerified) {
            return EmailVerificationPage(
              user: user,
              authRepository: authRepository,
            );
          }
          return AppBootstrapPage(
            onReady: (context, result) => MainNavigationShell(
              user: user,
              authRepository: authRepository,
              initialOnline: result.isOnline,
              initialLocationStatus: result.locationStatus,
            ),
          );
        }

        return LoginPage(authRepository: authRepository);
      },
    );
  }
}

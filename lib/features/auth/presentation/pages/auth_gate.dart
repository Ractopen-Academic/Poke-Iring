import 'package:flutter/material.dart';

import '../../../permissions/presentation/pages/permission_gate.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
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
    return StreamBuilder<AuthUser?>(
      stream: widget.authRepository.authStateChanges,
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
          if (!user.emailVerified && !_skippedVerification) {
            return EmailVerificationPage(
              user: user,
              authRepository: widget.authRepository,
              onSkip: () => setState(() => _skippedVerification = true),
            );
          }
          return PermissionGate(
            user: user,
            authRepository: widget.authRepository,
          );
        }

        // Reset skip state when signed out
        if (_skippedVerification) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _skippedVerification = false);
          });
        }

        return LoginPage(authRepository: widget.authRepository);
      },
    );
  }
}

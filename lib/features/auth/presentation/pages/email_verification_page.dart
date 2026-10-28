import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class EmailVerificationPage extends StatefulWidget {
  final AuthUser user;
  final AuthRepository authRepository;

  const EmailVerificationPage({
    super.key,
    required this.user,
    required this.authRepository,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await action();
      if (mounted) {
        setState(() {
          _message = successMessage;
          _isError = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = error.toString().replaceFirst('Exception: ', '');
          _isError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.appName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 56,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Verify your email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a verification link to ${widget.user.email}. Verify your address to continue.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isError
                            ? Colors.red.shade700
                            : AppColors.secondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  AppButton(
                    text: 'I verified my email',
                    isLoading: _isLoading,
                    onPressed: () => _runAction(
                      widget.authRepository.reloadCurrentUser,
                      successMessage: 'Email checked. If you have not verified it yet, open the link in your inbox first.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Resend verification email',
                    isOutlined: true,
                    isLoading: _isLoading,
                    onPressed: () => _runAction(
                      widget.authRepository.sendEmailVerification,
                      successMessage: 'A new verification link has been sent.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : widget.authRepository.signOut,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

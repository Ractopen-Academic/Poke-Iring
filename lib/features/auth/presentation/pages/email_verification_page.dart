import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/calico_ui_kit.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../widgets/calico_login_mascot.dart';

class EmailVerificationPage extends StatefulWidget {
  final AuthUser user;
  final AuthRepository authRepository;
  final VoidCallback? onSkip;

  const EmailVerificationPage({
    super.key,
    required this.user,
    required this.authRepository,
    this.onSkip,
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
      backgroundColor: AppColors.dynamicBackground,
      body: CalicoAmbientBackdrop(
        child: SafeArea(
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
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.dynamicTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Transform.translate(
                        offset: const Offset(0, 10),
                        child: CalicoLoginMascot(hasError: _isError),
                      ),
                    ),
                    CalicoSpotCard(
                      padding: const EdgeInsets.all(22),
                      borderRadius: 26,
                      borderColor: AppColors.dynamicBorder,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.gingerSoft,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.dynamicBorder,
                                ),
                              ),
                              child: const Icon(
                                Icons.mark_email_unread_outlined,
                                size: 28,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Verify your email',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: AppColors.dynamicTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'We sent a verification link to ${widget.user.email}. Confirm your address to secure your explorer passport.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: AppColors.dynamicTextSecondary,
                            ),
                          ),
                          if (_message != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isError
                                    ? const Color(0xFFFEF2F2)
                                    : AppColors.gingerSoft,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isError
                                      ? const Color(0xFFFECACA)
                                      : AppColors.gingerBorder,
                                ),
                              ),
                              child: Text(
                                _message!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _isError
                                      ? Colors.red.shade800
                                      : AppColors.primaryDark,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          AppButton(
                            text: 'I verified my email',
                            isLoading: _isLoading,
                            onPressed: () => _runAction(
                              widget.authRepository.reloadCurrentUser,
                              successMessage: 'Email checked. Open the link in your inbox if it is still pending.',
                            ),
                          ),
                          const SizedBox(height: 10),
                          AppButton(
                            text: 'Resend verification email',
                            isOutlined: true,
                            isLoading: _isLoading,
                            onPressed: () => _runAction(
                              widget.authRepository.sendEmailVerification,
                              successMessage:
                                  'A new verification link has been sent.',
                            ),
                          ),
                          if (widget.onSkip != null) ...[
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: _isLoading ? null : widget.onSkip,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryDark,
                                side: const BorderSide(
                                  color: AppColors.gingerBorder,
                                ),
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Continue to App (Skip for now)',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : widget.authRepository.signOut,
                            child: const Text(
                              'Sign out',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
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

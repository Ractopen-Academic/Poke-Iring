import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/auth_error_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_version_badge.dart';
import '../../../../core/widgets/calico_ui_kit.dart';
import '../../domain/repositories/auth_repository.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_mode_selector.dart';
import '../widgets/calico_login_mascot.dart';
import '../widgets/login_mascot_controller.dart';
import 'forgot_password_dialog.dart';

class LoginPage extends StatefulWidget {
  final AuthRepository authRepository;

  const LoginPage({super.key, required this.authRepository});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _nicknameFocusNode = FocusNode();

  late final LoginMascotController _mascotController;

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _mascotController = LoginMascotController(
      emailFocusNode: _emailFocusNode,
      passwordFocusNode: _passwordFocusNode,
      confirmPasswordFocusNode: _confirmPasswordFocusNode,
    );
  }

  @override
  void dispose() {
    _mascotController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _nicknameFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleManualAuth() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isSignUp) {
        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() {
            _errorMessage = AuthErrorFormatter.format('Passwords do not match');
            _isLoading = false;
          });
          return;
        }
        final nickname = _nicknameController.text.trim();
        await widget.authRepository.registerWithEmailPassword(
          email,
          password,
          nickname: nickname.isNotEmpty ? nickname : null,
        );
      } else {
        await widget.authRepository.signInWithEmailPassword(email, password);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthErrorFormatter.format(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleAuth() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authRepository.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthErrorFormatter.format(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectMode(bool signUp) {
    if (_isLoading || _isSignUp == signUp) return;
    setState(() {
      _isSignUp = signUp;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      body: CalicoAmbientBackdrop(
        child: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight - 44).clamp(
                            0,
                            1200,
                          ),
                          maxWidth: 420,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 12),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.dynamicChromeTrack,
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(
                                      color: AppColors.primaryDark.withAlpha(
                                        120,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.pets_rounded,
                                        size: 13,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        'FELINE EXPLORER NETWORK',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.dynamicTextPrimary,
                                          letterSpacing: 0.7,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                AppStrings.appName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 31,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.dynamicTextPrimary,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  _isSignUp
                                      ? 'Join your barangay patrol and catalog local street cats'
                                      : AppStrings.tagline,
                                  key: ValueKey<bool>(_isSignUp),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.dynamicTextSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Center(
                                child: Transform.translate(
                                  offset: const Offset(0, 10),
                                  child: ListenableBuilder(
                                    listenable: _mascotController,
                                    builder: (context, _) {
                                      return CalicoLoginMascot(
                                        isEmailFocused:
                                            _mascotController.isEmailFocused,
                                        isPasswordFocused:
                                            _mascotController.isPasswordFocused,
                                        isPasswordVisible: !_obscurePassword,
                                        gazeAlignment: _mascotController
                                            .emailGazeAlignment,
                                        hasError: _errorMessage != null,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              CalicoSpotCard(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  22,
                                  20,
                                  24,
                                ),
                                borderRadius: 26,
                                backgroundColor: AppColors.dynamicSurface,
                                borderColor: AppColors.dynamicBorder,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    AuthModeSelector(
                                      isSignUp: _isSignUp,
                                      onModeChanged: _selectMode,
                                    ),
                                    const SizedBox(height: 18),
                                    if (_errorMessage != null) ...[
                                      AuthErrorBanner(message: _errorMessage!),
                                      const SizedBox(height: 16),
                                    ],
                                    AnimatedSize(
                                      duration: const Duration(
                                        milliseconds: 240,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          if (_isSignUp) ...[
                                            AppTextField(
                                              controller: _nicknameController,
                                              focusNode: _nicknameFocusNode,
                                              label: 'Nickname',
                                              hint: 'e.g. WhiskerPatrol',
                                              prefixIcon: Icons.badge_outlined,
                                              validator: (val) {
                                                if (_isSignUp &&
                                                    (val == null ||
                                                        val.trim().isEmpty)) {
                                                  return 'Please choose a nickname';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 14),
                                          ],
                                          AppTextField(
                                            controller: _emailController,
                                            focusNode: _emailFocusNode,
                                            onChanged: _mascotController
                                                .updateEmailGaze,
                                            label: 'Email Address',
                                            hint: 'explorer@example.com',
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            prefixIcon: Icons.email_outlined,
                                            validator: (val) {
                                              if (val == null ||
                                                  val.trim().isEmpty) {
                                                return 'Please enter your email';
                                              }
                                              if (!val.contains('@')) {
                                                return 'Please enter a valid email';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 14),
                                          AppTextField(
                                            controller: _passwordController,
                                            focusNode: _passwordFocusNode,
                                            label: 'Password',
                                            obscureText: _obscurePassword,
                                            prefixIcon: Icons.lock_outline,
                                            suffixIcon: IconButton(
                                              tooltip: _obscurePassword
                                                  ? 'Show password'
                                                  : 'Hide password',
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons
                                                          .visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color: _obscurePassword
                                                    ? const Color(0xFFB3A89D)
                                                    : AppColors.primary,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword =
                                                      !_obscurePassword;
                                                });
                                              },
                                            ),
                                            validator: (val) {
                                              if (val == null || val.isEmpty) {
                                                return 'Please enter your password';
                                              }
                                              if (val.length < 6) {
                                                return 'Password must be at least 6 characters';
                                              }
                                              return null;
                                            },
                                          ),
                                          if (_isSignUp) ...[
                                            const SizedBox(height: 14),
                                            AppTextField(
                                              controller:
                                                  _confirmPasswordController,
                                              focusNode:
                                                  _confirmPasswordFocusNode,
                                              label: 'Confirm Password',
                                              obscureText:
                                                  _obscureConfirmPassword,
                                              prefixIcon:
                                                  Icons.lock_clock_outlined,
                                              suffixIcon: IconButton(
                                                tooltip: _obscureConfirmPassword
                                                    ? 'Show password'
                                                    : 'Hide password',
                                                icon: Icon(
                                                  _obscureConfirmPassword
                                                      ? Icons
                                                            .visibility_off_outlined
                                                      : Icons
                                                            .visibility_outlined,
                                                  color: _obscureConfirmPassword
                                                      ? const Color(0xFFB3A89D)
                                                      : AppColors.primary,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _obscureConfirmPassword =
                                                        !_obscureConfirmPassword;
                                                  });
                                                },
                                              ),
                                              validator: (val) {
                                                if (_isSignUp) {
                                                  if (val == null ||
                                                      val.isEmpty) {
                                                    return 'Please confirm your password';
                                                  }
                                                  if (val !=
                                                      _passwordController
                                                          .text) {
                                                    return 'Passwords do not match';
                                                  }
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                          if (!_isSignUp) ...[
                                            const SizedBox(height: 8),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: TextButton(
                                                onPressed: _isLoading
                                                    ? null
                                                    : () =>
                                                          ForgotPasswordDialog.show(
                                                            context,
                                                            widget
                                                                .authRepository,
                                                          ),
                                                style: TextButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 4,
                                                      ),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                                child: const Text(
                                                  'Forgot Password?',
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                          ] else ...[
                                            const SizedBox(height: 18),
                                          ],
                                        ],
                                      ),
                                    ),
                                    AppButton(
                                      text: _isSignUp
                                          ? 'Create Explorer Account'
                                          : 'Enter Territory',
                                      isLoading: _isLoading,
                                      onPressed: _handleManualAuth,
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: AppColors.dynamicBorder,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                          ),
                                          child: Text(
                                            'or continue with',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors
                                                  .dynamicTextSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: AppColors.dynamicBorder,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    AppButton(
                                      text: 'Continue with Google',
                                      isOutlined: true,
                                      isLoading: _isLoading,
                                      icon: Image.asset(
                                        AppAssets.googleLogo,
                                        width: 20,
                                        height: 20,
                                      ),
                                      onPressed: _handleGoogleAuth,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Positioned(left: 16, bottom: 10, child: AppVersionBadge()),
            ],
          ),
        ),
      ),
    );
  }
}

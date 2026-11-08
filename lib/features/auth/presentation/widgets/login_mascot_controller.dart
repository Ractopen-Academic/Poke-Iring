import 'package:flutter/widgets.dart';

/// Coordinates focus and gaze states between auth form fields and [CalicoLoginMascot].
///
/// Encapsulates focus listeners and gaze alignment calculations so high-frequency
/// typing events only notify the mascot without forcing a full rebuild of the form tree.
class LoginMascotController extends ChangeNotifier {
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final FocusNode confirmPasswordFocusNode;

  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  double _emailGazeAlignment = 0.0;

  bool get isEmailFocused => _isEmailFocused;
  bool get isPasswordFocused => _isPasswordFocused;
  double get emailGazeAlignment => _emailGazeAlignment;

  LoginMascotController({
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.confirmPasswordFocusNode,
  }) {
    emailFocusNode.addListener(_syncFocusState);
    passwordFocusNode.addListener(_syncFocusState);
    confirmPasswordFocusNode.addListener(_syncFocusState);
    _syncFocusState();
  }

  void updateEmailGaze(String value) {
    final normalized = ((value.length.clamp(0, 28) / 28.0) * 2.0) - 1.0;
    if ((_emailGazeAlignment - normalized).abs() > 0.04) {
      _emailGazeAlignment = normalized;
      notifyListeners();
    }
  }

  void _syncFocusState() {
    final newEmail = emailFocusNode.hasFocus;
    final newPassword =
        passwordFocusNode.hasFocus || confirmPasswordFocusNode.hasFocus;
    if (newEmail != _isEmailFocused || newPassword != _isPasswordFocused) {
      _isEmailFocused = newEmail;
      _isPasswordFocused = newPassword;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailFocusNode.removeListener(_syncFocusState);
    passwordFocusNode.removeListener(_syncFocusState);
    confirmPasswordFocusNode.removeListener(_syncFocusState);
    super.dispose();
  }
}

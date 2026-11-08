import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/auth/presentation/widgets/login_mascot_controller.dart';

void main() {
  group('LoginMascotController', () {
    late FocusNode emailFocus;
    late FocusNode passwordFocus;
    late FocusNode confirmPasswordFocus;
    late LoginMascotController controller;

    setUp(() {
      emailFocus = FocusNode();
      passwordFocus = FocusNode();
      confirmPasswordFocus = FocusNode();
      controller = LoginMascotController(
        emailFocusNode: emailFocus,
        passwordFocusNode: passwordFocus,
        confirmPasswordFocusNode: confirmPasswordFocus,
      );
    });

    tearDown(() {
      controller.dispose();
      emailFocus.dispose();
      passwordFocus.dispose();
      confirmPasswordFocus.dispose();
    });

    test('initializes with inactive focus states and zero gaze alignment', () {
      expect(controller.isEmailFocused, isFalse);
      expect(controller.isPasswordFocused, isFalse);
      expect(controller.emailGazeAlignment, 0.0);
    });

    test('updates gaze alignment as email text length changes', () {
      int notifications = 0;
      controller.addListener(() => notifications++);

      controller.updateEmailGaze('test');
      expect(controller.emailGazeAlignment, isNot(0.0));
      expect(notifications, greaterThan(0));

      final lastGaze = controller.emailGazeAlignment;
      // Very tiny difference should not trigger extra notifications (debounced by threshold)
      controller.updateEmailGaze('test');
      expect(controller.emailGazeAlignment, lastGaze);

      // Long text clamps to 1.0
      controller.updateEmailGaze('a' * 50);
      expect(controller.emailGazeAlignment, 1.0);
    });
  });
}

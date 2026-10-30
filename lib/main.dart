import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/responsive_web_shell.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/data/repositories/dev_auth_repository.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/pages/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final isFirebaseSupported =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows);

  late final AuthRepository authRepository;

  if (isFirebaseSupported) {
    try {
      await Firebase.initializeApp();
      authRepository = AuthRepositoryImpl();
    } catch (e) {
      debugPrint(
        'Firebase initialization failed, falling back to DevAuthRepository: $e',
      );
      authRepository = DevAuthRepository();
    }
  } else {
    authRepository = DevAuthRepository();
  }

  runApp(PokeIringApp(authRepository: authRepository));
}

class PokeIringApp extends StatelessWidget {
  final AuthRepository authRepository;

  const PokeIringApp({super.key, required this.authRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) =>
          ResponsiveWebShell(child: child ?? const SizedBox.shrink()),
      home: AuthGate(authRepository: authRepository),
    );
  }
}

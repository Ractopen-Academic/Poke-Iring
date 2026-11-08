import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/constants/app_strings.dart';
import 'core/services/data_purge_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/calico_theme_controller.dart';
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

  await CalicoThemeController.instance.loadSavedMode();
  await DataPurgeService.init();

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

class PokeIringApp extends StatefulWidget {
  final AuthRepository authRepository;

  const PokeIringApp({super.key, required this.authRepository});

  @override
  State<PokeIringApp> createState() => _PokeIringAppState();
}

class _PokeIringAppState extends State<PokeIringApp> {
  @override
  void initState() {
    super.initState();
    CalicoThemeController.instance.addListener(_handleThemeChanged);
  }

  @override
  void dispose() {
    CalicoThemeController.instance.removeListener(_handleThemeChanged);
    super.dispose();
  }

  void _handleThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mode = CalicoThemeController.instance.mode;
    final effective = CalicoThemeController.instance.effectiveMode;

    return MaterialApp(
      key: ValueKey('pokeiring_root_${effective.name}'),
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeFor(effective),
      darkTheme: AppTheme.themeFor(CalicoCoatMode.calicoDark),
      themeMode: mode == CalicoCoatMode.system
          ? ThemeMode.system
          : (effective == CalicoCoatMode.calicoDark
                ? ThemeMode.dark
                : ThemeMode.light),
      builder: (context, child) =>
          ResponsiveWebShell(child: child ?? const SizedBox.shrink()),
      home: AuthGate(
        key: ValueKey('pokeiring_auth_gate_${effective.name}'),
        authRepository: widget.authRepository,
      ),
    );
  }
}

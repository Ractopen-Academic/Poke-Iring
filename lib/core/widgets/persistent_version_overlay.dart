import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_version.dart';
import '../theme/calico_theme_controller.dart';

/// Controller managing persistent bottom-left version watermark visibility and placement.
class AppVersionOverlayController {
  AppVersionOverlayController._();
  static final AppVersionOverlayController instance =
      AppVersionOverlayController._();

  /// ValueNotifier indicating whether the camera / scanner viewfinder is active.
  final ValueNotifier<bool> isCameraActive = ValueNotifier<bool>(false);

  /// ValueNotifier indicating whether the bottom navigation bar is active on screen.
  final ValueNotifier<bool> isBottomNavActive = ValueNotifier<bool>(false);

  /// Sets camera active state. When true, the version badge is hidden.
  void setCameraActive(bool active) {
    if (isCameraActive.value != active) {
      isCameraActive.value = active;
    }
  }

  /// Sets bottom navigation bar active state. When true, vertical offset floats above the bar.
  void setBottomNavActive(bool active) {
    if (isBottomNavActive.value != active) {
      isBottomNavActive.value = active;
    }
  }
}

/// Route observer to detect scanner / camera route transitions.
class AppVersionRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _evaluateRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _evaluateRoute(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _evaluateRoute(newRoute);
    }
  }

  void _evaluateRoute(Route<dynamic> route) {
    final name = route.settings.name?.toLowerCase() ?? '';
    final isCameraRoute = name.contains('scanner') || name.contains('camera');
    AppVersionOverlayController.instance.setCameraActive(isCameraRoute);
  }
}

/// Global overlay widget that persists the discreet version badge at the bottom-left corner
/// across all screens (login, loading, lockout/error views, home, map, etc.),
/// hiding it only when taking camera / scanning cats.
class PersistentVersionOverlay extends StatelessWidget {
  final Widget child;

  const PersistentVersionOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final controller = AppVersionOverlayController.instance;

    return Stack(
      children: [
        child,
        ListenableBuilder(
          listenable: Listenable.merge([
            controller.isCameraActive,
            controller.isBottomNavActive,
            CalicoThemeController.instance,
          ]),
          builder: (context, _) {
            // Only in taking camera should it not be shown
            if (controller.isCameraActive.value) {
              return const SizedBox.shrink();
            }

            final hasBottomNav = controller.isBottomNavActive.value;
            // Float neatly above bottom nav bar (84px) or sit discreetly in bottom left (12px)
            final bottomOffset = hasBottomNav ? 84.0 : 12.0;

            return Positioned(
              left: 14,
              bottom: bottomOffset,
              child: IgnorePointer(
                child: SafeArea(
                  top: false,
                  right: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dynamicChromeTrack.withAlpha(180),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: AppColors.dynamicBorder.withAlpha(140),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      AppVersion.releaseTag,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dynamicTextSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

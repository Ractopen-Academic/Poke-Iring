import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/services/quick_snap_position_service.dart';

class QuickSnapPositionServiceImpl implements QuickSnapPositionService {
  static const _keyX = 'quick_snap_x_fraction';
  static const _keyY = 'quick_snap_y_fraction';

  @override
  Future<QuickSnapPosition> loadPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final x = prefs.getDouble(_keyX);
      final y = prefs.getDouble(_keyY);

      if (x != null && y != null) {
        final clampedX = x <= 0.5 ? 0.0 : 1.0;
        final clampedY = y.clamp(0.12, 0.82);
        return QuickSnapPosition(xFraction: clampedX, yFraction: clampedY);
      }
    } catch (_) {
      // Degrade gracefully to default on error
    }
    return QuickSnapPosition.defaultPosition;
  }

  @override
  Future<void> savePosition(QuickSnapPosition position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyX, position.xFraction);
      await prefs.setDouble(_keyY, position.yFraction);
    } catch (_) {
      // Ignore storage write failures
    }
  }
}

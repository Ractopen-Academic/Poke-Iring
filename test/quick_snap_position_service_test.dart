import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/scanner/data/services/quick_snap_position_service_impl.dart';
import 'package:pokeiring/features/scanner/domain/services/quick_snap_position_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuickSnapPositionServiceImpl', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns default position when no saved coordinates exist', () async {
      final service = QuickSnapPositionServiceImpl();
      final position = await service.loadPosition();

      expect(
        position.xFraction,
        equals(QuickSnapPosition.defaultPosition.xFraction),
      );
      expect(
        position.yFraction,
        equals(QuickSnapPosition.defaultPosition.yFraction),
      );
    });

    test('persists and restores snapped coordinates safely', () async {
      final service = QuickSnapPositionServiceImpl();
      const testPos = QuickSnapPosition(xFraction: 0.0, yFraction: 0.45);

      await service.savePosition(testPos);
      final restored = await service.loadPosition();

      expect(restored.xFraction, equals(0.0));
      expect(restored.yFraction, equals(0.45));
    });

    test('clamps yFraction if saved values exceed safe bounds', () async {
      SharedPreferences.setMockInitialValues({
        'quick_snap_x_fraction': 1.0,
        'quick_snap_y_fraction': 0.99,
      });

      final service = QuickSnapPositionServiceImpl();
      final restored = await service.loadPosition();

      expect(restored.xFraction, equals(1.0));
      expect(restored.yFraction, lessThanOrEqualTo(0.82));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/core/services/app_cache_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppCacheCoordinator Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('forceRecacheAll executes across all catalogs and produces report', () async {
      final report = await AppCacheCoordinator.instance.forceRecacheAll(
        userId: 'test_explorer',
      );

      expect(report.syncedCollectionsCount, greaterThanOrEqualTo(4));
      expect(report.timestamp, isNotNull);
      expect(report.statusSummary, isNotEmpty);
    });

    test('refreshHomeFeed runs without throwing', () async {
      await expectLater(
        AppCacheCoordinator.instance.refreshHomeFeed(userId: 'test_explorer'),
        completes,
      );
    });

    test('refreshDex runs without throwing', () async {
      await expectLater(
        AppCacheCoordinator.instance.refreshDex(),
        completes,
      );
    });

    test('refreshLeaderboard runs without throwing', () async {
      await expectLater(
        AppCacheCoordinator.instance.refreshLeaderboard(userId: 'test_explorer'),
        completes,
      );
    });
  });
}

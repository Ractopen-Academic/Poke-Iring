import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/rewards/services/reward_item.dart';
import 'package:pokeiring/features/rewards/services/rewards_service.dart';
import 'package:pokeiring/features/scanner/domain/entities/cat_sighting.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dual Verification Entity Tests', () {
    test('CatSighting supports AI stage 1 and Human stage 2 fields', () {
      final now = DateTime.now();
      final sighting = CatSighting(
        id: 'test-sighting-1',
        userId: 'user-alice',
        authorName: 'Alice',
        photoUrl: 'https://example.com/cat.jpg',
        stickerUrl: '',
        latitude: 10.3155,
        longitude: 123.9730,
        geohash: 'w721x',
        barangay: 'Bankal',
        city: 'Lapu-Lapu City',
        region: 'Central Visayas',
        country: 'Philippines',
        breed: 'Domestic Shorthair (Puspin)',
        coatPattern: 'Calico',
        dominantColor: 'Calico',
        rarityMultiplier: 1.4,
        pawPoints: 100,
        quirk: 'Exploring the backyard.',
        createdAt: now,
        aiVerified: true,
        aiConfidence: 0.98,
        humanUpvotes: 0,
        humanDownvotes: 0,
      );

      expect(sighting.aiVerified, isTrue);
      expect(sighting.aiConfidence, 0.98);
      expect(sighting.isHumanVerified, isFalse);

      final verified = sighting.copyWith(
        humanUpvotes: 3,
        humanDownvotes: 0,
        verifiedByUsers: ['user-bob', 'user-charlie', 'user-dan'],
      );

      expect(verified.isHumanVerified, isTrue);
      expect(verified.humanUpvotes, 3);
      expect(verified.verifiedByUsers.length, 3);

      final map = verified.toMap();
      final fromMap = CatSighting.fromMap(map);
      expect(fromMap.aiVerified, isTrue);
      expect(fromMap.isHumanVerified, isTrue);
      expect(fromMap.humanUpvotes, 3);
    });
  });

  group('RewardsService and Catalog Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await RewardsService.instance.reload();
    });

    test('catalog contains real-life cat food and animal welfare items', () {
      expect(RewardItem.catalog, isNotEmpty);
      final hasCatFood = RewardItem.catalog.any((i) => i.type == RewardType.catFood);
      final hasDonation = RewardItem.catalog.any((i) => i.type == RewardType.welfareDonation);

      expect(hasCatFood, isTrue);
      expect(hasDonation, isTrue);
    });

    test('redeemReward decrements points balance and registers redemption', () async {
      final service = RewardsService.instance;
      service.pointsNotifier.value = 500;

      final foodItem = RewardItem.catalog.firstWhere(
        (i) => i.type == RewardType.catFood,
      );

      final success = await service.redeemReward(
        userId: 'user-test',
        item: foodItem,
      );

      expect(success, isTrue);
      expect(service.pointsNotifier.value, 500 - foodItem.costPawPoints);
      expect(service.redemptionsNotifier.value.first.itemId, foodItem.id);
    });

    test('redeemReward rejects when balance is insufficient', () async {
      final service = RewardsService.instance;
      service.pointsNotifier.value = 50;

      final costlyItem = RewardItem.catalog.firstWhere(
        (i) => i.costPawPoints > 100,
      );

      final success = await service.redeemReward(
        userId: 'user-test',
        item: costlyItem,
      );

      expect(success, isFalse);
      expect(service.pointsNotifier.value, 50);
    });
  });
}

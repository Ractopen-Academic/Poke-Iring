import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/events/data/repositories/event_repository_impl.dart';
import 'package:pokeiring/features/events/domain/entities/user_event_wallet.dart';
import 'package:pokeiring/features/seasons/data/services/season_service_impl.dart';
import 'package:pokeiring/features/subscription/data/services/subscription_service_impl.dart';
import 'package:pokeiring/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pokeiring/features/territory/data/services/territory_service_impl.dart';
import 'package:pokeiring/features/vault/data/services/photo_vault_service_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Online-First Architecture Tests', () {
    test(
      'PhotoVaultServiceImpl falls back to local cache or seed when offline',
      () async {
        final vaultService = PhotoVaultServiceImpl.instance;
        vaultService.resetCache();

        // Clean install offline returns seed photos
        final seeds = await vaultService.getVault('user-clean');
        expect(seeds, isNotEmpty);
        expect(seeds.first.userId, equals('user-clean'));

        // Seed local prefs with custom photo
        final custom = seeds.first.copyWith(id: 'cached-photo-1');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('feline_club_raw_vault_user-offline', [
          jsonEncode(custom.toMap()),
        ]);

        vaultService.resetCache();
        final cachedPhotos = await vaultService.getVault('user-offline');
        expect(cachedPhotos.any((p) => p.id == 'cached-photo-1'), isTrue);
      },
    );

    test('SubscriptionServiceImpl falls back to local cache or free status when offline', () async {
      final subService = SubscriptionServiceImpl.instance;
      subService.resetCache();

      // Clean install offline returns free tier
      final freeStatus = await subService.getSubscription('user-free-test');
      expect(freeStatus.tier, equals(SubscriptionTier.free));
      expect(freeStatus.isClubMember, isFalse);

      // Seed local prefs with active club membership
      final activeClub = SubscriptionStatus(
        userId: 'user-cached-club',
        tier: SubscriptionTier.felineClubMember,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        isAutoRenewing: true,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'subscription_status_v1_user-cached-club',
        jsonEncode(activeClub.toMap()),
      );

      subService.resetCache();
      final cachedSub = await subService.getSubscription('user-cached-club');
      expect(cachedSub.isClubMember, isTrue);
      expect(cachedSub.tier, equals(SubscriptionTier.felineClubMember));
    });

    test('EventRepositoryImpl falls back to local cache or zero-balance wallet when offline', () async {
      final eventRepo = EventRepositoryImpl.instance;

      // Clean install returns 0 coins wallet
      final wallet = await eventRepo.getUserWallet('user-wallet-1', 'event-1');
      expect(wallet.coinBalance, equals(0));
      expect(wallet.unlockedBorderIds, isEmpty);

      // Seed local prefs
      final prefs = await SharedPreferences.getInstance();
      final customWallet = UserEventWallet(
        userId: 'user-cached-wallet',
        eventId: 'event-1',
        coinBalance: 350,
        unlockedBorderIds: const ['border_sakura'],
        completedQuestIds: const ['q1'],
      );
      await prefs.setString(
        'event_wallet_user-cached-wallet_event-1',
        jsonEncode(customWallet.toMap()),
      );

      final cachedWallet = await eventRepo.getUserWallet(
        'user-cached-wallet',
        'event-1',
      );
      expect(cachedWallet.coinBalance, equals(350));
      expect(cachedWallet.unlockedBorderIds, contains('border_sakura'));
    });

    test(
      'SeasonServiceImpl falls back to local cache or 0 prestige when offline',
      () async {
        final seasonService = SeasonServiceImpl.instance;

        // Clean install returns 0
        final pts = await seasonService.getMythicPrestige('user-season-test');
        expect(pts, equals(0));

        // Seed local prefs
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('mythic_prestige_user-cached-season', 450);

        final cachedPts = await seasonService.getMythicPrestige(
          'user-cached-season',
        );
        expect(cachedPts, equals(450));
      },
    );

    test('TerritoryServiceImpl falls back to local cache or default territory when offline', () async {
      final territoryService = TerritoryServiceImpl.instance;
      territoryService.resetCache();

      // Clean install returns default territory
      final defaultTerritory = await territoryService.getTerritory(
        'user-territory-clean',
      );
      expect(defaultTerritory.city, equals('Lapu-Lapu City'));
      expect(defaultTerritory.barangay, equals('Bankal'));

      // Seed local prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('territory_user-cached-t_barangay', 'Lahug');
      await prefs.setString('territory_user-cached-t_city', 'Cebu City');
      await prefs.setString('territory_user-cached-t_province', 'Cebu');
      await prefs.setString(
        'territory_user-cached-t_region',
        'Central Visayas',
      );
      await prefs.setString('territory_user-cached-t_country', 'Philippines');
      await prefs.setBool('territory_user-cached-t_confirmed', true);

      territoryService.resetCache();
      final cachedTerritory = await territoryService.getTerritory(
        'user-cached-t',
      );
      expect(cachedTerritory.barangay, equals('Lahug'));
      expect(cachedTerritory.city, equals('Cebu City'));
      expect(cachedTerritory.isHomeConfirmed, isTrue);
    });
  });
}

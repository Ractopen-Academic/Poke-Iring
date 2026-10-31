import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokeiring/features/subscription/data/services/subscription_service_impl.dart';
import 'package:pokeiring/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pokeiring/features/subscription/presentation/widgets/feline_club_paywall_sheet.dart';
import 'package:pokeiring/features/vault/data/services/photo_vault_service_impl.dart';
import 'package:pokeiring/features/vault/domain/entities/vault_photo_entry.dart';
import 'package:pokeiring/features/vault/presentation/pages/raw_photo_vault_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SubscriptionStatus & Service', () {
    test('defaults to free tier for fresh user', () async {
      final service = SubscriptionServiceImpl();
      final status = await service.getSubscription('u_test_1');

      expect(status.isClubMember, isFalse);
      expect(status.tier, equals(SubscriptionTier.free));
    });

    test('upgrades to Feline Club and broadcasts status', () async {
      final service = SubscriptionServiceImpl();

      final events = <SubscriptionStatus>[];
      final sub = service.watchSubscription('u_test_2').listen(events.add);

      final upgraded = await service.upgradeToClub(
        'u_test_2',
        interval: BillingInterval.annual,
      );

      expect(upgraded.isClubMember, isTrue);
      expect(upgraded.tier, equals(SubscriptionTier.felineClubMember));
      expect(upgraded.activeInterval, equals(BillingInterval.annual));
      expect(upgraded.isAutoRenewing, isTrue);

      final retrieved = await service.getSubscription('u_test_2');
      expect(retrieved.isClubMember, isTrue);

      await Future.delayed(const Duration(milliseconds: 10));
      expect(events.any((e) => e.isClubMember), isTrue);

      await sub.cancel();
    });

    test('cancels subscription back to free', () async {
      final service = SubscriptionServiceImpl();
      await service.upgradeToClub('u_test_3');
      final cancelled = await service.cancelSubscription('u_test_3');

      expect(cancelled.isClubMember, isFalse);
      expect(cancelled.tier, equals(SubscriptionTier.free));
    });
  });

  group('VaultPhotoEntry Entity', () {
    test('formats file size and megapixels correctly', () {
      final entry = VaultPhotoEntry(
        id: 'vp_1',
        userId: 'u_1',
        sightingId: 's_1',
        breedName: 'Pusapin',
        photoUrl: '',
        fileSizeBytes: 5242880, // 5 MB
        resolutionWidth: 4032,
        resolutionHeight: 3024,
        capturedAt: DateTime(2026, 10, 31),
      );

      expect(entry.fileSizeFormatted, equals('5.0 MB'));
      expect(entry.resolutionFormatted, equals('4032 x 3024'));
      expect(entry.megapixelFormatted, equals('12.2 MP'));
    });

    test('serializes toMap and fromMap cleanly', () {
      final entry = VaultPhotoEntry(
        id: 'vp_2',
        userId: 'u_2',
        sightingId: 's_2',
        breedName: 'Calico',
        photoUrl: '',
        fileSizeBytes: 125000,
        resolutionWidth: 1920,
        resolutionHeight: 1080,
        capturedAt: DateTime(2026, 10, 31),
      );

      final map = entry.toMap();
      final restored = VaultPhotoEntry.fromMap(map);

      expect(restored.id, equals(entry.id));
      expect(restored.breedName, equals(entry.breedName));
      expect(restored.resolutionWidth, equals(1920));
    });
  });

  group('PhotoVaultServiceImpl', () {
    test('loads default seed photos and calculates total bytes', () async {
      final service = PhotoVaultServiceImpl();
      final photos = await service.getVault('u_vault_1');

      expect(photos, isNotEmpty);
      expect(photos.first.isRawMaster, isTrue);

      final totalBytes = await service.getTotalVaultBytes('u_vault_1');
      expect(totalBytes, greaterThan(1000000));
    });

    test('archives photo and removes photo', () async {
      final service = PhotoVaultServiceImpl();
      final newPhoto = VaultPhotoEntry(
        id: 'custom_photo_1',
        userId: 'u_vault_2',
        sightingId: 's_custom',
        breedName: 'Black Shorthair',
        photoUrl: '',
        fileSizeBytes: 4194304, // 4 MB
        resolutionWidth: 3840,
        resolutionHeight: 2160,
        capturedAt: DateTime.now(),
      );

      await service.archivePhoto(newPhoto);
      var vault = await service.getVault('u_vault_2');
      expect(vault.any((p) => p.id == 'custom_photo_1'), isTrue);

      await service.removePhoto('u_vault_2', 'custom_photo_1');
      vault = await service.getVault('u_vault_2');
      expect(vault.any((p) => p.id == 'custom_photo_1'), isFalse);
    });
  });

  group('Presentation Widgets', () {
    testWidgets('FelineClubPaywallSheet renders perks and join button', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FelineClubPaywallSheet(userId: 'u_tester')),
        ),
      );

      expect(find.text('Feline Club Membership'), findsOneWidget);
      expect(find.text('Uncompressed RAW Photo Vault'), findsOneWidget);
      expect(find.text('Join Feline Club'), findsOneWidget);
    });

    testWidgets('RawPhotoVaultPage renders master captures grid', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: RawPhotoVaultPage(userId: 'u_tester')),
      );

      await tester.pumpAndSettle();

      expect(find.text('RAW Photo Vault'), findsOneWidget);
      expect(find.textContaining('Master Captures'), findsOneWidget);
      expect(find.textContaining('Lossless Vault'), findsOneWidget);
    });
  });
}

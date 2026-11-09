import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pokeiring/core/services/data_purge_service.dart';
import 'package:pokeiring/core/services/image_compression_service.dart';
import 'package:pokeiring/features/auth/domain/entities/auth_user.dart';
import 'package:pokeiring/features/stories/data/datasources/firebase_stories_datasource.dart';
import 'package:pokeiring/features/stories/data/repositories/stories_repository_impl.dart';
import 'package:pokeiring/features/stories/presentation/widgets/story_circle_item.dart';
import 'package:pokeiring/features/subscription/data/services/paypal_sandbox_api_service.dart';
import 'package:pokeiring/features/subscription/data/services/subscription_service_impl.dart';
import 'package:pokeiring/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pokeiring/features/subscription/presentation/widgets/paypal_sandbox_checkout_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DataPurgeService.restoreTestSeeds();
  });

  group('DataPurgeService Clean Slate & Deployment Reset', () {
    test(
      'purges test persistent keys and flags seed mock data as disabled',
      () async {
        SharedPreferences.setMockInitialValues({
          'scanner_sightings_cache_v2': ['test1', 'test2'],
          'stories_cache': 'some_stories',
          'raw_photo_vault_cache_v1_user1': ['photo1'],
          'subscription_status_v1_user1': '{"tier":"free"}',
          'events_cache_v1': 'events',
          'keep_user_auth_key': 'auth_token',
        });

        final report = await DataPurgeService.purgeAllTestDataAndCache(
          disableTestSeeds: true,
        );

        expect(report.clearedKeysCount, greaterThanOrEqualTo(5));
        expect(report.testSeedsDisabled, isTrue);
        expect(DataPurgeService.areSeedsDisabled, isTrue);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('scanner_sightings_cache_v2'), isFalse);
        expect(prefs.containsKey('stories_cache'), isFalse);
        expect(prefs.containsKey('raw_photo_vault_cache_v1_user1'), isFalse);
        expect(prefs.getString('keep_user_auth_key'), equals('auth_token'));
      },
    );
  });

  group('Story Duration and Ultra HD Perks', () {
    test(
      'StoriesRepository publishStory respects settable durations (48h, 7d)',
      () async {
        final repository = StoriesRepositoryImpl(
          dataSource: FirebaseStoriesDataSource(),
        );

        const testUser = AuthUser(
          id: 'user-vip-1',
          email: 'vip@cat.test',
          displayName: 'VipExplorer',
          photoUrl: '',
          emailVerified: true,
        );

        final dummyBytes = Uint8List.fromList([1, 2, 3]);

        final story48h = await repository.publishStory(
          user: testUser,
          compressedImageBytes: dummyBytes,
          caption: 'Extended MyDay 48h',
          catBreed: 'Calico Puspin',
          locationTag: 'Bankal',
          duration: const Duration(hours: 48),
        );

        final diffHours48 = story48h.expiresAt
            .difference(story48h.createdAt)
            .inHours;
        expect(diffHours48, equals(48));

        final story7d = await repository.publishStory(
          user: testUser,
          compressedImageBytes: dummyBytes,
          caption: 'Extended MyDay 7 Days',
          catBreed: 'Orange Tabby',
          locationTag: 'Marigondon',
          duration: const Duration(days: 7),
        );

        final diffDays7 = story7d.expiresAt
            .difference(story7d.createdAt)
            .inDays;
        expect(diffDays7, equals(7));
      },
    );

    test('ImageCompressionService supports Ultra HD 4K perks for Feline Club Members', () async {
      final testImg = img.Image(width: 3000, height: 3000);
      img.fill(testImg, color: img.ColorRgb8(100, 200, 50));
      final rawBytes = Uint8List.fromList(img.encodeJpg(testImg, quality: 100));

      final service = ImageCompressionService();

      // Free user compression
      final standardResult = await service.compressStoryImage(
        rawBytes,
        isClubMember: false,
      );
      expect(
        standardResult.width,
        lessThanOrEqualTo(ImageCompressionService.maxStoryWidth),
      );

      // Feline Club member Ultra HD compression
      final clubResult = await service.compressStoryImage(
        rawBytes,
        isClubMember: true,
      );
      expect(
        clubResult.width,
        greaterThan(ImageCompressionService.maxStoryWidth),
      );
      expect(
        clubResult.width,
        lessThanOrEqualTo(ImageCompressionService.clubStoryWidth),
      );
    });
  });

  group('MyDay Blurred Story Preview Widget Tests', () {
    testWidgets(
      'renders slightly blurred preview when storyMediaUrl is provided',
      (tester) async {
        // Create a tiny 10x10 base64 jpeg image for test
        final testImg = img.Image(width: 10, height: 10);
        img.fill(testImg, color: img.ColorRgb8(255, 120, 0));
        final jpgBytes = Uint8List.fromList(img.encodeJpg(testImg));
        final base64Url = 'data:image/jpeg;base64,${base64Encode(jpgBytes)}';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StoryCircleItem(
                label: 'FluffyFinder',
                seed: 'FluffyFinder',
                storyMediaUrl: base64Url,
                authorAvatarUrl: '',
                catBreed: 'Calico Puspin',
                isViewed: false,
                onTap: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify that ImageFiltered is present with blur
        final imageFilteredFinder = find.byType(ImageFiltered);
        expect(imageFilteredFinder, findsWidgets);

        final imageFiltered = tester.widget<ImageFiltered>(
          imageFilteredFinder.first,
        );
        expect(imageFiltered.imageFilter, isA<ImageFilter>());
        expect(find.text('FluffyFinder'), findsOneWidget);
      },
    );

    testWidgets('renders graceful breed fallback when storyMediaUrl is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryCircleItem(
              label: 'ShadowTracker',
              seed: 'ShadowTracker',
              storyMediaUrl: '',
              authorAvatarUrl: '',
              catBreed: 'Tuxedo Puspin',
              isViewed: true,
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('ShadowTracker'), findsOneWidget);
      expect(find.byType(ImageFiltered), findsWidgets);
    });

    testWidgets(
      'renders Your Story with active story blurred preview and add button',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StoryCircleItem(
                label: 'Your Story',
                seed: 'CurrentUser',
                storyMediaUrl: '',
                isUser: true,
                hasActiveUserStory: true,
                onTap: () {},
                onAddTap: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Your Story'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      },
    );
  });

  group('PayPal Sandbox Checkout Modal Tests', () {
    testWidgets(
      'renders PayPal Sandbox branding, buyer account, order breakdown and funding source',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PayPalSandboxCheckoutModal(
                userId: 'test-sandbox-buyer-1',
                interval: BillingInterval.annual,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('paypal.com'), findsOneWidget);
        expect(find.text('VERIFIED'), findsOneWidget);
        expect(find.text('PayPal Checkout'), findsOneWidget);
        expect(find.text('explorer@pokeiring.app'), findsOneWidget);
        expect(find.text('PayPal Balance'), findsOneWidget);
        expect(find.text('Complete Purchase'), findsOneWidget);
      },
    );

    testWidgets(
      'executes complete PayPal Sandbox payment flow and activates Feline Club membership',
      (tester) async {
        const testUserId = 'test-sandbox-buyer-flow';

        // Start as free tier
        final initialStatus = await SubscriptionServiceImpl.instance
            .getSubscription(testUserId);
        expect(initialStatus.isClubMember, isFalse);

        bool paymentSuccessCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PayPalSandboxCheckoutModal(
                userId: testUserId,
                interval: BillingInterval.annual,
                onPaymentSuccess: () {
                  paymentSuccessCalled = true;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Scroll to and tap Complete Purchase
        final buttonFinder = find.text('Complete Purchase');
        await tester.ensureVisible(buttonFinder);
        await tester.pumpAndSettle();
        await tester.tap(buttonFinder);
        await tester.pump();

        // Advance through simulated network latency stages
        await tester.pump(const Duration(milliseconds: 750));
        await tester.pump(const Duration(milliseconds: 650));
        await tester.pump(const Duration(milliseconds: 750));
        await tester.pumpAndSettle();

        expect(find.text('PayPal Payment Authorized'), findsOneWidget);
        expect(find.text('Done & Enjoy Perks'), findsOneWidget);
        expect(paymentSuccessCalled, isTrue);

        final updatedStatus = await SubscriptionServiceImpl.instance
            .getSubscription(testUserId);
        expect(updatedStatus.isClubMember, isTrue);
        expect(updatedStatus.tier, equals(SubscriptionTier.felineClubMember));
      },
    );
  });

  group('PayPalSandboxApiService REST Integration', () {
    test('persists and clears developer Client ID & Secret', () async {
      final service = PayPalSandboxApiService();

      expect(await service.hasCredentials(), isFalse);

      await service.saveCredentials('test_client_id_123', 'test_secret_456');
      expect(await service.hasCredentials(), isTrue);
      expect(await service.getClientId(), equals('test_client_id_123'));
      expect(await service.getClientSecret(), equals('test_secret_456'));

      await service.clearCredentials();
      expect(await service.hasCredentials(), isFalse);
      expect(await service.getClientId(), isNull);
    });

    test('creates order and captures with sandbox response', () async {
      final service = PayPalSandboxApiService();

      final order = await service.createOrder(
        referenceId: 'plan_annual',
        description: 'Feline Club Annual Pass',
        amountValue: '1190.00',
        currencyCode: 'PHP',
      );

      expect(order.orderId, isNotEmpty);
      expect(order.status, equals('CREATED'));
      expect(order.approveUrl, contains('sandbox.paypal.com'));

      final capture = await service.captureOrder(
        orderId: order.orderId,
        amountValue: '1190.00',
        currencyCode: 'PHP',
      );

      expect(capture.captureId, startsWith('CAPTURE-SBX-'));
      expect(capture.status, equals('COMPLETED'));
      expect(capture.currency, equals('PHP'));
    });
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/core/constants/app_colors.dart';
import 'package:pokeiring/core/network/network_info.dart';
import 'package:pokeiring/core/services/location_service.dart';
import 'package:pokeiring/core/utils/auth_error_formatter.dart';
import 'package:pokeiring/core/widgets/calico_ui_kit.dart';
import 'package:pokeiring/features/auth/domain/entities/auth_user.dart';
import 'package:pokeiring/features/auth/domain/repositories/auth_repository.dart';
import 'package:pokeiring/features/auth/presentation/pages/login_page.dart';
import 'package:pokeiring/features/auth/presentation/widgets/calico_login_mascot.dart';
import 'package:pokeiring/features/events/data/repositories/event_repository_impl.dart';
import 'package:pokeiring/features/events/presentation/widgets/event_popup_modal.dart';
import 'package:pokeiring/features/home/presentation/pages/main_navigation_shell.dart';
import 'package:pokeiring/features/home/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:pokeiring/features/home/presentation/widgets/iring_center_button.dart';
import 'package:pokeiring/features/map/domain/entities/user_location.dart';
import 'package:pokeiring/features/map/presentation/pages/live_map_page.dart';
import 'package:pokeiring/features/map/presentation/widgets/peeking_cat_recenter_button.dart';
import 'package:pokeiring/features/scanner/presentation/widgets/floating_snap_iring_button.dart';
import 'package:pokeiring/features/territory/data/services/territory_service_impl.dart';
import 'package:pokeiring/features/territory/domain/entities/explorer_territory.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthRepository implements AuthRepository {
  final AuthUser user;

  const _FakeAuthRepository(this.user);

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(user);

  @override
  AuthUser? get currentUser => user;

  @override
  Future<AuthUser> registerWithEmailPassword(
    String email,
    String password,
  ) async => user;

  @override
  Future<void> reloadCurrentUser() async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<AuthUser> signInWithEmailPassword(
    String email,
    String password,
  ) async => user;

  @override
  Future<AuthUser> signInWithGoogle() async => user;

  @override
  Future<void> signOut() async {}
}

class _FakeNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();

  @override
  void dispose() {}
}

class _FakeLocationService implements LocationService {
  final UserLocation sampleLocation = UserLocation(
    latitude: 10.3155,
    longitude: 123.9788,
    heading: 0.0,
    accuracy: 4.0,
    speed: 0.0,
    altitude: 10.0,
    timestamp: DateTime(2026, 11, 1, 9, 0),
  );

  @override
  Future<LocationAccessStatus> checkStatus() async =>
      LocationAccessStatus.granted;

  @override
  Future<UserLocation?> getCurrentLocation() async => sampleLocation;

  @override
  Stream<UserLocation> get onLocationChanged => const Stream.empty();

  @override
  Stream<bool> get onServiceStatusChanged => const Stream.empty();

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<LocationAccessStatus> requestPermission() async =>
      LocationAccessStatus.granted;
}

void main() {
  const testUser = AuthUser(
    id: 'calico-tester-1',
    email: 'calico@example.com',
    displayName: 'Marmalade',
    emailVerified: true,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TerritoryServiceImpl.instance.resetCache();
    await TerritoryServiceImpl.instance.updateTerritory(
      testUser.id,
      ExplorerTerritory.defaultTerritory.copyWith(
        isHomeConfirmed: true,
        lockedAt: DateTime(2026, 10, 1),
      ),
    );
    final events = await EventRepositoryImpl.instance.getActiveEvents();
    for (final event in events) {
      await EventPopupModal.markDismissedToday(event.id);
    }
  });

  group('Calico UI Kit & Navigation Components', () {
    testWidgets('CalicoSpotCard and CalicoAnimatedBar render and handle taps', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const CalicoAnimatedBar(isActive: true, activeWidth: 24),
                const CalicoAnimatedBar(isActive: false, activeWidth: 24),
                CalicoSpotCard(
                  onTap: () => tapped = true,
                  child: const Text('Calico Patch Card'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Calico Patch Card'), findsOneWidget);
      expect(AppColors.primary, equals(const Color(0xFFE06D22)));
      expect(AppColors.calicoBlack, equals(const Color(0xFF181513)));

      await tester.tap(find.text('Calico Patch Card'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tapped, isTrue);
    });

    testWidgets(
      'AppBottomNavBar highlights active tab bar and fires tab callbacks',
      (tester) async {
        var selectedIndex = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  bottomNavigationBar: AppBottomNavBar(
                    currentIndex: selectedIndex,
                    onTabSelected: (index) {
                      setState(() => selectedIndex = index);
                    },
                  ),
                );
              },
            ),
          ),
        );

        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Dex'), findsOneWidget);
        expect(find.text('Ranks'), findsOneWidget);
        expect(find.text('Account'), findsOneWidget);
        expect(find.byType(CalicoAnimatedBar), findsNWidgets(4));

        await tester.tap(find.text('Dex'));
        await tester.pump(const Duration(milliseconds: 350));
        expect(selectedIndex, equals(1));

        await tester.tap(find.text('Ranks'));
        await tester.pump(const Duration(milliseconds: 350));
        expect(selectedIndex, equals(2));

        await tester.tap(find.text('Account'));
        await tester.pump(const Duration(milliseconds: 350));
        expect(selectedIndex, equals(3));
      },
    );

    testWidgets('IringCenterButton animates on tap and map state toggle', (
      tester,
    ) async {
      var isMapOpen = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                floatingActionButton: IringCenterButton(
                  isMapOpen: isMapOpen,
                  onTap: () => setState(() => isMapOpen = !isMapOpen),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(IringCenterButton));
      await tester.pump(const Duration(milliseconds: 300));
      expect(isMapOpen, isTrue);

      await tester.tap(find.byType(IringCenterButton));
      await tester.pump(const Duration(milliseconds: 300));
      expect(isMapOpen, isFalse);
    });

    testWidgets(
      'PeekingCatRecenterButton lifts when off-center and fires onTap',
      (tester) async {
        var recenterCount = 0;
        var offCenter = false;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() => offCenter = !offCenter),
                        child: const Text('Toggle Drift'),
                      ),
                      PeekingCatRecenterButton(
                        isOffCenter: offCenter,
                        onTap: () => recenterCount++,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Toggle Drift'));
        await tester.pump(const Duration(milliseconds: 360));

        await tester.tap(find.byType(PeekingCatRecenterButton));
        await tester.pump(const Duration(milliseconds: 360));
        expect(recenterCount, equals(1));
      },
    );

    testWidgets(
      'MainNavigationShell choreographs map overlay and FloatingSnapIringButton',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MainNavigationShell(
              user: testUser,
              authRepository: const _FakeAuthRepository(testUser),
              networkInfo: _FakeNetworkInfo(),
              locationService: _FakeLocationService(),
              initialOnline: true,
              initialLocationStatus: LocationAccessStatus.granted,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(FloatingSnapIringButton), findsNothing);
        expect(find.byType(LiveMapPage), findsNothing);

        await tester.tap(find.byType(IringCenterButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(LiveMapPage), findsOneWidget);
        expect(find.byType(FloatingSnapIringButton), findsOneWidget);
        expect(find.text('10.3155, 123.9788'), findsOneWidget);

        await tester.tap(find.byType(IringCenterButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(LiveMapPage), findsNothing);
        expect(find.byType(FloatingSnapIringButton), findsNothing);

        await tester.tap(find.text('Dex'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(FloatingSnapIringButton), findsNothing);
      },
    );

    testWidgets(
      'LoginPage renders interactive CalicoLoginMascot without dev Quick Test Login',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: LoginPage(
              authRepository: const _FakeAuthRepository(testUser),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CalicoLoginMascot), findsOneWidget);
        expect(find.text('Quick Test Login'), findsNothing);
        expect(find.text('Enter Territory'), findsOneWidget);

        await tester.enterText(
          find.byType(TextFormField).first,
          'calico@iring.ph',
        );
        await tester.pump(const Duration(milliseconds: 250));

        await tester.tap(find.byType(TextFormField).last);
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byTooltip('Show password'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byTooltip('Hide password'), findsOneWidget);

        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();
        expect(find.text('Create Explorer Account'), findsOneWidget);
      },
    );

    test('AuthErrorFormatter formats raw Firebase errors into human messages', () {
      expect(
        AuthErrorFormatter.format(
          '[firebase_auth/invalid-credential] The supplied auth credential is incorrect, malformed or has expired.',
        ),
        'Incorrect email or password. Please double-check your credentials or reset your password.',
      );

      expect(
        AuthErrorFormatter.format('[firebase_auth/email-already-in-use] The email is already in use.'),
        'An account with this email address already exists. Please sign in instead.',
      );

      expect(
        AuthErrorFormatter.format('Exception: [firebase_auth/weak-password] Password should be at least 6 characters'),
        'Password is too weak. Please use at least 6 characters.',
      );

      expect(
        AuthErrorFormatter.format('Passwords do not match'),
        'Passwords do not match. Please ensure both fields are identical.',
      );

      expect(
        AuthErrorFormatter.format('Network error: SocketException'),
        'Unable to connect to game servers. Please check your network connection.',
      );
    });

    testWidgets(
      'CalicoLoginMascot reacts to hasError without breaking paw hiding on password focus',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CalicoLoginMascot(
                isPasswordFocused: true,
                isPasswordVisible: false,
                hasError: false,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(CalicoLoginMascot), findsOneWidget);

        // Update with error
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CalicoLoginMascot(
                isPasswordFocused: true,
                isPasswordVisible: false,
                hasError: true,
              ),
            ),
          ),
        );
        // Animate error shake
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(CalicoLoginMascot), findsOneWidget);
      },
    );

    testWidgets(
      'MainNavigationShell sequences TerritorySetupDialog before EventPopupModal without overlap',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        TerritoryServiceImpl.instance.resetCache();
        MainNavigationShell.resetModalState();

        await tester.pumpWidget(
          MaterialApp(
            home: MainNavigationShell(
              user: const AuthUser(
                id: 'fresh-explorer-seq',
                email: 'fresh@example.com',
                displayName: 'FreshPaws',
                emailVerified: true,
              ),
              authRepository: const _FakeAuthRepository(testUser),
              networkInfo: _FakeNetworkInfo(),
              locationService: _FakeLocationService(),
              initialOnline: true,
              initialLocationStatus: LocationAccessStatus.granted,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.textContaining('Lock'), findsWidgets);
        expect(find.byType(EventPopupModal), findsNothing);
      },
    );

    testWidgets(
      'FloatingSnapIringButton stays strictly above PeekingCatRecenterButton on LiveMapPage',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MainNavigationShell(
              user: testUser,
              authRepository: const _FakeAuthRepository(testUser),
              networkInfo: _FakeNetworkInfo(),
              locationService: _FakeLocationService(),
              initialOnline: true,
              initialLocationStatus: LocationAccessStatus.granted,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byType(IringCenterButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        final cameraPainterFinder = find.descendant(
          of: find.byType(FloatingSnapIringButton),
          matching: find.byType(SizedBox),
        );
        final recenterFinder = find.byType(PeekingCatRecenterButton);

        final cameraRect = tester.getRect(cameraPainterFinder.first);
        final recenterRect = tester.getRect(recenterFinder);

        expect(cameraRect.overlaps(recenterRect), isFalse);
        expect(cameraRect.bottom, lessThanOrEqualTo(recenterRect.top));
      },
    );
  });
}

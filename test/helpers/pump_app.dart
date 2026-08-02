import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/bare_ease_app.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/core/db/database_provider.dart';
import 'package:migraine_tracker/core/l10n/locale_provider.dart';
import 'package:migraine_tracker/core/permissions/app_permission.dart';
import 'package:migraine_tracker/core/permissions/app_permission_gateway.dart';
import 'package:migraine_tracker/features/app_update/domain/entities/app_update_config.dart';
import 'package:migraine_tracker/features/app_update/domain/entities/installed_app_version.dart';
import 'package:migraine_tracker/features/app_update/domain/repositories/app_update_repository.dart';
import 'package:migraine_tracker/features/app_update/domain/services/store_launcher.dart';
import 'package:migraine_tracker/features/app_update/providers.dart';
import 'package:migraine_tracker/features/auth/domain/entities/auth_user.dart';
import 'package:migraine_tracker/features/auth/domain/entities/user_profile.dart';
import 'package:migraine_tracker/features/auth/domain/enums/auth_error.dart';
import 'package:migraine_tracker/features/auth/domain/enums/auth_provider_kind.dart';
import 'package:migraine_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:migraine_tracker/features/auth/domain/repositories/user_profile_repository.dart';
import 'package:migraine_tracker/features/auth/providers.dart';
import 'package:migraine_tracker/features/health/domain/entities/sleep_night.dart';
import 'package:migraine_tracker/features/health/domain/repositories/health_repository.dart';
import 'package:migraine_tracker/features/health/providers.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication_reminder.dart';
import 'package:migraine_tracker/features/medications/domain/services/notification_scheduler.dart';
import 'package:migraine_tracker/features/medications/providers.dart';
import 'package:migraine_tracker/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:migraine_tracker/features/premium/domain/entities/premium_offer.dart';
import 'package:migraine_tracker/features/premium/domain/enums/premium_period.dart';
import 'package:migraine_tracker/features/premium/domain/repositories/premium_repository.dart';
import 'package:migraine_tracker/features/premium/domain/repositories/purchase_repository.dart';
import 'package:migraine_tracker/features/premium/providers.dart';
import 'package:migraine_tracker/features/settings/providers.dart';
import 'package:migraine_tracker/features/weather/domain/entities/pressure_forecast.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';
import 'package:migraine_tracker/features/weather/domain/repositories/weather_repository.dart';
import 'package:migraine_tracker/features/weather/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/v2/index.dart';

import 'export_fakes.dart';

/// Offline-behaving weather stub: widget tests never touch geolocator or
/// the network.
class FakeWeatherRepository implements WeatherRepository {
  FakeWeatherRepository({this.snapshot});

  /// Returned for every request; null simulates offline/no permission.
  WeatherSnapshot? snapshot;

  /// Returned by [pressureForecast]; null simulates offline.
  PressureForecast? forecast;

  @override
  Future<WeatherSnapshot?> snapshotAt(DateTime instant) async => snapshot;

  @override
  Future<PressureForecast?> pressureForecast() async => forecast;
}

/// No-op scheduler so widget tests never touch the notifications plugin.
class FakeNotificationScheduler implements NotificationScheduler {
  /// Set when [scheduleTest] is called, so a test can assert the debug
  /// "test notification" action reached the scheduler.
  bool testScheduled = false;

  @override
  Future<bool> ensurePermission() async => true;

  @override
  Future<void> schedule(
    MedicationReminder reminder, {
    required String medicationName,
    required String title,
    required String bodyTemplate,
  }) async {}

  @override
  Future<void> cancel(String reminderId) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> scheduleTest({
    required String title,
    required String body,
    Duration delay = const Duration(seconds: 10),
  }) async {
    testScheduled = true;
  }
}

/// Serves whatever update record a test asks for. Default: no record at
/// all, so the force-update wrapper never blocks the app under test.
class FakeAppUpdateRepository implements AppUpdateRepository {
  FakeAppUpdateRepository({this.config});

  AppUpdateConfig? config;

  /// How many times the wrapper asked — one per entry into the app.
  int calls = 0;

  @override
  Future<AppUpdateConfig?> latest() async {
    calls++;
    return config;
  }
}

/// Records the store link instead of leaving the test to url_launcher.
class FakeStoreLauncher implements StoreLauncher {
  final List<String> opened = <String>[];

  /// Flip to false to exercise the "couldn't open the store" branch.
  bool succeeds = true;

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return succeeds;
  }
}

/// In-memory account. Not optional like the other fakes: `authUserProvider`
/// is watched at build time, so a real one drags Firebase into the tree.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({bool signedIn = false})
    : _user = signedIn
          ? const AuthUser(
              uid: 'test-uid',
              isAnonymous: false,
              email: 'tester@example.com',
            )
          : const AuthUser(uid: 'test-uid', isAnonymous: true);

  /// Set to make [signIn] fail with this error instead of succeeding.
  AuthError? failWith;

  /// Whether the login screen should offer the Apple button.
  bool appleAvailable = true;

  /// Providers [signIn] was called with, in order.
  final List<AuthProviderKind> signInCalls = <AuthProviderKind>[];
  int signOutCalls = 0;

  AuthUser _user;
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> watchUser() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<bool> isAppleAvailable() async => appleAvailable;

  @override
  Future<AuthUser> signIn(AuthProviderKind provider) async {
    signInCalls.add(provider);
    final AuthError? error = failWith;

    if (error != null) throw AuthException(error);

    // Mirrors linkWithCredential: same UID, no longer anonymous.
    _user = AuthUser(
      uid: _user.uid,
      isAnonymous: false,
      email: 'tester@example.com',
    );
    _controller.add(_user);
    return _user;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _user = AuthUser(uid: _user.uid, isAnonymous: true);
    _controller.add(_user);
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    _user = AuthUser(
      uid: _user.uid,
      isAnonymous: _user.isAnonymous,
      email: _user.email,
      displayName: displayName,
    );
    _controller.add(_user);
  }

  void dispose() => _controller.close();
}

/// In-memory account document. The account tab watches it, so a real one
/// would drag Firestore into the test tree.
class FakeUserProfileRepository implements UserProfileRepository {
  FakeUserProfileRepository({this.profile});

  /// The current document, or null until something writes one.
  UserProfile? profile;
  final StreamController<UserProfile?> _controller =
      StreamController<UserProfile?>.broadcast();

  /// Users [upsertFromAccount] was called for — the sign-in/launch sync.
  final List<AuthUser> synced = <AuthUser>[];

  /// Names [updateDisplayName] was called with, in order.
  final List<String> renames = <String>[];

  @override
  Stream<UserProfile?> watch(String uid) async* {
    yield profile;
    yield* _controller.stream;
  }

  @override
  Future<void> upsertFromAccount(AuthUser user) async {
    synced.add(user);
    profile ??= UserProfile(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
    );
    _controller.add(profile);
  }

  @override
  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  }) async {
    renames.add(displayName);
    profile = (profile ?? UserProfile(uid: uid)).copyWith(
      displayName: displayName,
    );
    _controller.add(profile);
  }

  void dispose() => _controller.close();
}

/// Entitlement state a test sets directly.
///
/// There is no local premium repository in the app any more — premium comes
/// from RevenueCat and nothing the client can write (CLAUDE.md) — so the way
/// a test gets a premium user is to override the provider with this.
class FakePremiumRepository implements PremiumRepository {
  FakePremiumRepository({bool premium = false}) : _isPremium = premium;

  bool _isPremium;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  bool get isPremium => _isPremium;

  @override
  Stream<bool> watchIsPremium() async* {
    yield _isPremium;
    yield* _controller.stream;
  }

  /// Flips the entitlement mid-test — what a completed purchase looks like.
  void setPremium(bool value) {
    _isPremium = value;
    if (!_controller.isClosed) _controller.add(value);
  }

  void dispose() => _controller.close();
}

/// The store, without a store. A purchase grants the entitlement through
/// [FakePremiumRepository], so it behaves like the real thing: the paywall
/// never decides premium itself, the entitlement stream does.
class FakePurchaseRepository implements PurchaseRepository {
  FakePurchaseRepository(this._premium);

  final FakePremiumRepository _premium;

  /// The three plans PLAN.md sells, at their listed prices.
  List<PremiumOffer> availableOffers = const <PremiumOffer>[
    PremiumOffer(
      id: r'$rc_monthly',
      period: PremiumPeriod.monthly,
      priceLabel: r'$5.99',
    ),
    PremiumOffer(
      id: r'$rc_annual',
      period: PremiumPeriod.yearly,
      priceLabel: r'$39.99',
      trialDays: 7,
    ),
    PremiumOffer(
      id: r'$rc_lifetime',
      period: PremiumPeriod.lifetime,
      priceLabel: r'$79.99',
    ),
  ];

  /// Set to make [purchase] and [restore] throw this instead of granting.
  ///
  /// Deliberately NOT applied to [offers]: when one flag drove both, setting
  /// it emptied the paywall, which disabled the CTA — so a "purchase fails"
  /// test passed without a purchase ever being attempted.
  Exception? failWith;

  /// Set to make loading the offerings fail, which is a different story: the
  /// paywall has nothing to show rather than something that fails on tap.
  Exception? offersFailWith;

  /// Whether [restore] finds anything.
  bool hasPastPurchase = false;

  final List<String> purchased = <String>[];

  /// UIDs passed to [identify]; null entries are [forget] calls.
  final List<String?> identified = <String?>[];
  int restoreCalls = 0;

  @override
  Future<List<PremiumOffer>> offers() async {
    final Exception? failure = offersFailWith;

    if (failure != null) throw failure;

    return availableOffers;
  }

  @override
  Future<bool> purchase(PremiumOffer offer) async {
    final Exception? failure = failWith;

    if (failure != null) throw failure;

    purchased.add(offer.id);
    _premium.setPremium(true);

    return true;
  }

  @override
  Future<bool> restore() async {
    final Exception? failure = failWith;

    restoreCalls++;
    if (failure != null) throw failure;
    if (!hasPastPurchase) return false;

    _premium.setPremium(true);

    return true;
  }

  @override
  Future<void> identify(String uid) async => identified.add(uid);

  @override
  Future<void> forget() async => identified.add(null);
}

/// Stands in for HealthKit. Unavailable by default, so every existing test
/// sees the shipped Android/simulator shape (no Apple Health row, no sleep
/// card) and nothing touches the plugin.
class FakeHealthRepository implements HealthRepository {
  FakeHealthRepository({this.isAvailable = false});

  @override
  bool isAvailable;

  /// What the authorization sheet reports. False covers the "couldn't
  /// connect" branch.
  bool authorizes = true;

  /// Served by [sleepNights], unfiltered — tests hand over exactly the nights
  /// they want analysed.
  List<SleepNight> nights = <SleepNight>[];

  int authorizationRequests = 0;

  /// How many times sleep was actually read — the assertion behind "a free
  /// user never reaches a HealthKit read".
  int sleepReads = 0;

  @override
  Future<bool> requestAuthorization() async {
    authorizationRequests++;
    return authorizes;
  }

  @override
  Future<List<SleepNight>> sleepNights({
    required DateTime from,
    required DateTime to,
  }) async {
    sleepReads++;
    return nights;
  }
}

/// Grants permissions by default; a test can flip [statusFor] to exercise the
/// permanently-denied → settings-sheet path. Never touches the OS.
class FakeAppPermissionGateway implements AppPermissionGateway {
  AppPermissionStatus statusFor = AppPermissionStatus.granted;
  int openSettingsCalls = 0;

  @override
  Future<AppPermissionStatus> status(AppPermissionType type) async => statusFor;

  @override
  Future<AppPermissionStatus> request(AppPermissionType type) async =>
      statusFor;

  @override
  Future<void> openAppSettings() async => openSettingsCalls++;
}

class PumpedApp {
  PumpedApp({
    required this.db,
    required this.prefs,
    required this.weather,
    required this.scheduler,
    required this.permissions,
    required this.auth,
    required this.appUpdate,
    required this.storeLauncher,
    required this.profiles,
    required this.exportFiles,
    required this.health,
    required this.premiumRepository,
    required this.purchases,
  });

  final AppDatabase db;
  final SharedPreferences prefs;
  final FakeWeatherRepository weather;
  final FakeNotificationScheduler scheduler;
  final FakeAppPermissionGateway permissions;
  final FakeAuthRepository auth;
  final FakeAppUpdateRepository appUpdate;
  final FakeStoreLauncher storeLauncher;
  final FakeUserProfileRepository profiles;

  /// Stands in for HealthKit. Unavailable unless a test asks otherwise.
  final FakeHealthRepository health;

  /// The entitlement a test can flip. Premium is never a prefs flag now.
  final FakePremiumRepository premiumRepository;

  /// The fake store behind the paywall.
  final FakePurchaseRepository purchases;

  /// Where exports landed. Read `singleContent` to assert on what was
  /// written without touching a real filesystem.
  final FakeExportFileStore exportFiles;
}

/// Boots the full app with an in-memory database, mock prefs, and stubbed
/// weather. Uses bounded pumps — see the Drift/pumpAndSettle note below.
Future<PumpedApp> pumpApp(
  WidgetTester tester, {
  Map<String, Object> initialPrefs = const {},
  WeatherSnapshot? weatherSnapshot,
  // Riverpod 3 no longer exports the `Override` type, so the helper takes
  // the concrete fakes it knows about instead of a generic override list.
  RecordingExportSharer? exportSharer,
  RecordingFileSaver? fileSaver,

  /// Default free — gating tests must opt in to premium explicitly.
  bool premium = false,

  /// Follows [premium]: an entitlement without an account unlocks nothing,
  /// so a signed-out premium test would silently test the locked branch.
  bool? signedIn,

  /// Off, as shipped: the Apple button shows but its flow is not wired up.
  /// True covers the real path, which must work before submission.
  bool appleSignIn = false,

  /// What `SdGlassV2.isSupported` reports. Defaults to true (the shipped iOS
  /// path); pass false to cover the Android/Skia fallback chrome.
  bool glassSupported = true,

  /// The account document the account tab reads. Null = not written yet,
  /// which is what a brand-new sign-in looks like.
  UserProfile? userProfile,

  /// The record the force-update check reads. Null (default) = no record,
  /// so the blocking sheet never appears.
  AppUpdateConfig? appUpdate,

  /// Whether this fake device has HealthKit. False by default — the Apple
  /// Health row and the sleep card are iOS-only surfaces.
  bool healthAvailable = false,

  /// Nights the fake HealthKit serves to the sleep correlation.
  List<SleepNight> sleepNights = const <SleepNight>[],

  /// The build this fake device is running. Both are high by default, so a
  /// test that passes [appUpdate] still has to opt into being out of date.
  String installedBuildName = '99.0.0',
  int installedBuildNumber = 9999,
}) async {
  // Pin the test view to the 393×852 design size (an iPhone-class screen,
  // DPR 3 = 1179×2556 physical). The default 800×600 surface makes
  // screenutil scale `.sp`/`.w`/`.h` by ~2×, which distorts layout and
  // pushes tap targets off-screen.
  tester.view.physicalSize = const Size(393 * 3, 852 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // The test engine is Skia, so SdGlassV2.isSupported would always be false
  // and every test would assert the fallback layout instead of the shipped
  // one. The glass still renders as FakeGlass here; only the insets follow.
  SdGlassV2.debugSupported = glassSupported;
  addTearDown(() => SdGlassV2.debugSupported = null);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  // Onboarding is considered done by default so existing tests land on the
  // dashboard; pass onboarding_completed: false to exercise onboarding.
  SharedPreferences.setMockInitialValues({
    OnboardingController.completedKey: true,
    ...initialPrefs,
  });
  final prefs = await SharedPreferences.getInstance();
  final weather = FakeWeatherRepository(snapshot: weatherSnapshot);
  final scheduler = FakeNotificationScheduler();
  final permissions = FakeAppPermissionGateway();
  final exportFiles = FakeExportFileStore();
  final auth = FakeAuthRepository(signedIn: signedIn ?? premium);
  addTearDown(auth.dispose);
  final FakeAppUpdateRepository appUpdateRepository = FakeAppUpdateRepository(
    config: appUpdate,
  );
  final FakeStoreLauncher storeLauncher = FakeStoreLauncher();
  final FakeUserProfileRepository profiles = FakeUserProfileRepository(
    profile: userProfile,
  );
  addTearDown(profiles.dispose);
  final FakeHealthRepository health = FakeHealthRepository(
    isAvailable: healthAvailable,
  )..nights = <SleepNight>[...sleepNights];
  final FakePremiumRepository premiumRepository = FakePremiumRepository(
    premium: premium,
  );
  addTearDown(premiumRepository.dispose);
  final FakePurchaseRepository purchases = FakePurchaseRepository(
    premiumRepository,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        weatherRepositoryProvider.overrideWithValue(weather),
        notificationSchedulerProvider.overrideWithValue(scheduler),
        appPermissionGatewayProvider.overrideWithValue(permissions),
        authRepositoryProvider.overrideWithValue(auth),
        healthRepositoryProvider.overrideWithValue(health),
        premiumRepositoryProvider.overrideWithValue(premiumRepository),
        purchaseRepositoryProvider.overrideWithValue(purchases),
        userProfileRepositoryProvider.overrideWithValue(profiles),
        appUpdateRepositoryProvider.overrideWithValue(appUpdateRepository),
        storeLauncherProvider.overrideWithValue(storeLauncher),
        installedAppVersionProvider.overrideWith(
          (ref) async => InstalledAppVersion(
            buildName: installedBuildName,
            buildNumber: installedBuildNumber,
          ),
        ),
        appleSignInImplementedProvider.overrideWithValue(appleSignIn),
        // Always overridden: the real store needs path_provider, which a
        // widget test does not have.
        exportFileStoreProvider.overrideWithValue(exportFiles),
        if (exportSharer != null)
          exportSharerProvider.overrideWithValue(exportSharer),
        if (fileSaver != null) fileSaverProvider.overrideWithValue(fileSaver),
      ],
      child: const BaroEaseApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  return PumpedApp(
    db: db,
    prefs: prefs,
    weather: weather,
    scheduler: scheduler,
    permissions: permissions,
    auth: auth,
    appUpdate: appUpdateRepository,
    storeLauncher: storeLauncher,
    profiles: profiles,
    exportFiles: exportFiles,
    health: health,
    premiumRepository: premiumRepository,
    purchases: purchases,
  );
}

/// Must be the last statement of every test that used [pumpApp].
///
/// Flutter's end-of-test "no pending timers" check runs the instant the
/// test body returns — before addTearDown callbacks. Disposing the tree
/// here lets Drift's zero-duration stream-cancellation Timer (scheduled
/// when a Drift-backed StreamProvider is torn down) fire first.
Future<void> finishTest(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 500));
}

/// Taps a target below the fold. A plain `tap()` on an off-screen widget
/// only warns and taps nothing, failing some later assertion instead.
///
/// Deliberately not a bare `ensureVisible` + `tap`: `ensureVisible` aligns the
/// target to the viewport's LEADING edge, and every screen's viewport starts
/// at y=0 because content scrolls *behind* the frosted app bar. Called on a
/// row that is already on screen, it therefore drags that row UNDER the bar,
/// and the tap hit-tests the bar instead of the row — which `tap()` only
/// warns about, so it surfaces later as a missing widget somewhere else.
/// So: scroll only when the target really is off-screen, then make sure
/// whatever the scroll left behind is clear of the chrome.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  final double chromeBottom = _appBarBottom(tester, finder);
  final double screenBottom =
      tester.view.physicalSize.height / tester.view.devicePixelRatio;

  if (tester.getRect(finder).top < chromeBottom ||
      tester.getRect(finder).bottom > screenBottom) {
    await tester.ensureVisible(finder);
    await tester.pump();
  }

  // Only when there is something to scroll. A target inside a bottom sheet
  // has no Scrollable ancestor, and `find.byType(SdAppBarV2)` still matches
  // the bars sitting in the shell's IndexedStack *behind* the sheet — so
  // without this guard the nudge tried to drag a scrollable that does not
  // exist and threw `Bad state: No element`.
  final Finder scrollable = find.ancestor(
    of: finder,
    matching: find.byType(Scrollable),
  );
  final double covered = chromeBottom - tester.getRect(finder).top;

  if (covered > 0 && scrollable.evaluate().isNotEmpty) {
    await tester.drag(
      scrollable.first,
      Offset(0, covered + SdSpacingV2.h8),
    );
    await tester.pump();
  }

  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Bottom edge of the frosted app bar covering [finder]'s screen, or 0 where
/// that screen has none (a sheet, the log flow). Reads the app's own
/// [SdContentPaddingV2.appBarInset] rather than a second copy of the number.
double _appBarBottom(WidgetTester tester, Finder finder) {
  if (find.byType(SdAppBarV2).evaluate().isEmpty) return 0;

  return SdContentPaddingV2.appBarInset(tester.element(finder));
}

/// Tab switches from the shell's bottom nav. Every widget test that leaves
/// the dashboard goes through these rather than re-tapping the icons.
Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Settings → Export data. The export screen is pushed over the tab shell,
/// so it covers the bottom nav.
Future<void> openExportScreen(WidgetTester tester) async {
  await openSettings(tester);
  await tapVisible(tester, find.text('Export data'));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Runs the export flow's chain of awaits (repository reads, the file
/// write, the record insert) to completion on the fake event loop.
Future<void> settleExport(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> openMedications(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.medication_outlined));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> openHistory(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.calendar_month_outlined));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Pumps real frames so the correlation count-up (700ms) can run — one big
/// jump skips its start frame.
Future<void> openInsights(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.insights_outlined));
  for (int i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Opens the log flow from the dashboard's hero button (the flow is a pushed
/// route now, not a tab). Leaves the tester on the intensity step.
Future<void> openLog(WidgetTester tester) async {
  await tester.tap(find.text('Log an attack'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

/// Taps through the sacred flow with sensible defaults, starting from the
/// dashboard. Intensity advances immediately; location and medication are
/// pick-then-confirm — each pick is followed by a tap on the app bar's Next
/// (see LogScreen/LogController). By default it also taps "Done" on the
/// saved screen to return to the dashboard; pass finish: false to stay on the
/// saved step (e.g. to open "Add details").
Future<void> logAttack(
  WidgetTester tester, {
  String intensity = '7',
  String location = 'Right side',
  String medication = 'No medication',
  bool finish = true,
}) async {
  await openLog(tester);

  await tester.tap(find.text(intensity));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  await tester.tap(find.text(location));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.text('Next'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  // The medication step keeps both an expanded and a collapsed copy of the
  // action rows mounted (they cross-fade on scroll), so the label matches
  // twice — .first is the visible, tappable expanded one.
  await tester.tap(find.text(medication).first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.text('Next'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  if (finish) {
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }
}

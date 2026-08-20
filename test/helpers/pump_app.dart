import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/bare_ease_app.dart';
import 'package:migraine_tracker/core/constants/prefs_key_constant.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/core/db/database_provider.dart';
import 'package:migraine_tracker/core/l10n/locale_provider.dart';
import 'package:migraine_tracker/core/permissions/app_permission.dart';
import 'package:migraine_tracker/core/permissions/app_permission_gateway.dart';
import 'package:migraine_tracker/features/alerts/providers.dart';
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
import 'package:migraine_tracker/features/health/domain/entities/step_day.dart';
import 'package:migraine_tracker/features/health/domain/entities/step_hour.dart';
import 'package:migraine_tracker/features/health/domain/enums/health_data_kind.dart';
import 'package:migraine_tracker/features/health/domain/repositories/health_repository.dart';
import 'package:migraine_tracker/features/health/providers.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication_reminder.dart';
import 'package:migraine_tracker/features/medications/domain/services/notification_scheduler.dart';
import 'package:migraine_tracker/features/medications/providers.dart';
import 'package:migraine_tracker/features/notifications/providers.dart';
import 'package:migraine_tracker/features/premium/domain/entities/premium_offer.dart';
import 'package:migraine_tracker/features/premium/domain/enums/premium_period.dart';
import 'package:migraine_tracker/features/premium/domain/repositories/premium_repository.dart';
import 'package:migraine_tracker/features/premium/domain/repositories/purchase_repository.dart';
import 'package:migraine_tracker/features/premium/providers.dart';
import 'package:migraine_tracker/features/review/providers.dart';
import 'package:migraine_tracker/features/settings/domain/services/mail_launcher.dart';
import 'package:migraine_tracker/features/settings/providers.dart';
import 'package:migraine_tracker/features/sync/providers.dart';
import 'package:migraine_tracker/features/weather/domain/entities/pressure_forecast.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_report.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';
import 'package:migraine_tracker/features/weather/domain/repositories/weather_repository.dart';
import 'package:migraine_tracker/features/weather/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/index.dart';

import 'alert_fakes.dart';
import 'export_fakes.dart';
import 'notification_fakes.dart';
import 'review_fakes.dart';
import 'sync_fakes.dart';

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

  /// The weather card's payload. Null by default — no weather — because most
  /// tests care about some other card. Set it to make the card draw, and
  /// count [reportCalls] to prove something asked again.
  WeatherReport? weatherReport;

  int reportCalls = 0;

  @override
  Future<WeatherReport?> report() async {
    reportCalls++;

    return weatherReport;
  }
}

/// No-op scheduler so widget tests never touch the notifications plugin.
class FakeNotificationScheduler implements NotificationScheduler {
  /// Set when [scheduleTest] is called, so a test can assert the debug
  /// "test notification" action reached the scheduler.
  bool testScheduled = false;

  /// Reminder id a test replays as a tap on a running app.
  final StreamController<String> taps = StreamController<String>.broadcast();

  /// Reminder id a test says the app was launched by. Null = opened normally.
  String? launchReminderId;

  Future<void> dispose() => taps.close();

  @override
  Stream<String> get reminderTaps => taps.stream;

  @override
  Future<String?> takeLaunchReminderId() async => launchReminderId;

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

/// Records the mailto: recipient/subject instead of leaving the test to
/// url_launcher.
class FakeMailLauncher implements MailLauncher {
  String? to;
  String? subject;
  String? body;

  /// Flip to false to exercise the "couldn't open the mail app" branch.
  bool succeeds = true;

  @override
  Future<bool> open({
    required String to,
    required String subject,
    String? body,
  }) async {
    this.to = to;
    this.subject = subject;
    this.body = body;
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

  /// Records that the account was torn down, without pretending to do it.
  int deleteAccountCalls = 0;

  /// Records the Apple revoke, so a test can assert it ran BEFORE the wipe —
  /// the ordering the real deletion depends on.
  int revokeAppleTokenCalls = 0;

  /// Set to make [revokeAppleTokenIfLinked] throw, standing in for the user
  /// backing out of the Apple sheet that deletion re-opens.
  AuthError? revokeFailsWith;

  @override
  Future<void> deleteAccount() async {
    deleteAccountCalls++;
    await signOut();
  }

  @override
  Future<void> revokeAppleTokenIfLinked() async {
    revokeAppleTokenCalls++;
    final AuthError? error = revokeFailsWith;

    if (error != null) throw AuthException(error);
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
      priceLabel: r'$4.99',
    ),
    PremiumOffer(
      id: r'$rc_annual',
      period: PremiumPeriod.yearly,
      priceLabel: r'$29.99',
      trialDays: 7,
    ),
    PremiumOffer(
      id: r'$rc_lifetime',
      period: PremiumPeriod.lifetime,
      priceLabel: r'$44.99',
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

  /// Served by [stepDays], unfiltered — tests hand over exactly the days they
  /// want analysed.
  List<StepDay> days = <StepDay>[];

  /// Served by [stepHours], unfiltered — the step chart's Day range.
  List<StepHour> hours = <StepHour>[];

  int authorizationRequests = 0;

  /// How many times sleep was actually read — the assertion behind "a free
  /// user never reaches a HealthKit read".
  int sleepReads = 0;

  /// How many times steps were actually read — same role as [sleepReads].
  int stepReads = 0;

  /// Reads of the hourly series, counted separately: the Day range is its own
  /// query, so a test can tell which one a card issued.
  int stepHourReads = 0;

  /// Which sources were asked for: sleep and steps prompt separately now.
  final List<HealthDataKind> requestedKinds = <HealthDataKind>[];

  @override
  Future<bool> requestAuthorization(HealthDataKind kind) async {
    authorizationRequests++;
    requestedKinds.add(kind);
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

  @override
  Future<List<StepDay>> stepDays({
    required DateTime from,
    required DateTime to,
  }) async {
    stepReads++;
    return days;
  }

  @override
  Future<List<StepHour>> stepHours({
    required DateTime from,
    required DateTime to,
  }) async {
    stepHourReads++;

    return hours;
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
    required this.mailLauncher,
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
  final FakeMailLauncher mailLauncher;
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

  /// On, as shipped: the Apple button runs the real flow (App Store 4.8).
  /// False covers the kill-switch state, where tapping it says so instead.
  bool appleSignIn = true,

  /// What `SdGlassV2.isSupported` reports. Defaults to true (the shipped iOS
  /// path); pass false to cover the Android/Skia fallback chrome.
  bool glassSupported = true,

  /// What every OS permission answers from the first frame. Granted by
  /// default; set before the pump because the weather card reads location's
  /// status while it builds, and flipping `permissions.statusFor` afterwards
  /// is a frame too late.
  AppPermissionStatus permissionStatus = AppPermissionStatus.granted,

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

  /// Days the fake HealthKit serves to the step correlation.
  List<StepDay> stepDays = const <StepDay>[],

  /// The build this fake device is running. Both are high by default, so a
  /// test that passes [appUpdate] still has to opt into being out of date.
  String installedBuildName = '99.0.0',
  int installedBuildNumber = 9999,
}) async {
  // - pin the test view to the 393×852 design size (an iPhone-class screen, DPR 3 = 1179×2556 physical)
  // - the default 800×600 surface scales `.sp`/`.w`/`.h` ~2×, distorting layout and pushing tap targets off-screen
  tester.view.physicalSize = const Size(393 * 3, 852 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // - the test engine is Skia, so SdGlassV2.isSupported would always be false and tests would assert the fallback layout
  // - glass still renders as FakeGlass here; only the insets follow
  SdGlassV2.debugSupported = glassSupported;
  addTearDown(() => SdGlassV2.debugSupported = null);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  // Onboarding is considered done by default so existing tests land on the
  // dashboard; pass onboarding_completed: false to exercise onboarding.
  SharedPreferences.setMockInitialValues({
    PrefsKeyConstant.onboardingCompleted: true,
    ...initialPrefs,
  });
  final prefs = await SharedPreferences.getInstance();
  final weather = FakeWeatherRepository(snapshot: weatherSnapshot);
  final scheduler = FakeNotificationScheduler();
  addTearDown(scheduler.dispose);
  final permissions = FakeAppPermissionGateway()..statusFor = permissionStatus;
  final exportFiles = FakeExportFileStore();
  final auth = FakeAuthRepository(signedIn: signedIn ?? premium);
  addTearDown(auth.dispose);
  final FakeAppUpdateRepository appUpdateRepository = FakeAppUpdateRepository(
    config: appUpdate,
  );
  final FakeStoreLauncher storeLauncher = FakeStoreLauncher();
  final FakeMailLauncher mailLauncher = FakeMailLauncher();
  final FakeUserProfileRepository profiles = FakeUserProfileRepository(
    profile: userProfile,
  );
  addTearDown(profiles.dispose);
  final FakeHealthRepository health =
      FakeHealthRepository(isAvailable: healthAvailable)
        ..nights = <SleepNight>[...sleepNights]
        ..days = <StepDay>[...stepDays];
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
        mailLauncherProvider.overrideWithValue(mailLauncher),
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
        // Always overridden too: the app root fires a sync on sign-in, and
        // the real repositories reach for Firebase, which no widget test has.
        syncKeyRepositoryProvider.overrideWithValue(FakeSyncKeyRepository()),
        remoteSyncRepositoryProvider.overrideWithValue(
          FakeRemoteSyncRepository(),
        ),
        // Same reason: the GDPR wipe gives up the push token, and the real
        // repository reaches for FirebaseAuth and Firestore to do it.
        alertRegistrationRepositoryProvider.overrideWithValue(
          RecordingAlertRegistration(),
        ),
        // And again: the app root reconciles the last pressure alert on
        // launch, which is a Firestore read of `users/{uid}`.
        lastAlertRepositoryProvider.overrideWithValue(
          FakeLastAlertRepository(),
        ),
        // Every saved attack and every shared report reaches the review
        // prompt, and the real one is a platform channel.
        reviewPrompterProvider.overrideWithValue(RecordingReviewPrompter()),
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
    mailLauncher: mailLauncher,
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

/// The [TextField] inside the [SdTextFieldV2] labelled [label].
///
/// [SdTextFieldV2] draws its label as a `Text` *above* the box, not inside
/// its `InputDecoration` — so, unlike a raw `TextField`,
/// `find.widgetWithText(TextField, label)` never matches it (that finder
/// wants the label as a descendant of the `TextField` itself). This walks up
/// from the label to the field that owns it instead.
Finder findLabelledField(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(SdTextFieldV2)),
  matching: find.byType(TextField),
);

/// Scrolls until [finder] has been built, and does nothing when it already
/// has been.
///
/// A long list builds lazily, so a row far enough down does not exist yet and
/// anything measuring it throws on an empty finder — as `Bad state: No
/// element`, which reads as a broken helper rather than as "scroll further".
/// Two rows added to Settings is all it took the first time, and the dev
/// group moving to the top of that screen is what took it a second time.
///
/// **An `expect(find.text(...), findsOneWidget)` on a settings row needs this
/// first.** A finder is not a camera: a row below the built range is absent
/// from the tree, not merely off-screen, and the assertion fails on a screen
/// that is perfectly correct.
///
/// `find.byType(Scrollable).first` is the visible tab's own list — the shell's
/// other branches are offstage in its `IndexedStack`, and finders skip those.
Future<void> scrollIntoView(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) return;

  final Finder scrollable = find.byType(Scrollable);

  if (scrollable.evaluate().isEmpty) return;

  await tester.dragUntilVisible(
    finder,
    scrollable.first,
    const Offset(0, -200),
  );
  await tester.pump();
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
  await scrollIntoView(tester, finder);

  final double chromeBottom = _appBarBottom(tester, finder);
  final double screenBottom =
      tester.view.physicalSize.height / tester.view.devicePixelRatio;

  if (tester.getRect(finder).top < chromeBottom ||
      tester.getRect(finder).bottom > screenBottom) {
    await tester.ensureVisible(finder);
    await tester.pump();
  }

  // - only when there's something to scroll: a bottom-sheet target has no Scrollable ancestor
  // - `find.byType(SdAppBarV2)` still matches bars sitting behind the sheet in the shell's IndexedStack
  // - without this guard the nudge dragged a scrollable that doesn't exist and threw `Bad state: No element`
  final Finder scrollable = find.ancestor(
    of: finder,
    matching: find.byType(Scrollable),
  );
  final double covered = chromeBottom - tester.getRect(finder).top;

  if (covered > 0 && scrollable.evaluate().isNotEmpty) {
    await tester.drag(
      scrollable.first,
      Offset(0, covered + SdSpacingConstant.h8),
    );
    await tester.pump();
  }

  // - the same problem at the other end: a tab screen's floating nav pill
  //   covers its last rows, and tap() only warns when it hits the pill
  // - asks whether the row can be hit rather than measuring the chrome, so it
  //   costs nothing on a screen that has none
  for (int i = 0; i < 5; i++) {
    if (finder.hitTestable().evaluate().isNotEmpty) break;
    if (scrollable.evaluate().isEmpty) break;

    await tester.drag(
      scrollable.first,
      Offset(0, -SdContentPaddingV2.floatingBarHeight),
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
///
/// **Needs `pumpApp(premium: true)`**: export is premium in full, so the row
/// opens the paywall for a free user and every assertion after this lands on
/// the wrong screen.
Future<void> openExportScreen(WidgetTester tester) async {
  await openSettings(tester);
  await tapVisible(tester, find.text('Export data'));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Settings → Sleep. Carries the sleep insight and its connect switch.
Future<void> openSleepScreen(WidgetTester tester) async {
  await openSettings(tester);
  await tapVisible(tester, find.text('Sleep'));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Settings → Activity. Carries the exertion report, the step insight and
/// the step connect switch.
Future<void> openActivityScreen(WidgetTester tester) async {
  await openSettings(tester);
  await tapVisible(tester, find.text('Activity'));
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
  // `.last` is the nav bar, same as `openInsights`: the dashboard's
  // quick-access tile carries this glyph too, and the bottom bar is built
  // after the body, so it comes last.
  await tester.tap(find.byIcon(Icons.medication_outlined).last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> openHistory(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.calendar_month_outlined));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Medications tab → the add dialog → a medication named [name].
/// The "+" is in the app bar: a FAB would sit under the floating nav's hit
/// region on a shell tab (see MedicationsScreen).
Future<void> addMedication(WidgetTester tester, String name) async {
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.enterText(
    find.widgetWithText(TextField, 'Medication name'),
    name,
  );
  await tester.tap(find.text('Add'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Opens a medication's detail screen from its row in the list.
Future<void> openMedication(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Taps "Add reminder" on a medication's detail screen. What comes up is the
/// caller's business: the time picker when the budget allows one, the paywall
/// when it does not.
Future<void> openAddReminder(WidgetTester tester) async {
  await tester.tap(find.text('Add reminder'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Confirms the reminder time picker at whatever time it opened on. Scoped
/// to the sheet's own header: a focused medication name field carries a tick
/// too, and a bare `byIcon` would match both.
Future<void> confirmReminderTime(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(SdSheetHeaderV2),
      matching: find.byIcon(Icons.check),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Adds [count] reminders from a medication's detail screen, each at the
/// time the picker opens on. Only valid while the budget allows them — past
/// the limit the dialog comes up instead and there is no picker to confirm.
Future<void> addReminders(WidgetTester tester, int count) async {
  for (int i = 0; i < count; i++) {
    await openAddReminder(tester);
    await confirmReminderTime(tester);
  }
}

/// The delete button ON a reminder row — the detail screen's app bar carries
/// the same icon for deleting the medication itself, so a bare byIcon
/// matches two.
Finder reminderDelete() => find.descendant(
  of: find.byType(SdCardV2),
  matching: find.byIcon(Icons.delete_outline),
);

/// The notification list, from the dashboard's app-bar bell.
///
/// The extra frame is the medication stream's first emission: it only
/// starts once the list watches it, so a row renders its generic label for
/// one frame before it can name the medication.
Future<void> openNotifications(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.notifications_none));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 100));
}

/// History, switched to the chart deck via the view toggle.
Future<void> openHistoryCharts(WidgetTester tester) async {
  await openHistory(tester);
  await tester.tap(find.byIcon(Icons.bar_chart));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Pumps real frames so the correlation count-up (700ms) can run — one big
/// jump skips its start frame.
Future<void> openInsights(WidgetTester tester) async {
  // `.last` is the nav bar: the dashboard's quick-access tile now carries the
  // same glyph, and the bottom bar is built after the body, so it comes last.
  await tester.tap(find.byIcon(Icons.insights_outlined).last);
  await pumpCountUp(tester);
}

/// Real frames, enough of them for the correlation's 700ms count-up to land.
///
/// One big `pump` skips its start frame, and `pumpAndSettle` cannot be used
/// while it is running — so the frames are walked by hand.
Future<void> pumpCountUp(WidgetTester tester) async {
  for (int i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Insights, standing on its Pressure tab — which is where the correlation
/// lives.
///
/// **No tap any more: Insights opens on Pressure** (`InsightsTabController`),
/// now that the weather it used to open on lives on the dashboard. Tapping
/// the segment here would also be ambiguous — "Pressure" is on screen twice,
/// as the segment and as the card's own title.
///
/// The extra count-up still earns its place: the tabs build lazily, so the
/// first frames go on mounting the card and the hero number is still counting
/// when the frames inside `openInsights` run out.
Future<void> openPressureInsight(WidgetTester tester) async {
  await openInsights(tester);
  await pumpCountUp(tester);
}

/// Drags [target] into view with bounded pumps, and never `pumpAndSettle`.
///
/// **Insights never settles.** Its cards keep frames coming, so
/// `pumpAndSettle` — which `dragUntilVisible` and `scrollUntilVisible` both
/// use — waits out its own ten-minute timeout instead of scrolling. Two tests
/// spent that timeout each and read as a hung suite rather than a bad helper.
Future<void> dragInsightsTo(WidgetTester tester, Finder target) async {
  for (int i = 0; i < 12 && target.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -260));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Insights, standing on its Sleep tab.
///
/// **The tab has to be tapped**: Insights opens on Pressure, so a test that
/// only calls [openInsights] looks for the sleep card on a tab that does not
/// draw it. Scoped to the segment strip because the dashboard branch stays
/// mounted behind Insights and its Today section has a "Sleep" row too.
Future<void> openSleepInsight(WidgetTester tester) async {
  await openInsights(tester);
  await tester.tap(
    find.descendant(
      of: find.byType(SdSegmentedTabsV2),
      matching: find.text('Sleep'),
    ),
  );
  await pumpCountUp(tester);
}

/// Insights, standing on its Activity tab — same reason as
/// [openSleepInsight].
Future<void> openActivityInsight(WidgetTester tester) async {
  await openInsights(tester);
  await tester.tap(
    find.descendant(
      of: find.byType(SdSegmentedTabsV2),
      matching: find.text('Activity'),
    ),
  );
  await pumpCountUp(tester);
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
/// (see LogScreen/LogController). Exertion is skipped unless [exertion] names
/// a level, which is what most tests want: it is the one optional step. By
/// default it also taps "Done" on the saved screen to return to the
/// dashboard; pass finish: false to stay on the saved step (e.g. to open
/// "Add details").
Future<void> logAttack(
  WidgetTester tester, {
  String intensity = '7',
  String location = 'Right temple',
  String medication = 'No medication',
  String? exertion,
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

  // Expanded and collapsed action rows both stay mounted (cross-fade on scroll),
  // so the label matches twice — .first is the visible, tappable expanded one.
  await tester.tap(find.text(medication).first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.text('Next'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  // Exertion: skippable, so Next alone passes it when no level is asked for.
  if (exertion != null) {
    await tester.tap(find.text(exertion));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.tap(find.text('Next'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  if (finish) {
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }
}

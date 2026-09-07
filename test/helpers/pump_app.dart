import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/bare_ease_app.dart';
import 'package:migraine_tracker/core/constants/prefs_key_constant.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/core/db/database_provider.dart';
import 'package:migraine_tracker/core/permissions/app_permission.dart';
import 'package:migraine_tracker/core/permissions/app_permission_gateway.dart';
import 'package:migraine_tracker/core/router/app_router.dart';
import 'package:migraine_tracker/core/storage/secure_store.dart';
import 'package:migraine_tracker/core/theme/app_icon_constant.dart';
import 'package:migraine_tracker/features/alerts/providers.dart';
import 'package:migraine_tracker/features/app_config/domain/entities/app_config.dart';
import 'package:migraine_tracker/features/app_config/domain/entities/app_update_config.dart';
import 'package:migraine_tracker/features/app_config/domain/entities/installed_app_version.dart';
import 'package:migraine_tracker/features/app_config/domain/repositories/app_config_repository.dart';
import 'package:migraine_tracker/features/app_config/domain/repositories/app_update_repository.dart';
import 'package:migraine_tracker/features/app_config/domain/services/store_launcher.dart';
import 'package:migraine_tracker/features/app_config/providers.dart';
import 'package:migraine_tracker/features/attacks/providers.dart';
import 'package:migraine_tracker/features/auth/domain/entities/auth_user.dart';
import 'package:migraine_tracker/features/auth/domain/entities/user_profile.dart';
import 'package:migraine_tracker/features/auth/domain/enums/auth_error.dart';
import 'package:migraine_tracker/features/auth/domain/enums/auth_provider_kind.dart';
import 'package:migraine_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:migraine_tracker/features/auth/domain/repositories/user_profile_repository.dart';
import 'package:migraine_tracker/features/auth/providers.dart';
import 'package:migraine_tracker/features/health/domain/entities/cycle_day.dart';
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
import 'package:migraine_tracker/features/splash/providers.dart';
import 'package:migraine_tracker/features/sync/providers.dart';
import 'package:migraine_tracker/features/weather/data/datasources/location_source.dart';
import 'package:migraine_tracker/features/weather/domain/entities/geo_point.dart';
import 'package:migraine_tracker/features/weather/domain/entities/pressure_forecast.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_report.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';
import 'package:migraine_tracker/features/weather/domain/repositories/weather_repository.dart';
import 'package:migraine_tracker/features/weather/providers.dart';
import 'package:system_design/index.dart';

import 'alert_fakes.dart';
import 'attack_fakes.dart';
import 'export_fakes.dart';
import 'notification_fakes.dart';
import 'review_fakes.dart';
import 'sync_fakes.dart';

export 'settle_frames.dart';

/// Stands in for geolocator, which a widget test has no platform channel for — the real source's `requestPermission` never completes there, so a screen.
class RecordingLocationSource implements LocationSource {
  RecordingLocationSource({this.granted = true});

  /// What the OS answers. False covers a denial, which changes nothing about onboarding moving on.
  final bool granted;

  int requestCalls = 0;

  @override
  Future<GeoPoint?> currentPosition() async =>
      granted ? const GeoPoint(latitude: 48.85, longitude: 2.35) : null;

  @override
  Future<bool> requestPermission() async {
    requestCalls++;

    return granted;
  }
}

/// Offline-behaving weather stub: widget tests never touch geolocator or the network.
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

  /// The weather card's payload.
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
  /// Set when [scheduleTest] is called, so a test can assert the debug "test notification" action reached the scheduler.
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

/// Stands in for the `app_config/current` document. Default: premium on and every list empty — the state of a project nobody has configured, which is how the app ships.
class FakeAppConfigRepository implements AppConfigRepository {
  FakeAppConfigRepository({AppConfig? config})
    : config = config ?? AppConfig.empty;

  AppConfig config;

  /// How many times the document was subscribed to. One per app, or the read is being reopened on every rebuild.
  int watchCalls = 0;

  /// Not broadcast, and not an `async*` generator: both drop an event pushed
  /// before the subscription is live, which is exactly the race a test that
  /// emits right after the first value would lose.
  StreamController<AppConfig> _controller = StreamController<AppConfig>();

  @override
  Stream<AppConfig> watch() {
    watchCalls++;
    _controller = StreamController<AppConfig>();
    _controller.add(config);

    return _controller.stream;
  }

  /// Pushes an edit the way the owner saving the console document does.
  void emit(AppConfig next) => _controller.add(next);
}

/// Serves whatever update record a test asks for. Default: no record at all, so the force-update wrapper never blocks the app under test.
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

/// Records the mailto: recipient/subject instead of leaving the test to url_launcher.
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

/// In-memory account. Not optional like the other fakes: `authUserProvider` is watched at build time, so a real one drags Firebase into the tree.
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

  /// Records the Apple revoke, so a test can assert it ran BEFORE the wipe — the ordering the real deletion depends on.
  int revokeAppleTokenCalls = 0;

  /// Set to make [revokeAppleTokenIfLinked] throw, standing in for the user backing out of the Apple sheet that deletion re-opens.
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

/// In-memory account document. The account tab watches it, so a real one would drag Firestore into the test tree.
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
  Future<bool> upsertFromAccount(AuthUser user) async {
    final bool created = profile == null;

    synced.add(user);
    profile ??= UserProfile(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
    );
    _controller.add(profile);

    return created;
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

/// The store, without a store.
class FakePurchaseRepository implements PurchaseRepository {
  FakePurchaseRepository(this._premium);

  final FakePremiumRepository _premium;

  /// The two plans PLAN.md sells, at their listed prices.
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
  ];

  /// Set to make [purchase] and [restore] throw this instead of granting.
  Exception? failWith;

  /// Set to make loading the offerings fail, which is a different story: the paywall has nothing to show rather than something that fails on tap.
  Exception? offersFailWith;

  /// Whether [restore] finds anything.
  bool hasPastPurchase = false;

  /// Held open to keep [restore] in flight, so a test can tap while the store call has not landed. Complete it to let the call finish.
  Completer<void>? restoreGate;

  /// The store page [managementUrl] hands back. Null is the store having nothing to manage, which hides the manage button.
  String? management = 'https://apps.apple.com/account/subscriptions';

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
    await restoreGate?.future;
    if (failure != null) throw failure;
    if (!hasPastPurchase) return false;

    _premium.setPremium(true);

    return true;
  }

  @override
  Future<String?> managementUrl() async {
    final Exception? failure = failWith;

    if (failure != null) throw failure;

    return management;
  }

  @override
  Future<void> identify(String uid) async => identified.add(uid);

  @override
  Future<void> forget() async => identified.add(null);
}

/// Stands in for HealthKit.
class FakeHealthRepository implements HealthRepository {
  FakeHealthRepository({this.isAvailable = false});

  @override
  bool isAvailable;

  /// What the authorization sheet reports. False covers the "couldn't connect" branch.
  bool authorizes = true;

  /// Served by [sleepNights], unfiltered — tests hand over exactly the nights they want analysed.
  List<SleepNight> nights = <SleepNight>[];

  /// Served by [stepDays], unfiltered — tests hand over exactly the days they want analysed.
  List<StepDay> days = <StepDay>[];

  /// Served by [stepHours], unfiltered — the step chart's Day range.
  List<StepHour> hours = <StepHour>[];

  int authorizationRequests = 0;

  /// How many times sleep was actually read — the assertion behind "a free user never reaches a HealthKit read".
  int sleepReads = 0;

  /// How many times steps were actually read — same role as [sleepReads].
  int stepReads = 0;

  /// Reads of the hourly series, counted separately: the Day range is its own query, so a test can tell which one a card issued.
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
  Future<List<CycleDay>> cycleDays({
    required DateTime from,
    required DateTime to,
  }) async => const <CycleDay>[];

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

/// Grants permissions by default; a test can flip [statusFor] to exercise the permanently-denied → settings-sheet path. Never touches the OS.
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
    required this.location,
    required this.auth,
    required this.appConfig,
    required this.appUpdate,
    required this.storeLauncher,
    required this.mailLauncher,
    required this.profiles,
    required this.exportFiles,
    required this.shareFiles,
    required this.health,
    required this.premiumRepository,
    required this.purchases,
  });

  final AppDatabase db;
  final SecureStore prefs;
  final FakeWeatherRepository weather;
  final FakeNotificationScheduler scheduler;
  final FakeAppPermissionGateway permissions;

  /// The location plugin's stand-in. `requestCalls` is how a test proves the OS prompt was actually raised.
  final RecordingLocationSource location;
  final FakeAuthRepository auth;

  /// The `app_config` stand-in, so a test can revoke or block mid-run the way the owner editing the console does.
  final FakeAppConfigRepository appConfig;
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

  /// Where exports landed. Read `singleContent` to assert on what was written without touching a real filesystem.
  final FakeExportFileStore exportFiles;

  /// The share images the GDPR wipe has to reach. `cleared` says it did.
  final RecordingShareFileStore shareFiles;
}

/// Boots the full app with an in-memory database, mock prefs, and stubbed weather. Uses bounded pumps — see the Drift/pumpAndSettle note below.
Future<PumpedApp> pumpApp(
  WidgetTester tester, {
  Map<String, Object> initialPrefs = const {},
  WeatherSnapshot? weatherSnapshot,
  // Riverpod 3 no longer exports the `Override` type, so the helper takes the concrete fakes it knows about instead of a generic override list.
  RecordingExportSharer? exportSharer,
  RecordingFileSaver? fileSaver,

  /// Default free — gating tests must opt in to premium explicitly.
  bool premium = false,

  /// Default signed out, and independent of [premium]: buying needs no account (App Store 5.1.1(v)), so the two are unrelated states.
  bool signedIn = false,

  /// On, as shipped: the Apple button runs the real flow (App Store 4.8). False covers the kill-switch state, where tapping it says so instead.
  bool appleSignIn = true,

  /// What `SdGlassV2.isSupported` reports. Defaults to true (the shipped iOS path); pass false to cover the Android/Skia fallback chrome.
  bool glassSupported = true,

  /// What every OS permission answers from the first frame.
  AppPermissionStatus permissionStatus = AppPermissionStatus.granted,

  /// The account document the account tab reads. Null = not written yet, which is what a brand-new sign-in looks like.
  UserProfile? userProfile,

  /// The `app_config/current` document. Default: premium on and every list empty, which is every address the owner has not typed into the console.
  AppConfig? appConfig,

  /// The record the force-update check reads. Null (default) = no record, so the blocking sheet never appears.
  AppUpdateConfig? appUpdate,

  /// Whether this fake device has HealthKit. False by default — the Apple Health row and the sleep card are iOS-only surfaces.
  bool healthAvailable = false,

  /// Nights the fake HealthKit serves to the sleep correlation.
  List<SleepNight> sleepNights = const <SleepNight>[],

  /// Days the fake HealthKit serves to the step correlation.
  List<StepDay> stepDays = const <StepDay>[],

  /// The build this fake device is running. Both are high by default, so a test that passes [appUpdate] still has to opt into being out of date.
  String installedBuildName = '99.0.0',
  int installedBuildNumber = 9999,
}) async {
  // - pin the test view to the 393×852 design size (an iPhone-class screen, DPR 3 = 1179×2556 physical).
  tester.view.physicalSize = const Size(393 * 3, 852 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // - the test engine is Skia, so SdGlassV2.isSupported would always be false and tests would assert the fallback layout.
  SdGlassV2.debugSupported = glassSupported;
  addTearDown(() => SdGlassV2.debugSupported = null);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  // Onboarding is considered done by default so existing tests land on the dashboard; pass onboarding_completed: false to exercise onboarding.
  // The Keychain mock takes strings only, so a seed value is encoded the way SecureStore writes it.
  FlutterSecureStorage.setMockInitialValues(<String, String>{
    PrefsKeyConstant.onboardingCompleted: 'true',
    ...initialPrefs.map(
      (String key, Object value) => MapEntry<String, String>(key, '$value'),
    ),
  });
  final SecureStore prefs = await SecureStore.open();
  final weather = FakeWeatherRepository(snapshot: weatherSnapshot);
  final scheduler = FakeNotificationScheduler();
  addTearDown(scheduler.dispose);
  final permissions = FakeAppPermissionGateway()..statusFor = permissionStatus;
  final RecordingLocationSource location = RecordingLocationSource();
  final exportFiles = FakeExportFileStore();
  final RecordingShareFileStore shareFiles = RecordingShareFileStore();
  final auth = FakeAuthRepository(signedIn: signedIn);
  addTearDown(auth.dispose);
  final FakeAppConfigRepository appConfigRepository = FakeAppConfigRepository(
    config: appConfig,
  );
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
        // Straight past the splash: its dots never stop, so pumpAndSettle would wait out its whole timeout instead of settling.
        initialLocationProvider.overrideWithValue(AppRoutes.dashboard.path),
        secureStoreProvider.overrideWithValue(prefs),
        // No other build shares a test process's sandbox. Resolved
        // SYNCHRONOUSLY — a `FutureOr` override lands as data on the first
        // frame, where an `async` one would leave `FreshInstallGate` showing
        // the splash dots for a frame and every tree here pumping against a
        // half-built app.
        freshInstallProvider.overrideWith(
          (ref) => SdFreshInstallOutcome.normalLaunch,
        ),
        weatherRepositoryProvider.overrideWithValue(weather),
        notificationSchedulerProvider.overrideWithValue(scheduler),
        appPermissionGatewayProvider.overrideWithValue(permissions),
        locationSourceProvider.overrideWithValue(location),
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
        // Always overridden: the real store needs path_provider, which a widget test does not have.
        exportFileStoreProvider.overrideWithValue(exportFiles),
        // Same reason, and the wipe awaits it.
        attackShareFileStoreProvider.overrideWithValue(shareFiles),
        // Always overridden too: the app root fires a sync on sign-in, and the real repositories reach for Firebase, which no widget test has.
        syncKeyRepositoryProvider.overrideWithValue(FakeSyncKeyRepository()),
        remoteSyncRepositoryProvider.overrideWithValue(
          FakeRemoteSyncRepository(),
        ),
        // Same reason: the GDPR wipe gives up the push token, and the real repository reaches for FirebaseAuth and Firestore to do it.
        alertRegistrationRepositoryProvider.overrideWithValue(
          RecordingAlertRegistration(),
        ),
        // And again: the app root reconciles the last pressure alert on launch, which is a Firestore read of `users/{uid}`.
        lastAlertRepositoryProvider.overrideWithValue(
          FakeLastAlertRepository(),
        ),
        // Always overridden as well: the app-wide switches have no signed-in branch to short-circuit on, so every tree that gates on premium would open a real Firestore listener.
        appConfigRepositoryProvider.overrideWithValue(appConfigRepository),
        // Every saved attack and every shared report reaches the review prompt, and the real one is a platform channel.
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
    location: location,
    auth: auth,
    appConfig: appConfigRepository,
    appUpdate: appUpdateRepository,
    storeLauncher: storeLauncher,
    mailLauncher: mailLauncher,
    profiles: profiles,
    exportFiles: exportFiles,
    shareFiles: shareFiles,
    health: health,
    premiumRepository: premiumRepository,
    purchases: purchases,
  );
}

/// Must be the last statement of every test that used [pumpApp].
Future<void> finishTest(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 500));
}

/// The [TextField] inside the [SdTextFieldV2] labelled [label].
Finder findLabelledField(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(SdTextFieldV2)),
  matching: find.byType(TextField),
);

/// Scrolls until [finder] has been built, and does nothing when it already has been.
///
/// Bounded drags rather than `dragUntilVisible`, which settles between drags — see [settleFrames].
Future<void> scrollIntoView(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) return;

  final Finder scrollable = find.byType(Scrollable);

  if (scrollable.evaluate().isEmpty) return;

  // 40 rather than a dozen: `dragUntilVisible` kept going until it found the target, and the settings list is long enough
  // that a short bound stops above the row and fails as "not found" rather than as "not reachable".
  for (int i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.drag(scrollable.first, const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump();
}

/// Taps a target below the fold.
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

  // - only when there's something to scroll: a bottom-sheet target has no Scrollable ancestor - `find.byType(SdAppBarV2)` still matches bars sitting.
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

  // - the same at the other end: a tab screen's nav pill covers its last rows, and tap() only warns when it hits the pill - asks whether the row can be.
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

/// Bottom edge of the frosted app bar covering [finder]'s screen, or 0 where that screen has none (a sheet, the log flow).
double _appBarBottom(WidgetTester tester, Finder finder) {
  if (find.byType(SdAppBarV2).evaluate().isEmpty) return 0;

  return SdContentPaddingV2.appBarInset(tester.element(finder));
}

/// Tab switches from the shell's bottom nav. Every widget test that leaves the dashboard goes through these rather than re-tapping the icons.
Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(AppIconConstant.settings));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Settings → Export data.
Future<void> openExportScreen(WidgetTester tester) async {
  await openSettings(tester);
  await tapVisible(tester, find.text('Export data'));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Settings → Sleep, which now selects Insights' sleep tab rather than
/// pushing a screen of its own.
Future<void> openSleepTab(WidgetTester tester) async {
  await openSettings(tester);
  await tapVisible(tester, find.text('Sleep'));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Settings → Activity, which now selects Insights' activity tab rather than
/// pushing a screen of its own.
Future<void> openActivityTab(WidgetTester tester) async {
  await openSettings(tester);
  await tapVisible(tester, find.text('Activity'));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Runs the export flow's chain of awaits (repository reads, the file write, the record insert) to completion on the fake event loop.
Future<void> settleExport(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> openMedications(WidgetTester tester) async {
  // `.last` is the nav bar, same as `openInsights`.
  await tester.tap(find.byIcon(AppIconConstant.medication).last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> openHistory(WidgetTester tester) async {
  // `.last` is the nav bar, same as `openMedications`.
  await tester.tap(find.byIcon(AppIconConstant.history).last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Medications tab → the add dialog → a medication named [name].
Future<void> addMedication(WidgetTester tester, String name) async {
  await tester.tap(find.byIcon(AppIconConstant.add));
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

/// Taps "Add reminder" on a medication's detail screen.
Future<void> openAddReminder(WidgetTester tester) async {
  await tester.tap(find.text('Add reminder'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Confirms the reminder time picker at whatever time it opened on.
Future<void> confirmReminderTime(WidgetTester tester) async {
  // The commit is the button pinned along the sheet's bottom edge, not an icon in its header.
  await tester.tap(
    find.descendant(
      of: find.byType(SdSheetContentV2),
      matching: find.byType(SdButtonV2),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Adds [count] reminders from a medication's detail screen, each at the time the picker opens on.
Future<void> addReminders(WidgetTester tester, int count) async {
  for (int i = 0; i < count; i++) {
    await openAddReminder(tester);
    await confirmReminderTime(tester);
  }
}

/// The delete button ON a reminder row — the detail screen's app bar carries the same icon for deleting the medication itself, so a bare byIcon matches two.
Finder reminderDelete() => find.descendant(
  of: find.byType(SdCardV2),
  matching: find.byIcon(AppIconConstant.delete),
);

/// The notification list, from the dashboard's app-bar bell.
Future<void> openNotifications(WidgetTester tester) async {
  await tester.tap(find.byIcon(AppIconConstant.notifications));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 100));
}

/// History, switched to the chart deck via the view toggle.
Future<void> openHistoryCharts(WidgetTester tester) async {
  await openHistory(tester);
  await tester.tap(find.byIcon(AppIconConstant.barChart));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Pumps real frames so the correlation count-up (700ms) can run — one big jump skips its start frame.
Future<void> openInsights(WidgetTester tester) async {
  // `.last` is the nav bar: the dashboard's quick-access tile now carries the same glyph, and the bottom bar is built after the body, so it comes last.
  await tester.tap(find.byIcon(AppIconConstant.insights).last);
  await pumpCountUp(tester);
}

/// Real frames, enough of them for the correlation's 700ms count-up to land.
Future<void> pumpCountUp(WidgetTester tester) async {
  for (int i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Insights, standing on its Pressure tab — which is where the correlation lives.
Future<void> openPressureInsight(WidgetTester tester) async {
  await openInsights(tester);
  await pumpCountUp(tester);
}

/// Drags [target] into view with bounded pumps, and never `pumpAndSettle`.
Future<void> dragInsightsTo(WidgetTester tester, Finder target) async {
  for (int i = 0; i < 12 && target.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -260));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Insights, standing on its Sleep tab.
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

/// Insights, standing on its Factors tab — the trigger/protector map.
Future<void> openFactorsInsight(WidgetTester tester) async {
  await openInsights(tester);
  await tester.tap(
    find.descendant(
      of: find.byType(SdSegmentedTabsV2),
      matching: find.text('Factors'),
    ),
  );
  await pumpCountUp(tester);
}

/// Insights, standing on its Activity tab — same reason as [openSleepInsight].
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

/// Opens the log flow from the dashboard's hero button (the flow is a pushed route now, not a tab). Leaves the tester on the intensity step.
Future<void> openLog(WidgetTester tester) async {
  await tester.tap(find.text('Log an attack'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

/// Taps through the sacred flow with sensible defaults, starting from the dashboard.
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

  // Expanded and collapsed action rows both stay mounted (cross-fade on scroll), so the label matches twice — .first is the visible, tappable expanded one.
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

import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

import '../logging/app_logger.dart';

/// The single place the app talks to Firebase Analytics.
///
/// Every event is a typed method here — feature code never types an event
/// name or a parameter key, so the whole inventory of what we send is this
/// one file, reviewable in one read.
///
/// PRIVACY (hard rule 1): analytics carries *usage* only, never health data.
/// No attack intensity, no head location, no medication names, no attack
/// timestamps, no coordinates — ever, not even hashed. Counts and enum-ish
/// labels (which step, which export format) are fine; the values a user
/// logged are not. If a new event needs one of those, the answer is no.
///
/// Silent until [init] runs (it is only called from `main`), so widget tests
/// and any pre-Firebase code path are automatic no-ops rather than crashes.
/// Every call is fire-and-forget: a failed log must never break a user flow.
abstract final class AppAnalytics {
  // --- Event names (Firebase: snake_case, ≤40 chars). ---
  static const String _appOpen = 'app_open';
  static const String _onboardingCompleted = 'onboarding_completed';
  static const String _logFlowStep = 'log_flow_step';
  static const String _attackLogged = 'attack_logged';
  static const String _attackEdited = 'attack_edited';
  static const String _attackDeleted = 'attack_deleted';
  static const String _medicationAdded = 'medication_added';
  static const String _medicationRenamed = 'medication_renamed';
  static const String _medicationScanned = 'medication_label_scanned';
  static const String _medicationDeleted = 'medication_deleted';
  static const String _reminderAdded = 'reminder_added';
  static const String _reminderTimeEdited = 'reminder_time_edited';
  static const String _reminderToggled = 'reminder_toggled';
  static const String _reminderDeleted = 'reminder_deleted';
  static const String _alertsToggled = 'alerts_toggled';
  static const String _alertThresholdSet = 'alert_threshold_set';
  static const String _healthConnectionToggled = 'health_connection_toggled';
  static const String _signOut = 'sign_out';
  static const String _profileNameUpdated = 'profile_name_updated';
  static const String _signInFailed = 'sign_in_failed';
  static const String _premiumGateTapped = 'premium_gate_tapped';
  static const String _paywallCtaTapped = 'paywall_cta_tapped';
  static const String _purchaseStarted = 'purchase_started';
  static const String _purchaseCompleted = 'purchase_completed';
  static const String _purchaseRestored = 'purchase_restored';
  static const String _forceUpdateShown = 'force_update_shown';
  static const String _forceUpdateCtaTapped = 'force_update_cta_tapped';
  static const String _dataExported = 'data_exported';
  static const String _doctorReportShared = 'doctor_report_shared';
  static const String _exportShared = 'export_shared';
  static const String _exportSavedToDevice = 'export_saved_to_device';
  static const String _exportDeleted = 'export_deleted';
  static const String _dataWiped = 'data_wiped';

  // --- Parameter keys. ---
  static const String _pStep = 'step';
  static const String _pEnabled = 'enabled';
  static const String _pThresholdHpa = 'threshold_hpa';
  static const String _pMethod = 'method';
  static const String _pReason = 'reason';
  static const String _pFormat = 'format';
  static const String _pAttackCount = 'attack_count';
  static const String _pSignedIn = 'signed_in';
  static const String _pPeriod = 'period';

  // --- User properties (cohorts we slice every other metric by). ---
  static const String _upSignedIn = 'signed_in';
  static const String _upPremium = 'is_premium';
  static const String _upAlertsEnabled = 'alerts_enabled';

  /// Null until [init] — the no-op switch, and also what keeps this file
  /// importable from tests that never boot Firebase.
  static FirebaseAnalytics? _analytics;

  static bool get isReady => _analytics != null;

  /// Wires up the SDK. Called once from `main`, after `Firebase.initializeApp`.
  static Future<void> init({bool collectionEnabled = true}) async {
    final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

    await analytics.setAnalyticsCollectionEnabled(collectionEnabled);
    _analytics = analytics;
    logAppOpen();
  }

  /// Feeds `screen_view` for pushed routes automatically. Empty before
  /// [init] so the router builds fine in tests. Tab switches inside the
  /// shell never push a route — [logScreenView] covers those.
  static List<NavigatorObserver> get navigatorObservers {
    final FirebaseAnalytics? analytics = _analytics;

    if (analytics == null) return const <NavigatorObserver>[];
    return <NavigatorObserver>[FirebaseAnalyticsObserver(analytics: analytics)];
  }

  /// The kill switch behind a future "share usage data" setting. Also stops
  /// the SDK from collecting anything at all, not just our events.
  static void setCollectionEnabled(bool enabled) {
    unawaited(_analytics?.setAnalyticsCollectionEnabled(enabled));
  }

  // --- Identity / cohorts ---------------------------------------------

  /// [uid] is the Firebase Auth UID (opaque, not an email) or null when
  /// signed out. Anonymous users get a UID too — that is the point: the
  /// account-optional flow still needs to be measurable.
  static void setUser({required String? uid, required bool signedIn}) {
    unawaited(_analytics?.setUserId(id: uid));
    _setUserProperty(_upSignedIn, signedIn.toString());
  }

  static void setPremium(bool isPremium) =>
      _setUserProperty(_upPremium, isPremium.toString());

  static void setAlertsEnabled(bool enabled) =>
      _setUserProperty(_upAlertsEnabled, enabled.toString());

  // --- Screens ---------------------------------------------------------

  /// For screens no navigator observer sees: the five shell tabs, which are
  /// branches of an IndexedStack rather than pushed routes.
  static void logScreenView(String screenName) {
    unawaited(
      _guard(
        () => _analytics!.logScreenView(screenName: screenName),
        'screen_view($screenName)',
      ),
    );
  }

  // --- App / onboarding ------------------------------------------------

  static void logAppOpen() => _log(_appOpen);

  static void logOnboardingCompleted({required double thresholdHpa}) => _log(
    _onboardingCompleted,
    <String, Object>{_pThresholdHpa: thresholdHpa},
  );

  // --- The 3-tap log flow (funnel) -------------------------------------

  /// [step] is the flow step reached (`intensity`, `location`, …) — the
  /// drop-off funnel for the sacred flow. The picked *values* stay local.
  static void logLogFlowStep(String step) =>
      _log(_logFlowStep, <String, Object>{_pStep: step});

  /// Deliberately parameterless: intensity, head location and medication
  /// are health data (see the privacy note above).
  static void logAttackLogged() => _log(_attackLogged);

  static void logAttackEdited() => _log(_attackEdited);

  static void logAttackDeleted() => _log(_attackDeleted);

  // --- Medications & reminders ------------------------------------------
  // No medication names: what someone takes is health data.

  static void logMedicationAdded() => _log(_medicationAdded);

  static void logMedicationRenamed() => _log(_medicationRenamed);

  /// That a label was scanned — never what it said.
  static void logMedicationScanned() => _log(_medicationScanned);

  static void logMedicationDeleted() => _log(_medicationDeleted);

  static void logReminderAdded() => _log(_reminderAdded);

  static void logReminderTimeEdited() => _log(_reminderTimeEdited);

  static void logReminderToggled({required bool enabled}) =>
      _log(_reminderToggled, <String, Object>{_pEnabled: enabled.toString()});

  static void logReminderDeleted() => _log(_reminderDeleted);

  // --- Alerts -----------------------------------------------------------

  static void logAlertsToggled({required bool enabled}) {
    _log(_alertsToggled, <String, Object>{_pEnabled: enabled.toString()});
    setAlertsEnabled(enabled);
  }

  static void logAlertThresholdSet(double thresholdHpa) =>
      _log(_alertThresholdSet, <String, Object>{_pThresholdHpa: thresholdHpa});

  // --- Apple Health -------------------------------------------------------
  // Whether the source is connected, and nothing from it: hours slept are
  // health data and never leave the device (hard rule 1).

  static void logHealthConnectionToggled({required bool enabled}) => _log(
    _healthConnectionToggled,
    <String, Object>{_pEnabled: enabled.toString()},
  );

  // --- Auth -------------------------------------------------------------

  /// Firebase's reserved `login` event, so it shows up in the standard
  /// reports. [method] is the provider name (google/apple).
  static void logLogin(String method) {
    unawaited(
      _guard(() => _analytics!.logLogin(loginMethod: method), 'login($method)'),
    );
  }

  static void logSignInFailed({
    required String method,
    required String reason,
  }) =>
      _log(_signInFailed, <String, Object>{_pMethod: method, _pReason: reason});

  static void logSignOut() => _log(_signOut);

  /// The name only — never the value the user typed.
  static void logProfileNameUpdated() => _log(_profileNameUpdated);

  // --- Premium ----------------------------------------------------------

  /// A locked surface was tapped — the demand signal for the paywall.
  static void logPremiumGateTapped({required bool signedIn}) => _log(
    _premiumGateTapped,
    <String, Object>{_pSignedIn: signedIn.toString()},
  );

  static void logPaywallCtaTapped({required bool signedIn}) => _log(
    _paywallCtaTapped,
    <String, Object>{_pSignedIn: signedIn.toString()},
  );

  /// [period] is the plan shape (`monthly`, `yearly`, `lifetime`) — never a
  /// price or a transaction id. The store owns revenue reporting; this is
  /// only the funnel from tap to entitlement.
  static void logPurchaseStarted({required String period}) =>
      _log(_purchaseStarted, <String, Object>{_pPeriod: period});

  static void logPurchaseCompleted({required String period}) =>
      _log(_purchaseCompleted, <String, Object>{_pPeriod: period});

  static void logPurchaseRestored() => _log(_purchaseRestored);

  // --- Force update ------------------------------------------------------

  /// The blocking sheet went up — how many installs are actually stuck on
  /// an old build, and how many of them then leave for the store.
  static void logForceUpdateShown() => _log(_forceUpdateShown);

  static void logForceUpdateCtaTapped() => _log(_forceUpdateCtaTapped);

  // --- Settings / GDPR ---------------------------------------------------

  static void logDataExported({
    required String format,
    required int attackCount,
  }) => _log(_dataExported, <String, Object>{
    _pFormat: format,
    _pAttackCount: attackCount,
  });

  static void logDoctorReportShared({required int attackCount}) =>
      _log(_doctorReportShared, <String, Object>{_pAttackCount: attackCount});

  /// Re-sharing / saving / dropping something already in the export history.
  /// The format only — never the file's contents (hard rule 1).
  static void logExportShared({required String format}) =>
      _log(_exportShared, <String, Object>{_pFormat: format});

  static void logExportSavedToDevice({required String format}) =>
      _log(_exportSavedToDevice, <String, Object>{_pFormat: format});

  static void logExportDeleted() => _log(_exportDeleted);

  static void logDataWiped() => _log(_dataWiped);

  // --- Plumbing ----------------------------------------------------------

  static void _log(String name, [Map<String, Object>? parameters]) {
    unawaited(
      _guard(
        () => _analytics!.logEvent(name: name, parameters: parameters),
        parameters == null ? name : '$name $parameters',
      ),
    );
  }

  static void _setUserProperty(String name, String? value) {
    unawaited(
      _guard(
        () => _analytics!.setUserProperty(name: name, value: value),
        'property $name=$value',
      ),
    );
  }

  /// No-op before [init], and a swallowed warning after: analytics is never
  /// worth failing a user action over.
  static Future<void> _guard(
    Future<void> Function() send,
    String description,
  ) async {
    if (_analytics == null) return;

    try {
      await send();
      AppLogger.debug('📊 $description');
    } catch (error) {
      AppLogger.warning('Analytics failed', '$description — $error');
    }
  }
}

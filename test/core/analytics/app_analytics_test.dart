import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/analytics/app_analytics.dart';
import 'package:migraine_tracker/core/constants/log_tag_constant.dart';
import 'package:migraine_tracker/core/logging/crash_reporter.dart';
import 'package:system_design/common.dart';

/// Both helpers must be inert until `main` initializes them: widget tests
/// boot the app without Firebase, so any call that reached the SDK here
/// would crash every screen that logs an event.
void main() {
  test('analytics is a no-op before init', () {
    expect(AppAnalytics.isReady, isFalse);
    expect(() {
      AppAnalytics.logAttackLogged();
      AppAnalytics.logLogFlowStep('location');
      AppAnalytics.logScreenView('dashboard');
      AppAnalytics.logLogin('google');
      AppAnalytics.logDataExported(format: 'json', attackCount: 3);
      AppAnalytics.setUser(uid: 'uid', signedIn: true);
      AppAnalytics.setPremium(true);
    }, returnsNormally);
  });

  test('crash reporter is a no-op before init', () {
    expect(CrashReporter.isReady, isFalse);
    expect(() {
      CrashReporter.recordError(
        Exception('boom'),
        StackTrace.current,
        reason: 'test',
      );
      CrashReporter.log('breadcrumb');
      CrashReporter.setUserId('uid');
      CrashReporter.setCustomKey('flavor', 'dev');
    }, returnsNormally);
  });

  /// `SdLogger.error` reports through whatever `SdCrashReporter.instance`
  /// happens to be, and the adapter that points it here is attached in
  /// `AppBootstrap`. Nothing attaches it in a test, so the whole logging
  /// surface must stay inert — a single reachable Crashlytics call would
  /// crash every screen that logs a caught failure.
  test('SdLogger reports to the no-op before bootstrap attaches one', () {
    expect(
      () => SdLogger.error(
        LogTagConstant.bootstrap,
        'boom',
        error: Exception('boom'),
        stackTrace: StackTrace.current,
      ),
      returnsNormally,
    );
  });

  test('navigator observers are empty before init', () {
    expect(AppAnalytics.navigatorObservers, isEmpty);
  });
}

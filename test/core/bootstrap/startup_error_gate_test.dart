import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/bootstrap/app_bootstrap.dart';
import 'package:migraine_tracker/core/bootstrap/startup_error_gate.dart';
import 'package:migraine_tracker/core/bootstrap/startup_failures_provider.dart';
import 'package:migraine_tracker/core/theme/app_theme.dart';
import 'package:migraine_tracker/l10n/gen/app_localizations.dart';

/// A step that failed in `main` takes the whole app over — but only one the
/// app cannot run without.
void main() {
  /// Pumps the gate over a stand-in app, with [failures] as what `main` saw.
  Future<void> pumpGate(
    WidgetTester tester, {
    required Map<String, String> failures,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [startupFailuresProvider.overrideWithValue(failures)],
        child: ScreenUtilInit(
          designSize: const Size(393, 852),
          builder: (BuildContext context, Widget? child) => MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const StartupErrorGate(child: Text('the app')),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a clean start shows the app', (WidgetTester tester) async {
    await pumpGate(tester, failures: const <String, String>{});

    expect(find.text('the app'), findsOneWidget);
    expect(find.byType(StartupErrorView), findsNothing);
  });

  testWidgets('a failed Firebase step shows the error screen instead', (
    WidgetTester tester,
  ) async {
    await pumpGate(
      tester,
      failures: const <String, String>{
        AppBootstrap.firebaseStep:
            '[core/duplicate-app] A Firebase App named "[DEFAULT]" already '
                'exists',
      },
    );

    expect(find.byType(StartupErrorView), findsOneWidget);
    expect(find.text('the app'), findsNothing);
    // Outside production the raw error is on screen, because the person who
    // can fix this one is the person who built it.
    expect(find.textContaining('duplicate-app'), findsOneWidget);
  });

  testWidgets('a step the app can do without does not', (
    WidgetTester tester,
  ) async {
    await pumpGate(
      tester,
      failures: const <String, String>{'Timezone': 'no zone for this device'},
    );

    expect(find.text('the app'), findsOneWidget);
    expect(find.byType(StartupErrorView), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/bootstrap/startup_error_gate.dart';
import 'package:migraine_tracker/core/bootstrap/startup_failures_provider.dart';
import 'package:migraine_tracker/core/env/flavor_config_mismatch.dart';
import 'package:migraine_tracker/core/theme/app_theme.dart';
import 'package:migraine_tracker/l10n/gen/app_localizations.dart';

/// A step that failed in `main` takes the whole app over — but only one that
/// says the *build* is wrong, never one that says the backend is absent.
void main() {
  const FlavorConfigMismatch mismatch = FlavorConfigMismatch(
    expected: 'migraine-tracker-9f7b2',
    actual: 'migraine-tracker-prd',
  );

  /// Pumps the gate over a stand-in app, with [failures] as what `main` saw.
  Future<void> pumpGate(
    WidgetTester tester, {
    required Map<String, Object> failures,
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
    await pumpGate(tester, failures: const <String, Object>{});

    expect(find.text('the app'), findsOneWidget);
    expect(find.byType(StartupErrorView), findsNothing);
  });

  testWidgets('a flavour mismatch replaces the app with the error screen', (
    WidgetTester tester,
  ) async {
    await pumpGate(
      tester,
      failures: const <String, Object>{'Firebase': mismatch},
    );

    expect(find.byType(StartupErrorView), findsOneWidget);
    expect(find.text('the app'), findsNothing);
  });

  // The case that breaks a fresh clone if the policy widens: a build whose
  // backend is not configured, or a device with no signal, still gets an app —
  // the data is local-first and hard rule 4 wants an attack logged offline.
  testWidgets('an unreachable backend is not fatal', (
    WidgetTester tester,
  ) async {
    await pumpGate(
      tester,
      failures: const <String, Object>{
        'Firebase': "[core/no-app] No Firebase App '[DEFAULT]' has been created",
      },
    );

    expect(find.text('the app'), findsOneWidget);
    expect(find.byType(StartupErrorView), findsNothing);
  });

  testWidgets('an unrelated failed step is not fatal', (
    WidgetTester tester,
  ) async {
    await pumpGate(
      tester,
      failures: const <String, Object>{'Timezone': 'no zone for this device'},
    );

    expect(find.text('the app'), findsOneWidget);
    expect(find.byType(StartupErrorView), findsNothing);
  });

  // The screen says a build is broken; it never says *which* two projects
  // disagree. That sentence names the owner's backend and the command that
  // rewrites it, and the console is where a developer reads it.
  testWidgets('the screen carries nothing from the failure', (
    WidgetTester tester,
  ) async {
    await pumpGate(
      tester,
      failures: const <String, Object>{'Firebase': mismatch},
    );

    expect(find.textContaining('migraine-tracker-9f7b2'), findsNothing);
    expect(find.textContaining('migraine-tracker-prd'), findsNothing);
    expect(find.textContaining('prepare-env-'), findsNothing);
    expect(find.textContaining('Flavour config mismatch'), findsNothing);
  });
}

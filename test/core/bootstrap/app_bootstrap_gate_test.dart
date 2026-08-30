import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/bootstrap/app_bootstrap_gate.dart';
import 'package:migraine_tracker/core/storage/secure_store.dart';
import 'package:migraine_tracker/features/splash/presentation/screens/splash_screen/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Never completes, so the gate stays on the branch that draws while bootstrap runs.
  testWidgets('shows the splash while bootstrap is pending', (
    WidgetTester tester,
  ) async {
    final Completer<SecureStore> pending = Completer<SecureStore>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appBootstrapProvider.overrideWith((ref) => pending.future)],
        child: const AppBootstrapGate(),
      ),
    );
    // Never pumpAndSettle here: the dots animate forever and it would wait out its whole timeout.
    await tester.pump();

    // The theme this branch builds reads `.sp` sizes, which throw when ScreenUtil is not initialized above it — that crash is what this test is here to catch.
    expect(tester.takeException(), isNull);
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}

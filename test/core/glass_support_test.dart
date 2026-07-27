import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:migraine_tracker/core/widgets/main_app_bar.dart';

import '../helpers/pump_app.dart';

/// The chrome follows what the engine can actually render (`AppGlass`), with
/// the bottom nav as the one deliberate exception.
void main() {
  /// Icons.home is the nav's selected dashboard icon and appears nowhere
  /// else, so this pins the floating pill specifically.
  final Finder navGlass = find.ancestor(
    of: find.byIcon(Icons.home),
    matching: find.byType(LiquidGlass),
  );

  final Finder appBarBlur = find.descendant(
    of: find.byType(MainAppBar),
    matching: find.byType(BackdropFilter),
  );

  testWidgets('a supported engine frosts the app bar', (tester) async {
    await pumpApp(tester);

    expect(appBarBlur, findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('an unsupported engine drops the app-bar glass', (tester) async {
    await pumpApp(tester, glassSupported: false);

    expect(appBarBlur, findsNothing);

    await finishTest(tester);
  });

  testWidgets('the bottom nav stays glass on either engine', (tester) async {
    await pumpApp(tester, glassSupported: false);

    expect(navGlass, findsOneWidget);

    await finishTest(tester);
  });
}
